class CreateVoucherDetails < ActiveRecord::Migration
  def change
    create_table :voucher_details do |t|
      t.string :voucher_code
      t.date :generated_date
      t.boolean :available
      t.string :order_no
      t.integer :member_id
      t.timestamps
    end
  end
end
