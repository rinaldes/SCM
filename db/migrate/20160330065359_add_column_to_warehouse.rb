class AddColumnToWarehouse < ActiveRecord::Migration
  def change
  	add_column :offices, :code, :string
  end
end
