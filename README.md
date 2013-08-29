redmine_ldapserver
==================

Authentication for external applications (such as zabbix or jenkins) with redmine credentials


Installation and usage
-------------------------

* cd &lt;redmine_root&gt;/plugins
* git clone git://github.com/MiRacLe-RPZ/redmine_ldapserver.git
* cd ..
* bundle install
* restart redmine
* configure plugin (listen port, basedn) at http://&lt;redmine.url&gt;/settings/plugin/redmine_ldapserver
* setup ldap authentication in external application (ex. zabbix)
* use rake ldapsrv:stop, rake ldapsrv:start, rake ldapsrv:restart, rake ldapsrv:reload for control
* profit!

Current limitations (requirements)
-------------------------

* only mysql2
* ruby >= 1.9
* tested only on linux
* tested only on redmine-current (2.3.0.devel)


TODO
-------------------------

- [ ] database adapters ?!
- [ ] documentation
