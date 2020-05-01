class ChangeQtyToFloat < ActiveRecord::Migration
  def change
    change_column :sales_details, :quantity, :integer
  end
end
