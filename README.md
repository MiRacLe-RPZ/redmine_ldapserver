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

Current limitations
-------------------------

* only mysql
* tested only on ree (ruby1.8.7)
* tested only on linux
* tested only on redmine-current (2.3.0.devel)


TODO
-------------------------

- [ ] automaticaly start/stop with redmine instance
- [ ] reconfigure server after change settings
- [ ] clear internal cache after change users
- [ ] database adapters ?!
- [ ] documentation
