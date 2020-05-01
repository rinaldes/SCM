class PlanogramsStore < ActiveRecord::Base
  belongs_to :planogram
  belongs_to :office
end
