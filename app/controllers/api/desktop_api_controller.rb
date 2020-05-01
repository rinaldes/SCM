class Api::DesktopApiController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_current_user, :check_permitted_page
  skip_before_filter :protect_from_forgery
  skip_before_filter :authenticate_user!
#  before_filter :check_token
#  before_filter :check_params, :only => [:create_sales, :create_refund_order, :create_exchange_order, :create_ptb]

  def purchase_request_details
    supplier = Supplier.find_by_code params[:supplier_code]
    render xml: PurchaseRequestDetail.where("product_id IN (SELECT product_id FROM product_suppliers WHERE supplier_id=#{supplier.id}) AND status='APPROVED'").joins(:purchase_request).to_xml
  end

  def purchase_orders
    supplier = Supplier.find_by_code params[:supplier_code]
    render xml: PurchaseOrder.where("supplier_id=#{supplier.id} AND status='APPROVED'").map{|po|po.attributes.merge(detail: po.purchase_order_details)}.to_xml
  end

  def create_member
    Member.apa(params[:create_member])
    render json: {status: 'success'}, status: 201
  end

  def create_session
    Session.api(params[:create_session])
    render json: {status: 'success'}, status: 201
  end

  def account_receivable
    AccountReceivable.api(params[:account_receivable])
    render json: {status: 'success'}, status: 201
  end

  def sod_eod
    SodEod.api(params[:sod_eod])
    render json: {status: 'success'}, status: 201
  end

  def mutation_history
    ProductMutationHistory.api(params[:mutation_history])
    render json: {status: 'success'}, status: 200
  end

  def pos_machines
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    render json: PosMachine.where(conditions.join(' AND '))
  end

  def member_list
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    render json: Member.where(conditions.join(' AND '))
  end

  def entities
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = Entity.where(conditions.join(' AND '))
    render json: @promotions
  end

  def vouchers
    conditions = ["valid_until >= now()"]
    conditions << "vouchers.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "vouchers.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = Voucher.joins('LEFT JOIN offices ON vouchers.office_id = offices.id')
      .select("vouchers.office_id AS office_id, vouchers.id AS id, name, to_char(valid_from, 'DD-MM-YYYY') AS valid_from, to_char(valid_until, 'DD-MM-YYYY') AS valid_until, discount_amount, min_amount, discount,
      max_voucher, office_name, max_voucher_amt").where(conditions.join(' AND '))
    render json: @promotions
  end

  def sku
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = Sku.where(conditions.join(' AND '))
    render json: @promotions
  end

  def voucher_detail_list
    conditions = ["valid_until >= now()"]
    conditions << "voucher_details.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "voucher_details.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = VoucherDetail.where(conditions.join(' AND ')).joins(:voucher)
    render json: @promotions
  end

  def promo_prize_items
    conditions = ["promotions.to >= now()"]
    conditions << "promotions.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "promotions.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = PrizeList.where(conditions.join(' AND ')).joins(:promotion)
    render json: @promotions
  end

  def promo_items
    conditions = ["promotions.to >= now()"]
    conditions << "promotions.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "promotions.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = PromoItemList.joins(:promotion).where(conditions.join(' AND '))
    render json: @promotions
  end

  def product_structures
    conditions = []
    conditions << "product_structures.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "product_structures.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = Product.joins(:m_class).joins("RIGHT JOIN product_structures ON product_structures.parent_id=products.id")
    .select("products.*, m_classes.name as m_class_name, product_structures.*")
    .where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
    render json: @promotions
  end

  def product_prices
    conditions = ["end_date > now()"]
    conditions << "selling_prices.product_id is not null"
    conditions << "selling_prices.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "selling_prices.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = SellingPrice.where(conditions.join(' AND ')).joins(:product).limit(100)
    render json: @promotions
  end

  def product_price_details
    conditions = ["end_date > now()"]
    conditions << "selling_prices.product_id is not null"
    conditions << "selling_price_details.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "selling_price_details.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = SellingPriceDetail.where(conditions.join(' AND ')).joins(selling_price: :product).limit(300)
    render json: @promotions
  end

  def bank_list
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    @promotions = EdcMachine.where(conditions.join(' AND ')).order(default_order('edc_machines'))
    render json: @promotions
  end


  def discount_histories
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    @promotions = DiscountHistory.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')) rescue []
    render json: @promotions.map{|promo|promo.attributes.merge(complete_image_url: "http://#{request.env['HTTP_HOST']}#{product.image.url}",
      discount_details: promo.discount_history_details)}
  end

  def generate_sales_from_scheduler
    #raise params.inspect
    if params[:sale_transactions].present?# && params[:sales_details].present?
      puts 'SALES FOUND!'
      sale = Sale.where("code = #{params[:sale_transactions][0]}").first
      sale.sales_details.create(params[:sales_details])
      render json: {message: 'SUCCESS'}
    elsif
      puts 'SALES OR SALES DETAIL NOT DETECTEDNOT DETECTED!'
      render json: {message: 'SALES OR SALES DETAIL NOT DETECTEDNOT DETECTED!'}
    end
    render json: {status: 'success'}, status: 200
  end

  def generate_sales_detail
    sales_detail = SalesDetail.find(params[:id])
    sales_detail.generate_history
    render json: {success: true }
  end

  def product_promo_discounts
    hash = []
    product = Product.find_by_id(params[:id])
    branch = Branch.find_by_id(params[:branch_id])
    return render json: [] if product.blank? || branch.blank?
    promotions = PromoItemList.where(
      "department_id=#{product.brand.department_id} OR m_class_id=#{product.m_class_id} OR brand_id=#{product.brand_id} OR article_id='#{product.article}'"
    )
    render json: Promotion.where(
      "now() BETWEEN \"from\" AND \"to\" AND office_id IN (#{branch.id}, #{branch.head_office_id}) AND id IN (#{promotions.map(&:promotion_id).push(0).join(', ')})"
    ).map{|promo|
      promo.attributes.merge(
        promo_item_lists: promo.promo_item_lists.map{|pi|
          pi.attributes.merge(department_name: (pi.department.name rescue nil), brand_name: (pi.brand.name rescue nil), m_class_name: (pi.m_class.name rescue nil))
        },
        prize_lists: promo.prize_lists.map{|pi|
          pi.attributes.merge(department_name: (pi.department.name rescue nil), brand_name: (pi.brand.name rescue nil), m_class_name: (pi.m_class.name rescue nil))
        }
      )
    }
  end

  def member_levels
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    @promotions = MemberLevel.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
    render json: @promotions
  end

  def promotions
    conditions = ["promotions.to >= now()"]
    conditions << "promotions.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "promotions.created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    conditions << "promotions.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    conditions << "office_id='#{params[:branch_id]}'" if params[:branch_id].present?
    @promotions = Promotion.joins(:office).select("promotions.*, offices.office_name AS branch_name").where(conditions.join(' AND '))
      render json: @promotions.map{|promo|promo.attributes.merge(promo_item: promo.promo_item_lists, prize: promo.prize_lists)}
  end

  def index
    members = Member.all_to_api_request(params)

    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    conditions << "brands.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    @brands = Brand.where(conditions.join(' AND ')).joins(:supplier)
      .select("brands.id, brands.code, brands.name, suppliers.code AS supplier_code, suppliers.name AS supplier_name, discount_percent1, discount_percent2, discount_percent3,
        discount_percent4, discount_rp").order(params[:sort].to_s.gsub('-', ' '))

    get_paginated_colours
    get_paginated_sizes
    get_paginated_size_details

    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @departments = MClass.where("parent_id IS NULL").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))

    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @mclasses = MClass.where("parent_id IS NOT NULL").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))

    conditions = []
    conditions << "offices.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @branches = Office.joins("LEFT JOIN users ON offices.contact_person=users.id").select("offices.*, users.username").where(conditions.join(' AND '))
      .order(params[:sort].to_s.gsub('-', ' '))

    conditions = []
    conditions << "products.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'" if param[1].present?
    } if params[:search].present?
    @products = Product.joins(:m_class, :colour, :size, brand: :supplier).where(conditions.join(' AND '))
      .select("brands.name AS brand_name, suppliers.name AS supplier_name, colours.name AS colour_name, m_classes.name AS m_class_name, products.*, sizes.description AS size_name,
      to_char(selling_price, '99999999D99') AS selling_price, to_char(purchase_price, '99999999D99') AS purchase_price").order(params[:sort].to_s.gsub('-', ' '))

    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @edc_machines = EdcMachine.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))

    render json: {
      members: members, brands: @brands, colours: @colours, departments: @departments, m_classes: @mclasses,
      warehouses: @branches.map{|branch|branch.attributes.merge(type: branch.class.to_s)}, sizes: @sizes, size_details: @size_details, banks: @edc_machines
    }
  end

  def users
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    #conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    render json: User.where(conditions.join(' AND '))
  end

  def price_per_branch
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    conditions << "branch_id='#{params[:branch_id]}'" if params[:branch_id].present?
    render json: BranchPrice.where(conditions.join(' AND ')).to_json
  end

  def members
    render json: Member.all_to_api_request(params)
  end

  def size_list
    get_paginated_sizes
    render json: @sizes
  end

  def size_details_list
    get_paginated_size_details
    render json: @size_details
  end

  def branches_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @branches = Office.joins("LEFT JOIN users ON offices.contact_person=users.id").select("offices.*, users.username").where(conditions.join(' AND '))
      .order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
    render json: @branches
  end

  def m_class_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @mclasses = MClass.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
    render json: @mclasses
  end

  def department_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @mclasses = MClass.where("parent_id IS NULL").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
    render json: @mclasses
  end

  def product_detail_list
    conditions = []
    conditions << "product_id IN (#{params[:product_id]})" if params[:product_id].present?
    conditions << "product_details.updated_at > '#{params[:last_update]}'" if params[:last_update].present?
    conditions << "warehouse_id='#{params[:branch_id]}'" if params[:branch_id].present?
    render json: ProductDetail.where(conditions.join(' AND ')).joins(product_size: :product).map{|pd|pd.attributes.merge(product_id: pd.product_size.product_id)}
  end

  def colours_list
    get_paginated_colours
    render json: @colours
  end

  def warehouse_list
    conditions = []
    conditions << "offices.updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @branches = Office.joins("LEFT JOIN users ON offices.contact_person=users.id").select("offices.*, users.username").where(conditions.join(' AND '))
      .order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
    render json: @branches.map{|branch|branch.attributes.merge(type: branch.class.to_s)}
  end

  def product_stock
    conditions = []
    conditions = ["products.id=#{params[:product_id]}"] if params[:product_id].present?
    @current_user = User.first
    @current_offices = current_user.offices
    if params[:search].present?
      @brand = Brand.find_by_name params[:search][:brand]
      params[:search].each{|param|
        if param[0] == "status3" or param[0] == "status4"
          params[:search][param[0]].each{|status|
            conditions << "#{param[0]} = '#{status[1]}'"
          }
        end
      }
      if @brand.present?
        @supplier = @brand.supplier
        @products = @brand.products.where(conditions.join(' OR ')).group_by{|product|product.m_class.department.id}
        @departments = MClass.where(id: @products.keys.join(','))
      end
      @offices = Office.where(id: params[:search][:branch].keys)
    else
      @offices = current_user.offices
    end
    render template: "products/stock"#, layout: false
  end

  def brands_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @brands = Brand.where(conditions.join(' AND ')).joins(:supplier)
      .select("brands.id, brands.code, brands.name, suppliers.code AS supplier_code, suppliers.name AS supplier_name, discount_percent1, discount_percent2, discount_percent3,
        discount_percent4, discount_rp, brands.created_at, brands.updated_at")
      .order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
    render json: @brands
  end

  def supplier_list
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @suppliers = Supplier.where(conditions.join(' AND ')).order(default_order)#.paginate(page: params[:page], per_page: PER_PAGE) || []
    render json: @suppliers
  end

  def product_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'" if param[1].present?
    } if params[:search].present?
    @products = Product.joins(:m_class, :colour, :size, brand: :supplier).where(conditions.join(' AND '))
      .select("brands.name AS brand_name, suppliers.name AS supplier_name, colours.name AS colour_name, m_classes.name AS m_class_name, products.*, sizes.description AS size_name,
      to_char(selling_price, '99999999D99') AS selling_price, to_char(purchase_price, '99999999D99') AS purchase_price").order(params[:sort].to_s.gsub('-', ' '))
    render json: @products.map{|product|product.attributes.merge(department_id: product.m_class.department.id, unit_name: product.unit.name,
      complete_image_url: "http://#{request.env['HTTP_HOST']}#{product.image.url}")}
  end

  def cashback
    render json: (Cashback.find_by_member_level_id(params[:member_level_id]).attributes rescue nil)
  end
=begin
  def transaction
    #if params[:voucher_code].present? && ArVoucherDetail.find_by_code(params[:voucher_code]).blank?
    #  render json: {status: 'failed', message: 'Voucher code invalid'}, status: 200
    #else
      sales = ActiveSupport::JSON.decode(params[:transaction])
      sales.each do |sales|
        sales_detail = sales["sale_details"]
        total_quantity = sales_detail.map{|sale_detail|sale_detail['quantity']}.sum
        sale = Sale.new(payment_type: sales['payment_type'], member_id: sales['member_id'], client_id: sales['client_id'], store_id: sales['store_id'],
          total_price: sales['total_price'], total_discount: sales['total_discount'], user_id: sales['user_id'], bill_number: sales['bill_number'],
          #voucher_code: sales['voucher_code'],
          code: sales['code'], transaction_date: sales['transaction_date'].to_date, subtotal_price: sales['subtotal_price'], payment_cash: sales['payment_cash'], exchange: sales['exchange'], status: sales['status'], voucher_amt: sales['voucher_amt'], transfer_amt: sales['transfer_amt'], debit_amt: sales['debit_amt'], credit_amt: sales['credit_amt'], total_extra_charge: sales['total_extra_charge'], total_special_discount: sales['total_special_discount'], session_id: sales['session_id'], total_ppn: sales['total_ppn'], receipt_count: sales['receipt_count'],
          total_paid: sales['total_paid'], total_outstanding: sales['total_outstanding'], total_quantity: total_quantity,
          total_capital: sales_detail.map{|sale_detail| sale_detail['capital_price']}.sum.to_f * total_quantity.to_f
        )
        sale.sales_details.new sales_detail.map{|sale_detail|
          sale_detail.merge(quantity: sale_detail['quantity'], capital_price: sale_detail['capital_price'], price: sale_detail['price'], discount: sale_detail['discount'],
           price_after_discount: sale_detail['price_after_discount'], discount_amt: sale_detail['discount_amt'], total_discount_amt: sale_detail['total_discount_amt'],
           subtotal_price: sale_detail['subtotal_price'], total_price: sale_detail['total_price'], product_id: sale_detail['product_id'],
           product_detail_id: sale_detail['product_detail_id'], ppn: sale_detail['ppn'], sku_id: sale_detail['sku_id'], is_special_discount: sale_detail['is_special_discount'] )
        }
        sale.save
      end
      render json: {status: 'success'}, status: 201
    #end
  end
=end

  def transaction
    if params[:voucher_code].present? && ArVoucherDetail.find_by_code(params[:voucher_code]).blank?
      render json: {status: 'failed', message: 'Voucher code invalid'}, status: 200
    else
      sales = ActiveSupport::JSON.decode(params[:transaction])
      sales.each do |param|
        sales_detail = param['sale_details']
        total_quantity = sales_detail.map{|sale_detail|sale_detail['quantity']}.sum
        member_param = param['member']
        if member_param.present?
          member = Member.find(member_param['id'])
          if member.blank?
            member = Member.new card_number: rand.to_s.reverse[1..7], name: member_param[:name], address: member_param[:address], birthday: member_param[:birthday], phone_number: member_param[:phone_number],
              gender: member_param[:gender], hp: member_param[:hp], code: Member.last.code.to_i+1, city: member_param[:city], zip: member_param[:zip], datemember: member_param[:join_date], is_valid: true,
              discount: 0, active: true, email: member_param[:email], balance: 0, member_level_id: nil, point: 0
            member.save
          end
        end
        sale = Sale.new(payment_type: param['payment_type'], member_id: param['member_id'], client_id: param['client_id'], store_id: param['store_id'],
            total_price: param['total_price'], total_discount: param['total_discount'], user_id: param['user_id'], bill_number: param['bill_number'],
            #voucher_code: param['voucher_code'],
            code: param['code'], transaction_date: param['transaction_date'].to_date, subtotal_price: param['subtotal_price'], payment_cash: param['payment_cash'], exchange: param['exchange'], status: param['status'], voucher_amt: param['voucher_amt'], transfer_amt: param['transfer_amt'], debit_amt: param['debit_amt'], credit_amt: param['credit_amt'], total_extra_charge: param['total_extra_charge'], total_special_discount: param['total_special_discount'], session_id: param['session_id'], total_ppn: param['total_ppn'], receipt_count: param['receipt_count'],
            total_paid: param['total_paid'], total_outstanding: param['total_outstanding'], total_quantity: total_quantity,
            total_capital: sales_detail.map{|sale_detail| sale_detail['capital_price']}.sum.to_f * total_quantity.to_f
        )
        sale.save
        VoucherDetail.find_by_voucher_code(param['used_voucher']['voucher_code']).update_attributes(order_no: param['used_voucher']['order_no'], available: false, member_id: member.id) rescue ''
        sale.sales_details.new sales_detail.map{|sale_detail|
          sale_detail.merge(quantity: sale_detail['quantity'], capital_price: sale_detail['capital_price'], price: sale_detail['price'], discount: sale_detail['discount'],
           price_after_discount: sale_detail['price_after_discount'], discount_amt: sale_detail['discount_amt'], total_discount_amt: sale_detail['total_discount_amt'],
           subtotal_price: sale_detail['subtotal_price'], total_price: sale_detail['total_price'], product_id: sale_detail['product_id'],
           product_detail_id: sale_detail['product_detail_id'], ppn: sale_detail['ppn'], sku_id: sale_detail['sku_id'], is_special_discount: sale_detail['is_special_discount'] )
        }

        if member_param.present?
          member_param['balances'].each{|sd|
            member.member_balance_mutations.create! sd.delete_if{|d|%w(memberId).include?(d)}
          } if member_param['balances'].present?
          member_param['points'].each{|sd|
            member.member_point_mutations.create! sd.delete_if{|d|%w(memberId).include?(d)}
          } if member_param['points'].present?
        end
      end
      render json: {status: 'success'}, status: 201
    end
  end

  def voucher
    voucher = Voucher.find_by_code(params[:code])
    render json: voucher
  end

  def use_promo
    prize = PrizeList.find_by_id(params[:id])
    render json: {success: (prize.update_attributes(available_qty: prize.available_qty-params[:used_qty].to_i))}
  end

  def voucher_details
    voucher = VoucherDetail.find_by_voucher_code(params[:code])
    v_tohash = voucher.attributes
    vd = VoucherDetail.where(voucher_code: params[:code])
    parent_voucher = voucher.voucher
    parent_voucher.attributes.each{|v|
      v_tohash = v_tohash.merge("parent_#{v[0]}" => v[1])
    }
    render json: v_tohash.merge(parent_offices: parent_voucher.office.class == HeadOffice ? parent_voucher.office.branches : [parent_voucher.office])
  end

  def roles
    conditions = []
    conditions << "updated_at >= '#{params[:check_point_update]}'" if params[:check_point_update].present?
    conditions << "created_at >= '#{params[:check_point_create]}'" if params[:check_point_create].present?
    render json: Role.where(conditions.join(' AND ')).map{|role|role.attributes.merge(features: role.feature_names)}
  end

  def unit_list
    render json: {data: Unit.all}
  end

  def bank_list2
    render json: {data: EdcMachine.all}
  end

  def session_list
    render json: {data: Session.all}
  end

  def sod_list
    render json: {data: SodEod.all}
  end

  def products_sync
    render json: { data: Product.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def product_detail_sync
    render json: { data: ProductDetail.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def product_detail_sync
    render json: { data: ProductDetail.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def product_supplier_sync
    render json: { data: ProductSupplier.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def size_sync
    render json: { data: Size.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def size_detail_sync
    render json: { data: SizeDetail.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def members_sync
    render json: { data: Member.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def member_level_sync
    render json: { data: MemberLevel.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def mclasses_sync
    render json: { data: MClass.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def colours_sync
    render json: { data: Colour.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def brands_sync
    render json: { data: Brand.where("(created_at > :check_point_create AND created_at <= :end_date) OR (updated_at > :check_point_update AND updated_at <= :end_date)",
      {check_point_create: DateTime.parse(params[:check_point_create].gsub(" ","/")), check_point_update: DateTime.parse(params[:check_point_update].gsub(" ","/")), end_date: DateTime.now})}
  end

  def branch_list
    data = []
    data_index = Office.all
    data_index.each do |branch|
      detail = branch.get_branch_detail
      data << detail
    end
    render json: { data: data }.to_json, status: 200
  end

  private
    def render_json(result)
      if result.include?("Can't find sales") || result.blank?
        render json: {status: 'failed', :message => result}
      else
        render json: {status: 'success'}
      end
    end

    def check_params
      if params[:data].blank?
        params[:data] = request.body.read
      end
    end

    def check_token
      #example params[:token]=
      access_token = ApiKey.find_by_access_token(params[:token])
      unless access_token
        render :json => {message: "Token invalid", status: 401}, status: 401
      end
    end

    def respond(data, total, params)
      respond_to do |format|
        format.json { render json: { data: data, total_count: total }.to_json, status: 200 }
        format.pdf { send_data pdf_generator(data, params[:header], params[:title]), type: 'application/pdf', status: 200 }
        format.xls { send_data excel_generator(data, params[:header], params[:title]), type: 'application/vnd.ms-excel', status: 200 }
      end
    end
end
