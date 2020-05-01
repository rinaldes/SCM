class MonthlyForecastDetail < ActiveRecord::Base

  belongs_to :monthly_forecast
  belongs_to :department

  def self.by_department(department)
    if department.present?
      where(:department_id => department).order('forecast_date ASC')
    else
      where(nil).order('forecast_date ASC')
    end
  end

  def self.count_qty_in_percent
    qty = self.sum(:qty).to_f
    if qty > 0
      (self.sum(:realization_qty).to_f / self.sum(:qty).to_f ) * 100.0
    else
      0
    end
  end

  def self.count_amount_in_percent
    amount = self.sum(:amount).to_f
    if amount > 0
      (self.sum(:realization_amount).to_f / self.sum(:amount).to_f ) * 100.0
    else
      0
    end
  end

end
