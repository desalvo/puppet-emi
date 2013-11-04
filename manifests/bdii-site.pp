class emi::bdii-site (
  $cert,
  $key,
  $emi_version = 'emi-3',
  $emi_conf = 0,
  $siteinfo = 'puppet:///modules/emi/config/site-info.def',
  $wnlist = 'puppet:///modules/emi/config/wn-list.conf',
  $groupconf = 'puppet:///modules/emi/config/groups.conf',
  $userconf = 'puppet:///modules/emi/config/users.conf',
  $igi = true
) {
   include emi::params

   class {'emi::base':
      emi_version => $emi_version,
      siteinfo    => $siteinfo,
      wnlist      => $wnlist,
      groupconf   => $groupconf,
      userconf    => $userconf,
      igi         => $igi
   }

   class {'emi::service':
      cert => $cert,
      key  => $key,
      require => Package['ca-policy-egi-core'],
   }

   package { "emi-bdii-site":
               ensure => latest,
               require => $emi::params::emi_base_reqs
           }
   package { "${::params::openldap_servers}": ensure => latest, require => Package["emi-bdii-site"] }

   file { "/root/services/${::params::yaim-bdii_site}":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "puppet:///modules/igi-emi/services/${::params::emi_version}/${::params::yaim-bdii_site}",
      require => Package["emi-bdii-site"],
   }

   $logfile = "/root/emi-bdii-config-${logserial}.log"
   exec { "emi-config-bdii-site":
      command => "/opt/glite/yaim/bin/yaim -c -d 6 -s /root/atlas-site-info.def -n BDII_site &> ${logfile}",
      path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      unless  => "test -f ${logfile}",
      require => [Package["emi-bdii-site"],Package[${::params::openldap_servers}],File["/root/services/${::params::yaim-bdii_site}"]],
      timeout => 0
   }
}
