class AddReturToSo < ActiveRecord::Migration
  def change
    add_column :stock_opnames, :retur, :integer
  end
end
