class CreateStagingProducts < ActiveRecord::Migration
  def change
    create_table :staging_products do |t|
      t.integer :type_id
      t.integer :brand_id
      t.string :article
      t.string :barcode
      t.integer :size_id
      t.integer :unit_id
      t.string :status
      t.integer :colour_id
      t.float :cost_of_products
      t.float :purchase_price
      t.float :selling_price
      t.float :discount_price
      t.float :discount_price2
      t.float :discount_price3
      t.string :code
      t.float :percentage_price
      t.integer :netto
      t.date :cost_date
      t.date :sell_price_date
      t.integer :m_class_id
      t.date :purchase_price_date
      t.string :image
      t.integer :colour2_id
      t.integer :colour3_id
      t.integer :colour4_id
      t.string :status1
      t.string :status3
      t.date :first_po
      t.float :margin_percent1
      t.float :margin_percent2
      t.float :margin_percent3
      t.float :margin_percent4
      t.float :margin_rp
      t.string :status4, default: 'Fast Moving'
      t.string :status2
      t.string :colour_code
      t.float :discount_percent
      t.string :status5
      t.string :department_m_class
      t.float :margin_percent
      t.float :harga_bandrol
      t.float :harga_eceran
      t.float :harga_member_eceran
      t.float :harga_kredit
      t.integer :department_id
      t.string :description
      t.string :description_2
      t.string :short_name
      t.integer :box_id
      t.integer :box_num
      t.string :box_barcode
      t.integer :box2_id
      t.integer :box2_num
      t.string :box2_barcode
      t.string :sku
      t.string :flag_pajak
      t.string :flag_barang
      t.integer :fraction
      t.integer :minimal_order
      t.integer :parent_id
      t.boolean :is_composite, default: true
      t.boolean :status_retur, default: false
      t.boolean :is_imported, default: false
      t.boolean :is_updated, default: false

      t.timestamps
    end

    add_index :staging_products, :type_id
    add_index :staging_products, :brand_id
    add_index :staging_products, :article
    add_index :staging_products, :barcode
    add_index :staging_products, :size_id
    add_index :staging_products, :cost_of_products
    add_index :staging_products, :purchase_price
    add_index :staging_products, :selling_price
    add_index :staging_products, :discount_price
    add_index :staging_products, :percentage_price
    add_index :staging_products, :unit_id
    add_index :staging_products, :status
    add_index :staging_products, :colour_id
    add_index :staging_products, :discount_price2
    add_index :staging_products, :discount_price3
    add_index :staging_products, :code
    add_index :staging_products, :netto
  end
end
