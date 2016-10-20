require 'piwik'

#Piwik::PIWIK_URL = nil
#Piwik::PIWIK_TOKEN = nil

module Libra2
  module Analytics
    # Loads configuration options from config/piwik.yml. Expected structure:
    # `  piwik_url: PIWIK_URL`
    # `  piwik_site_id: PIWIK_SITE_ID`
    # `  auth_token: PIWIK_AUTH_TOKEN`
    # @return [Hash] A hash containing three keys: 'piwik_url', 'piwik_site_id', 'auth_token'
    def self.config
      @config ||= load_config
    end
    private_class_method :config

    def self.load_config
      filename = File.join(Rails.root, 'config', 'piwik.yml')
      yaml = YAML.load(File.read(filename))
      unless yaml
        Rails.logger.error("Unable to fetch any keys from #{filename}.")
        return
      end
      yaml
    end
    private_class_method :load_config

    def self.pageviews( options )
      puts "==> Libra2::Analytics::pageviews #{options.inspect}"

      piwik_config( )
      pa = Piwik::Actions.getPageUrls( :idSite => config.fetch( 'piwik_site_id' ),
                                       :period => :day,
                                       :date => options[ :start_date ] )
      puts "==> #{pa.inspect}"

      return []
    end

    def self.downloads( options )
      puts "==> Libra2::Analytics::downloads #{options.inspect}"

      piwik_config( )
      pa = Piwik::Actions.getDownloads( :idSite => config.fetch( 'piwik_site_id' ),
                                        :period => :day,
                                        :date => options[ :start_date ] )
      puts "==> #{pa.inspect}"
      return []
    end

    private

    #
    # really messy...
    # PIWICK defines this stuff in constants or requires a config mechanism that I do not
    # want to use
    #
    def self.piwik_config
      set_piwick_const( 'PIWIK_URL', config.fetch( 'piwik_url') )
      set_piwick_const( 'PIWIK_TOKEN', config.fetch( 'auth_token') )
    end

    def self.set_piwick_const( name, val )
      Piwik.const_set( name, val ) unless Piwik.const_defined?( name )
    end
  end
end
