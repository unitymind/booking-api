class SearchController < ApplicationController
  AIRPORTS = Mongoid::Config.master['airports']
  PRICES = Mongoid::Config.master['prices']

  def index
    query_params = parse_query
    results = []
    if query_params.is_a? Hash
      prices = PRICES.find(query_params[:filter], :sort => [['value', Mongo::ASCENDING]]).to_a
      if query_params[:duration] != 0
        prices.delete_if { |price| price['return_date'] != price['depart_date'] + query_params[:duration].week }
      end
      destinations = {}
      AIRPORTS.find( { '_id' => {'$in' => prices.map { |p| p['destination_id']}.uniq } }, :fields => ['_id', 'geo']).each { |airport| destinations[airport['_id']] = airport['geo'] }

      prices.each do |price|
        results.push({'destination' => {'id' => price['destination_id'],
                                        'latitude' => destinations[price['destination_id']][1],
                                        'longitude' => destinations[price['destination_id']][0]},
                     'price' => {'value' => price['value'],
                                 'depart_date' => price['depart_date'].to_date,
                                 'return_date' => price['return_date'].to_date}
                     })
      end
      encoded = encode_to_json(results)
    else
      encoded = encode_to_json({"ERROR" => "TRUE"})
    end

    respond_to do |format|
      format.html { render :text => encoded }
      format.json { render :json=> encoded }
    end
  end

  private
  def parse_query
    origins_ids = []
    AIRPORTS.find({'$or' => [{'city_rus' => params[:depart_name]}, {'city_eng' => params[:depart_name]}]}, :fields => ['_id']).each { |row| origins_ids.push row['_id']}

    depart_start_date = nil
    begin
      depart_start_date = Date.parse(params[:start_date])
    rescue ArgumentError
      depart_start_date = nil
    end

    depart_end_date = nil

    if !depart_start_date.nil?
      if params[:period_type] == 'month'
        depart_end_date = depart_start_date + 1.month
      elsif params[:period_type] == 'season'
        depart_end_date = Date.civil(depart_start_date.year, 2, -1) if [1, 2].include? depart_start_date.month
        depart_end_date = Date.civil(depart_start_date.year, 5, -1) if [3, 4, 5].include? depart_start_date.month
        depart_end_date = Date.civil(depart_start_date.year, 8, -1) if [6, 7, 8].include? depart_start_date.month
        depart_end_date = Date.civil(depart_start_date.year, 11, -1) if [9, 10, 11].include? depart_start_date.month
        depart_end_date = Date.civil(depart_start_date.year+1, 1, -1) if depart_end_date.nil?
      end
    end

    if origins_ids.empty? or depart_start_date.nil? or depart_end_date.nil? or ! [0, 1, 2, 3, 4].include? params[:duration].to_i
      parsed_query = false
    else
      parsed_query = { :filter => {'origin_id' => {'$in' => origins_ids },
                                   'destination_id' => {'$ne' => nil},
                                   'depart_date' => {'$gt' => depart_start_date.to_time, '$lte' => depart_end_date.to_time} },
                      :duration => params[:duration].to_i }
    end
  end
end
