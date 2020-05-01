class AddAvailableQtyToPrizeList < ActiveRecord::Migration
  def change
    add_column :prize_lists, :available_qty, :integer
  end
end
