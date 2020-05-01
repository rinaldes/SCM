class AddTermConditionToPromo < ActiveRecord::Migration
  def change
    add_column :promotions, :term_and_condition, :string
  end
end
