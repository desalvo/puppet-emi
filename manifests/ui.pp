class emi::ui (
  $emi_version = 'emi-3',
  $emi_conf = 0,
  $yaim_ui = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_ui}",
  $lsf_master = undef,
  $lsf_mount = undef
) {
    package {["globus-gssapi-gsi","globus-gss-assist"]:
        ensure  => latest,
        notify  => Exec["emi-reconfig-ui"],
        require => $emi::params::emi_base_reqs
    }

    package {"emi-ui":
        ensure  => latest,
        notify  => Exec["emi-reconfig-ui"],
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
                           "dpm-python26.x86_64", "lfc-python26.x86_64",
                           "gfal-python26.x86_64", "lcg-util-python26.x86_64",
                           "globus-gram-client-tools",
                          ]
            } else {
                $pypkgs = [
                           "dpm-libs.x86_64", "dpm-devel.x86_64",
                           "dpm-libs.i686", "dpm-devel.i686",
                           "lcgdm-libs.x86_64", "lcgdm-devel.x86_64",
                           "lcgdm-libs.i686", "lcgdm-devel.i686",
                           "lfc.x86_64", "lfc-devel.x86_64",
                           "lfc-devel.i686",
                           "globus-gram-client-tools",
                          ]
            }
        }
    }

    package { $pypkgs: ensure => latest, require => Package["emi-ui"] }

    file { "/root/services/${emi::params::yaim_ui}":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "${yaim_ui}",
      require => Package["emi-ui"],
   }

   $logfile = "/root/${emi_version}-ui-config-${emi_conf}.log"
   exec { "emi-config-ui":
      command => "/opt/glite/yaim/bin/yaim -c -d 6 -s /root/site-info.def -n UI &> ${logfile}",
      creates => "${logfile}",
      require => [
                  Package["emi-ui"],
                  File["/root/services/${emi::params::yaim_ui}"]
                 ],
      timeout => 0
   }
   exec { "emi-reconfig-ui":
      command => "/bin/rm -f ${logfile}",
      refreshonly => true,
      notify => Exec["emi-config-ui"],
      timeout => 0
   }

   exec { "validate-emi-config-ui":
      command => "/bin/false",
      path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      onlyif  => "test -s ${logfile} && tail -n 1 ${logfile} | grep ERROR: &> /dev/null",
      require => Exec["emi-config-ui"],
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
         options => "defaults",
         require => File["/lsf"]
      }

      exec { "lsf-bootstrap":
         command => "/root/lsf-bootstrap && touch /root/lsf-config-done",
         creates => "/root/lsf-config-done",
      }
   }
}
