#encoding: utf-8

namespace :db do
  namespace :populate do

    task :airports => :environment do
      puts "\n" + "** ".bold + "Импортируем данные об аэропортах...".green.bold

      AIRPORTS = Mongoid::Config.master['airports']
      AIRPORTS.drop()

      id = 1

      Nokogiri::XML::Reader.from_io(File.new(File.join(Rails.root, 'db', '/airports.xml'), 'r')).each do |node|
        if node.name == 'airport' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          parsed_node = {}
          latitude = 0
          longitude = 0

          Nokogiri::XML(node.outer_xml).xpath('//airport').children().each do |field|
            if field.is_a? Nokogiri::XML::Element
              if field.name == 'latitude'
                latitude = field.text.to_f
              elsif field.name == 'longitude'
                longitude = field.text.to_f
              else
                parsed_node[field.name] = field.text
              end
            end
          end

          if longitude != 0  && latitude != 0
            parsed_node['geo'] = [longitude, latitude]
            parsed_node['_id'] = id
            AIRPORTS.insert(parsed_node)
            id += 1
          end
        end
      end

      puts "   -->".bold + " добавлено ".green + AIRPORTS.count.to_s.bold + ' объектов'
      puts "   -->".bold + " завершено".green
    end

    task :prices => :environment do
      puts "\n" + "** ".bold + "Генерация цен на авиаперелеты...".green.bold

      PRICES = Mongoid::Config.master['prices']
      PRICES.drop()

      airports_origin_id_range = Range.new(1, Mongoid::Config.master['airports'].count)
      id = 1
      airports_origin_id_range.each do |origin_id|
        puts "   -->".bold + " генерация цен ".green + 'для ' + 'origin_id '.bold + origin_id.to_s
        airports_destination_ids = airports_origin_id_range.to_a
        airports_destination_ids = airports_destination_ids.sort_by { rand }

        times = 10 + Random.new.rand(0..390)
        iterates = 1
        prices = []
        while iterates <= times
          destination_id = airports_destination_ids.shift
          depart_date = Time.now.utc.to_date + Random.new.rand(2..365).day
          prices.push({ '_id' => id, 'origin_id' => origin_id, 'destination_id' => destination_id,
                        'depart_date' => depart_date.to_time, 'return_date' => (depart_date + Random.new.rand(1..4).week).to_time,  'value' => Random.new.rand(150..1500) })
          iterates += 1
          id += 1
        end
        PRICES.insert(prices)
      end

      puts "   -->".bold + " добавлено ".green + PRICES.count.to_s.bold + ' объектов'
      puts "   -->".bold + " завершено".green
    end

    task :create_indexes => :environment do
      puts "\n" + "** ".bold + "Создаем индексы...".green.bold
      puts "   -->".bold + " добавлен индекс ".green + Mongoid::Config.master['airports'].create_index([["geo", Mongo::GEO2D]]).bold
      puts "   -->".bold + " добавлен индекс ".green + Mongoid::Config.master['airports'].create_index([["city_rus", Mongo::ASCENDING]]).bold
      puts "   -->".bold + " добавлен индекс ".green + Mongoid::Config.master['airports'].create_index([["city_eng", Mongo::ASCENDING]]).bold
      puts "   -->".bold + " добавлен индекс ".green + Mongoid::Config.master['prices'].create_index([["origin_id", Mongo::ASCENDING], ["destination_id", Mongo::ASCENDING], ["depart_date", Mongo::ASCENDING], ["return_date", Mongo::ASCENDING]], :unique => true).bold
      puts "   -->".bold + " добавлен индекс ".green + Mongoid::Config.master['prices'].create_index([["value", Mongo::ASCENDING]]).bold
      puts "   -->".bold + " завершено".green
    end
  end

  desc "Populate and generate all init data"
  task :populate => ["db:populate:airports", "db:populate:prices", "db:populate:create_indexes"]
end