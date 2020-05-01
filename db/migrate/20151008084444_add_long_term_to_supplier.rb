class AddLongTermToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :long_term, :integer
  end
end
