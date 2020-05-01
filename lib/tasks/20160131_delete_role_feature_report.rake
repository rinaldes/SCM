namespace :seed do
  task :delete_role_feature_report => :environment do
    puts "========= Delete Feature Name and Feature Data ========="
    features = ["Bank Out Report", "Cash Out Report", "Global Finance Report", "Journal Memo Report", "Account Payable Report", "Store Cash Report", "Receivable Report", "Repayment Report", "Denomination Report"]
    array_feature = Array.new
    features.each do |feature|
      feature_name = FeatureName.find_by_name_and_module_name(feature, "Finance Report")
      if feature_name.present?
        Feature.where(:feature_name_id => feature_name.id).destroy_all
        feature_name.destroy
      end
    end
  end
end
