class ChangeColumnNameInUnit < ActiveRecord::Migration
  def change
    rename_column :units, :unit_name, :name
    rename_column :units, :unit_alias, :short_name
  end
end
