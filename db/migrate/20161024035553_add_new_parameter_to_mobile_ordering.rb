class AddNewParameterToMobileOrdering < ActiveRecord::Migration
  def change
    add_column :mobile_users, :token_registration_id, :string
  end
end