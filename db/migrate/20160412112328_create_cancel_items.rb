class CreateCancelItems < ActiveRecord::Migration
  def change
    create_table :cancel_items do |t|
      t.integer :quantity
      t.float :price
      t.float :discount
      t.string :discount_type
      t.float :price_after_discount
      t.integer :discount_id
      t.integer :sales_person_id
      t.string :sales_person_bill_number
      t.float :capital_price
      t.float :discount_amt
      t.float :total_discount_amt
      t.float :subtotal_price
      t.float :total_price
      t.integer :user_id
      t.datetime :cancel_date
      t.integer :client_id
      t.integer :store_id
      t.integer :product_id
      t.integer :product_detail_id
      t.timestamps
    end
  end
end
