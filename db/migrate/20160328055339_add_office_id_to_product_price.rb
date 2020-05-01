class AddOfficeIdToProductPrice < ActiveRecord::Migration
  def change
  	add_column :selling_prices, :office_id, :integer
  end
end
