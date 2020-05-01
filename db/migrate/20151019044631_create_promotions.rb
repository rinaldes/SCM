class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
    	t.string :name
    	t.string :code
    	t.integer :branch_id
    	t.string :berdasarkan
    	t.integer :colour_id
    	t.integer :size_id
    	t.integer :brand_id
    	t.integer :product_id
    	t.string :minimum_type
    	t.integer :minimum
    	t.boolean :kelipatan
    	t.date :start_date
    	t.date :end_date
    	t.integer :stock
    	t.string :jenis
    	t.string :product
    	t.integer :diskon
      t.timestamps
    end
  end
end
