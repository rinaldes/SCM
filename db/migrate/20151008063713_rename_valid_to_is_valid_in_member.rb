class RenameValidToIsValidInMember < ActiveRecord::Migration
  def change
    rename_column :members, :valid, :is_valid
  end
end
