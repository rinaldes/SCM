class CreateStockOpnames < ActiveRecord::Migration
  def change
    create_table :stock_opnames do |t|
      	t.string :opname_number
      	t.integer :inspector_id
      	t.string :status
      	t.date :date
      	t.integer :branch_id
      t.timestamps
    end
  end
end
