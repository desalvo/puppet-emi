class emi::service (
  $cert,
  $key
) inherits emi {
   file { "/etc/grid-security/hostcert.pem":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "${cert}",
      require => Package['ca-policy-egi-core'],
   }

   file { "/etc/grid-security/hostkey.pem":
      owner => "root",
      group => "root",
      mode => 0400,
      source  => "${key}",
      require => Package['ca-policy-egi-core'],
   }
}
