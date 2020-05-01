class ChangeAndAddColumnOnSodEods < ActiveRecord::Migration
  def change
    remove_column :sod_eods, :start_time, :time
    remove_column :sod_eods, :end_time, :time

    add_column :sod_eods, :machine_id, :string
    add_column :sod_eods, :start_time, :timestamp
    add_column :sod_eods, :end_time, :timestamp
  end
end
