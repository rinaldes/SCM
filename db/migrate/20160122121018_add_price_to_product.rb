class AddPriceToProduct < ActiveRecord::Migration
  def change
    add_column :products, :harga_bandrol, :float
    add_column :products, :harga_eceran, :float
    add_column :products, :harga_member_eceran, :float
    add_column :products, :harga_kredit, :float
  end
end
