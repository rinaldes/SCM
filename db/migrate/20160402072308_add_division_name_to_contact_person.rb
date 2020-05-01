class AddDivisionNameToContactPerson < ActiveRecord::Migration
  def change
    add_column :contact_people, :division_name, :string
  end
end
