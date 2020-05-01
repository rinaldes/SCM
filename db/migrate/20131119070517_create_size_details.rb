class CreateSizeDetails < ActiveRecord::Migration
  def change
    create_table :size_details do |t|
      t.integer :size_number
      t.integer :size_id
      t.timestamps
    end
    add_index :size_details, :size_number
    add_index :size_details, :size_id
  end
end
