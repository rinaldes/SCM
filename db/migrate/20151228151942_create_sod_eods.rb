class CreateSodEods < ActiveRecord::Migration
  def change
    create_table :sod_eods do |t|
      t.date :date
      t.integer :office_id
      t.time :start_time
      t.float :start_amount
      t.time :end_time
      t.float :actual_end_amount
      t.float :end_amount
      t.float :total_cash_sales
      t.float :total_spending
      t.float :petty_cash
      t.float :difference
      t.text :note
      t.text :cash
      t.integer :user_id
      t.integer :session
      t.timestamps
    end
  end
end
