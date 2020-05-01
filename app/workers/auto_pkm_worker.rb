class AutoPkmWorker
  include Sidekiq::Worker

  def perform(start_date, end_date)
    # Mengambil Semua Product Detail yang ada di dalam Plano
    Plano.all.each do |plano|
      # Menghitung SPD (Sales Average selama 3 Bulan)
      spd = SalesDetail.select(
        "round(AVG(quantity), 2) AS averages").where(
        "to_char(transaction_date, 'YYYY-MM-DD') BETWEEN '#{Date.today.beginning_of_month - 3.month}' AND
        '#{Date.today.end_of_month}' AND
        product_id = #{plano.product_id} AND
        store_id = #{plano.product_detail.warehouse_id}"
      ).joins(:sale).order("averages")
      @spd = spd.first.averages.to_i

      # Rumus PKM = SPD(LT+SS)+minor
      lt = (plano.leadtime rescue 0)
      ss = (plano.product_detail.min_stock rescue 0)
      minor = (plano.product_detail.rop_stock rescue 0)
      pkm = @spd*(lt+ss)+minor

      # Jika PKM < Mindis, PKM = Min.Display+Minor
      if pkm < plano.min
        Logger.new(STDOUT).info("PKM Kurang dari Min.Display")
        pkm = plano.min+minor
      # Jika SPD < 3 Bulan atau hasilnya = 0, PKM = Min.Display+Minor
      elsif @spd < 1
        Logger.new(STDOUT).info("SPD kurang dari 3 Bulan")
        pkm = plano.min+minor
      end
      Logger.new(STDOUT).info("PKM Adalah #{pkm}")
      # Update Max Stock (PKM)
      plano.product_detail.update_attributes(max_stock: pkm)
      Logger.new(STDOUT).info("PKM untuk #{plano.product.short_name} sekarang Adalah : #{pkm}")
    end
  end
end
