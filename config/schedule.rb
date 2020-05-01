# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, {:error => 'cron_error.log', :standard => 'cron_status.log'}

every '0 0 15,30 * *' do
  runner "Receiving.create_ap"
end

every 1.days do
  runner "PurchaseRequest.initialize_pbrop"
end

every 1.days do
  runner "PurchaseRequest.generate_pb"
end

# Genereta Petty cash details for the next month
every '0 0 L * *' do
  runner "PettyCash.generate_petty_cashes"
end
