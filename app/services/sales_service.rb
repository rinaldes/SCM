class SalesService
  def SalesService.saveSales(params)
    sales = Sale.new(params.permit(
        # :id,
                                   :session_id,
                                   :mobile_order,
                                   # :code,
                                   :payment_type,
                                   :member_id,
                                   :client_id,
                                   :store_id,
                                   # :transaction_date,
                                   :total_ppn,
                                   :total_price,
                                   :total_discount,
                                   :user_id,
                                   # :store_id,
                                   :bill_number,
                                   :voucher_code,
                                   :total_paid,
                                   :total_outstanding,
                                   :total_quantity,
                                   :total_capital,
                                   :member_id,
                                   :ship_address,
                                   :ship_address_name,
                                   :ship_address_phone,
                                   :ship_address_city,
                                   :ship_address_kecamatan,
                                   :ship_address_kelurahan,
                                   :ship_address_province).merge(status: "New"))

    sales.code = params[:id]
    sales.transaction_date = params[:transaction_date].to_datetime
    sales.store_id = User.find(params[:user_id]).branch_id

    ActiveRecord::Base.transaction do
      sales.save
      params['sales_details'].each { |sd|
        sku = Sku.find_by_id(sd['sku_id'])
        user = User.find_by_id(params[:user_id])
        sales.sales_details.create sd.delete_if {
            |d| %w(specialDisc itemNo initPrice discAmt discPct discPrice).include?(d)
        }.merge(
            store_id: user.branch_id,
            product_id: sku.product_id,
            unit_id: sku.unit_id
        ).permit(
            :id, :store_id, :capital_price, :discount_amt, :discount,
            :price, :price_after_discount, :is_special_discount, :quantity,
            :subtotal_price, :ppn, :total_price, :product_id
        )
      }

      VoucherDetail.find_by_voucher_code(params[:used_voucher][:voucher_code]).update_attributes(order_no: params[:used_voucher][:order_no], available: false, member_id: member.id) rescue ''
    end

  end
end