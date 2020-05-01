class ReEditPromo < ActiveRecord::Migration
  def change
  	rename_column :promotions, :branch, :branch_id
  	change_column :promotions, :branch_id, 'integer USING CAST(branch_id AS integer)'
  end
end
