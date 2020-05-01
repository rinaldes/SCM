class CreateReturnsToSuppliers < ActiveRecord::Migration
  def change
    create_table :returns_to_suppliers do |t|
      t.date :date
      t.integer :supplier_id
      t.string :status
      t.string :number
      t.integer :head_office_id
      t.timestamps
    end
    add_index :returns_to_suppliers, :date
    add_index :returns_to_suppliers, :supplier_id
    add_index :returns_to_suppliers, :status
    add_index :returns_to_suppliers, :number
    add_index :returns_to_suppliers, :head_office_id
  end
end
