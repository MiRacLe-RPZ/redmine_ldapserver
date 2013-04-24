#coding: utf-8

require 'redmine'

Rails.configuration.to_prepare do
#  Kernel.system ENV['MY_RUBY_HOME'] + '/bin/ruby ' + File.expand_path(File.dirname(__FILE__) + '/extra/ldapsrv.rb')  
end

Redmine::Plugin.register :redmine_ldapserver do
  name 'LDAP Server'
  author 'MiRacLe.RPZ'
  author_url 'http://miracle.rpz.name'
  description 'Simple LDAPServer for auth'
  version '0.1.1'

  settings :default => { 'sql_pool_size' => '10', 'listen_port' => 1389, 'pw_cache_size' => '100', 'basedn' => 'dc=example,dc=com' }, :partial => 'settings/ldapserver'

end
