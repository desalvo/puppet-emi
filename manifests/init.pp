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
#   Element type. Valid options are bdii-site,ui
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

   package { ["glite-yaim-core","glite-yaim-clients"]: ensure => latest, require => Package["emi-release"] }

   if ($igi) {
      file { "/etc/yum.repos.d/igi-emi.repo":
         owner => "root",
         group => "root",
         mode => 0644,
         source  => "puppet:///modules/emi/el${emi::params::elversion}/igi-emi.repo",
      }
   }

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


    # Install the host certificates for selected EMI types
    case $emi_type {
        'bdii-site': {
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

    case $emi_type {
        'ui': {
            notify {'EMI type $emi_type not implemented':}
        }
        'bdii-site': {
            class { 'emi::bdii-site':
               emi_conf => $emi_conf,
               emi_version => $emi_version,
            }
        }
        default: {
            fail ("Invalid emi type $emi_type")
        }
    }
}