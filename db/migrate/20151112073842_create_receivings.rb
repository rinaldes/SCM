class CreateReceivings < ActiveRecord::Migration
  def change
    create_table :receivings do |t|
      t.string  :number
      t.date  :date
      t.integer :supplier_id
      t.string :status, default: "Ready For Inspection"
      t.integer :sub_total
      t.timestamps
    end
  end
end
