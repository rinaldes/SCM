class AddIsCreditInMember < ActiveRecord::Migration
  def change
    add_column :members, :is_credit, :boolean
  end
end
