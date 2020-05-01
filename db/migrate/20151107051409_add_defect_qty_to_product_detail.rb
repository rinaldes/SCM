class AddDefectQtyToProductDetail < ActiveRecord::Migration
  def change
    add_column :product_details, :online_qty, :integer
  end
end
