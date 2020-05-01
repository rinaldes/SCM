class AddNewColumn < ActiveRecord::Migration
  def change
  	add_column :mobile_users, :email, :string
  end
end
