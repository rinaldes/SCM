class AddColumnToCompanyprofile < ActiveRecord::Migration
  def change
	add_column :companyprofiles, :domain_name, :string
  end
end
