class AddUnitTypeToPr < ActiveRecord::Migration
  def change
    add_column :purchase_request_details, :unit_type, :string
  end
end
