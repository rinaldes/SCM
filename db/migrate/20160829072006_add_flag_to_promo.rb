class AddFlagToPromo < ActiveRecord::Migration
  def change
    add_column :promotions, :is_member, :boolean, default: false
    add_column :promotions, :is_p2p, :boolean, default: false
    add_column :promotions, :is_claim, :boolean, default: false

  end
end
