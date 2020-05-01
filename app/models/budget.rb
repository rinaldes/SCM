class Budget < ActiveRecord::Base

  has_many :monthly_budgets, :dependent => :destroy
  accepts_nested_attributes_for :monthly_budgets, :allow_destroy => true, :reject_if => lambda { |c| c[:month_number].blank? }

  validates :year, :presence => true
  validates :monthly_budget, :presence => true

  def get_year_realization
    realization = Sale.where("EXTRACT(YEAR FROM created_at) = ?", self.year.year).select("SUM(total_price)")
    if realization.blank?
      realization
    else
      return 0 
    end
  end

  def get_year_realization_in_percent
      realization = self.get_year_realization.nil? ? 0 : self.get_year_realization.to_f
      monthly_budgets = self.monthly_budgets.sum(:initial_budget).to_f + self.monthly_budgets.sum(:additional_budget).to_f
      if realization > 0 && monthly_budgets > 0
        (realization / monthly_budgets) * 100.0
      else
        0
      end
  end

end