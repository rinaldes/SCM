class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :flag_pajak, :string
    add_column :products, :flag_barang, :string
    add_column :products, :fraction, :integer
    add_column :products, :minimal_order, :integer
  end
end
