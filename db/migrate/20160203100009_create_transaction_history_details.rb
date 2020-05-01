class CreateTransactionHistoryDetails < ActiveRecord::Migration
  def change
    create_table :transaction_history_details do |t|
      t.string :code
      t.integer :brand_id
      t.integer :m_class_id
      t.integer :article
      t.integer :colour_id
      t.integer :size_id
      t.integer :quantity
      t.float :total_price
      t.float :total_discount
      t.timestamps
    end
  end
end