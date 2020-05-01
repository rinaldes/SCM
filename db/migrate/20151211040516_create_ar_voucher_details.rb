class CreateArVoucherDetails < ActiveRecord::Migration
  def change
    create_table :ar_voucher_details do |t|
      t.string :code
      t.integer :ar_voucher_id
      t.timestamps
    end
  end
end
