class AddDefaultToPd < ActiveRecord::Migration
  def change
    change_column :product_details, :is_assembled, :boolean, default: true
  end
end
