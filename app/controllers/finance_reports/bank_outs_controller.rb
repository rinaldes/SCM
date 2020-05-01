class FinanceReports::BankOutsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_bank_outs, only: [:index, :export]
  before_filter :can_manage_bank_out_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Bank Out".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_bank_outs_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_bank_outs_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Bank Out Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_bank_outs
      # results = AccountPayable.in_receiving.order('created_at DESC')
      # @account_payables = results.page(params[:page]).per(PER_PAGE)
    end

    def can_manage_bank_out_report
      not_authorized unless current_user.can_manage_bank_out_report?
    end
end
