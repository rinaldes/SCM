class CreatePromoItemLists < ActiveRecord::Migration
  def change
    create_table :promo_item_lists do |t|
    	t.integer :department_id
    	t.integer :mclass_id
    	t.integer :brand_id
    	t.integer :article_id
    	t.integer :min_qty
      t.timestamps
    end
  end
end
