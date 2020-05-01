class AddPromotionId < ActiveRecord::Migration
  def change
  	add_column :promo_item_lists, :promotion_id, :integer
  	add_column :prize_lists, :promotion_id, :integer
  end
end
