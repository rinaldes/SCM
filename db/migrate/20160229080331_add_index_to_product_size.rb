class AddIndexToProductSize < ActiveRecord::Migration
  def change
    add_index :product_sizes, :size_detail_id
    add_index :product_sizes, :product_id
    add_index :product_sizes, :id
  end
end
