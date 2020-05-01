class AddSessionTypeToSodEods < ActiveRecord::Migration
  def change
    add_column :sod_eods, :session_type, :string
  end
end
