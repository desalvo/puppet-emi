# Class: emi::egi-ca
#
#  This class installs the egi-trustanchors repository and the ca-policy-egi-core package
#
# Actions:
#  Install the egi-trustanchors repository and the ca-policy-egi-core package
#
# Sample Usage:
#  include emi::egi-ca
#
class emi::egi-ca {
    yumrepo { "egi-trustanchors":
      baseurl => "http://repository.egi.eu/sw/production/cas/1/current/",
      descr => "EGI-trustanchors",
      protect => 1,
      enabled => 1,
      gpgcheck => 1,
      gpgkey => "http://repository.egi.eu/sw/production/cas/1/GPG-KEY-EUGridPMA-RPM-3",
   }

    package { ca-policy-egi-core: ensure => latest, require => Yumrepo["egi-trustanchors"] }
}
