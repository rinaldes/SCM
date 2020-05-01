class CreatePriceHistories < ActiveRecord::Migration
  def change
    create_table :price_histories do |t|
    	t.float :harga_lama
    	t.float :harga_baru
    	t.string :tipe_harga
    	t.integer :product_id
      t.timestamps
    end
  end
end
