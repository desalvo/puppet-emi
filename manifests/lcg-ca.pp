# Class: emi::lcg-ca
#
#  This class installs the ca-policy-egi-core and lcg-CA packages
#
# Actions:
#  Install the ca-policy-egi-core and lcg-CA packages
#
# Sample Usage:
#  include emi::lcg-ca
#
class emi::lcg-ca inherits emi::egi-ca {

    package { lcg-CA: ensure => latest, require => Package["ca-policy-egi-core"] }

}
