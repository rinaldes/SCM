class AddDiscountToProduct < ActiveRecord::Migration
  def change
    add_column :products, :discount_percent, :float
  end
end
