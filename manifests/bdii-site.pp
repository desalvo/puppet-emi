class emi::bdii-site (
  $emi_version = 'emi-3',
  $emi_conf = 0,
  $yaim_bdii_site = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_bdii_site}",
) {

   package { "emi-bdii-site":
               ensure => latest,
               require => $emi::params::emi_base_reqs
           }
   package { $emi::params::openldap_servers: ensure => latest, require => Package["emi-bdii-site"] }

   file { "/root/services/${emi::params::yaim_bdii_site}":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "${yaim_bdii_site}",
      require => Package["emi-bdii-site"],
   }

   $logfile = "/root/${emi_version}-bdii-config-${emi_conf}.log"
   exec { "emi-config-bdii-site":
      command => "/opt/glite/yaim/bin/yaim -c -d 6 -s /root/site-info.def -n BDII_site &> ${logfile}",
      path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      creates => "${logfile}",
      require => [
                  Package["emi-bdii-site"],
                  Package[$emi::params::openldap_servers],
                  File["/root/services/${emi::params::yaim_bdii_site}"]
                 ],
      timeout => 0
   }
   exec { "validate-emi-config-bdii-site":
      command => "tail -n 1 ${logfile} | cut -d: -f 1 | sed -e 's/^ *//g' -e 's/ *$//g' | grep -v ERROR &> /dev/null",
      path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      onlyif  => "test -s ${logfile}",
      require => Exec["emi-config-bdii-site"],
      timeout => 0
   }
}
