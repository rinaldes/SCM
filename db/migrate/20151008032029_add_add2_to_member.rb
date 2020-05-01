class AddAdd2ToMember < ActiveRecord::Migration
  def change
#    add_column :members, :add2, :string
    add_column :members, :city, :string
    add_column :members, :zip, :string
    add_column :members, :coment1, :string
    add_column :members, :coment2, :string
    add_column :members, :datemember, :date
    add_column :members, :reference_id, :integer
    add_column :members, :valid, :boolean
    add_column :members, :discount, :float
    add_column :members, :active, :boolean
  end
end
