class AddColumnPathCodeToMClass < ActiveRecord::Migration
  def change
    add_column :m_classes, :path_code, :string
  end
end
