class AddDueDateToReceiving < ActiveRecord::Migration
  def change
    add_column :receivings, :due_date, :date
  end
end
