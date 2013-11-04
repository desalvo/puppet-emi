class emi::service (
  $certrepo = "puppet:///modules/emi/certificates",
  $cert = "hostcert.pem.$hostname",
  $key = "hostkey.pem.$hostname"
) inherits emi {
   file { "/etc/grid-security/hostcert.pem":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "${certrepo}/${cert}",
      require => Package['ca-policy-egi-core'],
   }

   file { "/etc/grid-security/hostkey.pem":
      owner => "root",
      group => "root",
      mode => 0400,
      source  => "${certrepo}/${key}",
      require => Package['ca-policy-egi-core'],
   }
}
