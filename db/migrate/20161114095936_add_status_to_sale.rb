class AddStatusToSale < ActiveRecord::Migration
  def change
  	add_column :sales_details, :status, :string
  end
end
