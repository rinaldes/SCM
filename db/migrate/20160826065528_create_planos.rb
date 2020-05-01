class CreatePlanos < ActiveRecord::Migration
  def change
    create_table :planos do |t|
      t.integer :product_id
      t.string :code
      t.date :start
      t.date :end
      t.integer :rak_id
      t.string :rak_type
      t.integer :shelving
      t.integer :kir_ka
      t.integer :at_ba
      t.integer :de_be
      t.integer :min
      t.timestamps
    end
  end
end
