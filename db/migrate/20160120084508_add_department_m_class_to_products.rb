class AddDepartmentMClassToProducts < ActiveRecord::Migration
  def change
    add_column :products, :department_m_class, :string
  end
end
