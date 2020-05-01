class CreateMobileOrders < ActiveRecord::Migration
  def change
    create_table :mobile_orders do |t|
      t.string :transaction_number
      t.integer :member_id
      t.datetime :transaction_date
      t.string :status
      t.timestamps
    end
  end
end
