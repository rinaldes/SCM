class AddIsMenuToMclass < ActiveRecord::Migration
  def change
    add_column :m_classes, :is_menu, :boolean
  end
end
