class AddContactPersonIdToProductSuppliers < ActiveRecord::Migration
  def change
    add_column :product_suppliers, :contact_person_id, :integer
  end
end
