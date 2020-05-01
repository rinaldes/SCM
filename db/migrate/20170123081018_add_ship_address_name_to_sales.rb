class AddShipAddressNameToSales < ActiveRecord::Migration
  def change
    add_column :sales, :ship_address_name, :string
    add_column :sales, :ship_address_phone, :string
  end
end
