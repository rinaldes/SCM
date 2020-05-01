class AddColumnToTodolist < ActiveRecord::Migration
  def change
  	add_column :to_do_lists, :end_at, :date
  end
end
