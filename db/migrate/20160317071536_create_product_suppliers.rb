class CreateProductSuppliers < ActiveRecord::Migration
  def change
    create_table :product_suppliers do |t|
      t.integer :product_id
      t.integer :supplier_id
      t.integer :office_id
      t.timestamps
    end
  end
end
