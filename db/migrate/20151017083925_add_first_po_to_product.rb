class AddFirstPoToProduct < ActiveRecord::Migration
  def change
    add_column :products, :first_po, :date
    add_column :products, :margin_percent1, :float
    add_column :products, :margin_percent2, :float
    add_column :products, :margin_percent3, :float
    add_column :products, :margin_percent4, :float
    add_column :products, :margin_rp, :float
  end
end
