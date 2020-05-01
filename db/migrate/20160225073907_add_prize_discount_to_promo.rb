class AddPrizeDiscountToPromo < ActiveRecord::Migration
  def change
    add_column :promotions, :discount_percent, :float
    add_column :promotions, :discount_amount, :float
  end
end
