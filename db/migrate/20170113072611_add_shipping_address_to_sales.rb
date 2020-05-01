class AddShippingAddressToSales < ActiveRecord::Migration
  def change
    add_column :sales, :ship_address_city, :string
    add_column :sales, :ship_address_kecamatan, :string
    add_column :sales, :ship_address_kelurahan, :string
    add_column :sales, :ship_address_province, :string
    add_column :sales, :ship_address, :string
  end
end
