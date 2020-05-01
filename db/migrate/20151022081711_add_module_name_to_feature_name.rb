class AddModuleNameToFeatureName < ActiveRecord::Migration
  def change
    add_column :feature_names, :module_name, :string
  end
end
