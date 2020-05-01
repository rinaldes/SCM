class StatusPkpFlagPajak < ActiveRecord::Migration
  def change
  	add_column :suppliers, :status_pkp, :boolean
  	add_column :suppliers, :flag_pajak, :boolean
  end
end
