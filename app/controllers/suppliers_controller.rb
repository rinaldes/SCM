class SuppliersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_supplier, only: [:index, :show]
  before_filter :can_manage_supplier, only: [:new, :create, :edit, :update]

  autocomplete :supplier, :name
  # def validaterekening
  #     @supplier.errors.add(:contact_people_attributes,'atribut pada rekening bank tidak boleh kosong') if params[:supplier][:contact_people_attributes][1].blank?
  # end
  def import
    import_result = Supplier.import(params[:file])
    if %w(text/csv application/vnd.ms-excel).include?params[:file].content_type
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to suppliers_path
  end

  def add_contact
    respond_to do |format|
      format.js
    end
  end

  def add_bank_account
    respond_to do |format|
      format.js
    end
  end

  def index
    get_paginated_suppliers
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls do
        @sup_list = Supplier.all
      end
      if(params[:a] == "a")
        format.csv { send_data Supplier.all.to_csv2 }
      else
        format.csv { send_data Supplier.to_csv(@sup_list, {}) }
      end
    end
  end

  def new
    @supplier = Supplier.new(params[:supplier])
    load_departments
    respond_to do |format|
      format.html
    end
  end

  # GET /users/1
  def show
    @supplier = Supplier.find(params[:id])
    @depart = @supplier.departments
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def get_number
    @supplier_number = Supplier.number(params)
    respond_to do |format|
      format.js
    end
  end

  # GET /suppliers/1/edit
  def edit
    @supplier = Supplier.find(params[:id])
    load_departments
    respond_to do |format|
      format.html
    end
  end

  def get_suppliers_modal
    get_paginated_suppliers
  end

  def search_supplier
    conditions = []
    conditions << "LOWER(code) LIKE LOWER('%#{params[:supplier_code]}%')" if params[:supplier_code].present?
    conditions << "LOWER(name) LIKE LOWER('%#{params[:supplier_name]}%')" if params[:supplier_name].present?
    conditions << "LOWER(address) LIKE LOWER('%#{params[:supplier_address]}%')" if params[:supplier_address].present?
    conditions << "LOWER(city) LIKE LOWER('%#{params[:supplier_city]}%')" if params[:supplier_city].present?
    @suppliers = Supplier.where(conditions.join(' AND ')).paginate(page: params[:page], per_page: 10) || []
    respond_to do |format|
      format.js
    end
  end

  # POST /suppliers
  # POST /suppliers.json
  def create
    @supplier = Supplier.new(supplier_params.merge(code: ("S#{('%03d' % ((Supplier.last.code.gsub('S', '').to_i rescue 0)+1))}"), status_pkp: (params[:supplier][:status_pkp] == 'PKP')))
    # validaterekening
    # at_least_one_cp
    if @supplier.save
      save_to_other_database
      flash[:notice] = 'Supplier was successfully created'
      redirect_to suppliers_path
    else
      load_departments
      flash[:error] = @supplier.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def delete_from_other_database
    ptnr_mstr = PtnrMstr.find_by_ptnr_name(@sup_name)
    ptnra_addr = PtnraAddr.where(ptnra_ptnr_oid: ptnr_mstr.ptnr_oid) if ptnr_mstr.present?
    if ptnra_addr.present?
      ptnra_addr.each do |ptnra|
        ptnrac_cntc = PtnracCntc.where(addrc_ptnra_oid: ptnra.ptnra_oid)
        ptnrac_cntc.destroy_all
      end
      ptnra_addr.destroy_all
    end
    ptnr_mstr.destroy if ptnr_mstr.present?
  end

  def save_to_other_database
    if DatabaseLain.connected?
      #== master ==#
      if PtnrMstr.find_by_ptnr_code(@supplier.code).nil?
        @ptnr_id = PtnrMstr.order(:ptnr_id).last.ptnr_id
        if @ptnr_id.to_s.slice(0) == '2'
          @ptnr_id = (("#{('%06d')}" % ((PtnrMstr.order(:ptnr_id).last.ptnr_id)+1)).to_i)
        else
          @ptnr_id = (("#{('2%06d')}" % ((PtnrMstr.order(:ptnr_id).last.ptnr_id)+1)).to_i)
        end
        @ptnr_mstr = PtnrMstr.new(ptnr_oid: SecureRandom.uuid, ptnr_dom_id: 1, ptnr_en_id: 1, ptnr_add_by: current_user.username, ptnr_add_date: DateTime.now, ptnr_id: @ptnr_id, ptnr_code:@supplier.code, ptnr_name: @supplier.name, ptnr_ptnrg_id: 10174, ptnr_is_cust: 'N', ptnr_is_vend: 'Y', ptnr_active: 'Y', ptnr_dt: DateTime.now, ptnr_ac_ar_id: 0, ptnr_sb_ar_id: 0, ptnr_cc_ar_id: 0, ptnr_ac_ap_id: 0, ptnr_sb_ap_id: 0, ptnr_cc_ap_id: 0, ptnr_cu_id: 1, ptnr_limit_credit: 0, ptnr_institution_id: 1000100, ptnr_branch_id: 10001, ptnr_type_id: 991440, ptnr_credit_terms_id: 991025, ptnr_sales_id: 0, ptnr_tax_class: 0, ptnr_tax_include: 'N', ptnr_bk_id: 0)
        @ptnr_mstr.save
      else
        @ptnr_mstr = PtnrMstr.find_by_ptnr_code(@supplier.code)
        @ptnr_mstr.update_attributes(ptnr_upd_by: current_user.username, ptnr_upd_date: DateTime.now, ptnr_add_by: current_user.username, ptnr_name: params[:supplier][:name])
      end
      #== address ==#
      if PtnraAddr.find_by_ptnra_line_1_and_ptnra_ptnr_oid(@supplier.address, @ptnr_mstr.ptnr_oid).nil?
        @ptnra_id = PtnraAddr.order(:ptnra_id).last.ptnra_id
        if @ptnra_id.to_s.slice(0) == '2'
          @ptnra_id = (("#{('%07d')}" % ((PtnraAddr.order(:ptnra_id).last.ptnra_id)+1)).to_i)
        else
          @ptnra_id = (("#{('2%07d')}" % ((PtnraAddr.order(:ptnra_id).last.ptnra_id)+1)).to_i)
        end
        @ptnra_addr = PtnraAddr.new(ptnra_oid: SecureRandom.uuid, ptnra_dom_id: 1, ptnra_en_id: 1, ptnra_add_by: current_user.username, ptnra_add_date: DateTime.now, ptnra_id: @ptnra_id, ptnra_line_1: @supplier.address, ptnra_line_2: @supplier.city, ptnra_phone_1: @supplier.phone, ptnra_fax_1: @supplier.fax, ptnra_ptnr_oid: @ptnr_mstr.ptnr_oid, ptnra_addr_type: 993, ptnra_active: 'Y', ptnra_dt: DateTime.now)
        @ptnra_addr.save
      else
        @ptnra_addr = PtnraAddr.find_by_ptnra_line_1_and_ptnra_ptnr_oid(@supplier.address, @ptnr_mstr.ptnr_oid)
        @ptnra_addr.update_attributes(ptnra_upd_by: current_user.username, ptnra_upd_date: DateTime.now, ptnra_line_1: params[:supplier][:address], ptnra_line_2: params[:supplier][:city], ptnra_phone_1: params[:supplier][:phone], ptnra_fax_1: params[:supplier][:fax])
      end
      #== contact ==#
      params[:supplier][:contact_people_attributes].values.each do |su_cp|
        if su_cp[:id].blank? || PtnracCntc.find_by_ptnrac_contact_name_and_addrc_ptnra_oid((ContactPerson.find(su_cp[:id].to_i).name rescue ''), @ptnra_addr.ptnra_oid).nil?
          @ptnrac_cntc = PtnracCntc.new(ptnrac_oid: SecureRandom.uuid, addrc_ptnra_oid: @ptnra_addr.ptnra_oid, ptnrac_add_by: current_user.username, ptnrac_add_date: DateTime.now, ptnrac_seq: 1, ptnrac_function: 9945, ptnrac_contact_name: su_cp[:name], ptnrac_phone_1: su_cp[:phone], ptnrac_email: su_cp[:email], ptnrac_dt: DateTime.now)
          @ptnrac_cntc.save
        else
          update_cp = ContactPerson.find(su_cp[:id].to_i).name
          @ptnrac_cntc = PtnracCntc.find_by_ptnrac_contact_name_and_addrc_ptnra_oid(update_cp, @ptnra_addr.ptnra_oid)
          @ptnrac_cntc.update_attributes(ptnrac_upd_by: current_user.username, ptnrac_upd_date: DateTime.now, ptnrac_contact_name: su_cp[:name], ptnrac_phone_1: su_cp[:phone], ptnrac_email: su_cp[:email])
        end
      end
      @supplier.update_attributes(sent_to_erp: Time.now())
    end
  end

  # PUT /suppliers/1
  # PUT /suppliers/1.json
  def update
    @supplier = Supplier.find(params[:id])
    old_accounts = @supplier.bank_accounts.map(&:id)
    old_departments = @supplier.supplier_departments.map(&:id)
    if @supplier.update_attributes(params.require(:supplier).permit(
      :address, :city, :code, :status_bkt, :email, :fax, :hp1, :hp2, :name, :person, :phone, :send_address, :send_city, :pinbb, :no_bill, :bank, :branch, :long_term, :suptype, :setup_discount, :contact_name,
      bank_accounts_attributes: [:name, :account_number, :bank_name, :branch, :city], supplier_departments_attributes: [:department_id]
    ).merge(status_pkp: params[:supplier][:status_pkp] == 'PKP'))
      params[:supplier][:contact_people_attributes].each{|sd|
        if sd[1]['name'].present?
          if ContactPerson.find_by_id(sd[1]['id']).present?
            ContactPerson.find_by_id(sd[1]['id']).update_attributes(name: sd[1]['name'], phone: sd[1]['phone'], pinbb: sd[1]['pinbb'], email: sd[1]['email'])
          else
            ContactPerson.create(name: sd[1]['name'], phone: sd[1]['phone'], pinbb: sd[1]['pinbb'], email: sd[1]['email'], supplier_id: @supplier.id)
          end
        else
          ContactPerson.find_by_id(sd[1]['id']).delete
        end
      }
      BankAccount.where(id: old_accounts).delete_all
      SupplierDepartment.where(id: old_departments).delete_all
      begin
        DatabaseLain.establish_connection
        save_to_other_database# if DatabaseLain.connected?
        flash[:notice] = "Supplier Diubah, berhasil untuk mengirimnya ke ERP."
      rescue
        flash[:warning] = "Supplier Diubah, namun gagal untuk mengirimnya ke ERP."
      end
      redirect_to suppliers_path
    else
      load_departments
      flash[:error] = @supplier.errors.full_messages.join('<br/>')
      render "edit"
    end
  end

  def destroy
    @supplier = Supplier.find(params[:id])
    @sup_name = @supplier.name
    if @supplier.check_transaction && @supplier.destroy
      delete_from_other_database
      flash[:error] = nil
      flash[:notice] = "Successfully delete supplier"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete supplier. data in use"
    end
    get_paginated_suppliers
    respond_to do |format|
      format.js
    end
  end

  def search
    @suppliers = Supplier.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 100) || []
    respond_to do |format|
      @supplier = Supplier.new
      format.js
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def autocomplete_supplier_name
    hash = []
    suppliers = Supplier.where("LOWER(name) LIKE LOWER('%#{params[:term]}%')").limit(25)
    suppliers.collect do |p|
      hash << {"id" => p.id, "label" => p.name, "value" => p.name, "code" => p.code, "address" => p.address}
    end
    render json: hash
  end

  def autocomplete_supplier_code
    hash = []
    suppliers = Supplier.where("LOWER(code) LIKE LOWER('%#{params[:term]}%') OR LOWER(name) LIKE LOWER('%#{params[:term]}%')").limit(25)
    suppliers.collect do |p|
      hash << {"id" => p.id, "label" => "#{p.code} - #{p.name}", "name" => p.name, "value" => "#{p.code} - #{p.name}", "address" => p.address, 'id' => p.id}
    end
    render json: hash
  end

  private
  def get_paginated_suppliers
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @suppliers = Supplier.where(conditions.join(' AND ')).order(default_order).paginate(page: params[:page], per_page: PER_PAGE) || []
    @sup_list = Supplier.where(conditions.join(' AND ')).joins(:products).order(default_order) || []
  end

  def supplier_params
    params.require(:supplier).permit(
      :address, :city, :code, :email, :fax, :hp1, :hp2, :name, :person, :phone, :send_address, :send_city, :pinbb, :no_bill, :bank, :branch, :long_term, :suptype, :npwp,
      :setup_discount, :contact_name, :status_pkp, :status_bkt, :default_qty, contact_people_attributes: [:division_name, :name, :phone, :pinbb, :email],
      bank_accounts_attributes: [:name, :account_number, :bank_name, :branch, :city], supplier_departments_attributes: [:department_id]
    )
  end

  def can_view_supplier
    not_authorized unless current_user.can_view_supplier?
  end

  def can_manage_supplier
    not_authorized unless current_user.can_manage_supplier?
  end
end
