class CreateDiscountHistoryDetails < ActiveRecord::Migration
  def change
    create_table :discount_history_details do |t|
      t.integer :discount_history_id
      t.float :discount_percent
      t.float :discount_amount
      t.string :discount_type #Product, Member, Promo, Voucher
      t.timestamps
    end
  end
end
