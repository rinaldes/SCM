class AddIdCompanyToCompanyProfile < ActiveRecord::Migration
  def change
  	add_column :companyprofiles, :entity_id, :string
	add_column :companyprofiles, :coba, :string
  end
end
