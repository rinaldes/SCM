class AddStatus2ToProductDetail < ActiveRecord::Migration
  def change
    add_column :product_details, :status2, :integer
  end
end
