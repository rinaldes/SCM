class ChangeGoodsSizeToProductSize < ActiveRecord::Migration
  def change
    rename_column :stock_opname_details, :goods_size_id, :product_size_id
  end
end
