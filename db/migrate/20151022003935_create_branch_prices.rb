class CreateBranchPrices < ActiveRecord::Migration
  def change
    create_table :branch_prices do |t|
      t.integer :branch_id
      t.integer :product_id
      t.float :nominal
      t.float :percentage
      t.timestamps
    end
  end
end
