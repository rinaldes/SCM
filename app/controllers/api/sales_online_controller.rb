class Api::SalesOnlineController < ApplicationController
  require "net/http"
  require "uri"

  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_current_user, :check_permitted_page
  skip_before_filter :protect_from_forgery
  skip_before_filter :authenticate_user!

  def topup_telco_voucher
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # VARIABEL
    jenis = params[:jenis]
    idpel = params[:idpel]

    # PARAMETER
    # "I.HTSEL10.085324207078.EDC.IP.PIN.SESSION_SECURITY"
    uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=I.#{jenis}.#{idpel}.EDC.#{MY_IP}.#{pin}.#{code}")

    # Lakukan Login jika Access Denied  - User/PW Salah
    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end

    # Jika status Sukses maka akan disimpan ke database
    # unless res.split(";")[4].include? 'GAGAL'
    #   son = SalesOnline.new
    #   son.transaction_id = res.split(";")[3]    #ex:  3625020
    #   son.pay_date = res.split(";")[5].to_datetime   #ex: 2014/10/24-14:56:36
    #   son.code = res.split(";")[7]         #ex: HTSEL10-081285318543
    #   son.status = res.split(";")[14].gsub("\n", "")
    #   son.biller_msg = "#{res.split(";")[15]} #{res.split(";")[16]}"
    #   son.bill_amt = res.split(";")[9].gsub(/[Rp.,\n]/,'').to_f

    #   son.save
    # end
  end

  def check_price
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # VARIABLE/PARAMETER
    product_type = nil
    product_type = URI.encode(params[:type]) if params[:type].present?

    # REQUEST
    # http://IP:PORT/[URI]/?EDC=HARGA.[PRODUCT_VOUCHER_TELCO/PRODUCT_VOUCHER_GAME].EDC.[IP].[PIN].[SESSION_SECURITY]
    uri = URI(
      "http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=HARGA.#{product_type}.EDC.#{MY_IP}.#{pin}.#{code}"
    )

    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end
  end

  def check_balance
    debug = true
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # REQUEST
    # EDC:SALDO.EDC.[IP].[PIN].[SESSION_SECURITY]
    uri = URI(
      "http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=SALDO.EDC.#{MY_IP}.#{pin}.#{code}"
    )

    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end
  end

  def push_data
    # REQUEST
    # http://IP:PORT/[URI]/?DATA=IDTRANSAKSI|KODEVOUCHER|NOHP|STATUS|KETERANGAN
    param = {"DATA" => "IDTRANSAKSI|KODEVOUCHER|NOHP|STATUS|KETERANGAN"}
    uri = URI(
      "http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?#{param.to_query}"
    )

    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end
  end

  def complain
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # VARIABEL
    inv_code = nil
    inv_code = URI.encode(params[:no_invoice]) if params[:no_invoice].present?
    comp_type = params[:complain_type]

    if comp_type == 'PP'
      # PARAMETER
      # http://IP:PORT/[URI]/?EDC=C.PP.[NO_INVOICE].EDC.[IP].[PIN].[SESSION_SECURITY]
      uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=C.PP.#{inv_code}.EDC.#{MY_IP}.#{pin}.#{code}")

      get = Net::HTTP.get(uri)
      if get.split(";")[3] == 'Access Denied'
        login
        res = Net::HTTP.get(uri)
        render :json => res
      else
        render :json => get
      end

    elsif comp_type == 'RS'
      rs_type = params[:rs_type]
      if rs_type == '1'
        id_trx = params[:id_trx]
        # PARAMETER
        # http://IP:PORT/[URI]/?EDC=C.RS.[ID_TRX].EDC.[IP].[PIN].[SESSION_SECURITY]
        uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=C.RS.#{id_trx}.EDC.#{MY_IP}.#{pin}.#{code}")

        get = Net::HTTP.get(uri)
        if get.split(";")[3] == 'Access Denied'
          login
          res = Net::HTTP.get(uri)
          render :json => res
        else
          render :json => get
        end
      elsif rs_type == '2'
        no_hp = params[:no_hp]
        date = params[:date]
        # PARAMETER
        # http://IP:PORT/[URI]/?EDC=C.RS.[NO_HANDPHONE].[DATE].EDC.[IP].[PIN].[SESSION_SECURITY]
        uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=C.RS.#{no_hp}.#{date}.EDC.#{MY_IP}.#{pin}.#{code}")

        get = Net::HTTP.get(uri)
        if get.split(";")[3] == 'Access Denied'
          login
          res = Net::HTTP.get(uri)
          render :json => res
        else
          render :json => get
        end
      else
        render :json => "Tipe RS tida ada yang cocok."
      end
    else
      render :json => "Parameter Tipe tidak ada yang cocok."
    end
  end

  def call_center
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # "CALLCENTER.EDC.IP.PIN.SESSION_SECURITY"
    uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=CALLCENTER.EDC.#{MY_IP}.#{pin}.#{code}")

    # Lakukan Login jika Access Denied  - User/PW Salah
    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end
  end

  def sms_center
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # "SMSCENTER.EDC.IP.PIN.SESSION_SECURITY"
    uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=SMSCENTER.EDC.#{MY_IP}.#{pin}.#{code}")

    # Lakukan Login jika Access Denied  - User/PW Salah
    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end
  end

  def topup_payment_point
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # VARIABEL
    jenis = params[:jenis]
    idpel = params[:idpel]
    nominal = params[:nominal] + ";0" if params[:nominal].present? && params[:jenis] == "PLNPREPAID"

    # PARAMETER
    # "http://<hostname:port/uri>?EDC=<JenisTagihan>.<noTagihan>.<nominal_token>.EDC.<ip>.<pin_dari_login>.<kode_verifikasi_dari_login>"
    if params[:nominal].present?
      uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=#{jenis}.#{idpel}.#{nominal}.EDC.#{MY_IP}.#{pin}.#{code}")
    else
      uri = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=#{jenis}.#{idpel}.EDC.#{MY_IP}.#{pin}.#{code}")
    end

    # Lakukan Login jika Access Denied  - User/PW Salah
    get = Net::HTTP.get(uri)
    if get.split(";")[3] == 'Access Denied'
      login
      res = Net::HTTP.get(uri)
      render :json => res
    else
      render :json => get
    end
  end

  private

  def login
    # URI
    uri_login = URI("http://#{ONLINE_IP}:#{ONLINE_PORT}/#{ONLINE_URL}/?EDC=LOGIN.#{ONLINE_USER}.#{ONLINE_PSWD}.EDC.#{MY_IP}")

    # INITIATE LOGIN
    begin
      result = Net::HTTP.get(uri_login)
      if SalesOnlineSession.first.nil?
        SalesOnlineSession.create(pin: result.split(";")[2], code: result.split(";")[3])
      else
        SalesOnlineSession.first.update_attributes(pin: result.split(";")[2], code: result.split(";")[3])
      end
    rescue Errno::ETIMEDOUT => e
      render :json => "Gagal menyambung ke server, Server tidak merespon."
    end
  end
end
