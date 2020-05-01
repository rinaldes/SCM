<% if @product.present? %>
  $("#product_id").val("<%= @product.id %>");
  $("#merk").val("<%= @product.brand.name %>");
  $("#article").val("<%= @product.article %>");
  $("#disc1").val("<%= @product.margin_percent1 %> %");
  $("#disc2").val("<%= @product.margin_percent2 %> %");
  $("#disc3").val("<%= @product.margin_percent3 %> %");
  $("#disc4").val("<%= @product.margin_percent4 %> %");
  $("#disc5").val("<%= @product.margin_rp %>");
  $("#jenis").val("<%= @product.brand.id %>");
  $("#warna").val("<%= @product.full_colour.join(' / ') %>");
  $("#harga_pokok").val("<%= @product.cost_of_products %>");
  $("#harga_jual").val("<%= @product.purchase_price %>");
  $("#harga_beli").val("<%= @product.selling_price %>");
  $("#size").val("<%= @product.size.code %>");
  $("#status2").val("<%= @product.status2 %>");
  $("#status3").val("<%= @product.status3 %>");
  $("#status4").val("<%= @product.status4 %>");
  $("#m_class").val("<%= @product.m_class.name %>")
  $("#departement").val("<%= @product.brand.department.name %>")
  $("#product_image").html("<%= j(image_tag @product.image, width: '250px', height: '250px') %>")
  $("#table_size thead tr:eq(0) td").html(" ")
  $("#table_size tbody tr:eq(0) td").html(" ")
  nomor_ganti()

  <% @list_product.each_with_index do |detail, i|%>
    $("#table_size tbody tr:eq(0) td:eq(<%= i %>)").html("<%= detail.min_stock.to_i %>")
    $("#table_size tbody tr:eq(1) td:eq(<%= i %>)").html("<%= detail.available_qty %>")
    $("#table_size tbody tr:eq(2) td:eq(<%= i %>)").html("<%= detail.min_stock.to_i rescue 0 %>")
    $("#table_size tbody tr:eq(3) td:eq(<%= i %>)").html("<%= detail.available_qty.to_i rescue 0 %>")
  <% end %>
<% else %>
  alert('Your Product not present!')
<% end %>
