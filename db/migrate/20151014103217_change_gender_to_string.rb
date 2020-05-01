class ChangeGenderToString < ActiveRecord::Migration
  def change
    change_column :members, :gender, :string
  end
end
