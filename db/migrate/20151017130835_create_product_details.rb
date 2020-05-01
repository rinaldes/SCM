class CreateProductDetails < ActiveRecord::Migration
  def change
    create_table :product_details do |t|
      t.integer :product_id
      t.integer :size_detail_id
      t.integer :min_stock
      t.integer :warehouse_id
      t.integer :available_qty #ready to sold
      t.integer :allocated_qty #sudah dibooking
      t.integer :freezed_qty #maybe in QA
      t.integer :rejected_qty #will be returned to supplier
      t.timestamps
    end
  end
end
