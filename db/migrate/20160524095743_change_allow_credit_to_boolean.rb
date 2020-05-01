class ChangeAllowCreditToBoolean < ActiveRecord::Migration
  def change
    add_column :member_levels, :is_credit, :boolean
  end
end
