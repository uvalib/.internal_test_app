require_dependency 'libra2/lib/serviceclient/user_info_client'
require_dependency 'libra2/lib/helpers/user_info'

module Helpers

  class EtdHelper

    def self.new_etd_from_deposit_request( dr )

      # lookup the user by computing id
      user_info = lookup_user( dr.who )
      if user_info.nil?
        puts "Cannot locate user info for #{dr.who}"
        return false
      end

      default_email_domain = 'virginia.edu'

      # locate the user and create the account if we cannot... cant create an ETD without an owner
      email = user_info.email
      email = "#{user_info.id}@#{default_email_domain}" if email.nil? || email.blank?
      user = User.find_by_email( email )
      user = create_user( user_info, email ) if user.nil?

      # default values
      default_title = 'Enter your title here'
      default_description = 'Enter your description here'
      default_contributor = 'Enter your contributors here'
      default_rights = 'Determine your rights assignments here'
      default_license = 'None'

      GenericWork.create!( title: [ default_title ] ) do |w|

        # generic work attributes
        w.apply_depositor_metadata( user )
        w.creator = email
        w.date_created = CurationConcerns::TimeService.time_in_utc.strftime( "%Y/%m/%d" )

        w.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        w.description = default_description
        w.work_type = GenericWork::WORK_TYPE_THESIS
        w.draft = 'true'
        w.publisher = GenericWork::DEFAULT_PUBLISHER
        w.department = dr.department
        w.degree = dr.degree

        w.contributor << default_contributor
        w.rights << default_rights
        w.license = default_license

        status, id = ServiceClient::EntityIdClient.instance.newid( w )
        if ServiceClient::EntityIdClient.instance.ok?( status )
           w.identifier = id
        else
          puts "Cannot mint DOI (#{status})"
          return false
        end

      end
      return true
    end

    private

    def self.create_user( user_info, email )

      default_password = 'password'

      user = User.new( email: email,
                       password: default_password, password_confirmation: default_password,
                       display_name: user_info.display_name,
                       department: user_info.department,
                       office: user_info.office,
                       telephone: user_info.phone,
                       title: user_info.title )
      user.save!
      puts "Created new account for #{user_info.id}"
      return( user )

    end

    def self.lookup_user( id )

      status, resp = ServiceClient::UserInfoClient.instance.get_by_id( id )
      if ServiceClient::UserInfoClient.instance.ok?( status )
        return Helpers::UserInfo.create( resp )
      end
      return nil

    end

  end

end

#
# end of file
#