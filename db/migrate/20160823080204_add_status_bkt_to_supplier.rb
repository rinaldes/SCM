class AddStatusBktToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :status_bkt, :boolean
  end
end