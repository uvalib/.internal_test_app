#
# Some helper tasks to create and delete users
#

namespace :libra2 do

desc "Delete all users"
task del_users: :environment do |t, args|

  count = 0
  User.all.each do |user|
     count += 1
     user.destroy
  end
  puts "Deleted #{count} user(s)"

end

desc "Create new user; provide name and email"
task create_user: :environment do |t, args|

  name = ARGV[ 1 ]
  email = ARGV[ 2 ]
  password = 'password'

  if name.nil? == false && email.nil? == false
     user = User.find_by_email( email )
     if user.nil?
        user = User.new( email: email, password: password, password_confirmation: password, display_name: name, title: name )
        user.save!
        puts "Created user: #{name} (#{email})"
     else
       puts "Email #{email} already in use"
     end

     task name.to_sym do ; end
     task email.to_sym do ; end
  end

end

end   # namespace

#
# end of file
#
