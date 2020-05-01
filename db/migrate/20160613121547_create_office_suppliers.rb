class CreateOfficeSuppliers < ActiveRecord::Migration
  def change
    create_table :office_suppliers do |t|
      t.integer :office_id
      t.integer :supplier_id
      t.timestamps
    end
  end
end
