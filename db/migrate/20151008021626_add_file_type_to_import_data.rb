class AddFileTypeToImportData < ActiveRecord::Migration
  def change
    add_column :import_data, :file_type, :string
  end
end
