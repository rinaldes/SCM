class AddIndexProductDetail < ActiveRecord::Migration
  def change
    add_index :product_details, :id
    add_index :product_details, :min_stock
    add_index :product_details, :warehouse_id
    add_index :product_details, :available_qty
    add_index :product_details, :allocated_qty
    add_index :product_details, :freezed_qty
    add_index :product_details, :rejected_qty
    add_index :product_details, :created_at
    add_index :product_details, :updated_at
    add_index :product_details, :defect_qty
    add_index :product_details, :online_qty
    add_index :product_details, :product_size_id
  end
end
