class AddPricesToProducts < ActiveRecord::Migration
  def change
    add_column :products, :margin_percent, :float
  end
end
