class AddMinAmountToPromo < ActiveRecord::Migration
  def change
    add_column :promotions, :min_amount, :float
    add_column :promotions, :min_qty, :integer
  end
end
