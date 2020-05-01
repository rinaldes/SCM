class ImportData < ActiveRecord::Base
  mount_uploader :file_name, AttachmentUploader
  after_create :import_data
  require 'csv'

  def import_data
    csv_text = File.read(file_name.file.path)
    csv = CSV.parse(csv_text, headers: true)

    if file_type == 'Supplier'
      csv.each do |row|
        hash = row.to_hash
        Supplier.create code: hash["CODE"], name: hash["DESC"], address: hash["ADD1"], city: hash["CITY"], province: hash["PROVINCE"], zip: hash["ZIP"], send_address: hash["ADD2"],
          phone: hash["TELP"], fax: hash["FAX"], hp1: hash["TELP2"], term: hash["TERM"], suptype: hash["SUPTYPE"], ppn: hash["PPN"], paytype: hash["PAYTYPE"], share: hash["SHARE"]
      end
    elsif file_type == 'Brand'
      csv.each do |row|
        hash = row.to_hash
#        Brand.create(name: hash["DESC2 / KODE MERK"], code: hash["DESC2 / KODE MERK"].gsub(' ', '')) if hash["DESC2 / KODE MERK"].present? && !Brand.find_by_code(hash["DESC2 / KODE MERK"].gsub(' ', ''))
 #       if hash["DESC1"].present?
#          Colour.create(name: hash["DESC1"].split(' ')[1], code: hash["DESC1"].split(' ')[1]) unless Colour.find_by_code(hash["DESC1"].split(' ')[1])
 #         current_size = Size.where(description: hash["DESC1"].split(' ')[0], code: hash["DESC1"].split(' ')[0]).first_or_create
#          SizeDetail.where(size_number: hash["DESC1"].split(' ')[2], size_id: current_size.id).first_or_create
  #      end

        Member.create name: hash["NAME"], address: hash["ADD1"], add2: hash["ADD2"], city: hash["CITY"],#, birthday: date, phone_number: string, gender: boolean,
          code: hash["CODE"], city: hash["CITY"], zip: hash["ZIP"], coment1: hash["COMENT1"], coment2: hash["COMENT2"], datemember: hash["DATEMEMBER"]#, card_number: string,
          #hp: string, reference_id: integer, valid: boolean, discount: float, active: boolean
      end
    end

  end
end

=begin
Supplier
done  {"CODE"=>"001", "DESC"=>"SAHI JAYA", "ADD1"=>nil, "ADD2"=>nil, "CITY"=>nil, "PROVINCE"=>nil, "ZIP"=>nil, "TELP"=>"08157139989", "TELP1"=>nil, "TELP2"=>nil, "TELP3"=>nil,
    "FAX"=>"(022)5211746", "TERM"=>"0", "SUPTYPE"=>nil, "PPN"=>nil, "PAYTYPE"=>nil, "SHARE"=>nil, 

op    "QTY ORDER"=>nil, "REMARK"=>nil, "VALDORD"=>nil, "BALANCE"=>nil}

skip nil=>nil, "YTDADJ"=>nil, "YTDAMT"=>nil, "LASTORD"=>nil
CONTACT PERSON (NAMA/TELP/EMAIL) MULTI"=>"ARIEF", "PERSON2"=>nil, 

hold
=end
