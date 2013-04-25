redmine_ldapserver
==================

Authentication for external applications (such as zabbix) with redmine credentials

Installation and usage
-------------------------

* cd <redmine_root>/plugins
* git clone git://github.com/MiRacLe-RPZ/redmine_ldapserver.git
* cd ..
* bundle install
* restart redmine
* configure plugin (listen port, basedn) at http://&lt;redmine.url&gt;/settings/plugin/redmine_ldapserver
* rake ldapsrv:start
* setup ldap authentication in external application (ex. zabbix)
* profit!

TODO
-------------------------

- [ ] automaticaly start/stop with redmine instance
- [ ] reconfigure daemon on the fly?!
- [ ] documentation
