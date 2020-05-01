class CreateFavoriteProducts < ActiveRecord::Migration
  def change
    create_table :favorite_products do |t|
      t.integer :mobile_user_id
      t.integer :product_id
      t.timestamps
    end
  end
end
