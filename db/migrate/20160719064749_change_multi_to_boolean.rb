class ChangeMultiToBoolean < ActiveRecord::Migration
  def change
    remove_column :promotions, :multi
    add_column :promotions, :multi, :boolean, default: false
  end
end
