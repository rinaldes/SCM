class Feature < ActiveRecord::Base
 	belongs_to :role
 	# has_one :feature_group, dependent: :destroy
 	belongs_to :feature_name
end
