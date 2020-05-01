class MonthlyBudget < ActiveRecord::Base
  belongs_to :budget

  before_create :set_initial_budget#, if: :already_initialized?
  before_update :set_realization_in_percent

  def set_initial_budget
    self.initial_budget = self.budget.monthly_budget
  end

  def already_initialized?
  	!self.budget.present?
  end

  def set_realization_in_percent
    self.realization_in_percent = (self.get_month_realization.to_f / (self.initial_budget.to_f + additional_budget.to_f)) * 100.0
  end

  def get_month_realization
    realization = Sale.where('extract(year from created_at) = ? and extract(month from created_at) = ?', self.budget.year.year, self.month_number).sum(:total_price)
    if realization.blank?
      realization
    else
       return 0
     end
  end

  def get_month_realization_in_percent
      realization = self.get_month_realization.to_f
      budgets = self.initial_budget.to_f + self.additional_budget.to_f
      if realization > 0 && budgets > 0
        (realization / budgets) * 100.0
      else
        0
      end
  end

  # ToDo: sisa budget sama total budget dari bulan sebelumnya.
  def get_month_prev_budget
    prev = self.budget.monthly_budgets.where("month_number < ?", 5).last
   (prev.initial_budget.to_f + prev.additional_budget.to_f)
  end

end