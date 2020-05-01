class AddUnitId < ActiveRecord::Migration
  def change
    add_column :sales_details, :unit_id, :integer
  end
end
