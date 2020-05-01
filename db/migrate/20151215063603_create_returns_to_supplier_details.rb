class CreateReturnsToSupplierDetails < ActiveRecord::Migration
  def change
    create_table :returns_to_supplier_details do |t|
      t.string :code
      t.string :brand
      t.string :article
      t.string :color
      t.string :dept
      t.integer :total
      t.integer :quantity
      t.timestamps
    end
  end
end
