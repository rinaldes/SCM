class CreateSalesDetails < ActiveRecord::Migration
  def change
    create_table :sales_details do |t|
      t.integer :product_size_id
      t.integer :quantity
      t.float :price
      t.float :discount
      t.string :discount_type
      t.float :price_after_discount
      t.integer :discount_id
      t.integer :sale_id
      t.integer :sales_person_id
      t.string :sales_person_bill_number

      t.timestamps
    end
  end
end
