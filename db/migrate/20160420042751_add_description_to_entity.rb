class AddDescriptionToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :title, :string
    add_column :entities, :footer, :string
  end
end
