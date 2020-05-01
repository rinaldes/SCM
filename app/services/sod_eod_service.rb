
class SodEodService
  def SodEodService.saveSodEod(params)

    if !params[:uuid].nil?
      sod_eod = SodEod.where(uuid: params[:uuid]).take
    end
    if (sod_eod.nil?)
      sod_eod = SodEod.new
      sod_eod.uuid = params[:uuid] if params[:uuid]
      # sod_eod.id = (SodEod.last.id rescue 0)+1
    end

    sod_eod.sod_eod_date= (params['sod_eod_date'] rescue nil)
    sod_eod.voucher= params['voucher']
    sod_eod.user_id= params['user_id']
    sod_eod.debit= params['debit']
    # sod_eod.machine_id= params['client_id']
    sod_eod.machine_id= params['machine_id']
    sod_eod.difference= params['difference']
    sod_eod.start_amount= params['start_amount']
    sod_eod.discount= params['discount']
    sod_eod.session_type= params['session_type']
    sod_eod.note= params['note']
    sod_eod.start_time= params[:start_time].to_datetime
    sod_eod.cash= params['cash']
    sod_eod.office_id= params['office_id']

    # End Of Shift
    sod_eod.end_time= params[:end_time].to_datetime if params[:end_time].present?
    sod_eod.actual_end_amount = params['actual_end_amount'] if params['actual_end_amount'].present?
    sod_eod.end_amount = params['end_amount'] if params['end_amount'].present?
    sod_eod.credit = params['credit'] if params['credit'].present?
    sod_eod.retur = params['retur'] if params['retur'].present?
    sod_eod.total_cash_sales = params['total_cash_sales'] if params['total_cash_sales'].present?
    sod_eod.paid_difference = params['paid_difference'] if params['paid_difference'].present?
    sod_eod.petty_cash = params['petty_cash'] if params['petty_cash'].present?
    sod_eod.ppn = params['ppn'] if params['ppn'].present?
    sod_eod.receipt_count = params['receipt_count'] if params['receipt_count'].present?
    sod_eod.total_sales = params['total_sales'] if params['total_sales'].present?
    sod_eod.special_discount = params['special_discount'] if params['special_discount'].present?
    sod_eod.transfer = params['transfer'] if params['transfer'].present?


    sod_eod.save

    return sod_eod
  end

  def SodEodService.saveSession(params)
    if !params[:uuid].nil?
      session = Session.where(uuid: params[:uuid]).take
    end
    if (session.nil?)
      session = Session.new
      session.uuid = params[:uuid] if params[:uuid]
      # session.id = (Session.last.id rescue 0)+1
    end

    session.user_id = params[:user_id]
    session.client_id = params[:client_id]
    session.office_id = params[:office_id]
    session.sodeod_id = params[:sod_eod_id]
    session.shift_no = params[:shift_no]
    session.start_time = params[:start_time].to_datetime
    session.save
  end

end
