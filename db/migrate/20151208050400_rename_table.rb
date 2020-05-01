class RenameTable < ActiveRecord::Migration
  def change
  	rename_table :return_to_hos, :returns_to_hos
  end
end
