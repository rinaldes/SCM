class AddDiscAmtToPrizeList < ActiveRecord::Migration
  def change
    add_column :prize_lists, :disc_amt, :float
  end
end
