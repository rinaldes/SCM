class Remake < ActiveRecord::Migration
  def change
  	drop_table :return_to_hos
    create_table :return_to_hos do |t|
      t.string :code
      t.date :date
      t.integer :supplier_id
      t.string :receive_no
      t.integer :retur_quantity
      t.integer :total
      t.string :note
      t.string :status
      t.timestamps
  end
  end
end
