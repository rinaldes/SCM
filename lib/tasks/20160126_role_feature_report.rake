namespace :seed do
  task :role_feature_report => :environment do
    # Form laporan bank keluar (Pembayaran supplier)
    # Form laporan kas keluar
    # Laporan Global Keuangan (dari setoran kasir)
    # Memo Jurnal (rekapitulasi pembayaran jatuh tempo juga dari laporan bank keluar)
    # Rekapan Hutang
    # Laporan Kas per Toko (Global dari Form laporan kas keluar)
    # Laporan Piutang
    # Laporan Pelunasan
    # Laporan Keuangan dari Kasir Mengenai pecahan uang

    puts "========= Seeding Feature Name Data ========="
    features = ["Bank Out Report", "Cash Out Report", "Global Finance Report", "Journal Memo Report", "Account Payable Report", "Store Cash Report", "Receivable Report", "Repayment Report", "Denomination Report"]
    array_feature = Array.new
    features.each do |feature|
      hash_feature = Hash.new
      hash_feature["name"] = feature
      hash_feature["module_name"] = "Finance Report"
      array_feature.push(hash_feature)
    end

    array_feature_id = Array.new
    array_feature.each do |hash|
      feature = FeatureName.find_by_name_and_module_name(hash["name"], hash["module_name"])
      if feature.blank?
        feature = FeatureName.new({:name => hash["name"], :module_name => hash["module_name"]})
        feature.save(:validate => false)
        array_feature_id.push(feature.id)
      end
    end

    puts "========= Seeding Feature Data ========="
    if array_feature_id.present?
      role_id = Role.find_by_name("CEO").try(:id)
      if role_id.present?
        array_feature_id.each do |feature_id|
          Feature.create(:role_id => role_id, :feature_name_id => feature_id)
        end
      end
    end
  end
end
