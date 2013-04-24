desc 'Control ldapsrv'


namespace :ldapsrv do
  pidfile = "/tmp/ldapsrv.pid"
  task :start => :environment do
    conf = Setting.plugin_redmine_ldapserver
    PLUGIN_ROOT = File.expand_path('../../../', __FILE__)
    cmd = "#{PLUGIN_ROOT}/extra/ldapsrv.rb --port=#{conf['listen_port']} --basedn=\"#{conf['basedn']}\" --cache=#{conf['pw_cache_size']} --pool=#{conf['sql_pool_size']} --pid=#{pidfile} --env=#{Rails.env} --root=#{Rails.root}  --background"
    puts "Starting LDAPsrv"
    puts system(cmd) ? "OK" : "FAIL"

  end
  task :stop => :environment do
    puts "Stoping LDAPsrv"
    Process.kill("TERM", File.read(pidfile).to_i) if File.exists?(pidfile)
  end
  task :reload => :environment do
    Process.kill("HUP", File.read(pidfile).to_i) if File.exists?(pidfile)
  end
  task :restart => :environment do
    Rake::Task['ldapsrv:stop'].invoke
    Rake::Task['ldapsrv:start'].invoke
  end
end
