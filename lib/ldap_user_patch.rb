#coding: utf-8

module RedmineLdapServerUserPatch
  def self.included(base)
     base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        after_save :reload_ldapsrv
        
        def reload_ldapsrv
    	    srv = LdapServerControl.new
    	    srv.reload()
        end
     end
  end
end