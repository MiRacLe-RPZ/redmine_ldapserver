#!/usr/bin/env ruby
#coding: utf-8

require 'rubygems'
require 'optparse'
require 'yaml'
require 'mysql'
require 'ldap/server'
require 'thread'
require 'resolv-replace' # ruby threading DNS client
require 'digest/sha1'

conf = {:daemonize => false,
        :debug => false,
        :env => 'production',
        :root => File.expand_path('../../../../', __FILE__),
        :daemonize => true,
        :basedn => "dc=example,dc=org",
        :pool_size => 2,
        :pw_cache => 10,
        :pid => "/tmp/#{File.basename(__FILE__)}.pid",
        :port => 1389
}

opt_parser = OptionParser.new do |opt|
  opt.on("-p", "--port=LISTENPORT", "which tcp-port you want server listen") do |port|
    conf[:port] = port.to_i
  end
  opt.on("-b", "--background", "run in background") do |background|
    conf[:daemonize] = true
  end
  opt.on("-s", "--basedn=BASEDN", "BASEDN") do |basedn|
    conf[:basedn] = basedn
  end
  opt.on("-l", "--pool=POOLSIZE", "Size of sql pool") do |pool|
    conf[:pool_size] = pool.to_i
  end
  opt.on("-c", "--cache=CACHESIZE", "Size of internal cache") do |cache|
    conf[:pw_cache] = cache.to_i
  end
  opt.on("-d", "--debug", "DEBUG") do |debug|
    conf[:debug] = true
  end

  opt.on("-w", "--pid=PIDFILE", "Path to pid file") do |pid|
    conf[:pid] = pid
  end

  opt.on("-e", "--env=ENV", "Rails.env") do |env|
    conf[:env] = env
  end

  opt.on("-r", "--root=ROOTDIR", "Rails.root") do |root|
    conf[:root] = root
  end

  opt.on("-f", "--foreground", "Run in foreground") do |op|
    conf[:daemonize] = false
  end


  opt.on_tail("-h", "--help", "Show this message") do
    puts opt
    exit
  end

end

opt_parser.parse!

exit if conf[:root].nil?

dbconf = YAML.load(File.read("#{conf[:root]}/config/database.yml"))

conf[:db] = dbconf[conf[:env]]


# To test:
#    ldapsearch -H ldap://127.0.0.1:1389/ -b "dc=example,dc=com" \
#       -D "uid=mylogin,dc=example,dc=com" -W "(uid=searchlogin)"

$debug = conf[:debug]

