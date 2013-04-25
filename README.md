redmine_ldapserver
==================

Authentication for external applications (such as zabbix) with redmine credentials

Installation:and usage
-------------------------

* cd <redmine_root>/plugins
* git clone git://github.com/MiRacLe-RPZ/redmine_ldapserver.git
* cd ..
* bundle install
* restart redmine
* configure plugins at http://<redmine.url>/settings/plugin/redmine_ldapserver
* rake ldapsrv:start
* setup ldap authentication in external application (ex. zabbix)
* profit!

TODO:

- [ ] reconfigure daemon on the fly?!
- [ ] documentation
