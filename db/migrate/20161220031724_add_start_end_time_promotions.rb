class AddStartEndTimePromotions < ActiveRecord::Migration
  def change
    PromoItemList.reset_column_information
    add_column :promo_item_lists, :start_time, :time unless PromoItemList.column_names.include?('start_time')
    add_column :promo_item_lists, :end_time, :time unless PromoItemList.column_names.include?('end_time')
  end
end
