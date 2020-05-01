class CreateBranchToDoLists < ActiveRecord::Migration
  def change
    create_table :branch_to_do_lists do |t|
      t.integer :office_id, index: true
      t.integer :to_do_list_id, index: true

      t.timestamps
    end
  end
end
