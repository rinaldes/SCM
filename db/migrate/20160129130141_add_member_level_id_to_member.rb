class AddMemberLevelIdToMember < ActiveRecord::Migration
  def change
    add_column :members, :member_level_id, :integer
  end
end
