class AddRoundingAmtToSales < ActiveRecord::Migration
  def change
    add_column :sales, :rounding_amt, :float
  end
end
