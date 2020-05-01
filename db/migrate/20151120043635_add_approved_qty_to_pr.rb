class AddApprovedQtyToPr < ActiveRecord::Migration
  def change
    add_column :purchase_request_details, :approved_qty, :integer
  end
end
