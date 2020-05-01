class AddStatus4ToStock < ActiveRecord::Migration
  def change
  	add_column :products, :status4, :string, default: "Fast Moving"
  	add_column :product_details, :defect_qty, :integer, default: 0
  end
end
