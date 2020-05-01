class AddIndex < ActiveRecord::Migration
  def change
    add_index :skus, :id
    add_index :skus, :product_id
    add_index :skus, :unit_id
    add_index :skus, :barcode
    add_index :skus, :convertion_unit

    add_index :selling_prices, :code
    add_index :selling_prices, :product_id
    add_index :selling_prices, :margin
    add_index :selling_prices, :hpp
    add_index :selling_prices, :dpp
    add_index :selling_prices, :ppn_in
    add_index :selling_prices, :ppn_out
    add_index :selling_prices, :start_date
    add_index :selling_prices, :end_date
    add_index :selling_prices, :branch_id
    add_index :selling_prices, :office_id
    add_index :selling_prices, :selling_price
    add_index :selling_prices, :margin_amount
    add_index :selling_prices, :hpp_2
    add_index :selling_prices, :receiving_id
    add_index :selling_prices, :margin_percent
    add_index :selling_prices, :hpp_average
    add_index :selling_prices, :supplier_id

    add_index :selling_price_details, :selling_price_id
    add_index :selling_price_details, :sku_id
    add_index :selling_price_details, :price

    #add_index :products, :article
    #add_index :products, :id
    #add_index :products, :barcode
    #add_index :products, :short_name

    #add_index :product_details, :short_name
    #add_index :product_details, :available_qty
    #add_index :product_details, :product_id
    #add_index :product_details, :id
    #add_index :product_details, :warehouse_id

    #add_index :units, :short_name
    #add_index :units, :unit_id
  end
end
