class emi::creamce (
  $emi_version = 'emi-3',
  $emi_conf = 0,
  $yaim_creamce = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_creamce}",
  $yaim_dgas_sensors = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_dgas_sensors_conf}",
  $admin_list = undef,
  $dgas = false,
  $dgas_local = undef,
  $argus_host = undef,
  $lsf_master = undef,
  $lsf_mount = undef
) {
   package {["xml-commons-apis"]:
       ensure  => latest,
       notify  => Exec["emi-reconfig-creamce"],
       require => $emi::params::emi_base_reqs
   }

   package {"emi-cream-ce":
       ensure  => latest,
       notify  => Exec["emi-reconfig-creamce"],
       require => Package["xml-commons-apis"]
   }

   package {"emi-cream-nagios":
       ensure => latest,
       require => Package["emi-cream-ce"],
   }

   case $emi_version {
       'emi-1': {
           $xtra_pkgs = [ "openldap2.4-servers" ]
       }
       default: {
           if $operatingsystemrelease < 6 {
               $xtra_pkgs = [ "openldap2.4-servers" ]
           } else {
               $xtra_pkgs = []
           }
       }
   }

   if ($lsf_master) {
       $batch_pkgs = ['emi-lsf-utils']
       $batch_profile = "-n LSF_utils"
   } else {
       $batch_pkgs = []
       $batch_profile = ""
   }

   if ($dgas) {
       $dgas_pkgs = [
                     "glite-dgas-common",
                     "glite-dgas-hlr-clients",
                     "glite-dgas-hlr-sensors",
                     "glite-dgas-hlr-sensors-producers",
                     "yaim-dgas",
                    ]
       $dgas_profile = "-n DGAS_sensors"
   } else {
       $dgas_pkgs = []
       $dgas_profile = ""
   }

   $all_pkgs = unique(flatten([$batch_pkgs,$dgas_pkgs]))
   package { $all_pkgs: ensure => latest, require => Package["emi-cream-ce"] }

   file { "/root/services/${emi::params::yaim_creamce}":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "${yaim_creamce}",
      require => Package["emi-cream-ce"],
   }

   $conf_files = [
                  "/root/services/${emi::params::yaim_creamce}",
                 ]

   if ($dgas) {
       file { "/root/services/${emi::params::yaim_dgas_sensors_conf}":
          owner => "root",
          group => "root",
          mode => 0644,
          source  => "${yaim_dgas_sensors}",
          require => Package["emi-cream-ce"],
       }
       $dgas_common_files = [ "/root/services/${emi::params::yaim_dgas_sensors_conf}" ]

       if ($dgas_local) {
          file { $emi::params::dgas_localUserGroup2VOMap:
             owner => "root",
             group => "root",
             mode => 0644,
             source  => $dgas_local,
             require => Package["glite-dgas-hlr-sensors"],
          }
          $dgas_local_files = [ $emi::params::dgas_localUserGroup2VOMap ]
       } else {
          $dgas_local_files = []
       }

       $dgas_files = unique(flatten([$dgas_common_files,$dgas_local_files]))
   } else {
       $dgas_files = []
   }

   if ($admin_list) {
       file { $emi::params::admin_list_file:
          owner => "root",
          group => "root",
          mode => 0644,
          source  => $admin_list,
          require => Package["emi-cream-ce"],
       }
       $xtra_files = [ $emi::params::admin_list_file ]
   } else {
       $xtra_files = []
   }

   if ($argus_host) {
      mount { "/etc/grid-security/gridmapdir":
         ensure => mounted,
         atboot => true,
         device => "${argus_host}:/etc/grid-security/gridmapdir",
         fstype => "nfs",
         options => "defaults",
         require => Exec["emi-config-creamce"]
      }
   }

   $all_files = unique(flatten([$conf_files,$dgas_files,$xtra_files]))

   $logfile = "/root/${emi_version}-creamce-config-${emi_conf}.log"
   exec { "emi-config-creamce":
      command => "/bin/bash -c '. /etc/profile && /opt/glite/yaim/bin/yaim -c -d 6 -s /root/site-info.def -n creamCE $batch_profile $dgas_profile' &> ${logfile}",
      path => [ '/bin', '/usr/bin' ],
      creates => "${logfile}",
      require => [
                  Package["emi-cream-ce"],
                  Package[$all_pkgs],
                  File[$all_files]
                 ],
      timeout => 0
   }

   exec { "emi-reconfig-creamce":
      command => "/bin/rm -f ${logfile}",
      refreshonly => true,
      notify => Exec["emi-config-creamce"],
      timeout => 0
   }

   exec { "validate-emi-config-creamce":
      command => "/bin/false",
      path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      onlyif  => "test -s ${logfile} && tail -n 1 ${logfile} | grep ERROR: &> /dev/null",
      require => Exec["emi-config-creamce"],
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
         require => File["/root/lsf-bootstrap"]
      }

      Exec["lsf-bootstrap"] -> Exec["emi-config-creamce"]
   }
}
