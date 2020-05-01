class SettingPointMember < ActiveRecord::Base
  validates :point, presence: {:message => 'required'}
  validates :price, presence: {:message => 'required'}
  has_many :members, :through => :point_members #join table
  has_many :point_members
end
