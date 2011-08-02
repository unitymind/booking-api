#encoding: utf-8
require 'spec_helper'

describe 'search' do
  describe 'incorrect requests' do
     it 'should have RoutingError for not full search requests' do
      expect { visit '/search/' }.to raise_error(ActionController::RoutingError)
      expect { visit '/search/Moscow' }.to raise_error(ActionController::RoutingError)
      expect { visit '/search/Moscow/01-09-2011' }.to raise_error(ActionController::RoutingError)
      expect { visit '/search/Moscow/01-09-2011/season' }.to raise_error(ActionController::RoutingError)
    end

    it 'should have \'{"ERROR":"TRUE"}\' response for full, but incorrect search requests' do
      # Некорректный город
      visit '/search/Moscow23/01-09-2011/season/0'
      page.should have_content('{"ERROR":"TRUE"}')
      # Некорректная дата начала периода
      visit '/search/Moscow/01-26-2011/season/0'
      page.should have_content('{"ERROR":"TRUE"}')
      # Некорректный тип периода
      visit '/search/Moscow/01-09-2011/another_type/0'
      page.should have_content('{"ERROR":"TRUE"}')
      # Некорректная длительность пребывания в неделях
      visit '/search/Moscow/01-09-2011/season/5'
      page.should have_content('{"ERROR":"TRUE"}')
    end
  end

  describe 'out of range requests' do
    it 'should have empty array in response for out of range depart date' do
      visit '/search/Moscow/01-09-2010/season/0'
      parse_from_json(source).should be_empty
      visit '/search/Moscow/01-09-2012/season/0'
      parse_from_json(source).should be_empty
    end
  end

  describe 'validate results' do

    before(:all) do
      @start_depart_date = Date.civil(2011, 9, 10)
      @end_depart_date_month = Date.civil(2011, 9, 10) + 1.month
      @end_depart_date_season = Date.civil(2011, 11, 30)

      @month = {}
      @season = {}

      visit '/search/Moscow/10-09-2011/month/0'
      [0, 1, 2, 3, 4].each do |duration|
        visit "/search/Moscow/10-09-2011/month/#{duration}"
        @month[duration] = parse_from_json(source)
        visit "/search/Moscow/10-09-2011/season/#{duration}"
        @season[duration] = parse_from_json(source)
      end
    end

    it 'depart dates should be only in monthly period' do
      # Дата отправления входит в месячный период начиная с 10-09-2011 и заканчивая 10-10-2011
      @month.each do |duration, results|
        results.each do |result|
          depart_date = Date.parse(result['price']['depart_date'])
          (depart_date >= @start_depart_date).should be_true
          (depart_date <= @end_depart_date_month).should be_true
        end
      end
    end

    it 'depart dates should be only in season period' do
      # Дата отправления входит в сезонный период начиная с 10-09-2011 и заканчивая 30-11-2011
      @month.each do |duration, results|
        results.each do |result|
          depart_date = Date.parse(result['price']['depart_date'])
          (depart_date >= @start_depart_date).should be_true
          (depart_date <= @end_depart_date_season).should be_true
        end
      end
    end

    it 'return dates should be match for duration type (1, 2, 3 or 4 weeks) from depart date' do
      # Дата возвращения должна совпадать с длительностью пребывания в неделях
      @month.each do |duration, results|
        if duration != 0
          results.each do |result|
            depart_date = Date.parse(result['price']['depart_date'])
            return_date = Date.parse(result['price']['return_date'])
            (depart_date + duration.week == return_date).should be_true
          end
        end
      end
    end
  end
end
