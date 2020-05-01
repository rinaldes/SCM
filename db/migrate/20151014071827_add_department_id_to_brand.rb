class AddDepartmentIdToBrand < ActiveRecord::Migration
  def change
    add_column :brands, :department_id, :integer
  end
end
