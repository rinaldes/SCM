class Forecast < ActiveRecord::Base

  has_many :monthly_forecasts, :dependent => :destroy
  accepts_nested_attributes_for :monthly_forecasts, :allow_destroy => true, :reject_if => lambda { |c| c[:month_number].blank? }

  belongs_to :office, :foreign_key => "branch_id"

  validates :year, :presence => true
  validates :branch_id, :presence => true

end