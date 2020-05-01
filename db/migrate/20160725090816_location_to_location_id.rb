class LocationToLocationId < ActiveRecord::Migration
  def change
    rename_column :stock_transfers, :location, :location_id
    change_column :stock_transfers, :location_id, 'integer USING CAST(location_id AS integer)'
  end
end
