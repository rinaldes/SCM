class AddPrizePromoToPrizeList < ActiveRecord::Migration
  def change
    add_column :prize_lists, :prize_promo, :float
  end
end
