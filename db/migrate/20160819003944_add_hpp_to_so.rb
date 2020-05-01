class AddHppToSo < ActiveRecord::Migration
  def change
    add_column :stock_opname_details, :hpp, :float
  end
end
