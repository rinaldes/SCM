class FixFeature < ActiveRecord::Migration
  def change
  	remove_column :features, :name
  	add_column :features, :feature_name_id, :integer
  end
end
