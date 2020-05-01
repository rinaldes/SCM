class CreatePettyCashes < ActiveRecord::Migration
  def change
    create_table :petty_cashes do |t|
      t.date :date
      t.integer :office_id
      t.time :start_time
      t.float :start_amount
      t.time :end_time
      t.float :actual_end_amount
      t.timestamps
    end
  end
end
