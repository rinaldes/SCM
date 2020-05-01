class AddSodeodIdToSessions < ActiveRecord::Migration
  def change
    add_column :sessions, :sodeod_id, :integer
  end
end
