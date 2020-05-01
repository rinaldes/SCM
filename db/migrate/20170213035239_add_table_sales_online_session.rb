class AddTableSalesOnlineSession < ActiveRecord::Migration
  def change
    create_table :sales_online_sessions do |t|
      t.string :pin
      t.string :code
      t.timestamps
    end
  end
end
