#
# Some helper tasks to create and delete works
#

# pull in the helpers
require_dependency 'libraetd/tasks/task_helpers'
include TaskHelpers

require_dependency 'libraetd/app/helpers/service_helper'
include ServiceHelper

require_dependency 'libraetd/lib/serviceclient/entity_id_client'

namespace :libraetd do

namespace :work do

sample_pdf_file = "data/sample.pdf"

desc "List all works"
task list_all_works: :environment do |t, args|

  count = 0
  GenericWork.search_in_batches( {} ) do |group|
    TaskHelpers.batched_process_solr_works( group, &method( :show_generic_work_callback ) )
    count += group.size
  end

  puts "Listed #{count} work(s)"
end

desc "Summerize all works"
task summerize_all_works: :environment do |t, args|

  count = 0
  GenericWork.search_in_batches( {} ) do |group|
    TaskHelpers.batched_process_solr_works( group, &method( :summerize_generic_work_callback ) )
    count += group.size
  end

  puts "Summerized #{count} work(s)"
end

desc "List my works; optionally provide depositor email"
task list_my_works: :environment do |t, args|

  who = ARGV[ 1 ]
  who = TaskHelpers.default_user_email if who.nil?
  task who.to_sym do ; end

  count = 0
  GenericWork.search_in_batches( { depositor: who } ) do |group|
    TaskHelpers.batched_process_solr_works( group, &method( :show_generic_work_callback ) )
    count += group.size
  end

  puts "Listed #{count} work(s)"
end

desc "Summerize my works; optionally provide depositor email"
task summerize_my_works: :environment do |t, args|

  who = ARGV[ 1 ]
  who = TaskHelpers.default_user_email if who.nil?
  task who.to_sym do ; end

  count = 0
  GenericWork.search_in_batches( { depositor: who } ) do |group|
    TaskHelpers.batched_process_solr_works( group, &method( :summerize_generic_work_callback ) )
    count += group.size
  end

  puts "Summerized #{count} work(s)"
end

desc "List work by id; must provide the work id"
task list_by_id: :environment do |t, args|

  work_id = ARGV[ 1 ]
  if work_id.nil?
    puts "ERROR: no work id specified, aborting"
    next
  end

  task work_id.to_sym do ; end

  work = TaskHelpers.get_work_by_id( work_id )
  if work.nil?
    puts "ERROR: work #{work_id} does not exist, aborting"
    next
  end

  TaskHelpers.show_generic_work(work )
end

desc "Work counts by depositor"
task count_by_depositor: :environment do |t, args|

  depositors = {}
  count = 0
  GenericWork.search_in_batches( {} ) do |group|
    group.each do |gw_solr|

      depositor = gw_solr[ Solrizer.solr_name( 'depositor' ) ]
      depositor = depositor[ 0 ] if depositor.present?
      depositor = 'unknown' if depositor.blank?

      if depositors[ depositor ].nil?
        depositors[ depositor ] = 1
      else
        depositors[ depositor ] = depositors[ depositor ] + 1
      end

    end

    count += group.size
  end

  # output a summary...
  depositors.keys.sort.each do |k|
    puts " #{k} => #{depositors[k]} work(s)"
  end

  puts "Summerized #{count} work(s)"
end

desc "Work counts by work source"
task count_by_source: :environment do |t, args|

  sources = { :ingested => 0, :legacy => 0, :optional => 0, :sis => 0, :unknown => 0 }
  count = 0
  GenericWork.search_in_batches( {} ) do |group|
    group.each do |gw_solr|
      source = gw_solr[ Solrizer.solr_name( 'work_source' ) ]
      source = source[ 0 ] if source.present?
      source = '' if source.blank?

      if source.start_with? GenericWork::THESIS_SOURCE_SIS
        sources[ :sis ] += 1
      elsif source.start_with? GenericWork::THESIS_SOURCE_OPTIONAL
        sources[ :optional ] += 1
      elsif source.start_with? GenericWork::THESIS_SOURCE_LEGACY
        sources[ :legacy ] += 1
      elsif source.start_with? GenericWork::THESIS_SOURCE_INGEST
        sources[ :ingested ] += 1
      else
        sources[ :unknown ] += 1
      end
    end

    count += group.size
  end

  # output a summary...
  sources.keys.sort.each do |k|
    puts " #{k} => #{sources[k]} work(s)"
  end

  puts "Summerized #{count} work(s)"
end

desc "Delete all works"
task del_all_works: :environment do |t, args|

  count = 0
  GenericWork.search_in_batches( {} ) do |group|
    TaskHelpers.batched_process_solr_works( group, &method( :delete_generic_work_callback ) )
    count += group.size
  end

  puts "done" unless count == 0
  puts "Deleted #{count} work(s)"

end

desc "Delete my works; optionally provide depositor email"
task del_my_works: :environment do |t, args|

   who = ARGV[ 1 ]
   who = TaskHelpers.default_user_email if who.nil?
   task who.to_sym do ; end

   count = 0
   GenericWork.search_in_batches( { depositor: who } ) do |group|
     TaskHelpers.batched_process_solr_works( group, &method( :delete_generic_work_callback ) )
     count += group.size
   end

   puts "done" unless count == 0
   puts "Deleted #{count} work(s)"

end

desc "Delete work by id; must provide the work id"
task del_by_id: :environment do |t, args|

  work_id = ARGV[ 1 ]
  if work_id.nil?
    puts "ERROR: no work id specified, aborting"
    next
  end

  task work_id.to_sym do ; end

  work = TaskHelpers.get_work_by_id( work_id )
  if work.nil?
    puts "ERROR: work #{work_id} does not exist, aborting"
    next
  end

  delete_generic_work_callback( work )
  puts "Work deleted"
