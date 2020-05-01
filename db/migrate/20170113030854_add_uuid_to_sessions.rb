class AddUuidToSessions < ActiveRecord::Migration
  def change
    add_column :sessions, :uuid, :uuid, default: "uuid_generate_v4()", null: false
  end
end
