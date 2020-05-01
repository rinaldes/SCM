class AddNpwpToSuppliers < ActiveRecord::Migration
  def change
    add_column :suppliers, :npwp, :string
  end
end
