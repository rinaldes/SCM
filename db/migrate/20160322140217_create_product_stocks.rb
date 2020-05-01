class CreateProductStocks < ActiveRecord::Migration
  def change
    create_table :product_stocks do |t|
      t.integer :product_detail_id
      t.integer :stock
      t.string :stock_type

      t.timestamps
    end
  end
end
