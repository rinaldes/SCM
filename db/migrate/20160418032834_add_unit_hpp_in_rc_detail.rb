class AddUnitHppInRcDetail < ActiveRecord::Migration
  def change
    add_column :receiving_details, :unit_type, :string
  end
end
