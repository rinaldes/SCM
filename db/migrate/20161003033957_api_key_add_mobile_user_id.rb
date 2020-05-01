class ApiKeyAddMobileUserId < ActiveRecord::Migration
  def change
  	add_column :api_keys, :mobile_user_id, :integer
  end
end