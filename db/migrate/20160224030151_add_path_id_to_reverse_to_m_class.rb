class AddPathIdToReverseToMClass < ActiveRecord::Migration
  def change
    add_column :m_classes, :path_id, :string
  end
end
