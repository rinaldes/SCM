class CreateMobileOrderDetails < ActiveRecord::Migration
  def change
    create_table :mobile_order_details do |t|
      t.integer :product_id
      t.float :price
      t.float :quantity
      t.text :note
      t.timestamps
    end
  end
end
