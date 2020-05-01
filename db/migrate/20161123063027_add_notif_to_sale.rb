class AddNotifToSale < ActiveRecord::Migration
  def change
    Sale.reset_column_information
  	add_column :sales, :notif_mobile, :boolean unless Sale.column_names.include?('notif_mobile')
  end
end
