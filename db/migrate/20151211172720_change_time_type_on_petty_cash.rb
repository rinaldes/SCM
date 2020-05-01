class ChangeTimeTypeOnPettyCash < ActiveRecord::Migration

  def change
    remove_column :petty_cashes, :start_time
    remove_column :petty_cashes, :end_time
    add_column :petty_cashes, :start_time, :datetime
    add_column :petty_cashes, :end_time, :datetime
  end

end
