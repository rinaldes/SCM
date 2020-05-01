class CreateVoucherPieces < ActiveRecord::Migration
  def change
    create_table :voucher_pieces do |t|
      t.belongs_to :voucher, index:true
      t.string :code
      t.string :given_to_order_no
      t.string :used_in_order_no

      t.timestamps
    end
  end
end
