class emi::params {
  $emi_base_packages = [
                        Package["emi-release"],
                        Package["ca-policy-egi-core"],
                        Package["glite-yaim-core"],
                        Package["glite-yaim-clients"]
                       ]

  $emi_base_files = [
                     File["/root/site-info.def"],
                     File["/root/wn-list.conf"],
                     File["/root/groups.conf"],
                     File["/root/users.conf"],
                     File["/root/services"],
                     File["/opt/glite/yaim/node-info.d/atlas_localenv"],
                     File["/opt/glite/yaim/functions/config_atlas_localenv"]
                    ]

  $emi_base_other = [Exec["epel enable"]]

  if ($igi) {
    $emi_base_extra_files = [File["/etc/yum.repos.d/igi-emi.repo"]]
  } else {
    $emi_base_extra_files = []
  }

  if (defined(File["/etc/grid-security/hostcert.pem"]) and defined(File["/etc/grid-security/hostkey.pem"])) {
    $emi_hostcerts = [File["/etc/grid-security/hostcert.pem"],File["/etc/grid-security/hostkey.pem"]]
  } else {
    $emi_hostcerts = []
  }
  case $::operatingsystem {
    'centos','scientific','redhat': {
      if ($::operatingsystemrelease < 6) {
        $emi_base_other_extra = []
        $elversion = 5
      } else {
        $emi_base_other_extra = [Augeas["epel raise priority"]]
        $elversion = 6
      }
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}/${::operatingsystemrelease}")
    }
  }

  $emi_base_reqs = split(inline_template("<%= (emi_base_packages+emi_base_files+emi_base_extra_files+emi_base_other+emi_base_other_extra+emi_hostcerts).join(',') %>"),',')
}
