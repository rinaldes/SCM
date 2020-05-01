class AddPajakToReceivingDetails < ActiveRecord::Migration
  def change
    add_column :receiving_details, :pajak, :float
  end
end
