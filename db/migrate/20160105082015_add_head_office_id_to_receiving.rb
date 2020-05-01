class AddHeadOfficeIdToReceiving < ActiveRecord::Migration
  def change
    add_column :receivings, :head_office_id, :integer
  end
end
