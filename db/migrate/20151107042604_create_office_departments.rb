class CreateOfficeDepartments < ActiveRecord::Migration
  def change
    create_table :office_departments do |t|
      t.integer :department_id
      t.integer :office_id
      t.timestamps
    end
  end
end
