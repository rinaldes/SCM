class AddNpwpToStore < ActiveRecord::Migration
  def change
    add_column :offices, :npwp, :string
  end
end
