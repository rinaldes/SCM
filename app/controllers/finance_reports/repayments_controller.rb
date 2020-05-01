class FinanceReports::RepaymentsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_repayments, only: [:index, :export]
  before_filter :can_manage_repayment_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Repayment Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_repayments_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_repayments_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Repayment Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_repayments
      # results = AccountPayable.in_receiving.order('created_at DESC')
      # @account_payables = results.page(params[:page]).per(PER_PAGE)
    end

    def can_manage_repayment_report
      not_authorized unless current_user.can_manage_repayment_report?
    end
end
