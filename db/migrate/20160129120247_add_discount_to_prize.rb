class AddDiscountToPrize < ActiveRecord::Migration
  def change
    add_column :prize_lists, :discount_type, :string #Percent, Amount, Free
    add_column :prize_lists, :discount_nom, :float
  end
end
