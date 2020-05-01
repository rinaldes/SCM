class CreateOffices < ActiveRecord::Migration
  def change
    create_table :offices do |t|
      t.string :office_name
      t.string :description
      t.string :warehouse
      t.string :contact_person
      t.integer :departement_id
      t.string :phone_number
      t.string :fax_number
      t.string :mobile_phone
      t.string :address
      t.string :type

      t.timestamps
    end
  end
end
