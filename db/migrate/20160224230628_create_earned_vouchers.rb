class CreateEarnedVouchers < ActiveRecord::Migration
  def change
    create_table :earned_vouchers do |t|
      t.integer :sale_id
      t.integer :voucher_id
      t.timestamps
    end
  end
end
