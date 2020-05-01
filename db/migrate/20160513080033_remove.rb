class Remove < ActiveRecord::Migration
  def change
	remove_column :companyprofiles, :entity_id
  end
end
