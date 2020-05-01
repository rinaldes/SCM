class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.integer :user_id
      t.integer :shift_no
      t.time :start_time
      t.time :end_time
      t.timestamps
    end
  end
end
