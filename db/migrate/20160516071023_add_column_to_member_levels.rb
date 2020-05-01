class AddColumnToMemberLevels < ActiveRecord::Migration
  def change
	add_column :member_levels, :allow_credit, :string
  end
end
