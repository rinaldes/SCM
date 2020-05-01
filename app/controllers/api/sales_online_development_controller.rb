class Api::SalesOnlineDevelopmentController < ApplicationController
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
    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=I.#{jenis}.#{idpel}.EDC.#{MY_IP}.#{pin}.#{code}")

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
      "http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=HARGA.#{product_type}.EDC.#{MY_IP}.#{pin}.#{code}"
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
      "http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=SALDO.EDC.#{MY_IP}.#{pin}.#{code}"
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
      "http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?#{param.to_query}"
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
      uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=C.PP.#{inv_code}.EDC.#{MY_IP}.#{pin}.#{code}")

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
        uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=C.RS.#{id_trx}.EDC.#{MY_IP}.#{pin}.#{code}")

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
        uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=C.RS.#{no_hp}.#{date}.EDC.#{MY_IP}.#{pin}.#{code}")

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
    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=CALLCENTER.EDC.#{MY_IP}.#{pin}.#{code}")

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
    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=SMSCENTER.EDC.#{MY_IP}.#{pin}.#{code}")

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
      uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=#{jenis}.#{idpel}.#{nominal}.EDC.#{MY_IP}.#{pin}.#{code}")
    else
      uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=#{jenis}.#{idpel}.EDC.#{MY_IP}.#{pin}.#{code}")
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

  def topup_telco_pascabayar
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # VARIABEL
    jenis = params[:jenis]
    no_tag = params[:no_tag]
    # info = params[:info]

    # PARAMETER
    # "http://<hostname:port/uri>?EDC=<JenisTagihan>.<noTagihan>.EDC.<ip>.<pin_dari_login>.<kode_verifikasi_dari_login>"
    # uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=#{jenis}.#{no_tag}.#{info}.EDC.#{MY_IP}.#{pin}.#{code}")
    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=#{jenis}.#{no_tag}.EDC.#{MY_IP}.#{pin}.#{code}")

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

  def airline_list_city
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    #PARAMETER
    # EDC : TIKET.AIRLINES.EDC.[IP].[PIN].[SESSION_SECURITY]
    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.AIRLINES.EDC.#{MY_IP}.#{pin}.#{code}")

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

  def airline_check_flight_schedule
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    #PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.AIRLINES.SCHEDULE.EDC.[IP].[PIN].[SESSION_SECURITY]&FROM=?&TO=?&DATE=?
    # FROM : (ex: CGK)
    # TO: (ex: SUB)
    # DATE : (ex: 30-05-2015) (dd-mm-yyyy)
    from = params[:from]
    to = params[:to]
    date = params[:date]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.AIRLINES.SCHEDULE.EDC.#{MY_IP}.#{pin}.#{code}&FROM=#{from}&TO=#{to}&DATE=#{date}")

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

  def airline_check_price_and_seat
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.AIRLINES.CHECK.EDC.[IP].[PIN].[SESSION_SECURITY]&FROM=?&TO=?&DATE=?&FLIGHT=?&ADULT=?&CHILD=?&INFANT=?
    # FROM: (ex: CGK)
    # TO: (ex: SUB)
    # DATE: (ex: 30-05-2015) (dd-mm-yyyy)
    # FLIGHT: (ex: SJ-254)
    # ADULT: (ex: 1)
    # CHILD: (ex: 0)
    # INFANT: (ex: 0)

    from = params[:from]
    to = params[:to]
    date = params[:date]
    flight = params[:flight]
    adult = params[:adult]
    child = params[:child]
    infant = params[:infant]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.AIRLINES.CHECK.EDC.#{MY_IP}.#{pin}.#{code}&FROM=#{from}&TO=#{to}&DATE=#{date}&FLIGHT=#{flight}&ADULT=#{adult}&CHILD=#{child}&INFANT=#{infant}")

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

  def airline_booking_ticket
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.AIRLINES.BOOKING.EDC.[IP].[PIN].[SESSION_SECURITY]&FROM=?&TO=?&DATE=?&FLIGHT=?&ADULT=?&CHILD=?&INFANT=?&EMAIL=?&PHONE=?&PASSANGERNAME=?&DATEOFBIRTH=?&BAGGAGEVOLUME=?&PASSPORTNUMBER=?&PASSPORTEXPIRED=?

    from = params[:from]
    to = params[:to]
    date = params[:date]
    flight = params[:flight]
    adult = params[:adult]
    child = params[:child]
    infant = params[:infant]
    email = params[:email]
    phone = params[:phone]
    name = params[:name]
    dob = params[:dob]
    bag_vol = params[:bag_vol]
    pass_num = params[:pass_num]
    pass_ex = params[:pass_ex]

    uri = URI(
      "http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.
      AIRLINES.BOOKING.EDC.#{MY_IP}.#{pin}.#{code}
      &FROM=#{from}
      &TO=#{to}
      &DATE=#{date}
      &FLIGHT=#{flight}
      &ADULT=#{adult}
      &CHILD=#{child}
      &INFANT=#{infant}
      &EMAIL=#{email}
      &PHONE=#{phone}
      &PASSANGERNAME=#{name}
      &DATEOFBIRTH=#{dob}
      &BAGGAGEVOLUME=#{bag_vol}
      &PASSPORTNUMBER=#{pass_num}
      &PASSPORTEXPIRED=#{pass_ex}"
      )

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

  def airline_issued_ticket
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.AIRLINES.ISSUED.[KODEBOOKING].EDC.[IP].[PIN].[SESSION_SECURITY]
    booking_code = params[:booking_code]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.AIRLINES.ISSUED.#{booking_code}.EDC.#{MY_IP}.#{pin}.#{code}")

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

  def railway_list_city
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.KAI.GETCODE.EDC.[IP].[PIN].[SESSION_SECURITY]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.KAI.GETCODE.EDC.#{MY_IP}.#{pin}.#{code}")

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

  def railway_check_schedule
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.KAI.GETSCHEDULE.EDC.[IP].[PIN].[SESSION_SECURITY]&FROM=?&TO=?&DATE=?&ADULT=?&CHILD=?&INFANT=?
    from = params[:from]
    to = params[:to]
    date = params[:date]
    flight = params[:flight]
    adult = params[:adult]
    child = params[:child]
    infant = params[:infant]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.KAI.GETSCHEDULE.EDC.#{MY_IP}.#{pin}.#{code}&FROM=#{from}&TO=#{to}&DATE=#{date}&ADULT=#{adult}&CHILD=#{child}&INFANT=#{infant}")

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

  def railway_check_price
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.KAI.GETPRICE.EDC.[IP].[PIN].[SESSION_SECURITY]&SESSION_ID=?&TRAIN_NO=?&TRAIN_NAME=?&SUB_CLASS=?
    session_id = params[:session_id]
    train_no = params[:train_no]
    train_name = params[:train_name]
    sub_class = params[:sub_class]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.KAI.GETSCHEDULE.EDC.#{MY_IP}.#{pin}.#{code}&SESSION_ID=#{session_id}&TRAIN_NO=#{train_no}&TRAIN_NAME=#{train_name}&SUB_CLASS=#{sub_class}")

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

  def railway_booking_ticket
    # SESSION DATABASE
    sos = SalesOnlineSession.first
    pin = sos.pin
    code = sos.code

    # PARAMETER
    # http://IP:PORT/[URI]/?EDC=TIKET.KAI.BOOKING.EDC.[IP].[PIN].[SESSION_SECURITY]&SESSION_ID=?&CUST_NAME=?&CUST_PHONE=?&CUST_EMAIL=?&PASS_TYPE_1=?&NAME_1=?&ID_CARD_1=?&HP_1=?&BIRTHDATE_1=?
    session_id = params[:session_id]
    cust_name = params[:cust_name]
    cust_phone = params[:cust_phone]
    cust_email = params[:cust_email]
    pass_type = params[:pass_type]
    name = params[:name]
    id_card = params[:id_card]
    hp = params[:hp]
    birthdate = params[:birthdate]

    uri = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=TIKET.KAI.GETSCHEDULE.EDC.#{MY_IP}.#{pin}.#{code}&SESSION_ID=#{session_id}&TRAIN_NO=#{train_no}&TRAIN_NAME=#{train_name}&SUB_CLASS=#{sub_class}")

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
    uri_login = URI("http://#{DEV_ONLINE_IP}:#{DEV_ONLINE_PORT}/#{DEV_ONLINE_URL}/?EDC=LOGIN.#{DEV_ONLINE_USER}.#{DEV_ONLINE_PSWD}.EDC.#{MY_IP}")

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
