class emi::params (
  $emi_version
) {
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

  $emi_base_other = [Augeas["epel enable"]]

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
        $openldap_servers = "openldap2.4-servers"
        $elversion = 5
        $igi_emi_repo = 'igi-emi.repo'
        case $emi_version {
          'emi-1': {
             $emi_release = "http://repo-pd.italiangrid.it/mrepo/EMI/1/sl5/x86_64/updates/emi-release-1.0.1-1.sl5.noarch.rpm"
             $emi_release_ver = '1.0.1-1'
          }
          'emi-2': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/2/sl5/x86_64/base/emi-release-2.0.0-1.sl5.noarch.rpm"
             $emi_release_ver = '2.0.0-1'
          }
          'emi-3': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl5/x86_64/base/emi-release-3.0.0-2.el5.noarch.rpm"
             $emi_release_ver = '3.0.0-2'
          }
          default: {
             fail("Unsupported EMI flavor $emi_version for $operatingsystem $operatingsystemrelease")
          }
        }
        $wlcg_repo_url='http://linuxsoft.cern.ch/wlcg/sl5/$basearch'
      } else {
        $emi_base_other_extra = [Augeas["epel raise priority"]]
        $openldap_servers = "openldap-servers"
        $elversion = 6
        $igi_emi_repo = 'igi-emi2.repo'
        case $emi_version {
          'emi-2': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/2/sl6/x86_64/base/emi-release-2.0.0-1.sl6.noarch.rpm"
          }
          'emi-3': {
             $emi_release = "http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl6/x86_64/base/emi-release-3.0.0-2.el6.noarch.rpm"
          }
          default: {
             fail("Unsupported EMI flavor $emi_version for $operatingsystem $operatingsystemrelease")
          }
        }
        $wlcg_repo_url='http://linuxsoft.cern.ch/wlcg/sl6/$basearch'
      }
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}/${::operatingsystemrelease}")
    }
  }
  case $emi_version {
    'emi-1','emi-2': {
      $yaim_argus = "glite-argus_server"
      $yaim_bdii_site = "glite-bdii_site"
      $yaim_ui = "glite-ui"
      $yaim_wn = "glite-wn"
      $yaim_mpi_wn = "glite-mpi_wn"
      $yaim_glexec_wn = "glite-glexec_wn"
      $yaim_creamce = "glite-creamce"
      $yaim_dgas_sensors_conf = "dgas_sensors"
      $glexec_wn_pkg = "emi-glexec_wn"
      $yaim_glexec_wn_pkg = "yaim-glexec-wn"
    }
    'emi-3': {
      $yaim_argus = "glite-argus_server"
      $yaim_bdii_site = "emi-bdii_site"
      $yaim_ui = "glite-ui"
      $yaim_wn = "glite-wn"
      $yaim_mpi_wn = "glite-mpi_wn"
      $yaim_glexec_wn = "glite-glexec_wn"
      $yaim_creamce = "glite-creamce"
      $yaim_dgas_sensors_conf = "dgas_sensors"
      $glexec_wn_pkg = "glexec-wn"
      $yaim_glexec_wn_pkg = "yaim-glexec-wn"
    }
    default: {
      fail ("Unsupported emi version ${mwtype}")
    }
  }

  $admin_list_file = "/etc/grid-security/admin-list"
  $dgas_localUserGroup2VOMap = "/etc/dgas/dgas_localUserGroup2VOMap.conf"

  $emi_base_reqs = split(inline_template("<%= (emi_base_packages+emi_base_files+emi_base_extra_files+emi_base_other+emi_base_other_extra+emi_hostcerts).join(',') %>"),',')
}
