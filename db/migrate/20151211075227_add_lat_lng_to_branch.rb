class AddLatLngToBranch < ActiveRecord::Migration
  def change
    add_column :offices, :lat, :string
    add_column :offices, :long, :string
  end
end
