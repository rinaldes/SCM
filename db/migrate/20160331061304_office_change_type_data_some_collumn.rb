class OfficeChangeTypeDataSomeCollumn < ActiveRecord::Migration
  def change
  	add_column :offices, :province_id, :integer
  	add_column :offices, :district_id, :integer
  end
end