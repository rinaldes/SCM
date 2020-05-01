class ChangeTipeData < ActiveRecord::Migration
  def change
    remove_column :sessions, :start_time
    remove_column :sessions, :end_time
    add_column :sessions, :start_time, :datetime
    add_column :sessions, :end_time, :datetime
  end
end
