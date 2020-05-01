class AddCityNameToOffices < ActiveRecord::Migration
  def change
    add_column :offices, :city_name, :string
  end
end
