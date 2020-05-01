class CreateVoucherLists < ActiveRecord::Migration
  def change
    create_table :voucher_lists do |t|
      t.string :code
      t.date :date
      t.string :available
      t.string :order_no
      t.string :customer
      t.integer :voucher_credit_id
      t.timestamps
    end
  end
end
