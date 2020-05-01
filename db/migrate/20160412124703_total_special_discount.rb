class TotalSpecialDiscount < ActiveRecord::Migration
  def change
    add_column :sales, :total_special_discount, :float
  end
end
