class AddHpp2ToPp < ActiveRecord::Migration
  def change
    add_column :selling_prices, :hpp_2, :float
  end
end
