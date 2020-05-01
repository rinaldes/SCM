class CreateSdbbcasds < ActiveRecord::Migration
=begin
  def change
    create_table :sdbbcasds do |t|
      t.integer :product_size_id
      t.integer :quantity
      t.float :price_after_discount
      t.integer :discount_id
      t.integer :sale_id
      t.integer :sales_person_id
      t.string :sales_person_bill_number
      t.float :capital_price
      t.float :discount_amt
      t.float :total_discount_amt
      t.float :subtotal_price
      t.float :total_price
      t.integer :product_id
      t.integer :product_detail_id
      t.boolean :is_special_discount
      t.integer :sku_id
      t.timestamps
    end
  end
=end
ActiveRecord::Base.connection.execute("CREATE TABLE sdbbcasds AS SELECT * FROM sales_details;")
end