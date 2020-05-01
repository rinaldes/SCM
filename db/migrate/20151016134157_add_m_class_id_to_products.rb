class AddMClassIdToProducts < ActiveRecord::Migration
  def change
    add_column :products, :m_class_id, :integer
  end
end
