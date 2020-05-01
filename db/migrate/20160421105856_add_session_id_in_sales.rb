class AddSessionIdInSales < ActiveRecord::Migration
  def change
    add_column :sales, :session_id, :integer
  end
end
