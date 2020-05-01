class CreatePosMachines < ActiveRecord::Migration
  def change
    create_table :pos_machines do |t|
      t.string :name
      t.string :uuid
      t.integer :office_id
      t.timestamps
    end
  end
end
