class AddHoIdAndBranchIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :head_office_id, :integer
    add_column :users, :branch_id, :integer
  end
end
