class ToDoList < ActiveRecord::Migration
  def change
    create_table :to_do_lists do |t|
      t.string :code
      t.integer :user_id
      t.string :description
      t.string :status
      t.string :image
      t.string :tujuan
      t.date :date
      t.time :time
      t.timestamps
    end
  end
end
