class AddMissingColumn < ActiveRecord::Migration
  def change
    add_column :returns_to_suppliers, :quantity, :integer
    add_column :returns_to_suppliers, :total, :integer
    add_column :returns_to_suppliers, :note, :string
  end
end
