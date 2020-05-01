class AddIsSpecialDiscount < ActiveRecord::Migration
  def change
    add_column :sales_details, :is_special_discount, :boolean
  end
end
