class CreateGlobalSettings < ActiveRecord::Migration
  def change
    create_table :global_settings do |t|
      t.string :category
      t.string :name
      t.string :description
      t.integer :order
      t.boolean :is_active
      t.timestamps
    end
  end
end
