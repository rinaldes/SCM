class AddPaidOffOnReceivingDetails < ActiveRecord::Migration
  def change
    add_column :receiving_details, :paid_off, :boolean, :default => false
  end
end
