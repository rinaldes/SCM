class CreateBrands < ActiveRecord::Migration
  def change
    create_table :brands do |t|
      t.string :name
      t.integer :supplier_id
      t.string :code
      t.float :discount_percent1
  	  t.float :discount_percent2
  	  t.float :discount_percent3
  	  t.float :discount_rp
      t.timestamps
    end
    add_index :brands, :name
    add_index :brands, :supplier_id
    add_index :brands, :code
    add_index :brands, :discount_percent1
    add_index :brands, :discount_percent2
    add_index :brands, :discount_percent3
    add_index :brands, :discount_rp
  end
end
