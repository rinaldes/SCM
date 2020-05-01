class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      t.string :card_number
      t.string :name
      t.string :address
      t.date :birthday
      t.string :phone_number
      t.boolean :gender
      t.string :hp
      t.string :code
      t.timestamps
    end
    add_index :members, :card_number
    add_index :members, :name
    add_index :members, :address
    add_index :members, :birthday
    add_index :members, :phone_number
    add_index :members, :gender
    add_index :members, :hp
    add_index :members, :code
  end
end
