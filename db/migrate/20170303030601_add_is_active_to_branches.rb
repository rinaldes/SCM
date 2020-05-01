class AddIsActiveToBranches < ActiveRecord::Migration
  def change
    add_column :offices, :is_active, :boolean, default: true
  end
end
