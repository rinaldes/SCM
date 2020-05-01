class AddCreditLimitToMember < ActiveRecord::Migration
  def change
    add_column :members, :credit_limit, :float
  end
end
