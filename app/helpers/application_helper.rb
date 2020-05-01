module ApplicationHelper

  def use_purchase_order
    GlobalSetting.find_by_name('use_purchase_order').is_active rescue true
  end

  def month_in_word(num)
    return 'Januari' if num == 1
    return 'Februari' if num == 2
    return 'Maret' if num == 3
    return 'April' if num == 4
    return 'Mei' if num == 5
    return 'Juni' if num == 6
    return 'Juli' if num == 7
    return 'Agustus' if num == 8
    return 'September' if num == 9
    return 'Oktober' if num == 10
    return 'November' if num == 11
    return 'Desember' if num == 12
  end

  def pagination_links(collection, options = {})
    options[:renderer] ||= BootstrapPaginationHelper::LinkRenderer
    options[:inner_window] ||= 1
    options[:outer_window] ||= 0
    will_paginate(collection, options)
  end

  def setup_size(size)
    1.upto(14-size.size_details.size){
      size.size_details.build
    }
    size
  end

  def hierarchy num
    "#{num}#{num == 1 ? 'st' : (num == 2 ? 'nd' : (num == 3 ? 'rd' : 'th'))}"
  end

  #preview image in new goods
  def goods_image
    return params[:image_url] if params[:image_url].present?
    return params[:based64_image] if params[:based64_image].present?
    @image.present? ? @image : 'no_pic.png'
  end

  def visibility_link link
    return true if !current_user || current_user.is_superadmin?
    return current_user.pages.map(&:name).include?(link) if link.class == String
    link.each{|ahref| return true if current_user.pages.map(&:name).include?(ahref) }
    false
  end

  def get_distribution_branch_link good_distribution_branch, stat=0
    return good_distribution_branch.get_status[stat] unless good_distribution_branch.get_status[stat] == GoodsDistribution::Pending
    link_to good_distribution_branch.get_status[stat], edit_goods_distribution_path(good_distribution_branch.goods_distribution, branch: good_distribution_branch.branch), class: 'blue'
  end

  def main_sell_link
    return point_of_sales_url if visibility_link Page::POS
    return new_goods_request_url if visibility_link Page::CREATE_GOODS_REQUEST
    return goods_requests_url if visibility_link Page::VIEW_GOODS_REQUEST
    exchange_datas_url
  end

  def main_purchase_link
    return purchase_orders_url if visibility_link Page::PURCHASE_ORDER
    return goods_receipts_url if can_access_goods_receipt
    goods_allocations_url
  end

  def can_access_goods_receipt
    visibility_link(Page::VIEW_GOODS_RECEIPT) || visibility_link(Page::CREATE_GOODS_RECEIPT) || visibility_link(Page::INSPECT_GOODS_RECEIPT)
  end

  def to_local_currency number
    return "-" if number.nil?
    number_to_currency number.to_f, unit: "", delimiter: ".", precision: 2
  end

  def is_colorbox
    %w(new_colorbox_goods create_colorbox_goods add_goods create_goods new_users create_users search_filter_by_brands_po detail_goods_photo_goods).include?("#{params[:action]}_#{params[:controller]}")
  end

  def jzebra_applet(printer_type)
    @printer_barcode = ''#Printer.first rescue ''

    if @printer_barcode.nil?
      html = <<-"HTML"
        <div id="color_box" style="display:none">
          <div id="print_confirmation" class="popup">
            #{render :partial => "shared/printer_is_not_setted"}
          </div>
        </div>
        <script type="text/javascript">
          function callColorBox(){
            $.fn.colorbox({width:"auto",height:"auto", inline:true, href:"#print_confirmation", fixed: true});
          }
        </script>
      HTML
    else
      html = <<-"HTML"
        <div id="applet_container_#{printer_type}">
          <applet name="jZebra_#{printer_type}" code="jzebra.RawPrintApplet.class" archive="/applet/jzebra.jar" width="0" height="0">
              <param name="printer" value="Zebra-Technologies-ZTC-GK420t">
           </applet>
        </div>

        <script type="text/javascript">
          function isZplBased(){
            return true;
          }
        </script>
      HTML
    end

    return raw html
  end

  def print_barcode_applet_1row(printer_code, location)
    html = <<-"HTML"
      #{jzebra_applet('barcode')}
      <script type='text/javascript'>
        function printBarcode(arrCodes, printCount){
          var applet = document.jZebra_barcode;
          if(applet == undefined){
            setTimeout("callColorBox()",1000);
          } else {
            var codeCount = arrCodes.length;
            var paperCount = codeCount * printCount;
            var arrBarcode = new Array(paperCount);
            var arrInfo1 = new Array(paperCount);
            var arrInfo2 = new Array(paperCount);
            var j = 0;
            var k = 0;
            var i = 0;

            for(i=0;i<printCount;i++){
              for(k=0;k<codeCount;k++){
                arrBarcode[j] = arrCodes[k].split('#BARCODE#')[0];
                arrInfo1[j] = arrCodes[k].split('#BARCODE#')[1].substr(0,20);
                arrInfo2[j] = arrCodes[k].split('#BARCODE#')[1].substr(21,40);
                j++;
              }
            }

            for(var l=0;l<paperCount;l++){
              applet.append('N\\n');
              applet.append('A40,60,0,1,2,2,N,"'+ arrInfo1[l] +'"\\n');
              applet.append('A40,90,0,1,2,2,N,"'+ arrInfo2[l] +'"\\n');
              applet.append('B40,120,0,1,5,8,200,B,"'+ arrBarcode[l] +'"\\n');
              applet.append('P1\\n');
              applet.print();
            }
          }
        }
      </script>
    HTML
    return raw html
  end


  def error_field obj, field_name
    'error-field' if obj.errors.messages.keys.include?(field_name)
  end

  def is_pos
    %w(point_of_sales goods_requests exchange_datas).include?(params[:controller])
  end

  def is_master
    %w(suppliers sizes types brands colours members edc_machines goods_branch_prices).include?(params[:controller])
  end

  def is_inventory
    %w(stock_opnames goods goods_transfers goods_movements goods_stocks goods_transfer_receipt_details).include?(params[:controller])
  end

  def is_purchase
    %w(goods_receipts returns_to_suppliers purchase_requests purchase_orders goods_distributions composite_purchase_orders goods_allocations returns_to_head_offices).include?(params[:controller])
  end

  def is_setting
    %w(branches units stores users user_branches).include?(params[:controller])
  end

  def is_dashboard
    %w(dashboards).include?(params[:controller])
  end

  def is_job_task
    %w(to_do_lists).include?(params[:controller])
  end

  def is_report
    %w(reports).include?(params[:controller])
  end

  def is_sell
    %w(goods_requests sales_bills).include?(params[:controller])
  end

  def navigation_menu
    return 'master_menu' if is_master
    return 'dashboards_menu' if is_dashboard
    return 'inventory_menu' if is_inventory
    return 'setting_menu' if is_setting
    return 'purchase_menu' if is_purchase
    return 'job_task_menu' if is_job_task
    return 'report_menu' if is_report
    return 'sell_menu' if is_pos
    'setting_menu'
  end

  def delete_label
    raw("<div class='delete-icon'>x</div>Hapus")
  end

  def fix_zero_float number
    number = number.to_i if number.to_s.split(".")[1] == "0" rescue number
    return number
  end

  def remove_currency number
    return number.to_s.split(".").join("").to_i if number.present?
  end

  def format_date(date)
    date.strftime("%Y/%m/%d") unless date.blank?
  end

  def format_time(time)
    time.strftime("%H:%M") unless time.blank?
  end

  def format_currency(number)
    number_to_currency(number, precision: 0, unit: "" ) unless number.blank?
  end

  def truncate_text(text)
    text.truncate(20) unless text.blank?
  end

  def get_image(image)
      if image.present? && FileTest.exist?(image.path)
         image_tag(image.url)
      else
        " "# image_tag('no_pic.png')
      end
  end


  def finance_report_module
    ["finance_reports/store_cashs", "finance_reports/receivables", "finance_reports/bank_outs", "finance_reports/repayments"].include? params[:controller]
  end

  def finance_module
    ["finances/account_payables", "finances/account_receivables", "finances/budgetings", "finances/forecasts", "finances/petty_cashes", "finances/sod_eods", "finances/monthly_forecasts"].include? params[:controller]
  end

  def current_petty_cash
    cash = PettyCashDetail.where("EXTRACT(MONTH FROM date) = ?", Time.now.month).first
    cash.petty_cash_id rescue nil
  end

end
