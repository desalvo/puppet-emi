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

Limitations
------------

* Only a few configurations are currently supported. Those are:

**certificates**

Contributors
------------

* https://github.com/desalvo/puppet-emi/graphs/contributors

Release Notes
-------------

**0.1.0**

* Initial version
