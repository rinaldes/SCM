class AddProductIdToPrize < ActiveRecord::Migration
  def change
    add_column :prize_lists, :product_id, :integer
  end
end
