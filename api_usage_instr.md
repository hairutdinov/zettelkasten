### Авторизация
Для работы с АПИ необходимо пройти авторизацию. Тип авторизации: **Bearer Token**

### Создание пациента
После создания нового пациента и сохранения его в вашей БД, необходимо отправить POST запрос на
`POST http://185.104.107.24:8090/api/v1/patient`
**Формат тела запроса:**
```json
{
  "id": 200,
  "email": "babunov@gmail.com",
  "first_name": "Jesus",
  "last_name": "Snyder",
  "patronymic": "M.",
  "phone": "79998887766",
  "snils": "22092398885",
  "gender": "0",
  "birth_at": "1991-12-21",
  "hospital_id": "10564",
  "status": "10",
  "auth_key": "VxNShyw3h45IWNucNwIl10ltE2uCwv80",
  "password_hash": "$2y$13$IaOL3CNvu.M3SJl0uQmqp.nWTTHoGFTjSZDmTdnm10T46B6BBRpWl",
  "password_reset_token": "",
  "verification_token": "ohIcC0WfwkskmV8HaC3pbXieYIVZUSMG_1661945785",
  "access_token": "jqFNgqj8uwm2WtuTu_H01NfhkwGJqSs",
  "extra": {
    "education": null,
    "oms_number": "",
    "profession": "",
    "address_reg": "г Казань ул Восстания дом 24 кв 4 ",
    "nationality": "",
    "oms_company": "",
    "address_match": "0",
    "address_residence": "г Казань ул Лукина 54- 46"
  },
  "created_at": "2022-10-24 10:00:00",
  "updated_at": "2022-10-24 10:00:00"
}
```

**Обязательные поля**:
- id
- first_name
- last_name
- patronymic

**Ответы**:
1. Status: 200. message: api.patient.create.success - сохранен
2. Status: 500. message: api.patient.alreadyExists - пациент уже существует
3. Status: 422. message: api.patient.create.modelValidateError - ошибки валидации данных
4. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

### Обновление пациента
После обновления и сохранения данных в БД, отправить PATCH/PUT запрос на 
`PATCH http://185.104.107.24:8090/api/v1/patient/410` , где 210 - ID пациента
**Формат тела запроса:**
```json
{
  "id": 410,
  "first_name": "Ivan",
  "last_name": "Ivanov",
  "patronymic": "Ivanovich",
  "phone": "70007771122",
  "status": "10",
  "updated_at": "2022-11-01 12:11:14"
}
```
**Ответы**:
1. Status: 200. message: api.patient.update.success - обновлен
2. Status: 200. message: api.patient.create.success - если попытаться обновить несуществующего пользователя, то он создаст его и вернет сообщение: api.patient.create.success
3. Status: 422.  message: api.patient.update.modelLoadError - ошибка загрузки данных в модель
4. Status: 422. message: api.patient.update.modelValidateError - ошибка валидации данных
5. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова


### Создание карты пациента
После заполнения карты пациента и сохранения в БД, отправить POST запрос на
`POST http://185.104.107.24:8090/api/v1/patient/410/card` , где 410 - ID пациента
**Формат тела запроса:**
```json
{
  "doctor_id": 15,
  "diabetes": {
    "type": "1"
  },
  "diagnosis": {
    "mkb": "14"
  },
  "status": null,
  "created_at": "2022-09-27 06:16:43",
  "updated_at": "2022-09-27 06:16:43"
}
```
**Ответы**:
1. Status: 200. message: app.patient.card.create.success - сохранен
2. Status: 500.  message: app.patient.card.alreadyExists - карта пациента уже существует
3. Status: 500. message: api.patient.notFound - пациент не найден
4. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

### Обновление карты пациента
После обновления карты пациента и сохранения, отправить PATCH/PUT запрос на
`PATCH http://185.104.107.24:8090/api/v1/patient/410/card` , где 410 - ID пациента
**Ответы**:
1. Status: 200. message: app.patient.card.update.success
2. Status: 200. message: app.patient.card.create.success - в случае, если карты не было, она будет создана
3. Status: 500.  message: app.patient.card.alreadyExists
4. Status: 500. message: api.patient.notFound
5. Status: 422. message: app.patient.card.update.modelSaveError
6. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

### Добавление значения показателя глюкозы
`POST http://185.104.107.24:8090/api/v1/patient/410/arterial-pressure` , где 410 - ID пациента
**Формат тела запроса:**
```json
{
  "systolic": 120,
  "dystolic": 78,
  "taken_at": "2022-01-01 17:17:17",
  "moment": 0
}
```
**Ответы**:
1. Status: 200. message: app.patient.arterialPressure.create.success
2. Status: 500. message: api.patient.notFound
3. Status: 422. message: app.patient.arterialPressure.create.modelValidateError
4. Status: 422. message: app.patient.arterialPressure.create.modelSaveError
5. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

