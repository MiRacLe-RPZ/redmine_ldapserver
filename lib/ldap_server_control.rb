class LdapServerControl
  def pidfile()
    "/tmp/ldapsrv.pid"
  end

  def reload()
    control "USR1"
  end

  def restart()
    stop()
    start()
  end

  def start()
    plugin_root = File.expand_path('../../', __FILE__)
    conf = settings
    cmd = "#{plugin_root}/extra/ldapsrv.rb --port=#{conf['listen_port']} --basedn=\"#{conf['basedn']}\" --cache=#{conf['pw_cache_size']} --pool=#{conf['sql_pool_size']} --pid=#{pidfile} --env=#{Rails.env} --root=#{Rails.root} -b"
    puts cmd
    system cmd
  end

  def stop()
    control "TERM"
  end

  def settings()
    Setting.plugin_redmine_ldapserver
  end


  def control(signal)
    begin
      Process.kill(signal, File.read(pidfile).to_i) if File.exists?(pidfile)
    rescue Errno::ESRCH => e
      start() unless signal == 'TERM'
    end

  end
end