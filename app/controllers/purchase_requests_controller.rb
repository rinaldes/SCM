class PurchaseRequestsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :get_paginated_purchase_requests, only: [:index, :destroy]
  autocomplete :purchase_request, :number
  before_filter :can_view_pr, only: [:index, :show]
  before_filter :can_manage_pr, only: [:new, :create, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html # show.html.erb
      format.js
      format.json{render json: @purchase_requests.map{|pr|pr.attributes.merge(details: pr.purchase_request_details)}.to_json}
    end
  end

  def show
    @purchase_request = PurchaseRequest.find(params[:id])
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(:product).group_by{|pd|pd.product_id}
    @supplier = @purchase_request.supplier
    respond_to do |format|
      format.html # show.html.erb
      format.xlsx{
        response.headers['Content-Disposition'] = "attachment; filename=PR#{@purchase_request.date}.xlsx"
      }
    end
  end

  def get_last_number
    render json: {
      number: (('%07d' % (((PurchaseRequest.where("extract(YEAR FROM date)=#{Time.now.year}").order("id DESC").limit(1)[0].number.last.to_i rescue 0) +1))))
    }
  end

  def print_to_pdf
    @purchase_request = PurchaseRequest.find params[:id]
    @supplier = @purchase_request.supplier
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "Purchase Request #{@purchase_request.number}.pdf",
      :disposition => 'attachment',
    )
  end

  def print_to_excel
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(name: "Distributor-#{Time.now.to_i}") do |sheet|
      sheet.add_row ["Code", "Name", "Email", "Phone", "Phone2", "Fax", "Join Date", "Address", "City", "Country", "Postal Code", "Latitude", "Longitude"]
      @distributors.each{|item|
        user = item.user
        sheet.add_row [item.code, (user.usr_name rescue '-'), (user.email rescue '-'), (user.usr_phone_number rescue '-'), (item.cst_phone_2 rescue '-'), item.cst_fax,
          item.cst_join_date, item.cst_address, item.cst_city, (item.cst_country.name rescue '-'), item.cst_postal_code, item.lat, item.lng]
      }
      wb.add_worksheet(:name => "Contact Person") do |sheet2|
        sheet2.add_row ["Distributor Code", "Name", "Email", "Phone 1", "Phone 2", "Position"]
        @distributors.map(&:customer_contacts).each{|customer_contacts|
          customer_contacts.each{|contact|
            sheet2.add_row [contact.customer.code, contact.cstd_name, contact.cstd_email,
              contact.cstd_phone_number.to_i == 0 ? contact.cstd_phone_number : "'#{contact.cstd_phone_number}",
              contact.cstd_phone_number_2.to_i == 0 ? contact.cstd_phone_number_2 : "'#{contact.cstd_phone_number_2}", contact.cstd_position]
          }
        }
      end
    end
  end

  def new
    time_now = Time.now
    @purchase_request = PurchaseRequest.new date: time_now.strftime('%Y-%m-%d')
    @branches = Branch.all
    @date = time_now.strftime("%d-%m-%Y")
    load_master
  end

  def generate_po
    @purchase_request = PurchaseRequest.find(params[:id])
    @purchase_request.update_attributes(status: PurchaseRequest::APPROVED)
    @purchase_request.purchase_request_details.group_by{|prd|
      (ProductSupplier.where(product_id: prd.product_id).limit(1).order("id DESC").first.supplier_id rescue 1)}.each{|prd1|
        po = PurchaseOrder.new number: "PO#{Time.now.year}#{sprintf('%06d', (PurchaseOrder.last.id rescue 0)+1)}",
          date: Time.now, supplier_id: prd1[0], status: PurchaseOrder::WAITING_APPROVAL,
          grand_total: (prd1[1].map{|prd2|SellingPrice.where("product_id=#{prd2.product_id} AND end_date>NOW()").last.hpp}.compact.sum * prd1[1].map(&:quantity).sum * prd1[1].map(&:fraction).sum), purchase_request_id: @purchase_request.id,
          head_office_id: @purchase_request.branch_id, total_qty: prd1[1].map(&:quantity).sum, top: 7, expected_delivery_date: Time.now+7.days, due_date: Time.now+7.days
      if po.save
        prd1[1].each{|prd|
          PurchaseOrderDetail.create purchase_order_id: po.id, product_id: prd.product_id,
            total_price: SellingPrice.where("product_id=#{prd.product_id} AND end_date>NOW()").last.hpp.to_f*prd.quantity.to_f*prd.fraction.to_f,
            quantity: prd.quantity, unit_type: prd.unit_type, hpp: SellingPrice.where("product_id=#{prd.product_id} AND end_date>NOW()").last.hpp, fraction: prd.fraction
        }
        PoPr.create purchase_order_id: po.id, purchase_request_id: @purchase_request.id
      end
    }
    flash[:notice] = "Purchase Order created."
    redirect_to purchase_requests_path
  end

  def create
    @purchase_request = PurchaseRequest.new(
      purchase_request_params.merge(
        status: params[:commit] == 'Save' ? 'Draft' : PurchaseRequest::WAITING_APPROVAL,
        requester_id: current_user.id, date: Time.now,
        grand_total: (params[:cost].values.map{|v|v.to_f}.sum rescue 0),
        number: "PR/#{Branch.find(params[:purchase_request][:branch_id]).office_name}/#{Time.now.strftime('%Y-%m-%d')}/#{(('%07d' % (((PurchaseRequest.where("extract(YEAR FROM date)=#{Time.now.year}").order("id DESC").limit(1)[0].number.last.to_i rescue 0) +1))))}"
      )
    )
    if @purchase_request.save
      old_details = @purchase_request.purchase_request_details.map(&:id)
      if params[:create_po] == '1'
        @purchase_request.update_attributes(status: 'APPROVED')
        PurchaseRequestDetail.where("purchase_request_id=#{@purchase_request.id}").group_by{|prd|(ProductSupplier.where(product_id: prd.product_id).limit(1).order("id DESC").first.supplier_id rescue 1)}.each{|prd1|
          po = PurchaseOrder.new number: "PO#{Time.now.year}#{sprintf('%06d', (PurchaseOrder.last.id rescue 0)+1)}", date: Time.now, supplier_id: prd1[0], status: PurchaseOrder::WAITING_APPROVAL,
            grand_total: (prd1[1].map{|prd2|SellingPrice.where("product_id=#{prd2.product_id} AND end_date>NOW()").last.hpp}.compact.sum * prd1[1].map(&:quantity).sum * prd[1].map(&:fraction).sum), purchase_request_id: @purchase_request.id,
            head_office_id: @purchase_request.branch_id, total_qty: prd1[1].map(&:quantity).sum, top: 7, expected_delivery_date: Time.now+7.days, due_date: Time.now+7.days
          if po.save
            prd1[1].each{|prd|
              PurchaseOrderDetail.create purchase_order_id: po.id, product_id: prd.product_id, total_price: SellingPrice.where("product_id=#{prd.product_id} AND end_date>NOW()").last.hpp.to_f*prd.quantity.to_f,
                quantity: prd.quantity, unit_type: prd.unit_type, hpp: SellingPrice.where("product_id=#{prd.product_id} AND end_date>NOW()").last.hpp, fraction: prd.fraction
            }
            PoPr.create purchase_order_id: po.id, purchase_request_id: @purchase_request.id
          end
        }

        flash[:notice] = 'Purchase Request was successfully created with Generated PO.'
      else
        flash[:notice] = 'Purchase Request was successfully created'
      end
      redirect_to purchase_requests_path
    else
      flash[:error] = @purchase_request.errors.full_messages
      render "new"
    end
  end

  def update
    @purchase_request = PurchaseRequest.find_by_id(params[:id])
    old_details = @purchase_request.purchase_request_details.map(&:id)
    if @purchase_request.update_attributes(purchase_request_params)
      PurchaseRequestDetail.where(id: old_details).delete_all
      if params[:create_po] == '1'
        @purchase_request.update_attributes(status: 'APPROVED')
        PurchaseRequestDetail.where("purchase_request_id=#{@purchase_request.id}").group_by{|prd|(ProductSupplier.where(product_id: prd.product_id).limit(1).order("id DESC").first.supplier_id rescue 1)}.each{|prd1|
          po = PurchaseOrder.new number: "PO#{Time.now.year}#{sprintf('%06d', (PurchaseOrder.last.id rescue 0)+1)}", date: Time.now, supplier_id: prd1[0], status: PurchaseOrder::WAITING_APPROVAL,
            grand_total: (prd1[1].map{|prd2|SellingPrice.where("product_id=#{prd2.product_id} AND end_date>NOW()").last.hpp}.compact.sum * prd1[1].map(&:quantity).sum * prd1[1].map(&:fraction).sum), purchase_request_id: @purchase_request.id,
            head_office_id: @purchase_request.branch_id, total_qty: prd1[1].map(&:quantity).sum, top: 7, expected_delivery_date: Time.now+7.days, due_date: Time.now+7.days
          if po.save
            prd1[1].each{|prd|
              PurchaseOrderDetail.create purchase_order_id: po.id, product_id: prd.product_id, total_price: SellingPrice.where("product_id=#{prd.product_id} AND end_date>NOW()").last.hpp.to_f*prd.quantity.to_f*prd.fraction.to_f,
                quantity: prd.quantity, unit_type: prd.unit_type, hpp: SellingPrice.where("product_id=#{prd.product_id} AND end_date>NOW()").last.hpp, fraction: prd.fraction
            }
            PoPr.create purchase_order_id: po.id, purchase_request_id: @purchase_request.id
          end
        }

      end
      flash[:notice] = t(:successfully_updated)
      redirect_to purchase_requests_path
    else
      flash[:error] = @purchase_request.errors.full_messages
      render "edit"
    end
  end

  def autocomplete_purchase_request
    hash = []
    conditions = ["status IN (#{params[:status]})"]
    conditions << "number like '%#{params[:term]}%'" if params[:term].present?
    conditions << "supplier_id=#{params[:supplier_id]}" if params[:supplier_id].present?
    conditions << "number NOT IN (#{params[:present_pr]})" if params[:present_pr].present?
    @pr = PurchaseRequest.where(conditions.join(' AND ')).order('number')
    @pr.collect do |p|
      hash << {
        "id" => p.id, "label" => p.number, "value" => p.number, pr_date: p.created_at.strftime('%Y-%m-%d'), pr_note: p.note, branch_name: (p.branch.office_name rescue nil),
        quantity: p.purchase_request_details.map(&:approved_qty).compact.sum
      }
    end
    respond_to do |format|
      format.js
      format.json {render json: hash}
    end
  end

  def destroy
    @request = PurchaseRequest.find_by_id(params[:id])
    respond_to do |format|
      if @request.is_waiting_approval? && @request.destroy
        flash.now[:notice] = "PR was successfully deleted"
      else
        flash.now[:error] = t(:already_in_used)
      end
      format.js
    end
  end

  def edit
    @purchase_request = PurchaseRequest.find_by_id(params[:id])
    @supplier = @purchase_request.supplier rescue ''
    @list_product = ProductDetail.where("warehouse_id=#{@purchase_request.branch_id}")
    load_master
  end

  def load_master
    @suppliers = Supplier.select("name, id, address, code").limit(7).order("name")
    @products = Product.select("barcode, id").limit(7).order("barcode").map{|product|[product.barcode, product.id]}
  end

  def get_product
    @product = Product.find_by_article(params[:article]) || Product.find_by_barcode(params[:article])
    # useless?
    @office = Office.find_by_id(params[:origin_warehouse_id])
    @supplier = @product.brand.supplier rescue nil

    #find_by_product_id_and_warehouse_id
    @sellingprice = SellingPrice.where("product_id=#{@product.id} AND end_date > NOW()").last

    unless @office.nil?
      @productdetail = ProductDetail.where("product_id=#{@product.id} and warehouse_id=#{@office.id}").first
      #find_by_product_id_and_warehouse_id
      @sellingprice = SellingPrice.where("product_id=#{@product.id} and office_id=#{@office.id} AND end_date > NOW()").last
      @list_product = ProductDetail.where("warehouse_id=#{params[:origin_warehouse_id] || current_user.branch_id || Branch.first.id} AND products.id=#{@product.id}")
        .joins(:product)
        .sort_by{|product_detail|
          size_number = (product_detail.product_size.size_detail.size_number rescue 1000000) || 1000000
          size_number.to_i == 0 ? size_number : size_number.to_i
        }
    end
    respond_to do |format|
      format.js
    end
  end

  def get_supplier
    @supplier = Supplier.find_by_name(params[:name])
    respond_to do |format|
      format.js
    end
  end

  def add_product
    @product = Product.find(params[:id])
    @supplier = @product.brand.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue params[:branch_id])} AND products.id=#{@product.id}").joins(product_size: [:product])
    respond_to do |format|
      format.js
    end
  end

  def search_in_modal
    search_product_manual
  end

  def search_product_manual
    conditions = []
    #conditions << "status_retur = true" if params[:cntrl].present? and params[:cntrl] == 'returns_to_suppliers'
    conditions << "LOWER(suppliers.code) LIKE LOWER('%#{params[:supplier_code]}%')" if params[:supplier_code].present?
    conditions << "LOWER(article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    if params[:barcode].present?
      if params[:barcode].include?(" ")
        conditions << "LOWER(barcode) IN ('%#{params[:barcode].gsub(' ', "','")}%')"
      else
        conditions << "LOWER(barcode) LIKE LOWER('%#{params[:barcode]}%')"
      end
    end
    conditions << "LOWER(description) LIKE LOWER('%#{params[:description].gsub("'", "''")}%')" if params[:description].present?
    conditions << "LOWER(brands.name) LIKE LOWER('%#{params[:brand_name]}%')" if params[:brand_name].present?
    conditions << "LOWER(barcode) NOT IN (#{params[:present_product]})" if params[:present_product].present?
    @products = Product.where(conditions.join(' AND '))
      .joins("LEFT JOIN product_suppliers ON products.id=product_suppliers.product_id LEFT JOIN suppliers ON product_suppliers.supplier_id=suppliers.id").paginate(page: params[:page], per_page: 10) || []
  end

  private

    def purchase_request_params
      params.require(:purchase_request).permit(:note, :date, :number,
        :supplier_id, :branch_id,
        purchase_request_details_attributes: [
          :quantity, :product_id, :unit_type, :fraction, :_destroy
        ]
      )
    end

    def get_paginated_purchase_requests
      conditions = []
      conditions << "branch_id=#{current_user.branch_id}" if current_user.branch_id.present?
      params[:search].each{|param|
        conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
      } if params[:search].present?
      @purchase_requests = PurchaseRequest.select("purchase_requests.id, number, date, status, offices.office_name, note, grand_total").where(conditions.join(' AND ')).joins(:branch)
        .order(default_order('purchase_requests')).paginate(page: params[:page], per_page: 10) || []
    end

    def can_view_pr
      not_authorized unless current_user.can_view_pr?
    end

    def can_manage_pr
      not_authorized unless current_user.can_manage_pr?
    end
end
