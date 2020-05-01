class AddParentIdToZones < ActiveRecord::Migration
  def change
  	add_column :zones, :regional_id, :integer
  	add_column :zones, :city_id, :integer
  end
end
