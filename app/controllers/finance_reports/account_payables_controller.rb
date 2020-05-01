class FinanceReports::AccountPayablesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_account_payables, only: [:index, :export]
  before_filter :can_manage_account_payable_report, only: [:index]

  add_crumb "Finance", '/'
  add_crumb("Account Payable Report".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_account_payables_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finance_reports_account_payables_path }

  def index
    respond_to do |format|
      format.html
    end
  end

  def export
    filename = "Account Payable Report.xlsx"
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  private
    def prepare_account_payables
      @account_payables = AccountPayable.get_report
    end

    def can_manage_account_payable_report
      not_authorized unless current_user.can_manage_account_payable_report?
    end
end
