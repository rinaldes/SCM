class AddMinQtyHappyHour < ActiveRecord::Migration
  def change
  	add_column :prize_lists, :min_qty, :integer
  end
end
