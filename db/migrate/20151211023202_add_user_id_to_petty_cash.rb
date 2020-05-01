class AddUserIdToPettyCash < ActiveRecord::Migration
  def change
    add_column :petty_cashes, :user_id, :integer
  end
end
