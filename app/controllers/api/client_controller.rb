require 'yaml'
class Api::ClientController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_current_user, :check_permitted_page
  skip_before_filter :protect_from_forgery
  skip_before_filter :authenticate_user!

  def login
    render json: {status: 'success'}
  end

  def m_classes
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @mclasses = MClass.where(conditions.join(' AND ')).offset(params[:offset]).limit(params[:limit]).order("m_classes.updated_at ASC")
    render json: @mclasses
  end

  def warehouse_list
    conditions = ["type='Branch'"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @branches = Office.joins("LEFT JOIN users ON offices.contact_person=users.id").select("offices.*, users.username").where(conditions.join(' AND '))
      .order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
    render json: @branches.map{|branch|branch.attributes.merge(type: branch.class.to_s)}
  end

  def entities_list
    render json: Entity.all
  end

  def users
    conditions = ["branch_id=#{params[:store_id]}"]
    conditions << "users.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    render json: User.where(conditions.join(' AND ')).joins(:role).select("users.*, roles.name AS role_name")
  end

  def roles
    render json: Role.where("id IN (SELECT role_id FROM users WHERE branch_id=#{params[:store_id]})").map{|role|role.attributes.merge(features: role.feature_names)}
  end

  def edc_bank_account_list
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    render json: EdcMachine.where(conditions.join(' AND '))
  end

  def skus
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    render json: Sku.where(conditions.join(' AND '))
  end

  def brands_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @brands = Brand.where(conditions.join(' AND ')).joins(:supplier).offset(params[:offset]).limit(params[:limit])
      .select("brands.id, brands.code, brands.name, suppliers.code AS supplier_code, suppliers.name AS supplier_name, discount_percent1, discount_percent2, discount_percent3, discount_percent4, discount_rp")
      .order("brands.updated_at ASC") || []
    render json: @brands
  end

  def colours_list
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    render json: Colour.where(conditions.join(' AND ')).offset(params[:offset]).limit(params[:limit]).order("colours.updated_at ASC")
  end

  def m_class_list
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @mclasses = MClass.where(conditions.join(' AND ')).offset(params[:offset]).limit(params[:limit]).order("m_classes.updated_at ASC")
    render json: @mclasses
  end

  def unit_list
    render json: Unit.all
  end

  def product_list
    conditions = ["selling_price_details.price > 0 AND end_date>NOW() AND office_id=#{params[:store_id]}"]
    conditions << "products.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @products = SellingPriceDetail.order("products.updated_at ASC").limit(params[:limit]).offset(params[:offset])
      .where(conditions.join(' AND '))
      .select("skus.id, skus.unit_id, units.name AS unit_name, skus.product_id, skus.barcode, skus.convertion_unit, products.article, products.short_name, products.m_class_id, products.department_id,
        products.flag_pajak, products.is_composite, selling_price_details.price, selling_prices.hpp_average, article, description, office_id")
      .joins(sku: :unit, selling_price: :product)
    render json: @products.map{|product|
      product.attributes.merge(
        available_qty: (ProductDetail.find_by_product_id_and_warehouse_id(product.product_id, params[:store_id]).available_qty rescue 0), is_assembled: ProductDetail.find_by_product_id(product.product_id).is_assembled,
        image: (Product.find_by_id(product.product_id).image.url rescue nil).present? ? ("http://#{request.env['HTTP_HOST']}#{Product.find_by_id(product.product_id).image.url}" rescue nil) : nil
      )
    }
  end
=begin
skus.id AS id
skus.unit_id
skus.product_id
skus.barcode
skus.convertion_unit

products.article
products.short_name
products.m_class_id
products.department_id
products.flag_pajak
products.is_composite

product_details.available_qty
product_details.is_assembled

selling_price_details.price
selling_prices.hpp_average

margin_percent
margin_amount
dpp
ppn_in
ppn_out

units.name

=end

  def product_detail_list
    conditions = []
    conditions << "product_id IN (#{params[:product_id]})" if params[:product_id].present?
    conditions << "product_details.updated_at > '#{params[:last_update]}'" if params[:last_update].present?
    conditions << "warehouse_id='#{params[:warehouse_id]}'" if params[:warehouse_id].present?
    render json: ProductDetail.where(conditions.join(' AND ')).joins(product_size: :product).offset(params[:offset]).limit(params[:limit]).order("product_details.updated_at ASC")
      .select("product_details.*, product_size_id AS product_size")
  end

  def promotions_list
    conditions = []
    conditions << "promotions.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    conditions << "office_id='#{params[:branch_id]}'" if params[:branch_id].present?
    @promotions = Promotion.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).joins(:office).select("promotions.*, offices.office_name AS branch_name")
    render json: @promotions.map{|promo|promo.attributes.merge(promo_item: promo.promo_item_lists, prize: promo.prize_lists)}
  end

  def promo_items_list
    conditions = []
    conditions << "promo_item_lists.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    @promotions = PromoItemList.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
    render json: @promotions
  end

  def prizes_list
    conditions = []
    conditions << "prize_lists.updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    @promotions = PrizeList.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
    render json: @promotions
  end

  def voucher
    voucher = Voucher.find_by_code(params[:code])
    render json: voucher
  end

  def voucher_details_list
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @vouchers = VoucherDetail.where(conditions.join(' AND ')).offset(params[:offset]).limit(params[:limit]).order("voucher_details.updated_at ASC")
    render json: @vouchers
  end

  def member_levels
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    @promotions = MemberLevel.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' '))
    render json: @promotions
  end

  def members
    if params[:member_id].present?
      member = Member.find_by_id(params[:member_id])
      render json: member.attributes.merge(member_level: member.member_level).to_json
    else
      render json: Member.all_to_api_request(params)
    end
  end

  def create_sod_eod
    param = params[:sodeod]
    @sodeod = SodEod.new(
        sod_eod_date: (param['sod_eod_date'] rescue nil),
        voucher: param['voucher'],
        user_id: param['user_id'],
        debit: param['debit'],
        machine_id: param['client_id'],
        difference: param['difference'],
        start_amount: param['start_amount'],
        discount: param['discount'],
        session_type: param['session_type'],
        note: param['note'],
        start_time: param[:start_time].to_datetime,
        cash: param['cash'],
        office_id: param['office_id'],
        uuid: SecureRandom.uuid
    )
    @sodeod.save!
  end

  def sod_eod
    @sodeod = SodEod.where(machine_id: params['machine_id']).last
    sessions = Session.where(sodeod_id: @sodeod.id).all unless @sodeod.nil?

    unless @sodeod == nil
      render :json => @sodeod.as_json.merge(id: @sodeod.uuid, sod_eod_date: (@sodeod.sod_eod_date.iso8601 rescue nil), start_time: (@sodeod.start_time.iso8601 rescue nil), end_time: (@sodeod.end_time.iso8601 rescue nil), sessions: sessions.as_json)
    else
      head :no_content
    end
  end

  def create_session
    begin
      param = params[:sodeod]
      param[:uuid] = param[:id]
      ActiveRecord::Base.transaction do
        sod_eod = SodEodService.saveSodEod(param)
        params[:uuid] = params[:id]
        params[:sod_eod_id] = sod_eod.id
        SodEodService.saveSession(params)
      end

      head 200, content_type: "application/json"
    end
  end

  def create_member
    if params[:card_number].blank?
      card_number = "#{Date.today.strftime("%y")}#{Branch.find(params[:store_id]).id}#{((sprintf '%03d', ((Member.last.id rescue 0)+1)))}"
    else
      card_number = params[:card_number]
    end
    @member = Member.new(
      card_number: card_number,
      name: params[:name],
      address: params[:address],
      city: params[:city],
      zip: params[:zip],
      hp: params[:hp],
      gender: params[:gender],
      birthday: params[:birthday],
      email: params[:email],
      credit_limit: params[:credit_limit]
    )
    @member.save!
    render json: @member
  end

  def transaction
    if params[:voucher_code].present? && ArVoucherDetail.find_by_code(params[:voucher_code]).blank?
      render json: {status: 'failed', message: 'Voucher code invalid'}, status: 200
    else
      param = params
      member_param = param['member']
      if member_param.present?
        member = Member.find(param[:member_id])
        if member.blank?
          member = Member.new card_number: rand.to_s.reverse[1..7], name: member_param[:name], address: member_param[:address], birthday: member_param[:birthday], phone_number: member_param[:phone_number],
            gender: member_param[:gender], hp: member_param[:hp], code: Member.last.code.to_i+1, city: member_param[:city], zip: member_param[:zip], datemember: member_param[:join_date], is_valid: true,
            discount: 0, active: true, email: member_param[:email], balance: 0, member_level_id: nil, point: 0
          member.save
        end
      end

      # sale = Sale.new(
      #                 id: (Sale.last.id rescue 0)+1,
      #                 session_id: param['session_id'],
      #                 status: param[:status],
      #                 mobile_order: true,
      #                 code: param[:id],
      #                 payment_type: param[:payment_type],
      #                 member_id: param[:member_id],
      #                 client_id: param['client_id'],
      #                 store_id: param['store_id'],
      #                 transaction_date: param[:transaction_date].to_s.gsub(' ', '-'),
      #                 total_ppn: param[:total_ppn],
      #                 total_price: param['total_price'],
      #                 total_discount: param['total_discount'],
      #                 user_id: param['user_id'],
      #                 store_id: User.find(param[:user_id]).branch_id,
      #                 bill_number: param['bill_number'],
      #                 voucher_code: param['voucher_code'],
      #                 total_paid: param[:total_paid],
      #                 total_outstanding: param[:total_outstanding],
      #                 total_quantity: param[:total_quantity],
      #                 total_capital: param[:totalCapitalPrice],
      #                 member_id: (param[:member_id]),
      #                 ship_address_name: param[:ship_address_name],
      #                 ship_address_phone: param[:ship_address_phone],
      #                 ship_address_city: param[:ship_address_city],
      #                 ship_address_kecamatan: param[:ship_address_kecamatan],
      #                 ship_address_kelurahan: param[:ship_address_kelurahan],
      #                 ship_address_province: param[:ship_address_province],
      #                 ship_address: param[:ship_address]
      #   # member_id: (member.id rescue nil)
      # )
      # sale.save
      # VoucherDetail.find_by_voucher_code(param['used_voucher']['voucher_code']).update_attributes(order_no: param['used_voucher']['order_no'], available: false, member_id: member.id) rescue ''
      # param['sales_details'].each{|sd|
      #   sku = Sku.find_by_id(sd['sku_id'])
      #   user = User.find_by_id(params[:user_id])
      #   sale.sales_details.create sd.delete_if{
      #       |d|%w(specialDisc itemNo initPrice discAmt discPct discPrice).include?(d)
      #   }.merge(
      #       store_id: user.branch_id,
      #       product_id: sku.product_id,
      #       unit_id: sku.unit_id,
      #       id: (SalesDetail.last.id rescue 0)+1
      #   ).permit(
      #       :id, :store_id, :capital_price, :discount_amt, :discount,
      #       :price, :price_after_discount, :is_special_discount, :quantity,
      #       :subtotal_price, :ppn, :total_price, :product_id
      #   )
      # }

      sale = SalesService.saveSales(param)

      if member_param.present?
        member_param['balances'].each{|sd|
          member.member_balance_mutations.create! sd.delete_if{|d|%w(memberId).include?(d)}.merge(id: (MemberBalanceMutation.last.id.to_i rescue 0)+1)
        } if member_param['balances'].present?
        member_param['points'].each{|sd|
          member.member_point_mutations.create! sd.delete_if{|d|%w(memberId).include?(d)}.merge(id: (MemberPointMutation.last.id.to_i rescue 0)+1)
        } if member_param['points'].present?
      end
      render json: sale
    end
  end
end