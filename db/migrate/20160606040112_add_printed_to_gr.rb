class AddPrintedToGr < ActiveRecord::Migration
  def change
    add_column :receivings, :has_printed, :boolean
  end
end
