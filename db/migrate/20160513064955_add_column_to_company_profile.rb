class AddColumnToCompanyProfile < ActiveRecord::Migration
  def change
	add_column :companyprofiles, :logo, :string
	add_column :companyprofiles, :name, :string
	add_column :companyprofiles, :address, :string
	add_column :companyprofiles, :npwp, :string
	add_column :companyprofiles, :npwp_address, :string
	add_column :companyprofiles, :title, :string
	add_column :companyprofiles, :footer, :string
	add_column :companyprofiles, :favicon, :string
	add_column :companyprofiles, :custom_css, :string
  end
end
