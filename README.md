redmine_ldapserver
==================

Authentication for external applications (such as zabbix) with redmine credentials

Installation and usage
-------------------------

* cd &lt;redmine_root&gt;/plugins
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
- [ ] reconfigure server after change settings
- [ ] clear internal cache after change users
- [ ] documentation
