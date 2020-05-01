class AddCostDateToProduct < ActiveRecord::Migration
  def change
    add_column :products, :cost_date, :date
    add_column :products, :sell_price_date, :date
#    add_column :products, :netto, :float
  end
end
