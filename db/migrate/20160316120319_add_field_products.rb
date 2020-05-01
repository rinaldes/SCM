class AddFieldProducts < ActiveRecord::Migration
  def change
add_column :products, :box_id, :integer
add_column :products, :box_num, :integer
add_column :products, :box_barcode, :integer
add_column :products, :box2_id, :integer
  add_column :products, :box2_num, :integer
  add_column :products, :box2_barcode, :integer
  end
end
