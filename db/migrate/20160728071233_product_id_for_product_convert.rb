class ProductIdForProductConvert < ActiveRecord::Migration
  def change
  	add_column :product_structures, :product_id, :integer 
  end
end