class AddReceiveIdOnAccountPayableDetails < ActiveRecord::Migration
  def change
    add_column :account_payable_details, :recieve_id, :integer
  end
end
