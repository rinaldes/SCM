class AddCustomCssToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :custom_css, :string
  end
end
