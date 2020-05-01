class CreateCashOuts < ActiveRecord::Migration
  def change
    create_table :cash_outs do |t|
      t.integer :petty_cash_id
      t.time :time
      t.string :description
      t.float :amount
      t.string :receipt
      t.timestamps
    end
  end
end
