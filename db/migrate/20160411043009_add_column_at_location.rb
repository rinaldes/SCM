class AddColumnAtLocation < ActiveRecord::Migration
  def change
    add_column :locations, :province_location, :string
    add_column :locations, :level, :integer
    add_column :locations, :parent_id, :integer
    add_column :locations, :path_id, :string
    add_column :locations, :path_code, :string
  end
end
