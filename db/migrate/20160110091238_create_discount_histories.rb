class CreateDiscountHistories < ActiveRecord::Migration
  def change
    create_table :discount_histories do |t|
      t.string :description
      t.float :price
      t.float :price_after_discount
      t.float :monthly_amount
      t.integer :member_id
      t.float :generated_voucher_amount
      t.integer :member_level_id
      t.timestamps
    end
  end
end
