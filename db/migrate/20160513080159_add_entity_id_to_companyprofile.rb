class AddEntityIdToCompanyprofile < ActiveRecord::Migration
  def change
	add_column :companyprofiles, :entity_id, :integer
  end
end
