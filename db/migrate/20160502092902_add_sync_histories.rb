class AddSyncHistories < ActiveRecord::Migration
  def change
	create_table :sync_histories do |t|
      t.string :name
      t.timestamps
	  t.string :remarks
    end
  end
end
