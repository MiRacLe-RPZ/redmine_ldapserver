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
* setup ldap authentication in external application (ex. zabbix or jenkins)
* use rake ldapsrv:stop, rake ldapsrv:start, rake ldapsrv:restart, rake ldapsrv:reload for control
* profit!

Current limitations (requirements)
-------------------------

* ruby >= 1.9
* tested only on linux
* tested only on mysql2
* tested only on redmine-current (2.3.0.devel)


TODO
-------------------------

- [ ] documentation
