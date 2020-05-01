class SomController < ApplicationController
  def custom
  end

  def post_custom
    sheet = RubyXL::Parser.parse(params['file'].tempfile)[0]
    arts = []
    sheet.each_with_index do |row, i|
      arts << row[0].value
    end
    rd = ReceivingDetail.where("article IN ('#{arts.join("','")}') AND receiving_id=68").joins(:product)
    rd.delete_all
  end

  def regenerate_mutation_history
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE product_mutation_histories RESTART IDENTITY")
    (SalesDetail.select("*, sales_details.created_at AS created_at, 'Sales' AS mutation_type").joins(:product)
    +ReceivingDetail.select("*, receiving_details.created_at AS created_at, 'Receiving' AS mutation_type").joins(:receiving).joins(:product)
    +ProductMutationDetail.select("*, product_mutation_details.created_at AS created_at, 'Good Transfer' AS mutation_type, product_mutations.status").joins(:product_mutation).joins(:product)
    +ReturnsToSupplierDetail.select("*, returns_to_supplier_details.created_at AS created_at, 'Return To Supplier' AS mutation_type").joins(:product)
    +StockOpnameDetail.select("*, stock_opname_details.created_at AS created_at, 'Stock Opname' AS mutation_type")
    +ZfoodDetail.select("*, zfood_details.created_at AS created_at, 'Zfood' AS mutation_type").joins(sku: :product)).sort_by(&:created_at).each{|mutation|
      mutation.generate_history
      mutation.product_received_by_destination_branch if mutation.mutation_type == 'Good Transfer' && mutation.status == 'RECEIVED'
    }
  end

   def sc
      if current_user.valid_password?(params[:pass])
        columns = Sale.attribute_names - ['id']
        columns2 = SalesDetail.attribute_names - ['id']

        c1 = Sale.select(columns).all
        c2 = SalesDetail.select(columns2).all
        c1.each do |a|
          Sbbcas.create(a.attributes)
        end
        c2.each do |a|
          Sdbbcasd.create(a.attributes)
        end
       # send_data Sale.all.to_csv, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=Sale_Backup-#{Date.today}.csv"
       # send_data SalesDetail.to_csv, :type => 'text/csv; charset=iso-8859-1; header=present', filename: "Sale Detail Backup-#{Date.today}.csv"
        Sale.where("created_at < ?", Time.zone.now.beginning_of_day).destroy_all
        SalesDetail.where("created_at < ?", Time.zone.now.beginning_of_day).destroy_all
      else
        flash[:error] = 'Wrong Password!'
      end
   end
end