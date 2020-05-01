class NambahKolom < ActiveRecord::Migration
  def change
  	add_column :returns_to_supplier_details, :product_size_id, :integer
  end
end