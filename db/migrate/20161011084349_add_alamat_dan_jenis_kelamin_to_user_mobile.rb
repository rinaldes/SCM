class AddAlamatDanJenisKelaminToUserMobile < ActiveRecord::Migration
  def change
    add_column :mobile_users, :alamat, :string
    add_column :mobile_users, :jenis_kelamin, :string
  end
end
