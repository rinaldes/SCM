=begin
2.0.0-p594 :001 > DailySalesInventory.last
  DailySalesInventory Load (18.3ms)  SELECT  "daily_sales_inventories".* FROM "daily_sales_inventories"   ORDER BY "daily_sales_inventories"."id" DESC LIMIT 1
 => #<DailySalesInventory id: 590431, product_id: 1561, office_id: 4, start_amount: 0.0, start_qty: 0.0, sales_amount: 0.0, sales_qty: 0.0, retur_sales_amount: 0.0, retur_sales_qty: -0.0, gr_amount: 0.0, gr_qty: 0.0, tat_in_amount: 0.0, tat_in_qty: 0.0, tat_out_amount: 0.0, tat_out_qty: 0.0, retur_amount: 0.0, retur_qty: 0.0, so_amount: 0.0, so_qty: 0.0, end_amount: 0.0, end_qty: 0.0, date: "2016-08-31", created_at: "2016-09-05 11:26:34", updated_at: "2016-09-05 11:26:34", cost: 0.0, avg_cost: 0.0, last_cost: 0.0> 
=end
class DailySalesInventory < ActiveRecord::Base
  belongs_to :office
  belongs_to :product

  def self.reset_all_per_item_juli prod_id
    (1..31).each{|dt|
      [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
        DailySalesInventory.generate_daily_per_item prod_id, "2016-07-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
      }
    }
=begin
    (1..31).each{|dt|
      [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
        DailySalesInventory.generate_daily_per_item prod_id, "2016-08-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
      }
    }
    (1..17).each{|dt|
      [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
        DailySalesInventory.generate_daily_per_item prod_id, "2016-09-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
      }
    }
=end
  end

  def self.reset_all_per_item_agustus prod_id
    (1..31).each{|dt|
      [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
        DailySalesInventory.generate_daily_per_item prod_id, "2016-08-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
      }
    }
=begin
    (1..17).each{|dt|
      [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
        DailySalesInventory.generate_daily_per_item prod_id, "2016-09-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
      }
    }
