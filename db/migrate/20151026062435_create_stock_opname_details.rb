class CreateStockOpnameDetails < ActiveRecord::Migration
  def change
    create_table :stock_opname_details do |t|
      t.integer :stock_opname_id
      t.integer :quantity
      t.integer :qty_virtual
      t.integer :qty_actual
      t.string :explanation
      t.integer :goods_size_id
      t.timestamps
    end
  end
end
