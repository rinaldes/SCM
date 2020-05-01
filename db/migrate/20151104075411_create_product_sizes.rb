class CreateProductSizes < ActiveRecord::Migration
  def change
    create_table :product_sizes do |t|
      t.integer :size_detail_id
      t.integer :product_id
      t.timestamps
    end
  end
end

#TODO: pas create product, create product_sizes, 

