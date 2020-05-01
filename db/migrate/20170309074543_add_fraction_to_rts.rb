class AddFractionToRts < ActiveRecord::Migration
  def change
    add_column :returns_to_supplier_details, :fraction, :integer
  end
end
