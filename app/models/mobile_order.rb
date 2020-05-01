class MobileOrder < ActiveRecord::Base
  has_many :mobile_order_details
  belongs_to :mobile_user, foreign_key: :member_id

  def self.api(params)
    #begin
      t_number = "T#{(('%07d' % ((MobileOrder.where.not(status: 'Cart').last.transaction_number.gsub('T', '').to_i rescue 0)+1)))}"
      ActiveSupport::JSON.decode(params).each do |d|
        transaction = MobileOrder.find_by_status_and_member_id("Cart", d["member_id"])
        if transaction.present?
        transaction.transaction_date = d["date"].to_time
        transaction.member_id = d["member_id"]
        transaction.transaction_number = t_number
        transaction.status = "New"

        if transaction.save
          sale = SalePos.new code: t_number, transaction_date: d["date"].to_time, member_id: d["member_id"], bill_number: t_number, store_id: Office.first.id,
            total_price: transaction.mobile_order_details.map{|a|a.quantity*a.price}.sum, total_quantity: transaction.mobile_order_details.map{|a|a.quantity}.sum,
            total_capital: transaction.mobile_order_details.map{|a|a.product.product_price(Time.now).hpp}.sum, subtotal_price: transaction.mobile_order_details.map{|a|a.quantity.to_f*a.price.to_f}.sum,
            status: 'HOLD', total_discount: 0, total_paid: 0, payment_cash: 0, exchange: 0, voucher_amt: 0, transfer_amt: 0, debit_amt: 0, credit_amt: 0, total_extra_charge: 0, total_special_discount: 0,
            total_ppn: 0, p2p_amt: 0
          sale.save
          transaction.mobile_order_details.each{|transaction_detail|
            if FavoriteProduct.find_by_mobile_user_id_and_product_id(transaction.member_id, transaction_detail.product_id).present?
              favo = FavoriteProduct.find_by_mobile_user_id_and_product_id(transaction.member_id, transaction_detail.product_id)
            else
              favo = FavoriteProduct.new
            end
            favo.update quantity: transaction_detail.quantity, product_id: transaction_detail.product_id, mobile_user_id: transaction.member_id

            sale_pos = SalePosDetail.new sale_id: sale.id, quantity: transaction_detail.quantity, price: transaction_detail.price, price_after_discount: transaction_detail.price,
              capital_price: transaction_detail.product.product_price(Time.now).hpp, subtotal_price: transaction_detail.price*transaction_detail.quantity,
              total_price: transaction_detail.price*transaction_detail.quantity, product_id: transaction_detail.product_id, sku_id: Sku.find_by_product_id(transaction_detail.product_id).id
            sale_pos.save
          }
	end
        end
      end
      status = "success"
      error = ""
      transaction_number = t_number
    #rescue => e
    #  error = e.message
    #  status = "failed"
    #end
      return error, status, transaction_number
  end

  def self.update_cart(user_id, params)
    begin
      ActiveSupport::JSON.decode(params).each do |d|
        transaction = MobileOrder.find_by_status_and_member_id("Cart", user_id)
        d["mobile_order_details"].each{|mod|
          transaction_detail = MobileOrderDetail.find_by_product_id_and_mobile_order_id(mod["product_id"], transaction.id)
          transaction_detail.update price: mod['price'], quantity: mod['quantity']
        }
        transaction.save
      end
      status = "success"
      error = ""
    rescue => e
      error = e.message
      status = "failed"
    end
      return error, status
  end

  def self.to_cart(user_id, params)
    begin
      ActiveSupport::JSON.decode(params).each do |d|
        if MobileOrder.find_by_status_and_member_id("Cart", user_id).present?
          transaction = MobileOrder.find_by_status_and_member_id("Cart", user_id)
        else
          transaction = self.new()
          transaction.member_id = user_id
          transaction.status = "Cart"
          transaction.save!
        end
        d["mobile_order_details"].each{|mod|
          if MobileOrderDetail.find_by_mobile_order_id_and_product_id(transaction.id, mod['product_id']).present?
            tr = MobileOrderDetail.find_by_mobile_order_id_and_product_id(transaction.id, mod['product_id'])
            tr.quantity += mod['quantity'].to_i
            tr.price += mod['price'].to_f
            tr.save
          else
            tr = transaction.mobile_order_details.new()
            tr.status = 'Pending'
            tr.product_id = mod['product_id']
            tr.price = mod['price']
            tr.quantity = mod['quantity']
            tr.save
          end
        }
      end
      status = "success"
      error = ""
    rescue => e
      error = e.message
      status = "failed"
    end
      return error, status
  end
end
