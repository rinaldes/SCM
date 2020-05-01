class CreateContactPeople < ActiveRecord::Migration
  def change
    create_table :contact_people do |t|
      t.string :name
      t.string :phone
      t.string :pinbb
      t.string :email
      t.integer :supplier_id
      t.timestamps
    end
  end
end
