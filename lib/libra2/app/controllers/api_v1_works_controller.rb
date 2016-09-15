class APIV1WorksController < APIBaseController

  before_action :validate_user, only: [ :delete_work,
                                        :update_work
                                      ]

  #
  # get all works
  #
  def all_works
    start = numeric( params[:start], DEFAULT_START )
    limit = numeric( params[:limit], DEFAULT_LIMIT )

    works = batched_get( {}, start, limit )
    if works.empty?
       render_works_response( :not_found )
    else
       render_works_response( :ok, work_transform( works ) )
    end
  end

  #
  # search works
  #
  def search_works
    if valid_search_params
       works = do_works_search
       if works.empty?
         render_works_response( :not_found )
       else
         render_works_response( :ok, work_transform( works ) )
       end
    else
      render_works_response( :bad_request, nil, 'Missing or incorrect parameter' )
    end

  end

  #
  # get a specific work details
  #
  def get_work
    works = batched_get( { id: params[:id] }, 0, 1 )
    if works.empty?
      render_works_response( :not_found )
    else
      render_works_response( :ok, work_transform( works ) )
    end
  end

  #
  # delete a work
  #
  def delete_work
    work = get_the_work
    if work.nil?
      render_standard_response( :not_found )
    else
      # audit the information
      audit_log( "Work id #{work.id} (#{work.identifier}) deleted by by #{User.cid_from_email( @api_user.email)}" )

      # actually do the delete
      work.destroy
      render_standard_response( :ok )
    end
  end

  #
  # update a work
  #
  def update_work
    work = get_the_work
    if work.nil?
      render_standard_response( :not_found )
    else

      work_update = API::Work.new.from_json( params_whitelist )

      if valid_update_params( work_update )

        apply_and_audit( work, work_update )

        # if this work published, send the metadata to the DOI service
        if work.is_draft? == false && must_resubmit_metadata( work_update )
          update_doi_metadata( work )
        end

        render_standard_response( :ok )

      else
        render_standard_response( :bad_request, 'Missing or incorrect parameter' )
      end

    end
  end

  private

  def do_works_search

    start = numeric( params[:start], DEFAULT_START )
    limit = numeric( params[:limit], DEFAULT_LIMIT )

    field = params[:status]
    if field.present?
      if field == 'pending'
         draft = 'true'
      else
         draft = 'false'
      end
      return batched_get( { draft: draft }, start, limit )
    end

    field = params[:author_email]
    if field.present?
      return batched_get( { author_email: field }, start, limit )
    end

    field = params[:create_date]
    if field.present?
      return batched_get( { date_created: field.gsub( '-', '/' ) }, start, limit )
    end

    return []
  end

  def valid_search_params( )
    return true if params[:status].blank? == false && ['pending','submitted'].include?( params[:status] )
    return true if params[:author_email].blank? == false
    return true if params[:create_date].blank? == false && valid_create_date( params[:create_date] )
    return false
  end

  def valid_update_params( work_update )

    #puts "==> #{work_update.to_json}"

    return true if work_update.depositor_email.blank? == false

    return true if work_update.author_email.blank? == false
    return true if work_update.author_first_name.blank? == false
    return true if work_update.author_last_name.blank? == false
    return true if work_update.author_institution.blank? == false
    return true if work_update.author_department.blank? == false

    return true if work_update.title.blank? == false
    return true if work_update.abstract.blank? == false

    return true if work_update.embargo_state.blank? == false && ['open','authenticated','restricted'].include?( work_update.embargo_state )
    return true if work_update.embargo_end_date.blank? == false && valid_embargo_date( work_update.embargo_end_date )

    return true if work_update.notes.blank? == false
    return true if work_update.admin_notes.blank? == false

    return true if work_update.rights.blank? == false
    return true if work_update.advisers.blank? == false

    return true if work_update.keywords.blank? == false
    return true if work_update.language.blank? == false
    return true if work_update.related_links.blank? == false
    return true if work_update.sponsoring_agency.blank? == false

    return true if work_update.degree.blank? == false

    return true if work_update.status.blank? == false && ['pending','submitted'].include?( work_update.status )
    return false
  end

  def valid_embargo_date( date )
     return convert_date( date ) != nil
  end

  def valid_create_date( date )
    return convert_date( date ) != nil
  end

  def convert_date( date )
    begin
       return DateTime.strptime( date, '%Y-%m-%d' )
    rescue => e
      return nil
    end
  end

  def apply_and_audit( work, work_update )

    if work_update.abstract.blank? == false && work_update.abstract != work.description
      # update and audit the information
      audit_change(work, 'Abstract', work.description, work_update.abstract )
      work.description = work_update.abstract
    end
    if work_update.author_email.blank? == false && work_update.author_email != work.author_email
      # update and audit the information
      audit_change(work, 'Author Email', work.author_email, work_update.author_email )
      work.author_email = work_update.author_email
    end
    if work_update.author_first_name.blank? == false && work_update.author_first_name != work.author_first_name
      # update and audit the information
      audit_change(work, 'Author First Name', work.author_first_name, work_update.author_first_name )
      work.author_first_name = work_update.author_first_name
    end
    if work_update.author_last_name.blank? == false && work_update.author_last_name != work.author_last_name
      # update and audit the information
      audit_change(work, 'Author Last Name', work.author_last_name, work_update.author_last_name )
      work.author_last_name = work_update.author_last_name
    end
    if work_update.author_institution.blank? == false && work_update.author_institution != work.author_institution
      # update and audit the information
      audit_change(work, 'Author Institution', work.author_institution, work_update.author_institution )
      work.author_institution = work_update.author_institution
    end
    if work_update.author_department.blank? == false && work_update.author_department != work.department
      # update and audit the information
      audit_change(work, 'Department', work.department, work_update.author_department )
      work.department = work_update.author_department
    end
    if work_update.depositor_email.blank? == false && work_update.depositor_email != work.depositor
      # update and audit the information
      audit_change(work, 'Depositor Email', work.depositor, work_update.depositor_email )


      work.edit_users -= [ work.depositor ]
      work.edit_users += [ work_update.depositor_email ]
      work.depositor = work_update.depositor_email
    end
    if work_update.degree.blank? == false && work_update.degree != work.degree
      # update and audit the information
      audit_change(work, 'Degree', work.degree, work_update.degree )
      work.degree = work_update.degree
    end
    if work_update.embargo_state.blank? == false && work_update.embargo_state != work.embargo_state
      # update and audit the information
      audit_change(work, 'Embargo Type', work.embargo_state, work_update.embargo_state )
      work.embargo_state = work_update.embargo_state
    end
    if work_update.embargo_end_date.blank? == false
      new_end_date = convert_date( work_update.embargo_end_date ).to_s
      if new_end_date != work.embargo_end_date
         # update and audit the information
         audit_change(work, 'Embargo End Date', work.embargo_end_date, new_end_date )
         work.embargo_end_date = convert_date( work_update.embargo_end_date )
      end
    end
    if work_update.notes.blank? == false
      # update and audit the information
      audit_change(work, 'Notes', work.notes, work_update.notes )
      work.notes = work_update.notes
    end
    if work_update.admin_notes.blank? == false
      # update and audit the information
      audit_add(work, 'Admin Notes', work_update.admin_notes )
      work.admin_notes = work.admin_notes.concat( work_update.admin_notes )
    end
    if work_update.rights.blank? == false
      # update and audit the information
      audit_change(work, 'Rights', work.rights, work_update.rights )
      work.rights = [ work_update.rights ]
    end
    if work_update.title.blank? == false && work_update.title != [ work_update.title ]
      # update and audit the information
      audit_change(work, 'Title', work.title, work_update.title )
      work.title = [ work_update.title ]
    end
    if work_update.advisers.blank? == false
      # update and audit the information
      audit_change(work, 'Advisers', work.contributor, work_update.advisers )
      work.contributor = work_update.advisers
    end
    if work_update.keywords.blank? == false
      # update and audit the information
      audit_change(work, 'Keywords', work.keyword, work_update.keywords )
      work.keyword = work_update.keywords
    end
    if work_update.language.blank? == false
      # update and audit the information
      audit_change(work, 'Language', work.language, work_update.language )
      work.language = work_update.language
    end
    if work_update.related_links.blank? == false
      # update and audit the information
      audit_change(work, 'Related Links', work.related_url, work_update.related_links )
      work.related_url = work_update.related_links
    end
    if work_update.sponsoring_agency.blank? == false
      # update and audit the information
      audit_change(work, 'Sponsoring Agency', work.sponsoring_agency, work_update.sponsoring_agency )
      work.sponsoring_agency = work_update.sponsoring_agency
    end

    # actually update the work
    work.save!
  end

  def must_resubmit_metadata( work_update )
