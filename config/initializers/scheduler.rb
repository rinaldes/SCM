require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new(:max_work_threads => 7)
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

scheduler_erp = Rufus::Scheduler::singleton
scheduler_erp_sale = Rufus::Scheduler::singleton
scheduler_erp_gr = Rufus::Scheduler::singleton
scheduler_erp_retur = Rufus::Scheduler::singleton
scheduler_calculate_pkm = Rufus::Scheduler::singleton

# Generate PB Otomatis
#scheduler.cron '00 22 * * *' do
#  PurchaseRequest.initialize_pbrop
#end

# Menjalankan kalkulasi PKM setiap 1 bulan pada jam 12PM
#scheduler_calculate_pkm.cron '00 00 1 * *' do
#  Plano.calculate_pkm
#end

# Generate Stock Mutation History setiap jam 2 Dini Hari
# scheduler.cron '00 02 * * *' do
#   ProductMutationHistory.regenerate_mutation_history
# end

# Punya Rinaldes
scheduler_erp.cron '0 1 * * *' do
  Office.cut_off
end

scheduler_erp.cron '0 12 * * *' do
  Supplier.import_data_to_other_database
end

scheduler_erp.cron '0 8 * * *' do
  Supplier.import_data_to_other_database
end

scheduler_erp_sale.cron '20 0 * * *' do
  Supplier.import_data_to_other_database_sale
end

scheduler_erp_gr.cron '0 0 * * *' do
  Supplier.import_data_to_other_database_gr
end

scheduler_erp_retur.cron '10 0 * * *' do
  Supplier.import_data_to_other_database_retur
end
