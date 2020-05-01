class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.string :unit_name
      t.string :unit_alias

      t.timestamps
    end
  end
end