=end
  end

  def self.reset_all_per_item_september prod_id
    (1..21).each{|dt|
      [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
        DailySalesInventory.generate_daily_per_item prod_id, "2016-09-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
      }
    }
  end

  def self.start_qty current_date, current_item, current_office
    start_qty-sales_qty-retur_sls_qty+gr_qty+tat_in_qty-tat_out_qty-retur_qty+so_qty
  end

  def self.end_qty current_date, current_item, current_office
    
  end

  def self.reset_all
    [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
      DailySalesInventory.reset_all_per_office_in_current_month office_id
    }
  end

  def self.reset_all_per_office office_id
    Product.order("id ASC").map(&:id).compact.uniq.sort.each{|prod_id|
      (2..30).each{|dt|
        [office_id].sort.each{|office_id|
          DailySalesInventory.generate_daily_per_item prod_id, "2016-06-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
        }
      }
      (1..31).each{|dt|
        [office_id].sort.each{|office_id|
          DailySalesInventory.generate_daily_per_item prod_id, "2016-07-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
        }
      }
      (1..31).each{|dt|
        [office_id].sort.each{|office_id|
          DailySalesInventory.generate_daily_per_item prod_id, "2016-08-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
        }
      }
    }
  end

  def self.reset_all_per_item_juni prod_id
      (2..30).each{|dt|
        [21, 14, 7, 6, 3, 2, 1, 8, 5, 4].sort.each{|office_id|
          DailySalesInventory.generate_daily_per_item prod_id, "2016-06-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
        }
      }
  end

  def self.reset_all_per_office_in_current_month office_id
    Product.order("id ASC").map(&:id).compact.uniq.sort.each{|prod_id|
      (1..Time.now.day-1).each{|dt|
        [office_id].sort.each{|office_id|
          DailySalesInventory.generate_daily_per_item prod_id, "2016-09-#{dt}".to_date.strftime('%Y-%m-%d'), office_id
        }
      }
    }
  end

  def self.generate_daily_per_item prod_id, trans_date, office_id
    sales = SalesDetail.select("*, product_id, store_id AS office_id, to_char(sales_details.created_at, 'YYYY-MM-DD') AS created_at, 'Sales' AS mutation_type, quantity, capital_price AS hpp")
      .joins(:sale, :product).where("quantity>0 AND product_id=#{prod_id} AND to_char(sales_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND store_id=#{office_id}")

    rtr_sls = SalesDetail
      .select(
        "*, product_id, store_id AS office_id, to_char(sales_details.created_at, 'YYYY-MM-DD') AS created_at, 'Sales' AS mutation_type, quantity, capital_price AS hpp, quantity*capital_price AS total_price"
      ).joins(:sale, :product).where("quantity<0 AND product_id=#{prod_id} AND to_char(sales_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND store_id=#{office_id}")

    gr = ReceivingDetail
      .select("*, product_id, head_office_id AS office_id, to_char(receiving_details.created_at, 'YYYY-MM-DD') AS created_at, 'Receiving' AS mutation_type, quantity, hpp, quantity*hpp AS total_price")
      .joins(:receiving, :product).where("product_id=#{prod_id} AND to_char(receiving_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND head_office_id=#{office_id}")

    tat_out = ProductMutationDetail.select(
      "*, product_id, origin_warehouse_id AS office_id, to_char(product_mutation_details.created_at, 'YYYY-MM-DD') AS created_at, 'Good Transfer' AS mutation_type, product_mutations.status, quantity"
    ).joins(:product_mutation).joins(:product).where("product_id=#{prod_id} AND to_char(product_mutation_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND origin_warehouse_id=#{office_id}")

    tat_in = ProductMutationDetail.select(
      "product_id, destination_warehouse_id AS office_id, to_char(product_mutation_details.created_at, 'YYYY-MM-DD') AS created_at, 'Good Transfer Receipt' AS mutation_type, product_mutations.status, quantity"
    ).joins(:product_mutation).joins(:product).where("product_id=#{prod_id} AND to_char(product_mutation_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND destination_warehouse_id=#{office_id}")

    rts = ReturnsToSupplierDetail.select("*, head_office_id AS office_id, product_id, to_char(returns_to_supplier_details.created_at, 'YYYY-MM-DD') AS created_at, 'Return To Supplier' AS mutation_type,
      returns_to_supplier_details.quantity, returns_to_supplier_details.purchase_price AS hpp, returns_to_supplier_details.quantity*returns_to_supplier_details.purchase_price AS total_price")
      .joins(:returns_to_supplier, :product).where("product_id=#{prod_id} AND to_char(returns_to_supplier_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND head_office_id=#{office_id}")

    so = StockOpnameDetail
      .select(
        "product_id, office_id, to_char(stock_opname_details.created_at, 'YYYY-MM-DD') AS created_at, 'Stock Opname' AS mutation_type, qty_actual-qty_virtual AS quantity, (qty_actual-qty_virtual)*hpp AS total_price"
      )
      .where("qty_actual!=qty_virtual AND product_id=#{prod_id} AND stock_opnames.status='COMPLETED' AND to_char(stock_opname_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND office_id=#{office_id}")
      .joins(:stock_opname)

    parent_zfood = ZfoodDetail.select("*, product_id, to_char(zfood_details.created_at, 'YYYY-MM-DD') AS created_at, 'Parent Zfood' AS mutation_type").joins(zfood: :product_detail)
      .where("product_id=#{prod_id} AND to_char(zfood_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND warehouse_id=#{office_id}")
    structure_zfood = ZfoodDetail.select("*, skus.product_id, to_char(zfood_details.created_at, 'YYYY-MM-DD') AS created_at, 'Structure Zfood' AS mutation_type").joins(:sku, zfood: :product_detail)
      .where("skus.product_id=#{prod_id} AND to_char(zfood_details.created_at, 'YYYY-MM-DD')='#{trans_date}' AND warehouse_id=#{office_id}")
    dsi = DailySalesInventory.where(product_id: prod_id, office_id: office_id, date: trans_date).first_or_create
    prev_day = DailySalesInventory.find_by_product_id_and_office_id_and_date(prod_id, office_id, (trans_date.to_date-1.day).to_date.strftime('%Y-%m-%d'))

    start_amt = prev_day.end_amount.to_f rescue 0
    start_qty = prev_day.end_qty.to_f rescue 0

    sales_amt = sales.map{|s|s.capital_price.to_f*s.quantity.to_f}.compact.sum.to_f
    sales_qty = sales.map(&:quantity).compact.sum.to_f

    retur_sls_amt = rtr_sls.map(&:total_price).compact.sum.to_f
    retur_sls_qty = rtr_sls.map(&:quantity).compact.sum.to_f*-1

    gr_amt = gr.map(&:total_price).compact.sum.to_f
    gr_qty = gr.map(&:quantity).compact.sum.to_f

    tat_out_amt = tat_out.map{|g|g.quantity.to_f*g.hpp.to_f}.sum.to_f
    tat_out_qty = tat_out.map(&:quantity).compact.sum.to_f

    tat_in_amt = tat_in.map{|g|g.quantity.to_f*g.hpp.to_f}.sum.to_f
    tat_in_qty = tat_in.map(&:quantity).compact.sum.to_f

    retur_amt = rts.map(&:total_price).compact.sum.to_f
    retur_qty = rts.map(&:quantity).compact.sum.to_f

    so_amt = so.map(&:total_price).compact.sum.to_f
    so_qty = so.map(&:quantity).compact.sum.to_f

    end_qty = start_qty-sales_qty-retur_sls_qty+gr_qty+tat_in_qty-tat_out_qty-retur_qty+so_qty

    if gr_qty > 0
      cost = gr_amt/gr_qty
      last_cost = cost
      avg_cost = (gr_amt+start_amt)/(gr_qty+start_qty)
    else
      cost = prev_day.last_cost rescue start_amt
      last_cost = prev_day.last_cost rescue start_amt
      avg_cost = prev_day.avg_cost rescue start_amt
    end

    dsi.update_attributes(start_amount: start_amt, start_qty: start_qty, sales_amount: sales_amt, sales_qty: sales_qty, retur_sales_amount: retur_sls_amt, retur_sales_qty: retur_sls_qty, gr_amount: gr_amt,
      gr_qty: gr_qty, tat_in_amount: tat_in_amt, tat_in_qty: tat_in_qty, tat_out_amount: tat_out_amt, tat_out_qty: tat_out_qty, retur_amount: retur_amt, retur_qty: retur_qty, so_amount: so_amt, so_qty: so_qty,
      cost: cost, last_cost: last_cost, avg_cost: avg_cost, end_amount: end_qty.to_f*cost.to_f, end_qty: end_qty)
  end

  def self.generate_daily prod_id
    sales = SalesDetail.select("*, product_id, store_id AS office_id, to_char(sales_details.created_at, 'YYYY-MM-DD') AS created_at, 'Sales' AS mutation_type, quantity, capital_price AS hpp")
      .joins(:sale, :product).where("product_id=#{prod_id}")

    gr = ReceivingDetail.select("*, product_id, head_office_id AS office_id, to_char(receiving_details.created_at, 'YYYY-MM-DD') AS created_at, 'Receiving' AS mutation_type, quantity, hpp")
      .joins(:receiving, :product).where("product_id=#{prod_id}")

    tat_in = ProductMutationDetail.select(
      "*, product_id, origin_warehouse_id AS office_id, to_char(product_mutation_details.created_at, 'YYYY-MM-DD') AS created_at, 'Good Transfer' AS mutation_type, product_mutations.status, quantity"
    ).joins(:product_mutation).joins(:product).where("product_id=#{prod_id}")

    tat_out = ProductMutationDetail.select(
      "*, product_id, destination_warehouse_id AS office_id, to_char(product_mutation_details.created_at, 'YYYY-MM-DD') AS created_at, 'Good Transfer Receipt' AS mutation_type, product_mutations.status, quantity"
    ).joins(:product_mutation).joins(:product).where("product_id=#{prod_id}")

    rts = ReturnsToSupplierDetail
      .select("*, head_office_id AS office_id, product_id, to_char(returns_to_supplier_details.created_at, 'YYYY-MM-DD') AS created_at, 'Return To Supplier' AS mutation_type, returns_to_supplier_details.quantity,
        returns_to_supplier_details.purchase_price AS hpp").joins(:returns_to_supplier, :product).where("product_id=#{prod_id}")

    so = StockOpnameDetail.select("*, product_id, office_id, to_char(stock_opname_details.created_at, 'YYYY-MM-DD') AS created_at, 'Stock Opname' AS mutation_type, qty_actual-qty_virtual AS quantity, hpp")
      .where("product_id=#{prod_id} AND stock_opnames.status='COMPLETED'").joins(:stock_opname)

    parent_zfood = ZfoodDetail.select("*, product_id, to_char(zfood_details.created_at, 'YYYY-MM-DD') AS created_at, 'Parent Zfood' AS mutation_type").joins(zfood: :product_detail)
      .where("product_id=#{prod_id}")
    structure_zfood = ZfoodDetail.select("*, skus.product_id, to_char(zfood_details.created_at, 'YYYY-MM-DD') AS created_at, 'Structure Zfood' AS mutation_type").joins(:sku, zfood: :product_detail)
      .where("skus.product_id=#{prod_id}")
    (sales + gr + tat_in + tat_out + rts + so + parent_zfood + structure_zfood).group_by(&:created_at).sort_by{|c|c[0]}.each{|mutation|
      mutation[1].group_by(&:office_id).each{|mutation_per_office|
        mutation_per_office[1].group_by(&:product_id).each{|mutation_per_office_per_product|
          mutation_type = {}
          mutation_per_office_per_product[1].each{|transaction|
            qty = transaction.quantity
            amount = transaction.hpp.to_f*qty.to_f
            if transaction.mutation_type == 'Sales' && transaction.quantity < 0
              mutation_type["qty_Retur Sales"].present? ? mutation_type["qty_Retur Sales"] += qty : mutation_type["qty_Retur Sales"] = qty
              mutation_type["amt_Retur Sales"].present? ? mutation_type["amt_Retur Sales"] += amount : mutation_type["amt_Retur Sales"] = amount
            else
              mutation_type["qty_#{transaction.mutation_type}"].present? ? mutation_type["qty_#{transaction.mutation_type}"] += qty : mutation_type["qty_#{transaction.mutation_type}"] = qty
              mutation_type["amt_#{transaction.mutation_type}"].present? ? mutation_type["amt_#{transaction.mutation_type}"] += amount : mutation_type["amt_#{transaction.mutation_type}"] = amount
            end
          }
          dsi = DailySalesInventory.where(product_id: mutation_per_office_per_product[0], office_id: mutation_per_office[0], date: mutation[0]).first_or_create
          prev_day = DailySalesInventory.find_by_product_id_and_office_id_and_date(mutation_per_office_per_product[0], mutation_per_office[0], (mutation[0].to_date-1.day).to_date.strftime('%Y-%m-%d'))
          start_amt = prev_day.end_amount.to_f rescue 0
          start_qty = prev_day.end_qty.to_f rescue 0
          sales_amt = mutation_type['amt_Sales'].to_f
          retur_sls_amt = mutation_type['amt_Retur Sales'].to_f
          gr_amt = mutation_type['amt_Receiving'].to_f
          sales_qty = mutation_type['qty_Sales'].to_f
          retur_sls_qty = mutation_type['qty_Retur Sales'].to_f
          gr_qty = mutation_type['qty_Receiving'].to_f
          tat_amt = mutation_type['amt_Good Transfer'].to_f
          tat_qty = mutation_type['qty_Good Transfer'].to_f
          dsi.update_attributes(start_amount: start_amt, start_qty: start_qty, sales_amount: sales_amt, sales_qty: sales_qty, retur_sales_amount: retur_sls_amt, retur_sales_qty: retur_sls_qty, gr_amount: gr_amt,
            gr_qty: gr_qty, tat_in_amount: mutation_type['amt_Good Transfer Receipt'], tat_in_qty: mutation_type['qty_Good Transfer Receipt'], tat_out_amount: mutation_type['amt_Good Transfer'],
            tat_out_qty: mutation_type['qty_Good Transfer'], retur_amount: mutation_type['amt_Return To Supplier'], retur_qty: mutation_type['qty_Return To Supplier'],
            so_amount: mutation_type['amt_Stock Opname'], so_qty: mutation_type['qty_Stock Opname'],
            end_amount: start_amt-sales_amt-retur_sls_amt+gr_amt-tat_amt+mutation_type['amt_Good Transfer Receipt'].to_f+mutation_type['amt_Return To Supplier'].to_f+mutation_type['amt_Stock Opname'].to_f,
            end_qty: start_qty-sales_qty-retur_sls_qty+gr_qty-tat_qty+mutation_type['amt_Good Transfer Receipt'].to_f+mutation_type['amt_Return To Supplier'].to_f+mutation_type['amt_Stock Opname'].to_f)
        }
      }
    }
  end
  def self.generate_monthly_per_office trans_month, office_id
    Product.order("id ASC").map(&:id).each{|prod_id|
      DailySalesInventory.generate_monthly_per_item prod_id, trans_month, office_id
    }
  end

  def self.generate_monthly_per_item prod_id, trans_month, office_id
    sales = SalesDetail.select("*, product_id, store_id AS office_id, to_char(sales.created_at, 'YYYY-MM') AS created_at, 'Sales' AS mutation_type, quantity, capital_price AS hpp")
      .joins(:sale, :product).where("quantity>0 AND product_id=#{prod_id} AND to_char(sales.created_at, 'YYYY-MM')='#{trans_month}' AND store_id=#{office_id}")

    rtr_sls = SalesDetail
      .select(
        "*, product_id, store_id AS office_id, to_char(sales.created_at, 'YYYY-MM') AS created_at, 'Sales' AS mutation_type, quantity, capital_price AS hpp, quantity*capital_price AS total_price"
      ).joins(:sale, :product).where("quantity<0 AND product_id=#{prod_id} AND to_char(sales.created_at, 'YYYY-MM')='#{trans_month}' AND store_id=#{office_id}")

    gr = ReceivingDetail.select("*, product_id, head_office_id AS office_id, to_char(receivings.created_at, 'YYYY-MM') AS created_at, 'Receiving' AS mutation_type, quantity, hpp, quantity*hpp AS total_price")
      .joins(:receiving, :product).where("product_id=#{prod_id} AND to_char(receivings.created_at, 'YYYY-MM')='#{trans_month}' AND head_office_id=#{office_id} AND quantity>0")

    tat_out = ProductMutationDetail.select(
      "*, product_id, origin_warehouse_id AS office_id, to_char(product_mutations.created_at, 'YYYY-MM') AS created_at, 'Good Transfer' AS mutation_type, product_mutations.status, quantity"
    ).joins(:product_mutation).joins(:product).where("product_id=#{prod_id} AND to_char(product_mutations.created_at, 'YYYY-MM')='#{trans_month}' AND origin_warehouse_id=#{office_id}")

    tat_in = ProductMutationDetail.select(
      "product_id, destination_warehouse_id AS office_id, to_char(product_mutations.created_at, 'YYYY-MM') AS created_at, 'Good Transfer Receipt' AS mutation_type, product_mutations.status, quantity"
    ).joins(:product_mutation).joins(:product).where("product_id=#{prod_id} AND to_char(product_mutations.created_at, 'YYYY-MM')='#{trans_month}' AND destination_warehouse_id=#{office_id}")

    rts = ReturnsToSupplierDetail.select("*, head_office_id AS office_id, product_id, to_char(returns_to_suppliers.created_at, 'YYYY-MM') AS created_at, 'Return To Supplier' AS mutation_type,
      returns_to_supplier_details.quantity, returns_to_supplier_details.purchase_price AS hpp, returns_to_supplier_details.quantity*returns_to_supplier_details.purchase_price AS total_price")
      .joins(:returns_to_supplier, :product).where("product_id=#{prod_id} AND to_char(returns_to_suppliers.created_at, 'YYYY-MM')='#{trans_month}' AND head_office_id=#{office_id}")

    so = StockOpnameDetail
      .select(
        "product_id, office_id, to_char(stock_opnames.created_at, 'YYYY-MM') AS created_at, 'Stock Opname' AS mutation_type, qty_actual-qty_virtual AS quantity, (qty_actual-qty_virtual)*hpp AS total_price"
      )
      .where("qty_actual!=qty_virtual AND product_id=#{prod_id} AND stock_opnames.status='COMPLETED' AND to_char(stock_opnames.created_at, 'YYYY-MM')='#{trans_month}' AND office_id=#{office_id}")
      .joins(:stock_opname)

    parent_zfood = ZfoodDetail.select("*, product_id, to_char(zfoods.created_at, 'YYYY-MM') AS created_at, 'Parent Zfood' AS mutation_type").joins(zfood: :product_detail)
      .where("product_id=#{prod_id} AND to_char(zfoods.created_at, 'YYYY-MM')='#{trans_month}' AND warehouse_id=#{office_id}")
    structure_zfood = ZfoodDetail.select("*, skus.product_id, to_char(zfoods.created_at, 'YYYY-MM') AS created_at, 'Structure Zfood' AS mutation_type").joins(:sku, zfood: :product_detail)
      .where("skus.product_id=#{prod_id} AND to_char(zfood_details.created_at, 'YYYY-MM')='#{trans_month}' AND warehouse_id=#{office_id}")
    dsi = MonthlySalesInventory.where(product_id: prod_id, office_id: office_id, month: trans_month.split("-")[1], year: trans_month.split("-")[0]).first_or_create
    prev_month = "#{trans_month}-01".to_date-1.day
    prev_day = MonthlySalesInventory.find_by_product_id_and_office_id_and_year_and_month(prod_id, office_id, prev_month.year, prev_month.month)

    start_amt = prev_day.end_amount.to_f rescue 0
    start_qty = prev_day.end_qty.to_f rescue 0

    sales_amt = sales.map{|s|s.capital_price.to_f*s.quantity.to_f}.compact.sum.to_f
    sales_qty = sales.map(&:quantity).compact.sum.to_f

    retur_sls_amt = rtr_sls.map(&:total_price).compact.sum.to_f
    retur_sls_qty = rtr_sls.map(&:quantity).compact.sum.to_f*-1

    gr_amt = gr.map(&:total_price).compact.sum.to_f
    gr_qty = gr.map(&:quantity).compact.sum.to_f


    retur_amt = rts.map(&:total_price).compact.sum.to_f
    retur_qty = rts.map(&:quantity).compact.sum.to_f

    so_amt = so.map(&:total_price).compact.sum.to_f
    so_qty = so.map(&:quantity).compact.sum.to_f

    if gr_qty > 0
      cost = gr_amt/gr_qty
      last_cost = cost
      avg_cost = (gr_amt+start_amt)/(gr_qty+start_qty)
    elsif prev_day.present? && prev_day.last_cost > 0
      cost = prev_day.last_cost rescue start_amt
      last_cost = prev_day.last_cost rescue start_amt
      avg_cost = prev_day.avg_cost rescue start_amt
    else
      prev_dsi = MonthlySalesInventory.where("product_id=#{prod_id} AND month<=#{prev_month.month+1} AND year<=#{prev_month.year} AND end_amount>0").last
      prev_dsi = MonthlySalesInventory.where("product_id=#{prod_id} AND month<=#{prev_month.month+1} AND year<=#{prev_month.year} AND tat_out_amount>0").last if prev_dsi.blank?
      cost = prev_dsi.last_cost rescue start_amt
      last_cost = cost
      avg_cost = prev_dsi.avg_cost rescue start_amt
      if cost == 0
        prev_dsi = MonthlySalesInventory.where("product_id=#{prod_id} AND month<=#{prev_month.month+1} AND year<=#{prev_month.year} AND sales_amount>0").last if prev_dsi.blank?
        cost = (prev_dsi.sales_amount/prev_dsi.sales_qty) rescue 0
        last_cost = cost
        avg_cost = prev_dsi.avg_cost rescue start_amt
      end
    end

    tat_in_amt = tat_in.map{|g|g.quantity.to_f*cost}.sum.to_f
    tat_in_qty = tat_in.map(&:quantity).compact.sum.to_f

    tat_out_amt = tat_out.map{|g|g.quantity.to_f*cost}.sum.to_f
    tat_out_qty = tat_out.map(&:quantity).compact.sum.to_f

    end_qty = start_qty-sales_qty-retur_sls_qty+gr_qty+tat_in_qty-tat_out_qty-retur_qty+so_qty

    dsi.update_attributes(start_amount: start_amt, start_qty: start_qty, sales_amount: sales_amt, sales_qty: sales_qty, retur_sales_amount: retur_sls_amt, retur_sales_qty: retur_sls_qty, gr_amount: gr_amt,
      gr_qty: gr_qty, tat_in_amount: tat_in_amt, tat_in_qty: tat_in_qty, tat_out_amount: tat_out_amt, tat_out_qty: tat_out_qty, retur_amount: retur_amt, retur_qty: retur_qty, so_amount: so_amt, so_qty: so_qty,
      cost: cost, last_cost: last_cost, avg_cost: avg_cost, end_amount: end_qty*cost, end_qty: end_qty)
  end
end
