class emi::service (
  $cert,
  $key
) {
   file { "/etc/grid-security/hostcert.pem":
      owner => "root",
      group => "root",
      mode => 0644,
      source  => "${cert}",
   }

   file { "/etc/grid-security/hostkey.pem":
      owner => "root",
      group => "root",
      mode => 0400,
      source  => "${key}",
   }
}
