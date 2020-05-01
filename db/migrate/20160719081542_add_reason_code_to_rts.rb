class AddReasonCodeToRts < ActiveRecord::Migration
  def change
    add_column :returns_to_suppliers, :reason_code, :string
  end
end
