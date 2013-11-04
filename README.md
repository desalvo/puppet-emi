puppet-emi
======

Puppet module for managing EMI grid middleware configurations.

#### Table of Contents
1. [Overview - What is the emi module?](#overview)
2. [Managing the certification authorities - EGI CA and lcg CA](#managing-the-certificates-egi-ca-and-lcg-ca)

Overview
--------

This module is intended to be used to manage the EMI grid middleware configurations.
[The European Middleware Initiative (EMI)](http://www.eu-emi.eu/) is a close collaboration of the three major middleware providers,
ARC, gLite and UNICORE, and other specialized software providers like dCache.

Managing the certificates: EGI CA and lcg CA
------------------------------------------------------

The emi::egi-ca class will configure the EGI CA certificates in your machine. The EGI CA package contains all the certificates needed for a generic grid installation.
You can also use the legacy emi::lcg-ca class.

Using the emi module
--------------------

Parameters:
* **cert**: host certificate
* **key**: host key
* **siteinfo**: site-info.def for yaim
* **wnlist**: wn-list.def fot yaim
* **groupconf**: groups.conf for yaim
* **userconf**: users.conf for yaim
* **emi_version**: EMI version, valid options ar`emi-1`,`emi-2`,`emi-3`, 
* **emi_conf**: EMI configuration serial number, increase this to reconfigure
* **emi_type**: EMI element type

Currently the following emi types are supported:
* **bdii-site**

**Defining a site BDII**

```site-bdii
class {'emi':
    cert        => "puppet:///modules/mymodule/certificates/host.crt",
    key         => "puppet:///modules/mymodule/certificates/host.key",
    siteinfo    => "puppet:///modules/mymodule/config/emi-3/site-info.def",
    wnlist      => "puppet:///modules/mymodule/config/wn-list.conf",
    groupconf   => "puppet:///modules/mymodule/config/groups.conf",
    userconf    => "puppet:///modules/mymodule/config/users.conf",
    emi_version => 'emi-3',
    emi_conf    => 20137004,
    emi_type    => 'bdii-site',
}
```

Limitations
------------

* Only a few configurations are currently supported. Those are:

* **certificates**
* **bdii-site**

Contributors
------------

* https://github.com/desalvo/puppet-emi/graphs/contributors

Release Notes
-------------

**0.1.0**

* Initial version
