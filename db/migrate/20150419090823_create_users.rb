class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :gender
      t.string :birth_place
      t.datetime :birth_date
      t.string :email
      t.text :password_hash
      t.text :password_salt

      # t.string :role

      t.string :status
      t.integer :organization_id
      t.string :privilege
    
      t.timestamps
    end
  end
end
