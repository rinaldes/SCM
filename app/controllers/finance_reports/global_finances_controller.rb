class FinanceReports::GlobalFinancesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_global_finances, only: [:index, :export]
  before_filter :can_manage_global_finance_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Global Finance Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_global_finances_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_global_finances_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Global Finance Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_global_finances
      # results = AccountPayable.in_receiving.order('created_at DESC')
      # @account_payables = results.page(params[:page]).per(PER_PAGE)
    end

    def can_manage_global_finance_report
      not_authorized unless current_user.can_manage_global_finance_report?
    end
end
