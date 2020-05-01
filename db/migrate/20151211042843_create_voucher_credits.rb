class CreateVoucherCredits < ActiveRecord::Migration
  def change
    create_table :voucher_credits do |t|
      t.string :name
      t.date :start
      t.date :end
      t.integer :amount
      t.float :d_percent
      t.integer :d_nominal
      t.integer :quantity
      t.integer :branch_id
      t.string :term
      t.timestamps
    end
  end
end
