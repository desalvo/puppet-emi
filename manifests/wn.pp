class emi::wn (
  $emi_version = 'emi-3',
  $emi_conf = 0,
  $yaim_wn = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_wn}",
  $yaim_mpi_wn = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_mpi_wn}",
  $yaim_glexec_wn = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_glexec_wn}",
  $lsf_master = undef,
  $lsf_mount = undef,
  $afs = false,
  $glexec = true
) {
    package {["globus-gssapi-gsi","globus-gss-assist"]:
        ensure  => latest,
        notify  => Exec["emi-reconfig-wn"],
        require => $emi::params::emi_base_reqs
    }

    package {"emi-wn":
        ensure  => latest,
        notify  => Exec["emi-reconfig-wn"],
        require => [Package["globus-gssapi-gsi"],Package["globus-gss-assist"]]
    }

    case $emi_version {
        'emi-1': {
            $pypkgs = [
                      "dpm-libs.x86_64", "dpm-devel.x86_64",
                      "lcgdm-libs.x86_64", "lcgdm-devel.x86_64",
                      "lfc.x86_64", "lfc-devel.x86_64",
                      "dpm-python26.x86_64", "lfc-python26.x86_64",
                      "gfal-python26.x86_64", "lcg-util-python26.x86_64",
                      ]
        }
        default: {
            if $operatingsystemrelease < 6 {
                $pypkgs = [
                           "dpm-libs.x86_64", "dpm-devel.x86_64",
                           "dpm-libs.i386", "dpm-devel.i386",
                           "lcgdm-libs.x86_64", "lcgdm-devel.x86_64",
                           "lcgdm-libs.i386", "lcgdm-devel.i386",
                           "lfc.x86_64", "lfc-devel.x86_64",
                           "lfc.i386", "lfc-devel.i386",
                           "dpm-python26.x86_64", "lfc-python26.x86_64",
                           "dpm-python26.i386", "lfc-python26.i386",
                           "gfal-python26.x86_64", "lcg-util-python26.x86_64",
                          ]
            } else {
                $pypkgs = [
                           "dpm-libs.x86_64", "dpm-devel.x86_64",
                           "dpm-libs.i686", "dpm-devel.i686",
                           "lcgdm-libs.x86_64", "lcgdm-devel.x86_64",
                           "lcgdm-libs.i686", "lcgdm-devel.i686",
                           "lfc.x86_64", "lfc-devel.x86_64",
                           "lfc-libs.i686", "lfc-devel.i686",
                          ]
            }
        }
    }

    package { $pypkgs:
       ensure => latest,
       require => Package["emi-wn"],
       notify  => Exec["emi-reconfig-wn"]
    }

    file { "/root/services/${emi::params::yaim_wn}":
       owner   => "root",
       group   => "root",
       mode    => 0644,
       source  => "${yaim_wn}",
       require => Package["emi-wn"],
    }

    file { "/root/services/${emi::params::yaim_mpi_wn}":
       owner => "root",
       group => "root",
       mode => 0644,
       source  => "${yaim_mpi_wn}",
       require => Package["emi-wn"],
    }

    $wn_pkgs = [ Package['emi-wn'] ]
    $wn_files = [ File["/root/services/${emi::params::yaim_wn}"], File["/root/services/${emi::params::yaim_mpi_wn}"] ]

    if ($glexec) {
       file { "/root/services/${emi::params::yaim_glexec_wn}":
          owner => "root",
          group => "root",
          mode => 0644,
          source  => "${yaim_glexec_wn}",
          require => Package["emi-wn"],
       }
       $glexec_yaim_opt = '-n GLEXEC_wn'
       package { "${emi::params::yaim_glexec_wn_pkg}":
          ensure => latest,
          require => Package["emi-wn"],
       }
       package { "${emi::params::glexec_wn_pkg}":
          ensure => latest,
          require => Package["${emi::params::yaim_glexec_wn_pkg}"],
          notify  => Exec["emi-reconfig-wn"]
       }
       $glexec_pkgs = [ Package["${emi::params::glexec_wn_pkg}"] ]
       $glexec_files = [ File["/root/services/${emi::params::yaim_glexec_wn}"] ]
       $all_pkgs = unique(flatten([$wn_pkgs,$glexec_pkgs]))
       $all_files = unique(flatten([$wn_files,$glexec_files]))
    } else {
       $all_pkgs = $wn_pkgs
       $all_files = $wn_files
    }

    $logfile = "/root/${emi_version}-wn-config-${emi_conf}.log"
    exec { "emi-config-wn":
       command => "/opt/glite/yaim/bin/yaim -c -d 6 -s /root/site-info.def -n WN -n ATLAS_LOCALENV ${glexec_yaim_opt} &> ${logfile}",
       creates => "${logfile}",
       require => [ $all_pkgs, $all_files ],
       timeout => 0
    }
    exec { "emi-reconfig-wn":
       command => "/bin/rm -f ${logfile}",
       refreshonly => true,
       notify => Exec["emi-config-wn"],
       timeout => 0
    }

    exec { "validate-emi-config-wn":
       command => "/bin/false",
       path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
       onlyif  => "test -s ${logfile} && tail -n 1 ${logfile} | grep ERROR: &> /dev/null",
       require => Exec["emi-config-wn"],
       logoutput => true,
       timeout => 0
    }

    if ($lsf_master and $lsf_mount) {
        file { "/lsf": ensure => directory }
        file { "/root/lsf-bootstrap":
           owner => root,
           group => root,
           mode  => 755,
           source => "puppet:///modules/emi/config/lsf-bootstrap",
           require => Mount["/lsf"],
        }
        mount { "/lsf":
           ensure => mounted,
           atboot => true,
           device => "${lsf_master}:${lsf_mount}",
           fstype => "nfs",
           options => "intr,defaults",
           require => File["/lsf"]
        }

        exec { "lsf-bootstrap":
           command => "/root/lsf-bootstrap && touch /root/lsf-config-done",
           creates => "/root/lsf-config-done",
        }
    }
}