module RedmineLDAPSrv

  class SQLPool
    def initialize(n, conn)
      @args = [conn['host'], conn['username'], conn['password'], conn['database']]
      @charset = conn['encoding']
      @pool = Queue.new
      n.times { @pool.push nil }
    end

    def borrow
      conn = @pool.pop
      if conn.nil? then
        conn = Mysql.init
        conn.options(Mysql::SET_CHARSET_NAME, @charset)
        conn.real_connect(*@args)
        q ="SET NAMES `#{@charset}`"
        puts q if $debug
        conn.query(q)
      end
      yield conn
    rescue Exception
      conn = nil
      raise
    ensure
      @pool.push conn
    end
  end

  class LRUCache
    def initialize(size)
      @size = size
      @cache = [] # [[key,val],[key,val],...]
      @mutex = Mutex.new
    end

    def purge
      @mutex.synchronize do
        @cache = []
      end
    end

    def add(id, data)
      @mutex.synchronize do
        @cache.delete_if { |k, v| k == id }
        @cache.unshift [id, data]
        @cache.pop while @cache.size > @size
      end
    end

    def find(id)
      @mutex.synchronize do
        index = entry = nil
        @cache.each_with_index do |e, i|
          if e[0] == id
            entry = e
            index = i
            break
          end
        end
        return nil unless index
        @cache.delete_at(index)
        @cache.unshift entry
        return entry[1]
      end
    end
  end


  class SQLOperation < LDAP::Server::Operation
    def self.configure(conf)
      @@cache = LRUCache.new(conf[:pw_cache])
      @@pool = SQLPool.new(conf[:pool_size], conf[:db])
      @@basedn = conf[:basedn]
    end

    def self.reload
      @@cache.purge
    end

    def search(basedn, scope, deref, filter)
      puts "basedn: #{basedn}, scope: #{scope}, deref: #{deref}, filter: #{filter}" if $debug
      raise LDAP::ResultError::UnwillingToPerform, "Bad base DN" unless basedn == @@basedn
      raise LDAP::ResultError::UnwillingToPerform, "Bad filter" unless filter[0..1] == [:eq, "uid"]
      uid = filter[3]
      @@pool.borrow do |sql|
        q = "select login, firstname,lastname,mail,language,status,admin,mail_notification from users where login='#{sql.quote(uid)}'"
        puts "SQL Query #{sql.object_id}: #{q}" if $debug
        res = sql.query(q)
        res.each do |login, firstname, lastname, mail, language, status, admin, mail_notification|
          send_SearchResultEntry("uid=#{login},#{@@basedn}", {
              "login" => login,
              "mail" => mail,
              "firstname" => firstname,
              "lastname" => lastname,
              "language" => language,
              "status" => status == 1 ? 'active' : 'inactive',
              "mail_notification" => mail_notification
          })
        end
      end
    end

    def simple_bind(version, dn, password)
      return if dn.nil? # accept anonymous
      puts "version: #{version}, dn: #{dn}, password: ********" if $debug
      raise LDAP::ResultError::UnwillingToPerform unless dn =~/\Auid=([\w|-]+),#{@@basedn}\z/
      login = $1
      data = @@cache.find(login)
      unless data
        @@pool.borrow do |sql|
          q = "select salt,hashed_password from users where login='#{login}' and sha1(concat(salt,sha1('#{password}'))) = hashed_password and status = 1 and auth_source_id is null"
          puts "SQL Query #{sql.object_id}: #{q}" if $debug
          res = sql.query(q)
          if res.num_rows == 1
            res.each do |salt, hashed_password|
              data = [salt, hashed_password]
              @@cache.add(login, data)
            end
          end
        end
      end
      calculated_hash = Digest::SHA1.hexdigest(password)
      raise LDAP::ResultError::InvalidCredentials unless !data.nil? and data[1] != "" and data[1] == Digest::SHA1.hexdigest("#{data[0]}#{calculated_hash}")
    end
  end
end
##############################################################################
def with_lock_file(pid)
  return false unless obtain_lock(pid)
  begin
    yield
  ensure
    remove_lock(pid)
  end
end

def obtain_lock(pid)
  File.open(pid, File::CREAT | File::EXCL | File::WRONLY) do |o|
    o.write(Process.pid)
  end
  return true
rescue
  return false
end

def remove_lock(pid)
  FileUtils.rm(pid, :force => true) if File.exists?(pid)

end

##############################################################################
Signal.trap("USR1") do
  puts "Reloading" if $debug
  RedmineLDAPSrv::SQLOperation.reload()
end

Signal.trap("TERM") do
  puts "Stoping." if $debug
  Process.exit
end

Signal.trap("INT") do
  puts "Terminating." if $debug
  Process.exit
end


RedmineLDAPSrv::SQLOperation.configure(conf)

s = LDAP::Server.new(
    :port => conf[:port],
    :nodelay => true,
    :listen => 10,
    #	:ssl_key_file		=> "key.pem",
    #	:ssl_cert_file		=> "cert.pem",
    #	:ssl_on_connect		=> true,
    :operation_class => RedmineLDAPSrv::SQLOperation
)
if conf[:daemonize]
  if RUBY_VERSION < "1.9"
    exit if fork
    Process.setsid
    exit if fork
    Dir.chdir "/"
    STDIN.reopen "/dev/null"
    STDOUT.reopen "/dev/null", "a"
    STDERR.reopen "/dev/null", "a"
  else
    Process.daemon
  end
end

with_lock_file(conf[:pid]) do
  begin
    s.run_tcpserver
    s.join
  rescue Exception => e
    remove_lock(conf[:pid])
    puts "[LDAPSrv] Terminating application, raised unrecoverable error - #{e.message}!!!"
  end

end
