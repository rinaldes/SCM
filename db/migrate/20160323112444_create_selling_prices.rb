class CreateSellingPrices < ActiveRecord::Migration
  def change
    create_table :selling_prices do |t|
      t.string :code
      t.integer :product_id
      t.float :margin
      t.float :hpp
      t.float :dpp
      t.float :ppn_in
      t.float :ppn_out
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
