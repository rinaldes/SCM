class AddHeadOfficeIdToBranch < ActiveRecord::Migration
  def change
    add_column :offices, :head_office_id, :integer
  end
end