### Добавление значения показателя АД
`POST http://185.104.107.24:8090/api/v1/patient/410/glucose` , где 410 - ID пациента
**Формат тела запроса:**
```json
{
  "glucose": "12",
  "condition": 1,
  "moment": 4,
  "taken_at": null
}
```
**Ответы**:
1. Status: 200. message: app.patient.glucose.create.success
2. Status: 500. message: api.patient.notFound
3. Status: 422. message: app.patient.glucose.create.modelValidateError
4. Status: 422. message: app.patient.glucose.create.modelSaveError
5. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

#### Событие по пациенту
**Формат URL**:
`POST http://185.104.107.24:8090/api/v1/patient/100/event` , где 100 - ID пациента
Поля: 
- Стадия компенсации [string, по-умолчанию: null]:
	- compensation
	- decompensation
- Тип диабета [int, по-умолчанию: null]:
	- 1 [1 тип]
	- 2 [2 тип]
- Инсулинопотребный [string, по-умолчанию: null]:
	- yes
	- no
- Маркер критичности (необходимо согласовать справочники)
- Уровень критичности [string]:
	- high - Высокий
	- medium - Средний
	- low - Низкий
- Источник получения информации [string]:
	- sppvr
**Ответы**:
1. Status: 200 - success
2. Status: 500 - неизвестная ошибка. Попробуйте отправить данные снова.

#### Событие по врачу
`POST http://185.104.107.24:8090/api/v1/doctor/100/event` , где 100 - ID врача

#### Создание врача
`POST http://185.104.107.24:8090/api/v1/doctor`
**Формат тела запроса:**
```json
{
  "id": 479,
  "email": "CynthiaCCombs@armyspy.com",
  "first_name": "Cyntia",
  "last_name": "Combs",
  "patronymic": "C.",
  "phone": "74063243489",
  "snils": "91827381927",
  "gender": "0",
  "birth_at": "1982-04-21",
  "hospital_id": "10564",
  "status": "10",
  "extra": {
    "education": null,
    "oms_number": "",
    "profession": "",
    "address_reg": "г Казань, ул Хороводная дом 39 кв 11",
    "nationality": "",
    "oms_company": "",
    "address_match": "0",
    "address_residence": "г Казань, ул Хороводная дом 40 кв 10"
  },
  "created_at": "2011-11-11 11:11:11",
  "updated_at": "2022-11-11 11:11:11"
}
```

**Обязательные поля**:
- id
- first_name
- last_name
- patronymic

**Ответы**:
1. Status: 200. message: api.doctor.create.success - сохранен
2. Status: 500. message: api.doctor.alreadyExists - пациент уже существует
3. Status: 422. message: api.doctor.create.modelValidateError - ошибки валидации данных
4. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

#### Обновление врача
`PATCH http://185.104.107.24:8090/api/v1/doctor/479` , где 479 - ID врача
**Формат тела запроса:**
```json
{
  "id": 479,
  "first_name": "Cynthia",
  "updated_at": "2022-11-11 16:31:51"
}
```
**Ответы**:
1. Status: 200. message: api.doctor.update.success - обновлен
2. Status: 200. message: api.doctor.create.success - если попытаться обновить несуществующего пользователя, то он создаст его и вернет сообщение: api.doctor.create.success
3. Status: 422.  message: api.doctor.update.modelLoadError - ошибка загрузки данных в модель
4. Status: 422. message: api.doctor.update.modelValidateError - ошибка валидации данных
5. Status: 500. message: null - если неизвестная ошибка, попробовать отправить данные снова

#### Создание диспетчера
`POST http://185.104.107.24:8090/api/v1/dispatcher`
**Формат тела запроса:**
Такой же, как при [[#Создание врача]]

#### Обновление диспетчера
`PATCH http://185.104.107.24:8090/api/v1/dispatcher/504` , где 504 - ID врача
**Формат тела запроса:**
Такой же, как при [[#Обновление врача]]



### API с вашей стороны

#### Мед. карта пациента со всеми полями
**Формат ответа**: json
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/card` , где 100 - ID пациента
**Статус**: 200

#### Получение всех бланков осмотра пациента
**Формат ответа**: json
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/blanks` , где 100 - ID пациента
**Статус**: 200

#### Получение бланк осмотра по id
**Формат ответа**: СЭМД (xml)
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/blank/1` , где 
- 100 - ID пациента
- 1 - ID бланка осмотра

**Статус**: 200

#### Последний бланк осмотра
**Формат ответа**: СЭМД (xml)
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/blank/last` , где 100 - ID пациента
**Статус**: 200

#### Лабораторные исследования
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/laboratory-research` , где 100 - ID пациента

#### Инструментальные исследования
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/instrumental-research` , где 100 - ID пациента

#### Консультации специалистов
**Формат URL**:
`GET {{baseApiUrl}}/api/patient/100/consultations` , где 100 - ID пациента

## ⚠️ Необходимо обсуждение функционала чата на сокетах отдельно от ТЗ