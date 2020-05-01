namespace :regenerate_mutation_history do
  desc "TODO"
  task regenerate_mutation_history: :environment do
    ProductMutationHistory.regenerate_mutation_history
  end

  task regenerate_cut_off_daily: :environment do
    DailySalesInventory.reset_all
  end

  task generate_role: :environment do
[{"id"=>114, "name"=>"View Product Structure", "module_name"=>"Master Data"}, {"id"=>115, "name"=>"View Product Convertion", "module_name"=>"Inventory"},
  {"id"=>116, "name"=>"Manage Product Structure", "module_name"=>"Master Data"}, {"id"=>117, "name"=>"Manage Product Convertion", "module_name"=>"Inventory"}].each{|a|
  FeatureName.create a
}
end
end
