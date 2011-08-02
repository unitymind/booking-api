# Прототип веб-сервиса с json-интерефейсом для поиска минимальных цен на авиаперелеты

[http://booking-api.unitymind.org/](http://booking-api.unitymind.org/) - запущенный веб-сервис, соответствующий текущей версии.

Пример запроса: http://booking-api.unitymind.org/search/Moscow/10-09-2011/month/0

## Постановка задачи

Функциональные и иные требования в формате PDF доступны [здесь](https://github.com/unitymind/bookingapi/blob/master/doc/aviasales-test.pdf?raw=true).

## Выбор базы данных
Поскольку в требованиях не было ограничения по использованию СУБД, то выбрана [MongoDB](http://mongodb.org) в виду быстродействия и простоты использования, а также поддержки geospatial индексов.

Для доступа к данным используется напрямую API Ruby-драйвера MongoDB.

## Сбор данных и их структура

### Реальные данные
В качестве источника данных об аэропортах использован сайт [http://www.apinfo.ru/](http://www.apinfo.ru/airports/export.html).

Данные в формате XML находятся в файле db/airports.xml, который парсится и экспортируется в базу посредством соответствующей Rake-задачи.

Получены:

* IATA-код
* ICAO-код
* Название аэропорта на русском
* Название аэропорта на английском
* Город на русском
* Город на английском
* Страна на русском
* Страна на английском
* ISO-код страны
* Географические координаты

9298 аэропортов.

### Сгенерированные данные

Для каждого из аэропортов генерируется от 10 до 400 записей в коллекцияю с ценами (выбирается случайный пункт назначения, дата отправления + 2..365 дней от текущей, дата возвращения в интервале от 1 до 4-х недель, или же от 5 до 180-ти дней)

~1,9M записей с ценами.

## Тестирование

Web-сервис имеет всего один вызов формата: search/:depart_name/:start_date/:period_type/:duration

Результаты сортируются по возрастанию цены.

Покрыты случаи:

* неккоретного формата запроса
* некорректных данных в запросе
* дат начала периода, выходящих за рамки имеющихся в базе
* соответствия дат вылета выбранному типу периода (месяц или сезон)
* соответствие даты обратного вылета выбранной длительности пребывания (1, 2, 3, 4) недели.
* общее количество вариантов перелетов должно превышать количество вариантов с датами возвращениям кратными 1, 2, 3, 4 неделям от даты вылета.

## Недочеты

Посколько наш API очень простой, то он оформлен в виде GET-вызова с передачей всех параметров.

В реальных случаях уместно:

* более детальное (с группировками) дизайн URL-ов для запросов, так и передача параметров в теле запроса (XML или JSON).
* более детальные сообщения об ошибках (сейчас при некорректных данных всегда отдается {"ERROR":"TRUE"})
* декомпозиция (сейчас все выполняется в контроллере).

## Немного технических деталей

Парсер аэропортов и генерация данных оформлены в rake-задачу:

	rake db:populate
        Populate and generate all init data

Которая в свою очередь является оберткой для трех недокументированных задач:

    rake db:populate:airports - экспорт данных об аэропортах
    rake db:populate:prices - генерация цен
    rake db:populate:create_indexes - создание индексов