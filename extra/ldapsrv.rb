#!/usr/bin/env ruby
#coding: utf-8
REDMINE_ROOT = File.expand_path('../../../../', __FILE__)
ENV['RAILS_ENV'] = ENV['RAILS_ENV'] || 'production'
require "#{REDMINE_ROOT}/config/environment"

require 'ldap/server'
require 'thread'
require 'resolv-replace'	# ruby threading DNS client
require 'digest/sha1'

# To test:
#    ldapsearch -H ldap://127.0.0.1:1389/ -b "dc=example,dc=com" \
#       -D "uid=mylogin,dc=example,dc=com" -W "(uid=searchlogin)"

$debug = false

module RedmineLDAPSrv

  class SQLPool
    def initialize(n, conn)
      @args = [conn[:host], conn[:username], conn[:password], conn[:database]]
      @charset = conn[:encoding]
      @pool = Queue.new
      n.times { @pool.push nil }
    end

    def borrow
      conn = @pool.pop
      if conn.nil?  then
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
      @cache = []   # [[key,val],[key,val],...]
      @mutex = Mutex.new
    end

    def add(id,data)
      @mutex.synchronize do
        @cache.delete_if { |k,v| k == id }
        @cache.unshift [id,data]
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
    def self.configure()
      @@cache = LRUCache.new(Setting.plugin_redmine_ldapserver['pw_cache_size'].to_i)
      @@pool = SQLPool.new(Setting.plugin_redmine_ldapserver['sql_pool_size'].to_i, ActiveRecord::Base.connection_config)
      @@basedn = Setting.plugin_redmine_ldapserver['basedn']
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
        res.each do |login,firstname,lastname,mail,language,status,admin,mail_notification|
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
      return if dn.nil?   # accept anonymous
      puts "version: #{version}, dn: #{dn}, password: ********"  if $debug
      raise LDAP::ResultError::UnwillingToPerform unless dn =~/\Auid=([\w|-]+),#{@@basedn}\z/
      login = $1
      data = @@cache.find(login)
      unless data
        @@pool.borrow do |sql|
          q = "select salt,hashed_password from users where login='#{login}' and sha1(concat(salt,sha1('#{password}'))) = hashed_password and status = 1 and auth_source_id is null"
          puts "SQL Query #{sql.object_id}: #{q}" if $debug
          res = sql.query(q)
          if res.num_rows == 1
      	    res.each do |salt,hashed_password|
  	          data = [salt,hashed_password]
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
  RedmineLDAPSrv::SQLOperation.configure()

    s = LDAP::Server.new(
    	:port			=> Setting.plugin_redmine_ldapserver['listen_port'],
    	:nodelay		=> true,
    	:listen			=> 10,
    #	:ssl_key_file		=> "key.pem",
    #	:ssl_cert_file		=> "cert.pem",
    #	:ssl_on_connect		=> true,
    	:operation_class	=> RedmineLDAPSrv::SQLOperation
    )

    ActiveRecord::Base.connection.disconnect!
  unless $debug

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

  begin
    s.run_tcpserver
    s.join
  rescue Exception => e
    Rails.logger.fatal "[LDAPSrv] Terminating application, raised unrecoverable error - #{e.message}!!!"
  end