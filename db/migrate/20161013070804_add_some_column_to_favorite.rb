class AddSomeColumnToFavorite < ActiveRecord::Migration
  def change
  	add_column :favorite_products, :quantity, :integer
  end
end
