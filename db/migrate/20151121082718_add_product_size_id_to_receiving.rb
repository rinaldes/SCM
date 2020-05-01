class AddProductSizeIdToReceiving < ActiveRecord::Migration
  def change
    add_column :receiving_details, :product_size_id, :integer
    add_column :receiving_details, :quantity, :integer
  end
end
