class emi::bdii-site (
  $logserial
) inherits emi::service {
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
