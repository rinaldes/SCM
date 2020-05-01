class AddColumnToBrand < ActiveRecord::Migration
  def change
  	add_column :brands, :set_harga, :string
  end
end
