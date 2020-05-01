class AddNoteToBrands < ActiveRecord::Migration
  def change
    add_column :brands, :note, :text
  end
end
