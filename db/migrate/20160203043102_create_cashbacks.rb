class CreateCashbacks < ActiveRecord::Migration
  def change
    create_table :cashbacks do |t|
      t.float :transaction_amount
      t.float :cashback_amount
      t.integer :member_level_id
      t.timestamps
    end
  end
end
