class AddLastPrintToOffice < ActiveRecord::Migration
  def change
    add_column :offices, :last_print, :datetime
  end
end
