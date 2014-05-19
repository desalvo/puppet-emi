class emi::argus (
  $emi_version = 'emi-3',
  $emi_conf = 0,
  $site_domain = $domain,
  $vos = 'dteam,ops',
  $yaim_argus = "puppet:///modules/emi/services/${emi_version}/${emi::params::yaim_argus}",
) {
    # Export the gridmapdir directory
    file { "/etc/grid-security/gridmapdir": ensure => directory }
    nfs-share { "argus shares":
               shares => ["/etc/grid-security/gridmapdir"],
               share_access => "141.108.38.0/23",
               share_options => "rw,no_root_squash",
               require => File["/etc/grid-security/gridmapdir"]
    }

    package {"emi-argus":
        ensure  => latest,
        notify  => Exec["emi-reconfig-argus"],
        require => $emi::params::emi_base_reqs
    }

    package { $emi::params::openldap_servers: ensure => latest, require => Package["emi-argus"] }

    package { "fetch-crl":
        ensure  => latest,
        require => Package["emi-argus"]
    }

    file { "/root/services/${emi::params::yaim_argus}":
       owner   => "root",
       group   => "root",
       mode    => 0644,
       source  => "${yaim_argus}",
       require => Package["emi-argus"],
    }

    file { "/root/local-policies.spl":
       owner => "root",
       group => "root",
       mode => 0644,
       content => template("emi/local-policies.spl.erb"),
    }

    file { "/root/from-groupmap-to-policy.sh":
        owner => "root",
        group => "root",
        mode => 0755,
        source  => "puppet:///modules/emi/config/from-groupmap-to-policy.sh",
    }

    $logfile = "/root/${emi_version}-argus-config-${emi_conf}.log"
    exec { "emi-config-argus":
       command => "/opt/glite/yaim/bin/yaim -c -d 6 -s /root/site-info.def -n ARGUS_server &> ${logfile}",
       path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
       creates => "${logfile}",
       require => [
                   Package["emi-argus"],
                   Package[$emi::params::openldap_servers],
                   File["/root/services/${emi::params::yaim_argus}"]
                  ],
       timeout => 0
    }

    $logfile_policy = "/root/argus-policy-config-${emi_conf}.log"
    exec { "emi-config-argus-policy":
       command => "/root/from-groupmap-to-policy.sh > /root/my-policy.spl && /usr/bin/pap-admin add-policies-from-file /root/my-policy.spl > ${logfile_policy}",
       path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
       creates => "${logfile_policy}",
       require => [File["/root/from-groupmap-to-policy.sh"],Exec["emi-config-argus"]],
       timeout => 0
    }

    $logfile_policy_local = "/root/argus-policy-local-config-${emi_conf}.log"
    exec { "emi-config-argus-policy-local":
       command => "/usr/bin/pap-admin add-policies-from-file /root/local-policies.spl > ${logfile2}",
       path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
       creates => "${logfile_policy_local}",
       require => [File["/root/local-policies.spl"],Exec["emi-config-argus-policy"]],
       timeout => 0
    }

    exec { "emi-reconfig-argus":
       command => "/bin/rm -f ${logfile}",
       refreshonly => true,
       notify => Exec["emi-config-argus"],
       timeout => 0
    }

    exec { "validate-emi-config-argus":
       command => "/bin/false",
       path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
       onlyif  => "test -s ${logfile} && tail -n 1 ${logfile} | grep ERROR: &> /dev/null",
       require => Exec["emi-config-argus"],
       logoutput => true,
       timeout => 0
    }

    # Setup the central banning services
    if ($ngi_name and $ngi_argus_host and $ngi_argus_dn) {
       exec { "emi-config-ngi-it-argus":
          command => "pap-admin add-pap $ngi_name $ngi_argus_host \"$ngi_argus_dn\" && pap-admin enable-pap $ngi_name && pap-admin set-paps-order $ngi_name default && pap-admin set-polling-interval 600",
          path    => ["/bin", "/usr/bin"],
          unless  => "grep -q '$ngi_argus_host' /etc/argus/pap/pap_configuration.ini",
          require => [Exec["emi-config-argus"],Exec["emi-config-argus-policy-local"]],
          notify  => Exec["emi-config-argus-reload"],
          timeout => 0
       }
       exec { "emi-config-argus-reload":
          command     => "service argus-pdp reloadpolicy && service argus-pepd clearcache",
          path        => ["/bin", "/sbin", "/usr/bin"],
          refreshonly => true,
          timeout     => 0
       }
    }
}
