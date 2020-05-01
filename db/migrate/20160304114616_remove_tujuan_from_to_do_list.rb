class RemoveTujuanFromToDoList < ActiveRecord::Migration
  def change
    remove_column :to_do_lists, :tujuan, :string
  end
end
