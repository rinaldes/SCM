class RemoveBranchIdFromVoucher < ActiveRecord::Migration
  def change
    remove_column :vouchers, :branch_id, :integer
  end
end
