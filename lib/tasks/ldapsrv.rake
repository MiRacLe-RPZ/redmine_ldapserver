desc 'Control ldapsrv'

namespace :ldapsrv do
  plugin_root = File.expand_path('../../../', __FILE__)
  require "#{plugin_root}/lib/ldap_server_control.rb"
  srv = LdapServerControl.new
  task :start do
    Rake::Task['environment'].invoke
    cmd = srv.start_cmd()
    exec cmd
  end
  task :stop do
    Rake::Task['environment'].invoke
    srv.stop()
  end
  task :reload do
    Rake::Task['environment'].invoke
    srv.reload()
  end
  task :restart do
    Rake::Task['ldapsrv:stop'].invoke
    Rake::Task['ldapsrv:start'].invoke
  end
end
