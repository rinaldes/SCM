class AddTopToPo < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :top, :integer
  end
end
