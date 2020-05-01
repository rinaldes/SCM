class CreateCompanyprofiles < ActiveRecord::Migration
  def change
    create_table :companyprofiles do |t|

      t.timestamps
    end
  end
end
