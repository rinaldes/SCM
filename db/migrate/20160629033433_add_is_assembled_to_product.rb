class AddIsAssembledToProduct < ActiveRecord::Migration
  def change
    add_column :product_details, :is_assembled, :boolean
  end
end
