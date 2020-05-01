class ChangeTypesToMClass < ActiveRecord::Migration
  def change
    drop_table :m_classes
    rename_table :types, :m_classes
  end
end
