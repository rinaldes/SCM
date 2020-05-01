class FinanceReports::CashOutsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_cash_outs, only: [:index, :export]
  before_filter :can_manage_cash_out_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Cash Out Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_cash_outs_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_cash_outs_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Cash Out Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_cash_outs
      @cash_outs = CashOut.get_report
    end

    def can_manage_cash_out_report
      not_authorized unless current_user.can_manage_cash_out_report?
    end
end
