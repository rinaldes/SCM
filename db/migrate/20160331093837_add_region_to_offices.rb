class AddRegionToOffices < ActiveRecord::Migration
  def change
    add_column :offices, :regional_id, :integer
    add_column :offices, :city_id, :integer
    add_column :offices, :area_id, :integer
  end
end
