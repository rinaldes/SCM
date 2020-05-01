class AddSessionOnPettyCash < ActiveRecord::Migration
  def change
    add_column :petty_cashes, :session, :integer
  end
end
