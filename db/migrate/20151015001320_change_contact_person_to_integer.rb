class ChangeContactPersonToInteger < ActiveRecord::Migration
  def change
    change_column :offices, :contact_person, 'integer USING CAST(contact_person AS integer)'
  end
end
