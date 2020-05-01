class AddColumn3ToWarehouse < ActiveRecord::Migration
  def change
  	add_column :offices, :province, :string
  	add_column :offices, :city, :string
  	add_column :offices, :districts, :string
  	add_column :offices, :zip_code, :integer
  	add_column :offices, :rt, :integer
  	add_column :offices, :rw, :integer
  	add_column :offices, :village, :string
  end
end
