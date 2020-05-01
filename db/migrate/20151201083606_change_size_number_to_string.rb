class ChangeSizeNumberToString < ActiveRecord::Migration
  def change
    change_column :size_details, :size_number, :string
  end
end
