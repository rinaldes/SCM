class AddMemberToBalance < ActiveRecord::Migration
  def change
    add_column :members, :balance, :float
  end
end
