class CreateZfoodDetails < ActiveRecord::Migration
  def change
    create_table :zfood_details do |t|
      t.integer :sku_id
      t.float :moved_qty
      t.timestamps
    end
  end
end
