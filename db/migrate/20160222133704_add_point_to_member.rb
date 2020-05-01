class AddPointToMember < ActiveRecord::Migration
  def change
    add_column :members, :point, :integer
  end
end
