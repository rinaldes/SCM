class AddPasswordmd5ToUsers < ActiveRecord::Migration
  def change
    add_column :users, :pos_password, :string
  end
end
