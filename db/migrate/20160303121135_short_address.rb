class ShortAddress < ActiveRecord::Migration
  def change
    add_column :offices, :short_address, :string
  end
end