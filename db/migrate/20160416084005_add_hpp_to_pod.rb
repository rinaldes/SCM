class AddHppToPod < ActiveRecord::Migration
  def change
    add_column :purchase_order_details, :hpp, :float
  end
end
