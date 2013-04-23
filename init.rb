#coding: utf-8

require 'redmine'

Redmine::Plugin.register :redmine_ldapserver do
  name 'LDAP Server'
  author 'MiRacLe.RPZ'
  author_url 'http://miracle.rpz.name'
  description 'Authentication for external applications (such as zabbix) with redmine credentials'
  version '0.1.0'

  settings :default => { 'sql_pool_size' => '10', 'listen_port' => 1389, 'pw_cache_size' => '100', 'basedn' => 'dc=example,dc=com' }, :partial => 'settings/ldapserver'

end
