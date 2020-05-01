class AddBranchIdToPr < ActiveRecord::Migration
  def change
    add_column :purchase_requests, :branch_id, :integer
    add_column :purchase_requests, :requester_id, :integer
  end
end
