desc 'Control ldapsrv'


namespace :ldapsrv do
  plugin_root = File.expand_path('../../../', __FILE__)
  require "#{plugin_root}/lib/ldap_server_control.rb"
  srv = LdapServerControl.new
  task :start => :environment do
    puts srv.start() ? "OK" : "FAIL"
  end
  task :stop => :environment do
    puts "Stoping LDAPsrv"
    srv.stop()
  end
  task :reload => :environment do
    srv.reload()
  end
  task :restart => :environment do
    Rake::Task['ldapsrv:stop'].invoke
    Rake::Task['ldapsrv:start'].invoke
  end
end
