class AddUidToRts < ActiveRecord::Migration
  def change
    add_column :returns_to_suppliers, :user_id, :integer
  end
end
