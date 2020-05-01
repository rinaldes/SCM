class AddProvinceToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :province, :string
  end
end
