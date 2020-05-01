class SellingPriceDetail < ActiveRecord::Base
  belongs_to :selling_price
  belongs_to :sku
  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["no","article","barcode","product","store","start_date", "end_date", "hpp", "hpp_average", "ppn_in", 
        'margin_percent', 'margin_amount', 'ppn_out', 'selling_price']
      all.each_with_index do |spd, i|
        sp = spd.selling_price
        if sp.present?
          csv << [i+1, (sp.product.article rescue nil), (sp.product.barcode rescue nil), (sp.product.description rescue nil), (sp.office.office_name rescue nil), (sp.start_date rescue nil),
            (sp.end_date rescue nil), (sp.hpp rescue nil), (sp.hpp_average rescue nil), (sp.ppn_in rescue nil), (sp.margin_percent rescue nil), (sp.margin_amount rescue nil), (sp.ppn_out rescue nil), spd.price]
        end
      end
    end
  end
end
