namespace :seeding do
  desc "add default administrator"
  task :add_administrator, [:first, :last, :username, :email, :password] => :environment do |t, args|
  	ActiveRecord::Base.establish_connection
	  table = "admins"
	  if !["schema_migrations"].include?(table)
	    puts "TRUNCATE #{table}"
	    ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
    	ActiveRecord::Base.connection.reset_pk_sequence!(table)
			Admin.create!(first_name: args[:first], last_name: args[:last], username: args[:username], email: args[:email], password: args[:password], password_confirmation: args[:password])
			puts "default admin is: #{args[:username]} password: #{args[:password]} already done!"
	  end
  end
end