#    return true if work_update.author_email.blank? == false
#    return true if work_update.author_first_name.blank? == false
#    return true if work_update.author_last_name.blank? == false
    return true if work_update.title.blank? == false
#    return true if work_update.abstract.blank? == false
    return false
  end

  def work_transform( solr_works )
    return [] if solr_works.empty?
    res = []
    solr_works.each do |solr|

      # make an API work record
      w = API::Work.new.from_solr( solr )

      filesets = w.filesets
      w.filesets = []
      # add the fileset information if necessary
      if filesets.empty? == false
        tstart = Time.now
        FileSet.search_in_batches( { id: filesets } ) do |fsg|
          elapsed = Time.now - tstart
          puts "===> extracted #{fsg.length} fileset(s) in #{elapsed}"
          fsg.each do |fsid|
            fs = API::Fileset.new.from_solr( fsid, "#{request.base_url}/api/v1" )
            w.filesets << fs
          end
          tstart = Time.now
        end

      end
      res << w
    end
    return res
  end

  def render_works_response( status, works = [], message = nil )
    render json: API::WorkListResponse.new( status, works, message ), :status => status
  end

  def find_fileset( work, fsid )
    return nil if fsid.nil?
    return nil if work.file_sets.nil?
    work.file_sets.each { |fs | return fs if fs.id == fsid }
    return nil
  end

  def batched_get( constraints, start_ix, end_ix )

    res = []
    count = end_ix - start_ix
    tstart = Time.now
    GenericWork.search_in_batches( constraints, {:rows => count} ) do |group|
      elapsed = Time.now - tstart
      puts "===> extracted #{group.length} work(s) in #{elapsed}"
      #group.each { |r| puts "#{r.class}" }
      res.push( *group )
      tstart = Time.now
    end
    return res
  end

  def params_whitelist
    params.require(:work).permit( :abstract,
                                  :author_email,
                                  :author_first_name,
                                  :author_last_name,
                                  :author_department,
                                  :author_institution,
                                  :degree,
                                  :depositor_email,
                                  :embargo_state,
                                  :embargo_end_date,
                                  :language,
                                  :notes,
                                  :rights,
                                  :title,
                                  :admin_notes => [],
                                  :advisers => [],
                                  :keywords => [],
                                  :related_links => [],
                                  :sponsoring_agency => []
                                )
  end

  def audit_change(work, what, old_value, new_value )
    audit_log( "#{what} for work id #{work.id} (#{work.identifier}) changed from '#{old_value}' to '#{new_value}' by #{User.cid_from_email( @api_user.email)}" )
  end

  def audit_add(work, what, new_value )
    audit_log( "#{what} for work id #{work.id} (#{work.identifier}) updated to include '#{new_value}' by #{User.cid_from_email( @api_user.email)}" )
  end

end

