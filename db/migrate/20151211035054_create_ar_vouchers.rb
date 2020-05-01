class CreateArVouchers < ActiveRecord::Migration
  def change
    create_table :ar_vouchers do |t|
      t.string :name
      t.date :valid_from
      t.date :valid_until
      t.float :amount
      t.float :discount_percent
      t.float :discount_amount
      t.integer :office_id
      t.timestamps
    end
  end
end
