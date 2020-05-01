class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.integer :type_id
      t.integer :brand_id
      t.string :article
      t.string :barcode
      t.integer :size_id
      t.integer :unit_id
      t.string :status
      t.integer :colour_id
      t.float :cost_of_products
      t.float :purchase_price
      t.float :selling_price
      t.float :discount_price
      t.float :discount_price2
      t.float :discount_price3
      t.string :code
      t.float :percentage_price
      t.integer :netto
      t.timestamps
      t.timestamps
    end
    add_index :products, :type_id
    add_index :products, :brand_id
    add_index :products, :article
    add_index :products, :barcode
    add_index :products, :size_id
    add_index :products, :cost_of_products
    add_index :products, :purchase_price
    add_index :products, :selling_price
    add_index :products, :discount_price
    add_index :products, :percentage_price
    add_index :products, :unit_id
    add_index :products, :status
    add_index :products, :colour_id
    add_index :products, :discount_price2
    add_index :products, :discount_price3
    add_index :products, :code
    add_index :products, :netto
  end
end
