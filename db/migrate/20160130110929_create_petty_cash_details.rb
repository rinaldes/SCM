class CreatePettyCashDetails < ActiveRecord::Migration
  def change
    create_table :petty_cash_details do |t|
      t.integer :petty_cash_id
      t.date :date
      t.float :initial_budget
      t.float :cash_in
      t.float :cash_out
      t.float :balance
      t.string :note
      t.timestamps
    end
  end
end
