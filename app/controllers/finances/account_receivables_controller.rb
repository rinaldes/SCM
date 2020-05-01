class Finances::AccountReceivablesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_account_receivables, only: [:index, :destroy]
  before_filter :prepare_account_receivable, only: [:edit, :update, :destroy, :show]
  before_filter :can_view_account_receivable, only: [:index, :show]
  before_filter :can_manage_account_receivable, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("Account Receivable".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_account_receivables_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finances_account_receivables_path }
  add_crumb("Edit".html_safe, only: ["edit"]) { |instance| instance.send :finances_account_receivables_path }
  add_crumb("Show".html_safe, only: ["show"]) { |instance| instance.send :finances_account_receivables_path }

  def index
  end

  def show
  end

  def edit
  end

  def update
    if @account_receivable.update_attributes(account_receivable_params)
      flash[:notice] = 'Account Receivable was successfully updated.'
      redirect_to finances_account_receivables_path
    else
      flash[:error] = @account_receivable.errors.full_messages
      if params[:prev_action] == "show"
        render :edit
      else
        render :show
      end
    end
  end

  def destroy
    @account_receivable.destroy unless @account_receivable.blank?
  end

 private

  def account_receivable_params
    params.require(:account_receivable).permit(:due_date, :bill_to_name,  :bill_to_email, :bill_to_phone, :bill_to_address , payments_attributes: [:id, :amount, :due_date, :payment_amount, :payment_date, :penalty, :status, :account_receivable_id, :payment_number,  :_destroy])
  end

  def prepare_account_receivables
    ar_number = params[:by_ar_number]
    transaction_no = params[:by_transaction_no]
    customer_name = params[:by_customer_name]

    results = AccountReceivable.in_ar_number(ar_number).in_transaction_no(transaction_no).in_customer_name(customer_name).order('updated_at DESC')
    @account_receivables = results.page(params[:page]).per(PER_PAGE)
  end

  def prepare_account_receivable
    @account_receivable = AccountReceivable.find(params[:id])
  end

  def can_view_account_receivable
    not_authorized unless current_user.can_view_account_receivable?
  end

  def can_manage_account_receivable
    not_authorized unless current_user.can_manage_account_receivable?
  end

end
