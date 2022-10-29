require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = <<-SQL
            PRAGMA table_info(#{table_name});
        SQL
        
        table_info = DB[:conn].execute(sql)

        table_info.map do |info|
            info["name"]
        end
    end

    def initialize(properties = {})
        properties.each do |key, val|
            self.class.attr_accessor(key.to_sym)
            self.send("#{key}=", val)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.filter {|name| name != "id"}.join(", ")
    end

    def values_for_insert
        values = self.class.column_names.filter {|name| name != "id"}.map do |col_name|
            self.send(col_name)
        end

        values.map {|value| "'" + value.to_s + "'"}.join(", ")
    end  

    def save
        DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
        self.id = DB[:conn].execute("SELECT last_insert_rowid()")[0]["last_insert_rowid()"]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        colname = attribute.map {|key, val| [key.to_s, val.to_s]}[0][0]
        val = attribute.map {|key, val| [key.to_s, val]}[0][1]

        sql = "SELECT * FROM #{table_name} WHERE #{colname} = ?"
        DB[:conn].execute(sql, val)
    end
end