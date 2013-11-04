class emi::bdii-site (
  $logserial
) inherits emi::service {
   package { "emi-bdii-site":
               ensure => latest,
               require => $emi::params::emi_base_reqs
           }
   package { "openldap2.4-servers": ensure => latest, require => Package["emi-bdii-site"] }

   file { "/root/services/glite-bdii_site":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "puppet:///modules/igi-emi/services/glite-bdii_site",
      require => Package["emi-bdii-site"],
   }

   $logfile = "/root/emi-bdii-config-${logserial}.log"
   exec { "emi-config-bdii-site":
      command => "/opt/glite/yaim/bin/yaim -c -d 6 -s /root/atlas-site-info.def -n BDII_site &> ${logfile}",
      unless  => "test -f ${logfile}",
      require => [Package["emi-bdii-site"],Package["openldap2.4-servers"],File["/root/services/glite-bdii_site"]],
      timeout => 0
   }
}
