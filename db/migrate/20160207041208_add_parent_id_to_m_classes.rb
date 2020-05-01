class AddParentIdToMClasses < ActiveRecord::Migration
  def change
    add_column :m_classes, :parent_id, :integer
  end
end
