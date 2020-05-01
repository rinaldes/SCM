class RenameColumnBranchId < ActiveRecord::Migration
  def change  	
  	rename_column :promotions, :branch_id, :office_id
  end
end
