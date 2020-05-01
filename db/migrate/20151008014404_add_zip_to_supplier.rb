class AddZipToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :zip, :string
    add_column :suppliers, :term, :integer
    add_column :suppliers, :suptype, :string
    add_column :suppliers, :ppn, :float
    add_column :suppliers, :paytype, :string
    add_column :suppliers, :share, :string
  end
end
