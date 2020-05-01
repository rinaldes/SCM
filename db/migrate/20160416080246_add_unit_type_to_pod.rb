class AddUnitTypeToPod < ActiveRecord::Migration
  def change
    add_column :purchase_order_details, :unit_type, :string
  end
end
