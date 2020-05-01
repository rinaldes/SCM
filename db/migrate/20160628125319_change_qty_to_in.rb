class ChangeQtyToIn < ActiveRecord::Migration
  def change
    change_column :product_structures, :quantity, :integer
  end
end
