class AddReceivingNoToATable < ActiveRecord::Migration
  def change
    add_column :returns_to_suppliers, :receive_no, :string
  end
end
