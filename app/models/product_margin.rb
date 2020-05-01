class ProductMargin < ActiveRecord::Base
  belongs_to :product
  validates :margin, presence: true, numericality: true

  def check_transaction
    return false if Product.find_by_selling_price(self.selling_price)
    true
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["code", "start_date", "end_date", "product_id", "margin"]
      all.each do |product_margin|
        csv << [product_margin.code, product_margin.start_date, product_margin.end_date, product_margin.product_id, product_margin.margin]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["code","product_id","margin"]
      all.each do |product_margin|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_code(row["code"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        product_margin = new(parameters.permit(:code, :start_date, :end_date, :product_id, :margin).merge(:code => "#{('%03d' % ((ProductMargin.last.code.gsub('C', '').to_i rescue 0)+1))}"))
        unless product_margin.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{product_margin.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{product_margin.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
      end
    end
    return {error: 0, message: "Successfully imported"}
  end
end
