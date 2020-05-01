class AddPpnToSd < ActiveRecord::Migration
  def change
    add_column :sales_details, :ppn, :float
    add_column :sessions, :office_id, :integer
    add_column :sessions, :client_id, :string
  end
end
