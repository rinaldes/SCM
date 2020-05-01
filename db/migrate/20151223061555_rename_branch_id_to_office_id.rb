class RenameBranchIdToOfficeId < ActiveRecord::Migration
  def change
    rename_column :stock_opnames, :branch_id, :office_id
  end
end
