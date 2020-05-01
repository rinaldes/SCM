class AddDiscountPercent4ToBrand < ActiveRecord::Migration
  def change
    add_column :brands, :discount_percent4, :float
  end
end
