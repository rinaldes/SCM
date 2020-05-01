class AddProductIdToPromoItem < ActiveRecord::Migration
  def change
    add_column :promo_item_lists, :product_id, :integer
  end
end
