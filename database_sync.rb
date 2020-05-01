#!/usr/bin/env ruby

require 'pg'
require 'csv'

class DatabaseSync
  def initialize(dbname, user, password, hostaddr, port)
    @conn = PG::connect(dbname: dbname,
                        user: user,
                        password: password,
                        hostaddr: hostaddr,
                        port: port)
  end

  def export_sub(csv, update_last, table_name)
    deco = PG::TextDecoder::CopyRow.new
    @conn.copy_data "COPY (SELECT * FROM #{table_name} WHERE updated_at >= '#{update_last}') TO STDOUT", deco do
      while row = @conn.get_copy_data
        csv << [table_name] + row
      end
    end
  end

  def export(file, tables, update_last)
    CSV.open(file, 'w') do |csv|
      tables.each do |table|
        export_sub(csv, update_last, table)
      end
    end
  end

  def import_sub(table, data)
    query = """create temporary table import_#{table} as select * from #{table} limit 0;
               copy import_#{table} from stdin;
               begin transaction;
               delete from #{table}
               where id in (select  id from import_#{table});
               insert into #{table} select * from import_#{table};
               commit transaction;"""

    enco = PG::TextEncoder::CopyRow.new
    @conn.copy_data query, enco do
      data.each do |row|
        @conn.put_copy_data row[0]
      end
    end
  end

  def import(file)
    table = Hash.new
    CSV.foreach(file) do |csv|
      if !table.has_key?(csv[0])
        table[csv[0]] = Array.new
      end

      table[csv[0]] << [csv[1..-1]]
    end

    table.each do |key, arr|
      import_sub(key, arr)
    end
  end
end


tables = ['members', 'brands', 'm_classes', 'offices', 'products', 'edc_machines', 'to_do_lists']
sync_ex = DatabaseSync.new('abc_development', 'dev', 'admin', '127.0.0.1', 5432)
sync_ex.export('/tmp/export.csv', tables, '2016-03-01')

sync_im = DatabaseSync.new('abc_development2', 'dev', 'admin', '127.0.0.1', 5432)
sync_im.import('/tmp/export.csv')
