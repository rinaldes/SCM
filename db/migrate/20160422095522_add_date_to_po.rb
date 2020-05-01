class AddDateToPo < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :expected_delivery_date, :date
  end
end
