class CreateTypes < ActiveRecord::Migration
  def change
    create_table :types do |t|
      t.string :name
      t.string :code
      t.timestamps
    end
    add_index :types, :name
    add_index :types, :code
  end
end
