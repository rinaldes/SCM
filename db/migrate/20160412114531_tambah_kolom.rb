class TambahKolom < ActiveRecord::Migration
  def change
    add_column :product_stocks, :batas_kuantitas_maksimal, :integer
    add_column :product_suppliers, :minimal_order, :integer
  end
end
