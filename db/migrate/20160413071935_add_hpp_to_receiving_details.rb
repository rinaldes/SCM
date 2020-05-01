class AddHppToReceivingDetails < ActiveRecord::Migration
  def change
    add_column :receiving_details, :hpp, :float
  end
end
