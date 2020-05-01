class AddNewColumnToSale < ActiveRecord::Migration
  def change
    add_column :sales, :mobile_order, :boolean
  end
end