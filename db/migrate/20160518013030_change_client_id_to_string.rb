class ChangeClientIdToString < ActiveRecord::Migration
  def change
    change_column :cancel_items, :client_id, :string
  end
end
