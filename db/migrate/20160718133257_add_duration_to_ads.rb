class AddDurationToAds < ActiveRecord::Migration
  def change
    add_column :ads, :duration, :integer #in second
  end
end
