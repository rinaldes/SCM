class MonthlyForecast < ActiveRecord::Base

  belongs_to :forecast
  belongs_to :department
  has_many :monthly_forecast_details, :dependent => :destroy
  accepts_nested_attributes_for :monthly_forecast_details

  after_create :generate_for_departments

  def generate_for_departments
    start_date = Date.new(self.forecast.year.year, self.month_number, 1)
    end_date = start_date.end_of_month

      departments = self.forecast.office.departments
      departments.each do | department|
        (start_date..end_date).each do |date|
          self.monthly_forecast_details.create(:forecast_date => date, :department_id => department.id)
        end
      end
  end

  def self.by_month(month)
    if month.present?
      where(:month_number => month)
    else
      where(nil)
    end
  end

  def count_monthly_qty_department(dep)
    self.monthly_forecast_details.where(:department_id => dep).sum(:qty).to_f
  end

  def count_monthly_amount_department(dep)
    self.monthly_forecast_details.where(:department_id => dep).sum(:amount).to_f
  end

end
