class AddPromotionTypeToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :promotion_type, :string
  end
end
