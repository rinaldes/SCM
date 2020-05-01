class Change < ActiveRecord::Migration
  def change
    rename_column :locations, :type, :jenis
  end
end
