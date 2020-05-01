class AddEntityIdToOffice < ActiveRecord::Migration
  def change
    add_column :offices, :entity_id, :integer
  end
end