end

desc "Create new generic work; optionally provide depositor email"
task create_new_work: :environment do |t, args|

  who = ARGV[ 1 ]
  who = TaskHelpers.default_user_email if who.nil?
  task who.to_sym do ; end

  # lookup user and exit if error
  user = User.find_by_email( who )
  if user.nil?
    puts "ERROR: locating user #{who}, aborting"
    next
  end

  id = Time.now.to_i
  title = "Example generic work title (#{id})"
  description = "Example generic work description (#{id})"

  work = create_work( user, title, description )

  filename = TaskHelpers.get_random_image( )
  TaskHelpers.upload_file( user, work, filename, File.basename( filename ) )

  TaskHelpers.show_generic_work work

end

desc "Create new thesis; optionally provide depositor email"
task create_new_thesis: :environment do |t, args|

  who = ARGV[ 1 ]
  who = TaskHelpers.default_user_email if who.nil?
  task who.to_sym do ; end

  # lookup user and exit if error
  user = User.find_by_email( who )
  if user.nil?
    puts "ERROR: locating user #{who}, aborting"
    task who.to_sym do ; end
    next
  end

  id = Time.now.to_i
  title = "Example thesis title (#{id})"
  description = "Example thesis description (#{id})"

  work = create_thesis( user, title, description )

  #filename = copy_sourcefile( sample_pdf_file )
  #TaskHelpers.upload_file( user, work, filename )

  TaskHelpers.show_generic_work work

end

desc "Create new work for all registered users"
task works_for_all: :environment do |t, args|

  count = 0
  User.order( :email ).each do |user|

    id = Time.now.to_i
    title = "Example generic work title (#{id})"
    description = "Example generic work description (#{id})"

    work = create_work( user, title, description )

    filename = TaskHelpers.get_random_image( )
    TaskHelpers.upload_file( user, work, filename, File.basename( filename ) )

    count += 1
  end

  puts "Created #{count} works"

end

desc "Create new theses for all registered users"
task thesis_for_all: :environment do |t, args|

  count = 0
  User.order( :email ).each do |user|

    id = Time.now.to_i
    title = "Example thesis title (#{id})"
    description = "Example thesis description (#{id})"

    work = create_thesis( user, title, description )

    filename = TaskHelpers.get_random_image( )
    TaskHelpers.upload_file( user, work, filename, File.basename( filename ) )

    count += 1

  end

  puts "Created #{count} theses"

end

#
# helpers
#

def show_generic_work_callback( work )
  TaskHelpers.show_generic_work( work )
end

def summerize_generic_work_callback( work )
  puts "id:#{work.id} ws:#{work.work_source} doi:#{work.identifier} assets:#{work.file_sets.size}"
end

def delete_generic_work_callback( work )
  print "."
  # if the work is draft, we can remove the DOI, otherwise, we must revoke it
  if work.is_draft? == true
    remove_doi( work )
  else
    revoke_doi( work )
  end
  work.destroy
end

def create_work( user, title, description )
   return( create_generic_work( GenericWork::WORK_TYPE_GENERIC, user, title, description ) )
end

def create_thesis( user, title, description )
  return( create_generic_work( GenericWork::WORK_TYPE_THESIS, user, title, description ) )
end

def create_generic_work( work_type, user, title, description )

  # look up user details
  user_info = user_info_by_email( user.email )
  if user_info.nil?
    # fill in the defaults
    user_info = Helpers::UserInfo.create(
        "{'first_name': 'First name', 'last_name': 'Last name'}".to_json )
  end

  work = GenericWork.create!(title: [ title ] ) do |w|

    # generic work attributes
    w.apply_depositor_metadata(user)
    w.creator = user.email
    w.author_email = user.email
    w.author_first_name = user_info.first_name
    w.author_last_name = user_info.last_name
    w.author_institution = GenericWork::DEFAULT_INSTITUTION

    w.date_uploaded = CurationConcerns::TimeService.time_in_utc
    w.date_created = CurationConcerns::TimeService.time_in_utc.strftime( "%Y-%m-%d" )
    w.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    w.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    w.embargo_state = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    w.description = description
    w.work_type = work_type
    w.draft = work_type == GenericWork::WORK_TYPE_THESIS ? 'true' : 'false'

    w.publisher = GenericWork::DEFAULT_PUBLISHER
    w.department = 'Placeholder department'
    w.degree = 'Placeholder degree'
    w.notes = 'Placeholder notes'
    w.admin_notes << 'Placeholder admin notes'
    w.language = GenericWork::DEFAULT_LANGUAGE

    # assign some contributors
    # there's something about the way suffia handles contributors that messes up the ordering
    # so be explicit
    contributor = []
    contributor << TaskHelpers.contributor_fields_from_cid( 0, 'sah' )
    contributor << TaskHelpers.contributor_fields_from_cid( 1, 'ecr2c' )
    contributor << TaskHelpers.contributor_fields_from_cid( 2, 'naw4t' )
    w.contributor = contributor

    w.rights << 'Determine your rights assignments here'
    w.license = GenericWork::DEFAULT_LICENSE

    print "getting DOI..."
    status, id = ServiceClient::EntityIdClient.instance.newid( w )
    if ServiceClient::EntityIdClient.instance.ok?( status )
       w.identifier = id
       w.permanent_url = GenericWork.doi_url( id )
       puts "done"
    else
       puts "error"
    end
  end

  return work
end

def copy_sourcefile( source_file )

  dest_file = "#{File::SEPARATOR}tmp#{File::SEPARATOR}#{SecureRandom.hex( 5 )}#{File.extname( source_file )}"
  FileUtils.cp( source_file, dest_file )
  dest_file

end

end   # namespace work

end   # namespace libraetd

#
# end of file
#
