# == Class: emi
#
# Base class to configure EMI elements
#
# === Parameters
#
# [*emi_version*]
#   Version of the EMI middleware to use. Valid options are emi-1,emi-2,emi-3
#
# [*emi_type*]
#   Element type. Valid options are bdii-site,ui,creamce
#
# [*emi_conf*]
#   Element configuration serial.
#
# [*siteinfo*]
#   Site configuration. Override to use you customized configuration.
#
# [*wnlist*]
#   WN list. Override to use you customized configuration.
#
# [*groupconf*]
#   Groups configuration. Override to use you customized configuration.
#
# [*userconf*]
#   Users configuration. Override to use you customized configuration.
#
# [*igi*]
#   Add the IGI configurations.
#
# [*lsf_master*]
#   The LSF master hostname.
#
# [*lsf_mount*]
#   The mountpoint of the lsf software on the master.
#
# [*yaim_argus*]
#   The yaim argus service configuration file
#
# [*yaim_bdii_site*]
#   The yaim bdii site service configuration file
#
# [*yaim_creamce*]
#   The yaim cream CE service configuration file
#
# [*yaim_ui*]
#   The yaim UI service configuration file
#
# [*yaim_wn*]
#   The yaim WN service configuration file
#
# [*yaim_mpi_wn*]
#   The yaim MPI WN service configuration file
#
# [*yaim_glexec_wn*]
#   The yaim Glexec WN service configuration file
#
# [*dgas*]
#   Set this to true to use DGAS
#
# [*yaim_dgas_sensors*]
#   The yaim dgas_sensors service configuration file
#
# [*dgas_local*]
#   The dgas local map, only for one CE in the site
#
# [*argus_host*]
#   The argus host from where to mount the gridmap dir
#
# [*admin_list*]
#   The cream CE admin-list file
#
# [*afs*]
#   Set this to true to enable afs support (WN only)
#
# [*glexec*]
#   Enable Glexec WN if set to true
#
# [*vos*]
#   A comma-separated list of VOs to support, needed for ARGUS
#
# === Examples
#
#  class { emi:
#    emi_version => 'puppet:///modules/mymodule/config/site-info.def',
#    emi_type    => 'ui',
#    emi_conf    => 0,
#    siteinfo    => 'puppet:///modules/mymodule/config/site-info.def',
#    wnlist      => 'puppet:///modules/mymodule/config/wn-list.def',
#    groupconf   => 'puppet:///modules/mymodule/config/groups.def',
#    userconf    => 'puppet:///modules/mymodule/config/users.def',
#  }
#
# === Authors
#
# Alessandro De Salvo <Alessandro.DeSalvo@roma1.infn.it>
#
# === Copyright
#
# Copyright 2013 Alessandro De Salvo
#
class emi (
  $emi_version = 'emi-3',
  $emi_type = 'ui',
  $emi_conf = 0,
  $siteinfo = 'puppet:///modules/emi/config/site-info.def',
  $wnlist = 'puppet:///modules/emi/config/wn-list.conf',
  $groupconf = 'puppet:///modules/emi/config/groups.conf',
  $userconf = 'puppet:///modules/emi/config/users.conf',
  $igi = true,
  $cert = undef,
  $key = undef,
  $yaim_argus = "puppet:///modules/emi/services/emi-3/gllite-argus_server",
  $yaim_bdii_site = "puppet:///modules/emi/services/emi-3/emi-bdii_site",
  $yaim_ui = "puppet:///modules/emi/services/emi-3/glite-ui",
  $yaim_wn = "puppet:///modules/emi/services/emi-3/glite-wn",
  $yaim_mpi_wn = "puppet:///modules/emi/services/emi-3/glite-mpi_wn",
  $yaim_glexec_wn = "puppet:///modules/emi/services/emi-3/glite-glexec_wn",
  $yaim_creamce = "puppet:///modules/emi/services/emi-3/glite-creamce",
  $dgas = false,
  $yaim_dgas_sensors = "puppet:///modules/emi/services/emi-3/dgas_sensors",
  $admin_list = "puppet:///modules/emi/services/emi-3/admin-list",
  $dgas_local = undef,
  $argus_host = undef,
  $afs = false,
  $glexec = true,
  $lsf_master = undef,
  $lsf_mount = '/lsf',
  $vos = 'dteam,ops',
) {

   include yumconfig::yum-priorities
   include yumconfig::yum-protectbase

   class { 'emi::params': emi_version => $emi_version }

   # Fix for sudo bug
   file {"/root/fix-sudo.sh":
         owner  => root,
         group => "root",
         mode => 0755,
         source  => "puppet:///modules/emi/scripts/fix-sudo.sh",
   }

   exec { "fix-sudo-bug":
      command => "/root/fix-sudo.sh",
      onlyif  => "/root/fix-sudo.sh check",
      require => File["/root/fix-sudo.sh"],
      timeout => 0
   }

   package { "emi-release":
      ensure => installed,
      provider => rpm,
      source => $emi::params::emi_release,
      require => [Exec["fix-sudo-bug"],Package[$yumconfig::params::yum_priorities_package],Package[$yumconfig::params::yum_protectbase_package]]
   }

   if ($igi) {
      file { "/etc/yum.repos.d/igi-emi.repo":
         owner => "root",
         group => "root",
         mode => 0644,
         source  => "puppet:///modules/emi/el${emi::params::elversion}/${emi::params::igi_emi_repo}",
      }
      package { "yaim-addons": ensure => latest, require => File["/etc/yum.repos.d/igi-emi.repo"] }
      $emi_repos = [Package["emi-release"],File["/etc/yum.repos.d/igi-emi.repo"]]
   } else {
      $emi_repos = Package["emi-release"]
   }

   package { ["glite-yaim-core","glite-yaim-clients"]: ensure => latest, require => $emi_repos }

   file { "/root/site-info.def":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => [
                   "${siteinfo}.${hostname}",
                   "${siteinfo}",
                 ]
   }

   file { "/root/wn-list.conf":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "$wnlist",
   }

   file { "/root/groups.conf":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "$groupconf",
   }

   file { "/root/users.conf":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "$userconf",
   }

   file { "/root/services":
      ensure => directory,
      owner => "root",
      group => "root",
      mode => 0755,
   }

   file { "/opt/glite/yaim/node-info.d/atlas_localenv":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "puppet:///modules/emi/config/atlas_localenv",
      require => Package["glite-yaim-clients"],
   }

   file { "/opt/glite/yaim/functions/config_atlas_localenv":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "puppet:///modules/emi/config/config_atlas_localenv",
      require => Package["glite-yaim-clients"],
   }

   augeas{ "epel enable" :
        context => "/files/etc/yum.repos.d/epel.repo",
        changes => [
            "set epel/enabled 1",
        ],
    }

   if $operatingsystemrelease >= 6 {
       augeas{ "epel raise priority" :
            context => "/files/etc/yum.repos.d/epel.repo",
            changes => [
                "set epel/priority 50",
            ],
        }
    }

    # WLCG repository
    yumrepo {'wlcg':
        descr    => 'WLCG Repository',
        baseurl  => $emi::params::wlcg_repo_url,
        protect  => 1,
        enabled  => 1,
        priority => 1,
        gpgcheck => 0
    }

    # Install the host certificates for selected EMI types
    case $emi_type {
        'bdii-site','creamce': {
            if ($cert and $key) {
                class {'emi::service':
                    cert     => $cert,
                    key      => $key,
                    require  => Package['ca-policy-egi-core'],
                }
            } else {
                fail ("No certificates specified for emi type $emi_type")
            }
        }
    }

    file { "/etc/sysconfig/fetch-crl":
        ensure  => present,
        owner => "root",
        group => "root",
        mode => 0644,
    }


    case $emi_type {
        'argus': {
            class { 'emi::argus':
               emi_conf       => $emi_conf,
               emi_version    => $emi_version,
               yaim_argus     => $yaim_argus,
               vos            => $vos,
               require        => File["/root/services"]
            }
        }
        'bdii-site': {
            class { 'emi::bdii-site':
               emi_conf       => $emi_conf,
               emi_version    => $emi_version,
               yaim_bdii_site => $yaim_bdii_site,
               require        => File["/root/services"]
            }
        }
        'creamce': {
            class { 'emi::creamce':
               emi_conf          => $emi_conf,
               emi_version       => $emi_version,
               yaim_creamce      => $yaim_creamce,
               yaim_dgas_sensors => $yaim_dgas_sensors,
               admin_list        => $admin_list,
               dgas              => $dgas,
               dgas_local        => $dgas_local,
               argus_host        => $argus_host,
               lsf_master        => $lsf_master,
               lsf_mount         => $lsf_mount,
               require           => File["/root/services"]
            }
        }
        'ui': {
            class { 'emi::ui':
               emi_conf    => $emi_conf,
               emi_version => $emi_version,
               yaim_ui     => $yaim_ui,
               lsf_master  => $lsf_master,
               lsf_mount   => $lsf_mount,
               require     => File["/root/services"]
            }
        }
        'wn': {
            class { 'emi::wn':
               emi_conf       => $emi_conf,
               emi_version    => $emi_version,
               yaim_wn        => $yaim_wn,
               yaim_mpi_wn    => $yaim_mpi_wn,
               yaim_glexec_wn => $yaim_glexec_wn,
               lsf_master     => $lsf_master,
               lsf_mount      => $lsf_mount,
               afs            => $afs,
               glexec         => $glexec,
               require        => File["/root/services"]
            }
        }
        default: {
            fail ("Invalid emi type $emi_type")
        }
    }
}
