class CreateSkus < ActiveRecord::Migration
  def change
    create_table :skus do |t|
      t.integer :product_id
      t.integer :unit_id
      t.string :barcode
      t.integer :convertion_unit
      t.timestamps
    end
  end
end
