class AddLevelToMclass < ActiveRecord::Migration
  def change
    add_column :m_classes, :level, :integer
  end
end
