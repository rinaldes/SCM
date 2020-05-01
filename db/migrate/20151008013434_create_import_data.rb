class CreateImportData < ActiveRecord::Migration
  def change
    create_table :import_data do |t|
      t.string :file_name
      t.timestamps
    end
  end
end
