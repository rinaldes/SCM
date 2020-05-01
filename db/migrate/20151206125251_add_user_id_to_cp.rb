class AddUserIdToCp < ActiveRecord::Migration
  def change
    add_column :contact_people, :user_id, :integer
  end
end
