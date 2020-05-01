class AddColumnToStore < ActiveRecord::Migration
  def change
  	add_column :offices, :area, :string
  end
end
