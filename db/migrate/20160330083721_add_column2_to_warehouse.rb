class AddColumn2ToWarehouse < ActiveRecord::Migration
  def change
  	add_column :offices, :regional, :string
  	add_column :offices, :email, :string
  end
end
