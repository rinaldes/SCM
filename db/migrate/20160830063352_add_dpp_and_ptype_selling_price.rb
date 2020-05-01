class AddDppAndPtypeSellingPrice < ActiveRecord::Migration
  def change
    #add_column :selling_prices, :dpp, :integer
    add_column :selling_prices, :price_type, :string
  end
end
