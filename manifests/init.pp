# == Class: emi
#
# Generic class to configure EMI elements
#
# === Parameters
#
# [*mwtype*]
#   Middleware type version.
#   Valid options are: emi-1, emi-2, emi-3
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
#    mwtype => 'emi-3',
#    siteinfo  => 'puppet:///modules/mymodule/config/site-info.def',
#    wnlist    => 'puppet:///modules/mymodule/config/wn-list.def',
#    groupconf => 'puppet:///modules/mymodule/config/groups.def',
#    userconf  => 'puppet:///modules/mymodule/config/users.def',
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
class emi(
  $mwtype = 'emi-3',
  $siteinfo = 'puppet:///modules/emi/config/site-info.def',
  $wnlist = 'puppet:///modules/emi/config/wn-list.conf',
  $groupconf = 'puppet:///modules/emi/config/groups.conf',
  $userconf = 'puppet:///modules/emi/config/users.conf',
  $igi = true
) inherits emi::params {

   include yumconfig::yum-priorities
   include yumconfig::yum-protectbase

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

   if $operatingsystemrelease < 6 {
      case $mwtype {
         'emi-1': {
             $emi_release = "http://repo-pd.italiangrid.it/mrepo/EMI/1/sl5/x86_64/updates/emi-release-1.0.1-1.sl5.noarch.rpm"
         }
         'emi-2': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/2/sl5/x86_64/base/emi-release-2.0.0-1.sl5.noarch.rpm"
         }
         default: {
             fail("Unsupported flavor $mwtype for $operatingsystem $operatingsystemrelease")
         }
      }
   } else {
      case $mwtype {
         'emi-2': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/2/sl6/x86_64/base/emi-release-2.0.0-1.sl6.noarch.rpm"
         }
         'emi-3': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl6/x86_64/base/emi-release-3.0.0-2.el6.noarch.rpm"
         }
         default: {
             fail("Unsupported flavor $mwtype for $operatingsystem $operatingsystemrelease")
         }
      }
   }

   package { "emi-release":
      ensure => installed,
      provider => rpm,
      source => $emi_release,
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
}
