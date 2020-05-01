class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.string :logo
      t.string :name
      t.string :address
      t.string :npwp
      t.string :npwp_address
      t.timestamps
    end
  end
end
