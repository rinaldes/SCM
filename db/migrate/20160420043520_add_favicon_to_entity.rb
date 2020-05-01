class AddFaviconToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :favicon, :string
  end
end
