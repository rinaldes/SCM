class Plano < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_detail
  belongs_to :planogram, foreign_key: :rak_id

  validates :rak_id, :presence => {message: 'required'}
  validates :product_id, presence: true

  def self.to_csv(planos, options = {})
    CSV.generate(options) do |csv|
      csv << ["Rack", "Shelving", "Row", "Rack Type", "Article", "Product Name", "Kiri Kanan", "Atas Bawah", "Depan Belakang", "Minimal Display"]
      planos.each do |plano|
        csv << [plano.rak_name, plano.shelving, plano.rows, plano.rak_type, plano.product_article, plano.product_name, plano.kir_ka, plano.at_ba, plano.de_be, plano.min]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << [
        "article", "store", "start", "end", "rack_number", "shelving", "baris",
        "leadtime", "nplus", "kiri_kanan", "atas_bawah", "depan_belakang",
        "safety_stock", "minor"
      ]
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      line += 1
      if Product.find_by_article(row['article']).nil?
        return {error: 1, message: "Impor gagal karena Article produk tidak ada, Silakan cek article produk di baris #{line}."}
      else
        if Office.find_by_code(row['store']).nil?
          return {error: 1, message: "Impor gagal, Silakan cek store di baris #{line}. Store harus diisi menggunakan code."}
        else
          if Planogram.find_by_rack_number(row['rack_number']).nil?
            return {error: 1, message: "Impor gagal, Silakan cek rack number di baris #{line}."}
          else
            product = Product.find_by_article(row['article'])
            product_detail = product.product_details.find_by_warehouse_id(Office.find_by_code(row['store']).id)
            rak = Planogram.find_by_rack_number(row['rack_number'])

            mindis = row['kiri_kanan'].to_i + row['atas_bawah'].to_i + row['depan_belakang'].to_i rescue 0

            plano = Plano.new(
              product_id: product.id, start: row['start'], end: row['end'],
              rak_id: rak.id, rak_type: rak.rack_type, shelving: row['shelving'],
              kir_ka: row['kiri_kanan'], at_ba: row['atas_bawah'], de_be: row['depan_belakang'],
              rows: row['baris'], leadtime: row['leadtime'], min: mindis,
              product_detail_id: product_detail.id, nplus: row['nplus']
              )
            if mindis == 0
              return {error: 1, message: "Impor gagal, tidak bisa menghitung Min. Display, pastikan kolom kiri_kanan, atas_bawah, depan_belakang diisi dan menggunakan format numeric di baris #{line}."}
            else
              plano.save
              product_detail.update_attributes(
                min_stock: row['safety_stock'], rop_stock: row['minor']
                )
            end
          end
        end
      end
    end
    # calculate_pkm
    return {error: 0, message: "Rack Display Successfully imported."}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.calculate_pkm
    start_date = "2017-01-01"
    end_date = "2017-02-01"
    AutoPkmWorker.perform_async(start_date, end_date)
  end
end
