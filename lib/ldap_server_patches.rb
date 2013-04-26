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


module RedmineLdapServerSettingPatch
  def self.included(base)
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      after_save :restart_ldapsrv

      @@srv = LdapServerControl.new
      @@current_settings = @@srv.settings.clone

      def restart_ldapsrv
        new_settings = @@srv.settings
        @@srv.restart unless @@current_settings == new_settings
        @@current_settings = new_settings.clone
      end
    end
  end
end