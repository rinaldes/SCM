class AddColour24ToProducts < ActiveRecord::Migration
  def change
    add_column :products, :colour2_id, :integer
    add_column :products, :colour3_id, :integer
    add_column :products, :colour4_id, :integer
  end
end
