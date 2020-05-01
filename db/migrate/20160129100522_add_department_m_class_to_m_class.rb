class AddDepartmentMClassToMClass < ActiveRecord::Migration
  def change
    add_column :m_classes, :department_m_class, :string
  end
end
