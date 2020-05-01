class CreateSupplierDepartments < ActiveRecord::Migration
  def change
    create_table :supplier_departments do |t|
      t.integer :supplier_id
      t.integer :department_id
      t.timestamps
    end
  end
end
