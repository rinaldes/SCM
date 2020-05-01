class AddMoIdToMod < ActiveRecord::Migration
  def change
    add_column :mobile_order_details, :mobile_order_id, :integer
  end
end
