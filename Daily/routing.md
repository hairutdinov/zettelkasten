## api/web/index.php
```php
<?php

defined('YII_DEBUG') or define('YII_DEBUG', true);
defined('YII_ENV') or define('YII_ENV', 'dev');

require __DIR__ . '/../../vendor/autoload.php';
require __DIR__ . '/../../vendor/yiisoft/yii2/Yii.php';
require __DIR__ . '/../../common/config/bootstrap.php';
require __DIR__ . '/../config/bootstrap.php';

$config = yii\helpers\ArrayHelper::merge(
    require __DIR__ . '/../../common/config/main.php',
    require __DIR__ . '/../../common/config/main-local.php',
    require __DIR__ . '/../config/main.php',
    require __DIR__ . '/../config/main-local.php'
);

(new yii\web\Application($config))->run();

```

## api/web/index-test.php
```php
<?php

// NOTE: Make sure this file is not accessible when deployed to production
if (!in_array(@$_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1'])) {
    die('You are not allowed to access this file.');
}

defined('YII_DEBUG') or define('YII_DEBUG', true);
defined('YII_ENV') or define('YII_ENV', 'test');

require __DIR__ . '/../../vendor/autoload.php';
require __DIR__ . '/../../vendor/yiisoft/yii2/Yii.php';
require __DIR__ . '/../../common/config/bootstrap.php';
require __DIR__ . '/../config/bootstrap.php';

$config = yii\helpers\ArrayHelper::merge(
    require __DIR__ . '/../../common/config/main.php',
    require __DIR__ . '/../../common/config/main-local.php',
    require __DIR__ . '/../../common/config/test.php',
    require __DIR__ . '/../../common/config/test-local.php',
    require __DIR__ . '/../config/main.php',
    require __DIR__ . '/../config/main-local.php',
    require __DIR__ . '/../config/test.php',
    require __DIR__ . '/../config/test-local.php'
);

(new yii\web\Application($config))->run();

```

## api/resources/Card.php
```php
<?php

namespace api\resources;

class Card extends \common\models\Card
{
    public function fields()
    {
        return parent::fields();
    }

    public function getDoctor()
    {
        return $this->hasOne(User::class, ['id' => 'doctor_id']);
    }
}
```

## api/resources/Hospital.php
```php
<?php

namespace api\resources;

class Hospital extends \common\models\Hospital
{
    public function fields()
    {
        return [
            'id',
            'name_short',
            'name_full',
            'oid',
            'address_text',
            'phone',
        ];
    }

    public function extraFields()
    {
        return [
            'address_city_fias',
            'address_street_fias',
            'address_house_fias',
            'ogrn',
            'okato',
            'okpo',
            'extra',
        ];
    }
}
```

## api/resources/User.php
```php
<?php

namespace api\resources;

class User extends \common\models\User
{
    public function fields()
    {
        return [
            'id',
//            'email',
            'first_name',
            'last_name',
            'patronymic',
            'phone',
//            'role',
//            'status',
//            'password_hash',
//            'password_reset_token',
//            'verification_token',
//            'created_at',
//            'updated_at',
//            'external_token',
        ];
    }
}
```

## api/resources/Patient.php
```php
<?php

namespace api\resources;

class Patient extends \common\models\Patient
{
    public function fields()
    {
        return [
            'id',
            'email',
            'first_name',
            'last_name',
            'patronymic',
            'phone',
            'snils',
            'gender',
            'birth_at',
            'hospital_id',
            'status',
            'extra',
            'created_at',
            'updated_at',
            'external_id',
        ];
    }

    public function getHospital()
    {
        return $this->hasOne(Hospital::class, ['id' => 'hospital_id']);
    }

    public function getCard()
    {
        return $this->hasOne(Card::class, ['patient_id' => 'id']);
    }
}
```

## api/models/ApiLoginForm.php
```php
<?php

namespace api\models;

use Yii;
use yii\base\Model;

/**
 *
 * @property-read User|null $user
 *
 */
class ApiLoginForm extends Model
{
    public $login;
    public $password;

    private $_user = false;

    public function rules()
    {
        return [
            [['login', 'password'], 'required'],
            ['login', 'string'],
            ['password', 'validatePassword'],
        ];
    }

    public function validatePassword($attribute, $params)
    {
        if (!$this->hasErrors()) {
            $user = $this->getUser();
            if (!$user || !$user->validatePassword($this->password)) {
                $this->addError($attribute, Yii::t('app', 'Incorrect login or password.'));
            }
        }
    }

    public function login()
    {
        if ($this->validate()) {
            return $this->getUser();
        }
        return false;
    }

    /**
     * Finds user by [[email]] or [[phone]]
     *
     * @return User|null
     */
    public function getUser()
    {
        if ($this->_user === false) {
            $this->_user = User::find()->where(['or', ['email' => $this->login], ['phone' => $this->login]])->one();
        }

        return $this->_user;
    }
}

```

## api/models/User.php
```php
<?php

namespace api\models;

use Yii;
use yii\base\NotSupportedException;
use yii\behaviors\TimestampBehavior;
use yii\db\ActiveRecord;
use yii\filters\RateLimitInterface;
use yii\web\IdentityInterface;

class User extends \common\models\User implements IdentityInterface, RateLimitInterface
{
    public $rateLimit = 10;
    public $allowance;
    public $allowance_updated_at;

    public static function findIdentity($id)
    {
        return static::findOne(['id' => $id]);
    }

    public static function findIdentityByAccessToken($token, $type = null)
    {
        return self::findOne(['external_token' => $token]);
    }

    public function getId()
    {
        return $this->id;
    }

    public function getAuthKey()
    {
        return $this->external_token;
    }

    public function validateAuthKey($authKey)
    {
        return $this->getAuthKey() ===  $authKey;
    }

    public function getRateLimit($request, $action)
    {
        return [$this->rateLimit, 1]; // $rateLimit запросов в секунду
    }

    public function loadAllowance($request, $action)
    {
        return [$this->allowance, $this->allowance_updated_at];
    }

    public function saveAllowance($request, $action, $allowance, $timestamp)
    {
        $this->allowance = $allowance;
        $this->allowance_updated_at = $timestamp;
        $this->save();
    }
}

```

## api/models/sppvr/PatientEvent.php
```php
<?php

namespace api\models\sppvr;

use api\components\ApiResponseMessage;
use api\components\exceptions\UnprocessableContentException;
use common\models\DiabetesType;
use common\models\Event;
use common\models\EventClassifier;
use common\models\EventPriority;
use common\models\EventType;
use common\models\Mkb;
use common\models\Patient;
use Yii;
use yii\base\Model;
use yii\helpers\ArrayHelper;

class PatientEvent extends Model
{
    public $compensation_stage;
    public $diabetes_type;
    public $diabetesTypeExternal;
    public $mkb;
    public $mkbExternal;
    public $insulin_requiring;
    public $classifier_id;
    public $priority;
    public $source;
    public $patient;
    private ?Patient $_patient;

    public function rules()
    {
        return [
            [['compensation_stage', 'insulin_requiring', 'priority', 'source', 'patient'], 'required'],
            [['compensation_stage', 'insulin_requiring', 'priority', 'source'], 'string'],
            [['diabetes_type', 'classifier_id', 'mkb', 'mkbExternal'], 'integer'],

            ['compensation_stage', 'in', 'range' => ['compensation', 'decompensation']],
            ['insulin_requiring', 'in', 'range' => ['yes', 'no']],
            ['priority', 'in', 'range' => [EventPriority::HIGH, EventPriority::MEDIUM, EventPriority::LOW]],

            [['diabetes_type'], 'exist', 'skipOnError' => true,
                'targetClass' => DiabetesType::class,
                'targetAttribute' => ['diabetes_type' => 'id']
            ],
            [['mkb'], 'exist', 'skipOnError' => true,
                'targetClass' => Mkb::class,
                'targetAttribute' => ['mkb' => 'id']
            ],
            [['classifier_id'], 'exist', 'skipOnError' => true,
                'targetClass' => EventClassifier::class,
                'targetAttribute' => ['classifier_id' => 'external_id']
            ],
            [['patient'], 'validatePatient', 'skipOnEmpty' => false, 'skipOnError' => false],
        ];
    }

    public function validatePatient($attribute, $params, $validator)
    {
        $model = new Patient(['scenario' => Patient::SCENARIO_API_CREATE_EVENT]);
        if (!$model->load($this->$attribute, '') || !$model->validate()) {
            $this->addError($attribute, $model->errors);
        }
    }

    public function save(): bool
    {
        try {
            return $this->_save();
        } catch (UnprocessableContentException $e) {
            switch ($e->getMessage()) {
                case ApiResponseMessage::PATIENT_MODEL_LOAD_ERROR:
                    $exception = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_PATIENT_LOAD_ERROR);
                    $exception->setModel($e->getModel());
                    throw $exception;
                case ApiResponseMessage::PATIENT_MODEL_SAVE_ERROR:
                    $exception = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_PATIENT_SAVE_ERROR);
                    $exception->setModel($e->getModel());
                    throw $exception;
                default:
                    throw $e;
            }
        } catch (\Exception $e) {
            throw $e;
        }
    }

    private function _save(): bool
    {
        $this->insulin_requiring = $this->insulin_requiring === 'yes';

        $modelPatient = new Patient(['scenario' => Patient::SCENARIO_API_CREATE_EVENT]);
        $modelPatient->updateOrCreateIfNotExistsByExternalId($this->patient);

        $modelEvent = new Event();

        if ($modelEvent->load($this->attributes, '') === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_LOAD_ERROR);
            $e->setModel($modelEvent);
            throw $e;
        }

        $modelEvent->patient_id = $this->patient['id'];
        $modelEvent->created_by = (string) Yii::$app->user->id;
        $modelEvent->type = EventType::PATIENT;
        $modelEvent->diabetes_type = ArrayHelper::getValue($modelPatient->cardData, 'diabetes.type');
        $modelEvent->mkb_id = ArrayHelper::getValue($modelPatient->cardData, 'diagnosis.mkb');
        $modelEvent->classifier = EventClassifier::findOne(['external_id' => $this->classifier_id])->name;

        if ($modelEvent->validate() === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($modelEvent);
            throw $e;
        }

        if ($modelEvent->save() === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($modelEvent);
            throw $e;
        }

        return true;
    }
}
```

## api/components/ApiResponseMessage.php
```php
<?php

namespace api\components;

class ApiResponseMessage
{
    const PATIENT_CREATE_MODEL_LOAD_ERROR = 'api.patient.create.modelLoadError';
    const PATIENT_CREATE_MODEL_VALIDATE_ERROR = 'api.patient.create.modelValidateError';
    const PATIENT_CREATE_MODEL_SAVE_ERROR = 'api.patient.create.modelSaveError';
    const PATIENT_CREATE_SUCCESS = 'api.patient.create.success';
    const PATIENT_NOT_FOUND = 'api.patient.notFound';
    const PATIENT_ALREADY_EXISTS = 'api.patient.alreadyExists';

    const PATIENT_CREATE_EXTRA_MODEL_LOAD_ERROR = 'api.patient.create.extraModelLoadError';
    const PATIENT_CREATE_EXTRA_MODEL_VALIDATE_ERROR = 'api.patient.create.extraModelValidateError';

    const PATIENT_UPDATE_MODEL_LOAD_ERROR = 'api.patient.update.modelLoadError';
    const PATIENT_UPDATE_MODEL_VALIDATE_ERROR = 'api.patient.update.modelValidateError';
    const PATIENT_UPDATE_MODEL_SAVE_ERROR = 'api.patient.update.modelSaveError';
    const PATIENT_UPDATE_SUCCESS = 'api.patient.update.success';

    const PATIENT_MODEL_LOAD_ERROR = 'app.patient.modelLoadError';
    const PATIENT_MODEL_SAVE_ERROR = 'app.patient.modelSaveError';

    const PATIENT_CARD_NOT_FOUND = 'app.patient.card.notFound';
    const PATIENT_CARD_EXISTS = 'app.patient.card.alreadyExists';
    const PATIENT_CARD_UNKNOWN_DIABETES_TYPE = 'app.patient.card.unknownDiabetesType';
    const PATIENT_CARD_UNKNOWN_MKB = 'app.patient.card.unknownMkb';
    const PATIENT_CARD_MKB_DOESNT_MATCH_WITH_DIABETES_TYPE = 'app.patient.card.mkbDoesntMatchWithDiabetesType';
    const PATIENT_CARD_AIM_AD_EMPTY = 'app.patient.card.aim.ad.empty';
    const PATIENT_CARD_AIM_GLUCOSE_PREPRANDIAL_EMPTY = 'app.patient.card.aim.glucosePreprandial.empty';
    const PATIENT_CARD_AIM_GLUCOSE_POSTPRANDIAL_EMPTY = 'app.patient.card.aim.glucosePostprandial.empty';

    const PATIENT_CARD_CREATE_MODEL_LOAD_ERROR = 'app.patient.card.create.modelLoadError';
    const PATIENT_CARD_CREATE_MODEL_VALIDATE_ERROR = 'app.patient.card.create.modelValidateError';
    const PATIENT_CARD_CREATE_MODEL_SAVE_ERROR = 'app.patient.card.create.modelSaveError';
    const PATIENT_CARD_CREATE_SUCCESS = 'app.patient.card.create.success';

    const PATIENT_CARD_MODEL_LOAD_ERROR = 'app.patient.card.modelLoadError';
    const PATIENT_CARD_MODEL_VALIDATE_ERROR = 'app.patient.card.modelValidateError';
    const PATIENT_CARD_MODEL_SAVE_ERROR = 'app.patient.card.modelSaveError';
    const PATIENT_CARD_SUCCESS = 'app.patient.card.success';

    const PATIENT_CARD_UPDATE_MODEL_LOAD_ERROR = 'app.patient.card.update.modelLoadError';
    const PATIENT_CARD_UPDATE_MODEL_VALIDATE_ERROR = 'app.patient.card.update.modelValidateError';
    const PATIENT_CARD_UPDATE_MODEL_SAVE_ERROR = 'app.patient.card.update.modelSaveError';
    const PATIENT_CARD_UPDATE_SUCCESS = 'app.patient.card.update.success';

    const PATIENT_ARTERIAL_PRESSURE_CREATE_MODEL_LOAD_ERROR = 'app.patient.arterialPressure.create.modelLoadError';
    const PATIENT_ARTERIAL_PRESSURE_CREATE_MODEL_VALIDATE_ERROR = 'app.patient.arterialPressure.create.modelValidateError';
    const PATIENT_ARTERIAL_PRESSURE_CREATE_MODEL_SAVE_ERROR = 'app.patient.arterialPressure.create.modelSaveError';
    const PATIENT_ARTERIAL_PRESSURE_CREATE_SUCCESS = 'app.patient.arterialPressure.create.success';

    const PATIENT_GLUCOSE_CREATE_MODEL_LOAD_ERROR = 'app.patient.glucose.create.modelLoadError';
    const PATIENT_GLUCOSE_CREATE_MODEL_VALIDATE_ERROR = 'app.patient.glucose.create.modelValidateError';
    const PATIENT_GLUCOSE_CREATE_MODEL_SAVE_ERROR = 'app.patient.glucose.create.modelSaveError';
    const PATIENT_GLUCOSE_CREATE_SUCCESS = 'app.patient.glucose.create.success';

    const USER_LOGIN_INCORRECT_LOGIN_OR_PASSWORD = 'app.user.login.incorrectLoginOrPassword';

    const PATIENT_EVENT_CREATE_MODEL_LOAD_ERROR = 'app.patient.event.create.modelLoadError';
    const PATIENT_EVENT_CREATE_MODEL_VALIDATE_ERROR = 'app.patient.event.create.modelValidateError';
    const PATIENT_EVENT_CREATE_MODEL_ID_DOESNT_MATCH_TO_URL = 'app.patient.event.create.modelIdDoesntMatchToUrl';
    const PATIENT_EVENT_CREATE_MODEL_SAVE_ERROR = 'app.patient.event.create.modelSaveError';
    const PATIENT_EVENT_CREATE_SUCCESS = 'app.patient.event.create.success';

    const PATIENT_EVENT_CREATE_PATIENT_LOAD_ERROR = 'app.patient.event.create.patientLoadError';
    const PATIENT_EVENT_CREATE_PATIENT_SAVE_ERROR = 'app.patient.event.create.patientSaveError';
    const PATIENT_EVENT_CREATE_HOSPITAL_MODEL_LOAD_ERROR = 'app.patient.event.create.hospitalModelLoadError';

    const HOSPITAL_MODEL_LOAD_ERROR = 'app.hospital.modelLoadError';

    const EVENT_NOT_FOUND = 'app.event.notFound';
    const EVENT_STATUS_IS_IN_WORK = 'app.event.statusIsInWork';
    const EVENT_STATUS_IS_DELETED = 'app.event.statusIsDeleted';
    const EVENT_PRIORITY_IS_NOT_HIGH = 'app.event.priorityIsNotHigh';
    const EVENT_MODEL_LOAD_ERROR = 'app.event.modelLoadError';
    const EVENT_MODEL_VALIDATE_ERROR = 'app.event.modelValidateError';
    const EVENT_MODEL_SAVE_ERROR = 'app.event.modelSaveError';

    const REGISTRY_LIST_OF_EVENT_EXISTS = 'app.registryListOfEvent.alreadyExists';
    const REGISTRY_LIST_OF_EVENT_CREATE_MODEL_LOAD_ERROR = 'app.registryListOfEvent.modelLoadError';
    const REGISTRY_LIST_OF_EVENT_CREATE_MODEL_VALIDATE_ERROR = 'app.registryListOfEvent.modelValidateError';
    const REGISTRY_LIST_OF_EVENT_CREATE_MODEL_SAVE_ERROR = 'app.registryListOfEvent.modelSaveError';
    const REGISTRY_LIST_OF_EVENT_CREATE_SUCCESS = 'app.registryListOfEvent.success';

    const CLASSIFIER_COMMENT_REQUIRED = 'app.registryListOfEvent.classifierComment.required';

    const USER_NOT_FOUND = 'app.user.notFound';
    const USER_MODEL_VALIDATE_ERROR = 'app.user.modelValidateError';
    const USER_MODEL_SAVE_ERROR = 'app.user.modelSaveError';

    const DISPATCHER_WORKING_STATUS_ALREADY_PAUSED = 'app.user.dispatcherWorkingStatusAlreadyPaused';
    const DISPATCHER_WORKING_STATUS_IS_PAUSED = 'app.user.dispatcherWorkingStatusIsPaused';
}
```

## api/components/exceptions/InternalServerErrorException.php
```php
<?php

namespace api\components\exceptions;

use yii\base\Model;

class InternalServerErrorException extends CustomHttpException
{
    public function __construct($message = null, $code = 0, $previous = null)
    {
        parent::__construct(500, $message, $code, $previous);
    }
}
```

## api/components/exceptions/CustomHttpException.php
```php
<?php

namespace api\components\exceptions;

use yii\base\Model;
use yii\web\HttpException;

class CustomHttpException extends HttpException
{
    private $model = null;

    public function getModel()
    {
        return $this->model;
    }

    public function setModel(Model $model): void
    {
        $this->model = $model;
    }

    public function getErrors(): array
    {
        if ($this->model instanceof Model) return $this->model->getErrors();
        return [];
    }
}
```

## api/components/exceptions/UnprocessableContentException.php
```php
<?php

namespace api\components\exceptions;

use yii\base\Model;

class UnprocessableContentException extends CustomHttpException
{
    public function __construct($message = null, $code = 0, $previous = null)
    {
        parent::__construct(422, $message, $code, $previous);
    }
}
```

## api/components/ApiResponse.php
```php
<?php

namespace api\components;

use api\components\exceptions\CustomHttpException;
use Exception;
use Yii;
use yii\helpers\ArrayHelper;
use yii\web\HttpException;

/**
 *
 * @property string|null $message
 * @property array $data
 * @property array|null $errors
 * @property array|null $request
 * @property string $file
 * @property string $line
 * @property string $trace
 * @property array $response
 * @property array $debugResponse
 *
 * @property CustomHttpException|HttpException|Exception| $exception = null;

 *
 * */
class ApiResponse
{
    public $message = null;
    public array $data = [];
    public $errors = null;
    public $request;
    public string $file;
    public string $line;
    public string $trace;

    private ?Exception $exception = null;

    public function __construct($message = null, array $data = [], $errors = null)
    {
        $this->message = $message;
        $this->data = $data;
        $this->errors = $errors;
    }

    public function get(): array
    {
        Yii::$app->response->setStatusCode($this->getResponseStatusCode());

        if (YII_DEBUG === true)
            return ArrayHelper::merge($this->getResponse(), $this->getDebugResponse());

        return $this->getResponse();
    }

    public function getAndLog(): array
    {
        Yii::$app->response->setStatusCode($this->getResponseStatusCode());

        $this->log();

        if (YII_DEBUG === true)
            return ArrayHelper::merge($this->getResponse(), $this->getDebugResponse());

        return $this->getResponse();
    }

    protected function getResponse(): array
    {
        return [
            'message' => $this->getResponseMessage(),
            'data' => $this->data,
            'errors' => $this->getErrors(),
            'request' => Yii::$app->request->getBodyParams(),
        ];
    }

    protected function getDebugResponse(): array
    {
        return $this->exception instanceof Exception
            ? [
                'file' => $this->exception->getFile(),
                'line' => $this->exception->getLine(),
                'trace' => $this->exception->getTraceAsString(),
            ]
            : [];
    }

    protected function getResponseStatusCode(): string
    {
        if ($this->exception instanceof HttpException) {
            return $this->exception->statusCode;
        } else if ($this->exception instanceof Exception) {
            return 500;
        }
        return 200;
    }

    protected function getResponseMessage()
    {
        if (empty($this->message) && $this->exception instanceof Exception)
            $this->message = $this->exception->getMessage();

        return $this->message;
    }

    protected function getErrors()
    {
        if (empty($this->errors) && $this->exception instanceof CustomHttpException && !empty($this->exception->getModel())) {
            $this->errors = $this->exception->getModel()->getErrors();
        }

        return $this->errors;
    }

    public function setException(\Exception $e)
    {
        $this->exception = $e;
    }

    public function log()
    {
        $response = ArrayHelper::merge($this->getResponse(), $this->getDebugResponse());

        switch ($this->getResponseStatusCode()) {
            case 200:
                Yii::info($response, 'yii\web\HttpException');
                break;
            default:
                Yii::error($response, 'yii\web\HttpException');
        }
    }
}
```

## api/modules/v1/Module.php
```php
<?php

namespace api\modules\v1;

use Yii;
use yii\web\Response;

/**
 * api module definition class
 */
class Module extends \yii\base\Module
{
    public $controllerNamespace = 'api\modules\v1\controllers';

    public function init()
    {
        parent::init();

        Yii::$app->response->format = Response::FORMAT_JSON;
    }
}

```

## api/modules/v1/controllers/RegistryListOfEventController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\components\exceptions\UnprocessableContentException;
use common\models\Event;
use common\models\EventClassifier;
use common\models\EventStatus;
use common\models\RegistryListOfEvent;
use Exception;
use Yii;
use api\models\User;
use yii\db\ActiveQuery;
use yii\filters\AccessControl;
use yii\helpers\ArrayHelper;

class RegistryListOfEventController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'actions' => ['create', 'get-history-by-object-id'],
                    'matchCallback' => function ($rule, $action) {
                        return in_array(Yii::$app->user->identity->role, [ User::ROLE_DISPATCHER, User::ROLE_ADMIN]);
                    }
                ],
                [
                    'actions' => ['update'],
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return in_array(Yii::$app->user->identity->role, [User::ROLE_ADMIN]);
                    }
                ],
            ],
        ];

        return $behaviors;
    }

    public function actionCreate(int $eventId)
    {
        try {
            return $this->create($eventId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function actionUpdate(int $eventId)
    {
        try {
            return $this->update($eventId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(int $eventId): array
    {
        if (Yii::$app->user->identity->dispatcher_working_status === 'paused') {
            throw new InternalServerErrorException(ApiResponseMessage::DISPATCHER_WORKING_STATUS_IS_PAUSED);
        }

        $modelEvent = Event::find()
            ->joinWith('registryListOfEvent')
            ->where(['event.id' => $eventId])
            ->one();

        if (!$modelEvent) throw new InternalServerErrorException(ApiResponseMessage::EVENT_NOT_FOUND);
        if ($modelEvent->registryListOfEvent) throw new InternalServerErrorException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_EXISTS);

        $transaction = Yii::$app->db->beginTransaction();
        if ($modelEvent->classifier === EventClassifier::OTHER) {
            $modelEvent->classifier_comment = Yii::$app->request->post('classifier_comment');

            if (empty($modelEvent->classifier_comment)) {
                throw new InternalServerErrorException(ApiResponseMessage::CLASSIFIER_COMMENT_REQUIRED);
            }
        }

        $eventStatus = Yii::$app->request->post('event_status');
        $modelEvent->status = in_array($eventStatus, ['done', 'paused', 'in_work']) ? $eventStatus : $modelEvent->status;

        if ($modelEvent->validate() === false) {
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_VALIDATE_ERROR);
        }

        if ($modelEvent->save() === false) {
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_SAVE_ERROR);
        }

        $model = new RegistryListOfEvent();

        if (!$model->load(ArrayHelper::merge(Yii::$app->request->post(), [
            'event_id' => $modelEvent->id,
            'created_by' => Yii::$app->user->id,
        ]), '')) {
            throw new UnprocessableContentException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_CREATE_MODEL_LOAD_ERROR);
        }

        $model->castToTypeBoolean([
            'limited_mobility', 'doctor_appointment', 'telemedicine', 'doctor_alert',
            'calling_doctor_at_home', 'need_calling_an_ambulance'
        ]);

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $transaction->commit();
        return (new ApiResponse(null, $model->attributes))->getAndLog();
    }

    public function update(int $eventId): array
    {
        if (Yii::$app->user->identity->dispatcher_working_status === 'paused') {
            throw new InternalServerErrorException(ApiResponseMessage::DISPATCHER_WORKING_STATUS_IS_PAUSED);
        }

        $modelEvent = Event::find()
            ->joinWith('registryListOfEvent')
            ->where(['event.id' => $eventId])
            ->one();

        if (!$modelEvent) throw new InternalServerErrorException(ApiResponseMessage::EVENT_NOT_FOUND);

        $transaction = Yii::$app->db->beginTransaction();
        if ($modelEvent->classifier === EventClassifier::OTHER) {
            $modelEvent->classifier_comment = Yii::$app->request->post('classifier_comment');

            if (empty($modelEvent->classifier_comment)) {
                throw new InternalServerErrorException(ApiResponseMessage::CLASSIFIER_COMMENT_REQUIRED);
            }
        }

        $eventStatus = Yii::$app->request->post('event_status');
        $modelEvent->status = in_array($eventStatus, ['done', 'paused', 'in_work']) ? $eventStatus : $modelEvent->status;

        if ($modelEvent->validate() === false) {
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_VALIDATE_ERROR);
        }

        if ($modelEvent->save() === false) {
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_SAVE_ERROR);
        }

        $model = RegistryListOfEvent::findOne(['event_id' => $modelEvent->id]);

        if (!$model->load(Yii::$app->request->post(), '')) {
            throw new UnprocessableContentException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_CREATE_MODEL_LOAD_ERROR);
        }

        $model->castToTypeBoolean([
            'limited_mobility', 'doctor_appointment', 'telemedicine', 'doctor_alert',
            'calling_doctor_at_home', 'need_calling_an_ambulance'
        ]);

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::REGISTRY_LIST_OF_EVENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $transaction->commit();
        return (new ApiResponse(null, $model->attributes))->getAndLog();
    }
}


```

## api/modules/v1/controllers/UserController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use Yii;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;

class UserController extends BaseController
{
    public function actionGet()
    {
        return (new ApiResponse(null, ['user' => $this->filteredUserIdentity()]))->get();
    }

    private function filteredUserIdentity()
    {
        $except = ['auth_key', 'external_token', 'password_hash', 'password_reset_token', 'verification_token'];
        return array_filter(ArrayHelper::toArray(Yii::$app->user->identity), function ($key) use ($except) {
            return !in_array($key, $except);
        }, ARRAY_FILTER_USE_KEY);
    }
}
```

## api/modules/v1/controllers/PatientEventController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\components\exceptions\UnprocessableContentException;
use api\models\sppvr\PatientEvent;
use api\models\User;
use common\models\EventPriority;
use Exception;
use Yii;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;
use ZMQ;
use ZMQContext;

class PatientEventController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['authenticator']['class'] = HttpBearerAuth::class;
        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return Yii::$app->user->identity->role === User::ROLE_ADMIN;
                    }
                ],
            ],
        ];

        $behaviors['verbs'] = [
            'class' => VerbFilter::class,
            'actions' => [
                'create' => ['post'],
            ]
        ];

        return $behaviors;
    }

    public function actionCreate(int $patientExternalId)
    {
        try {
            return $this->create($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(int $patientExternalId): array
    {
        $model = new PatientEvent();
        $transaction = Yii::$app->db->beginTransaction();

        if (
            !$model->load(
                ArrayHelper::merge(Yii::$app->request->post(), [
                    'patient' => [
                        'id' => Yii::$app->request->get('patientExternalId'),
                        'cardData' => [
                            'patientExternalId' => Yii::$app->request->get('patientExternalId'),
                        ],
                    ]
                ]),
                ''
            )
        ) {
            $transaction->rollBack();

            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_LOAD_ERROR);
        }

        if (!$model->validate()) {
            $transaction->rollBack();

            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $transaction->rollBack();

            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $this->sendToZMQ($model);
        $transaction->commit();
        return (new ApiResponse(null, $model->attributes))->getAndLog();
    }

    private function sendToZMQ(PatientEvent $model)
    {
        // This is our new stuff
        $context = new ZMQContext();
        $socket = $context->getSocket(ZMQ::SOCKET_PUSH, 'my pusher');
        $socket->connect("tcp://localhost:5555");

        $socket->send(json_encode(['id' => 1000, 'priority' => EventPriority::HIGH]));
    }
}
```

## api/modules/v1/controllers/EventController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\components\exceptions\UnprocessableContentException;
use api\models\sppvr\PatientEvent;
use api\models\User;
use common\models\Card;
use common\models\DiabetesType;
use common\models\Event;
use common\models\EventClassifier;
use common\models\EventPriority;
use common\models\EventSearch;
use common\models\EventStatus;
use common\models\EventType;
use common\models\Mkb;
use common\models\Patient;
use common\models\PatientCondition;
use Exception;
use yii\helpers\ArrayHelper;
use yii\httpclient\Client;
use Yii;
use yii\db\ActiveQuery;
use yii\db\Expression;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;

class EventController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return in_array(Yii::$app->user->identity->role, [User::ROLE_DISPATCHER, User::ROLE_ADMIN]);
                    }
                ],
            ],
        ];

        return $behaviors;
    }

    public function actionLog()
    {
        $searchModel = new EventSearch();
        $dataProvider = $searchModel->search($this->request->queryParams['filters'] ?? [], $this->request->queryParams['route'] ?? 'home');

        return (new ApiResponse(
            null,
            [
                'events' => $dataProvider->allModels,
                'totalCount' => $dataProvider->pagination->totalCount,
                'pageCount' => $dataProvider->pagination->pageCount
            ]
        ))->get();
    }

    public function actionTakeInWork($eventId)
    {
        try {
            return $this->takeInWork($eventId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    private function takeInWork($eventId)
    {
        $model = Event::findOne($eventId);

        if (!$model)
            throw new InternalServerErrorException(ApiResponseMessage::EVENT_NOT_FOUND);

        if (Yii::$app->user->identity->dispatcher_working_status === 'paused') {
            throw new InternalServerErrorException(ApiResponseMessage::DISPATCHER_WORKING_STATUS_IS_PAUSED);
        }

        if ($model->status === EventStatus::DELETED)
            throw new InternalServerErrorException(ApiResponseMessage::EVENT_STATUS_IS_DELETED);

        if ($model->status === EventStatus::IN_WORK && $model->dispatcher_id_who_took_to_work !== Yii::$app->user->id)
            throw new InternalServerErrorException(ApiResponseMessage::EVENT_STATUS_IS_IN_WORK);

        if (!$model->load([
            'status' => EventStatus::IN_WORK,
            'dispatcher_id_who_took_to_work' => Yii::$app->user->id,
        ], '')) {
            $e = new UnprocessableContentException(ApiResponseMessage::EVENT_MODEL_LOAD_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::EVENT_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new UnprocessableContentException(ApiResponseMessage::EVENT_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(
            null,
            [],
        ))->get();
    }

    public function actionGet($eventId)
    {
        try {
            if (empty($event = $this->getEventById($eventId)))
                throw new InternalServerErrorException(ApiResponseMessage::EVENT_NOT_FOUND);

            return (new ApiResponse(
                null,
                $event
            ))->get();
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function actionClassifiers()
    {
        return (new ApiResponse(
            null,
            EventClassifier::find()
                ->select(['title', 'name'])
                ->where(['is_active' => true])
                ->indexBy('name')
                ->column()
        ))->get();
    }

    public function actionPriorities()
    {
        return (new ApiResponse(
            null,
            EventPriority::find()
                ->select(['title', 'name'])
                ->where(['is_active' => true])
                ->indexBy('name')
                ->column()
        ))->get();
    }

    public function actionTypes()
    {
        return (new ApiResponse(
            null,
            EventType::find()
                ->select(['title', 'name'])
                ->where(['is_active' => true])
                ->indexBy('name')
                ->column()
        ))->get();
    }

    public function actionPatientConditions()
    {
        return (new ApiResponse(
            null,
            PatientCondition::find()
                ->select(['title', 'name'])
                ->where(['is_active' => true])
                ->indexBy('name')
                ->column()
        ))->get();
    }

    public function actionDiabetesType()
    {
        return (new ApiResponse(
            null,
            DiabetesType::find()
                ->select(['name', 'id'])
                ->where(['is_enabled' => true])
                ->indexBy('id')
                ->column()
        ))->get();
    }

    public function actionMkbList()
    {
        return (new ApiResponse(
            null,
            Mkb::find()
                ->where(['is_enabled' => true])
                ->asArray()
                ->all()
        ))->get();
    }

    public function actionReferences()
    {
        return (new ApiResponse(
            null,
            [
                'classifiers' => EventClassifier::find()
                    ->select(['title', 'name'])
                    ->where(['is_active' => true])
                    ->indexBy('name')
                    ->column(),
                'priorities' => EventPriority::find()
                    ->select(['title', 'name'])
                    ->where(['is_active' => true])
                    ->indexBy('name')
                    ->column(),
                'types' => EventType::find()
                    ->select(['title', 'name'])
                    ->where(['is_active' => true])
                    ->indexBy('name')
                    ->column(),
                'patientConditions' => PatientCondition::find()
                    ->select(['title', 'name'])
                    ->where(['is_active' => true])
                    ->indexBy('name')
                    ->column(),
                'diabetesType' => DiabetesType::find()
                    ->select(['name', 'id'])
                    ->where(['is_enabled' => true])
                    ->indexBy('id')
                    ->column(),
                'mkbList' => Mkb::find()
                    ->where(['is_enabled' => true])
                    ->asArray()
                    ->all(),
            ]
        ))->get();
    }

    public function actionCreate()
    {
        try {
            return $this->create();
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(): array
    {
        switch (Yii::$app->request->post('event_type')) {
            case 'patient':
                return (new ApiResponse(null, $this->createPatientEvent()))->getAndLog();
            default:
                throw new Exception('Не удалось создать Событие и Учетный лист события для данного Типа события');
        }
    }

    private function createPatientEvent(): array
    {
        if (Yii::$app->user->identity->dispatcher_working_status === 'paused') {
            throw new InternalServerErrorException(ApiResponseMessage::DISPATCHER_WORKING_STATUS_IS_PAUSED);
        }

        $transaction = Yii::$app->db->beginTransaction();

        $modelPatient = Patient::findOne(['id' => (int) Yii::$app->request->post('patient_id')]);

        if (empty($modelPatient)) {
            $modelPatient = $this->createPatient();
        }

        $modelEvent = $this->createEvent($modelPatient);
        $transaction->commit();
        return $this->getEventById($modelEvent->id);
    }

    private function createPatient(): Patient
    {
        $model = new Patient(['scenario' => Patient::SCENARIO_API_CREATE_INTERNAL_PATIENT]);
        $data = [
            'last_name' => $this->explodeFullName(Yii::$app->request->post('full_name'))['last_name'],
            'first_name' => $this->explodeFullName(Yii::$app->request->post('full_name'))['first_name'],
            'patronymic' => $this->explodeFullName(Yii::$app->request->post('full_name'))['patronymic'],
            'phone' => Yii::$app->request->post('phone'),
            'birth_at' => Yii::$app->request->post('birthday'),
        ];

        if ( !$model->load($data, '') ) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_CREATE_MODEL_LOAD_ERROR);
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $this->createPatientCard($model);

        return $model;
    }

    private function createPatientCard(Patient $modelPatient)
    {
        $model = new Card(['scenario' => Card::SCENARIO_API_CREATE_INTERNAL_PATIENT]);
        $data = [
            'patient_id' => $modelPatient->id,
            'diabetes' => [
                'type' => Yii::$app->request->post('diabetes_type'),
                'first_identified' => Yii::$app->request->post('first_identified_diabetes', 'false') === 'true' ? 1 : 0,
                'manifest_year' => Yii::$app->request->post('manifest_year_diabetes'),
                'manifest_month' => Yii::$app->request->post('manifest_month_diabetes'),
                'insulin_requiring' => Yii::$app->request->post('insulin_requiring_diabetes', 'false') === 'true' ? 1 : 0,
                'insulin_method' => Yii::$app->request->post('insulin_method_diabetes'),
            ],
            'diagnosis' => [
                'mkb' => Yii::$app->request->post('diagnosis_mkb'),
            ],
        ];

        if ( !$model->load($data, '') ) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_CREATE_MODEL_LOAD_ERROR);
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return $model;
    }

    private function createEvent(Patient $modelPatient): Event
    {
        $model = new Event();

        if (
            !$model->load([
                'patient_id' => $modelPatient->id,
                'classifier' => Yii::$app->request->post('classifier'),
                'classifier_comment' => Yii::$app->request->post('classifier_comment'),
                'priority' => Yii::$app->request->post('event_priority'),
                'status' => Yii::$app->request->post('event_status', EventStatus::WAITING),
                'type' => EventType::PATIENT,
                'source' => 'routing',
                'is_system_event' => false,
                'dispatcher_id_who_took_to_work' => null,
                'compensation_stage' => Yii::$app->request->post('compensation_stage'),
                'diabetes_type' => Yii::$app->request->post('diabetes_type'),
                'mkb_id' => Yii::$app->request->post('diagnosis_mkb'),
                'insulin_requiring' => Yii::$app->request->post('insulin_requiring_diabetes', 'false') === 'true' ? true : false,
                'created_by' => (string) Yii::$app->user->id,
            ], '')
        ) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_LOAD_ERROR);
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_EVENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return $model;
    }

    private function explodeFullName(string $fullName)
    {
        $explode = [];
        preg_match(
            '#^(?<last_name>[а-яА-Я0-9\-\_\s]+)(?:\.|\s)(?<first_name>[а-яА-Я0-9\-\_]+)(?:\.|\s)(?<patronymic>[а-яА-Я0-9\-\_]+)\.?$#iu',
            trim($fullName),
            $match
        );

        foreach ([1 => 'last_name', 2 => 'first_name', 3 => 'patronymic'] as $index => $key) {
            $explode[$key] = $match[$key] ?? null;
        }
        return $explode;
    }

    private function getEventById($eventId)
    {
        return Event::find()
            ->where(['event.id' => $eventId])
            ->joinWith([
                'classifierRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title', 'external_id']);
                },
                'typeRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title']);
                },
                'statusRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title']);
                },
                'priorityRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title']);
                },
                'patient' => function (ActiveQuery $q) {
                    return $q->select([
                        'patient.id',
                        'patient.first_name',
                        'patient.last_name',
                        'patient.patronymic',
                        'patient.phone',
                        'patient.birth_at',
                        'to_char(patient.birth_at, \'DD.MM.YYYY\') as birth_at_formatted',
                        'patient.hospital_id',
                        'patient.external_id',
                        'concat_ws(\' \', patient.last_name, patient.first_name, patient.patronymic)  as full_name',
                    ])
                        ->joinWith([
                            'hospital' => function (ActiveQuery $q) {
                                return $q->select([
                                    'hospital.id',
                                    'hospital.name_short',
                                    'hospital.name_full',
                                ]);
                            },
                            'card'
                        ])->asArray();
                },
                'user' => function (ActiveQuery $q) {
                    return $q->alias('u')->select([
                        'u.id',
                        'u.first_name',
                        'u.last_name',
                        'u.patronymic',
                        'u.external_token',
                        'concat_ws(\' \', u.last_name, u.first_name, u.patronymic)  as full_name',
                    ]);
                },
                'dispatcherWhoTookToWork' => function (ActiveQuery $q) {
                    return $q->alias('dwttw')->select([
                        'dwttw.id',
                        'dwttw.first_name',
                        'dwttw.last_name',
                        'dwttw.patronymic',
                        'dwttw.external_token',
                        'concat_ws(\' \', dwttw.last_name, dwttw.first_name, dwttw.patronymic)  as full_name',
                    ]);
                },
                'registryListOfEvent' => function (ActiveQuery $q) {
                    return $q->alias('rloe')
                        ->joinWith([
                            'doctor' => function (ActiveQuery $q) {
                                return $q->select([
                                    'id', 'last_name', 'first_name', 'patronymic', 'phone',
                                    'TRIM(CONCAT_WS(\' \', last_name, first_name, patronymic)) as fullname'
                                ]);
                            },
                            'medicalInstitution' => function (ActiveQuery $q) {
                                return $q->select(['id', 'name_full', 'name_short']);
                            },
                            'medicalInstitutionUrgently' => function (ActiveQuery $q) {
                                return $q->select(['id', 'name_full', 'name_short']);
                            },
                            'patientCondition' => function (ActiveQuery $q) {
                                return $q->select(['name', 'title']);
                            },
                        ]);
                }
            ])
            ->asArray()
            ->one();
    }
}
```

## api/modules/v1/controllers/DateTimeController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\components\exceptions\UnprocessableContentException;
use api\models\User;
use common\models\DiabetesType;
use common\models\Event;
use common\models\EventClassifier;
use common\models\EventPriority;
use common\models\EventStatus;
use common\models\EventType;
use common\models\Mkb;
use common\models\PatientCondition;
use Exception;
use Yii;
use yii\db\ActiveQuery;
use yii\db\Expression;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;

class DateTimeController extends BaseController
{
    public function actionCurrentTimestamp()
    {
        return (new ApiResponse(
            null,
            [
                'timestamp' => (new \DateTime())->getTimestamp()
            ]
        ))->get();
    }
}
```

## api/modules/v1/controllers/PatientController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\models\User;
use common\models\EventStatus;
use common\models\RegistryListOfEvent;
use Exception;
use Yii;
use api\resources\Patient;
use api\components\exceptions\UnprocessableContentException;
use yii\db\ActiveQuery;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;

class PatientController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['authenticator']['class'] = HttpBearerAuth::class;
        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return Yii::$app->user->identity->role === User::ROLE_ADMIN;
                    }
                ],
            ],
        ];

        $behaviors['verbs'] = [
            'class' => VerbFilter::class,
            'actions' => [
                'create' => ['post'],
                'update' => ['put', 'patch'],
            ]
        ];

        return $behaviors;
    }

    public function actionCreate()
    {
        try {
            return $this->create();
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(): array
    {
        if (Patient::findOne(['external_id' => Yii::$app->request->post('id')]))
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_ALREADY_EXISTS);

        $model = new Patient(['scenario' => \common\models\Patient::SCENARIO_API_CREATE]);

        if (!$model->load(Yii::$app->request->post(), '')) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_CREATE_MODEL_LOAD_ERROR);
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(ApiResponseMessage::PATIENT_CREATE_SUCCESS, array_merge(
            $model->toArray(),
            [
                'hospital' => $model->hospital,
            ],
        )))->getAndLog();
    }

    public function actionUpdate(int $patientExternalId)
    {
        try {
            return $this->update($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function update(int $patientExternalId): array
    {
        $model = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($model)) return $this->create();

        $model->scenario = \common\models\Patient::SCENARIO_API_UPDATE;

        if (!$model->load(Yii::$app->request->post(), '')) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_UPDATE_MODEL_LOAD_ERROR);
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_UPDATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_UPDATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(ApiResponseMessage::PATIENT_UPDATE_SUCCESS, array_merge(
            $model->toArray(),
            [
                'hospital' => $model->hospital,
            ],
        )))->getAndLog();
    }

    public function actionSearch(string $fullName)
    {
        return (new ApiResponse(
            null,
            Patient::find()
                ->alias('p')
                ->select([
                    'p.id',
                    'last_name',
                    'first_name',
                    'patronymic',
                    'p.phone',
                    'birth_at',
                    'TO_CHAR(birth_at, \'DD.MM.YYYY\') as birth_at_formatted',
                    'hospital_id',
                    'TRIM(CONCAT_WS(\' \', last_name, first_name, patronymic)) as fullname',
                    'TRIM(CONCAT_WS(\' \', last_name, first_name, patronymic, TO_CHAR(birth_at, \'DD.MM.YYYY\'))) as fullname_with_birthdate'
                ])
                ->andFilterWhere(['ilike', 'CONCAT_WS(\' \', last_name, first_name, patronymic)', $fullName])
                ->joinWith([
                    'hospital' => function (ActiveQuery $q) {
                        return $q->select([
                            'hospital.id',
                            'hospital.name_short',
                            'hospital.name_full',
                        ]);
                    },
                    'card'
                ])
                ->limit(30)
                ->asArray()
                ->all()
        ))->get();
    }

    public function actionGetRegistryHistoryByEventInitiatorId($eventInitiatorExternalId, string $currentEventId)
    {
        return (new ApiResponse(
            null,
            RegistryListOfEvent::find()
                ->joinWith([
                    'event' => function (ActiveQuery $q) use ($eventInitiatorExternalId) {
                        return $q->select([
                            'id',
                            'user_id',
                            'patient_id',
                            'classifier',
                            'classifier_comment',
                            'priority',
                            'type',
                            'status',
                            'taking_to_work_at',
                            'dispatcher_id_who_took_to_work',
                            'compensation_stage',
                            'diabetes_type',
                            'insulin_requiring',
                            'created_at',
                            'updated_at',
                        ]);
                    },
                ])
                ->where(['event.patient_id' => $eventInitiatorExternalId])
                ->andWhere(['<>', 'event.id', $currentEventId])
                ->andFilterWhere(['event.status' => EventStatus::DONE])
                ->all()
        ))->get();
    }

}
```

## api/modules/v1/controllers/HospitalController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\models\User;
use common\models\Hospital;

class HospitalController extends BaseController
{
    public function actionSearch(string $name)
    {
        return (new ApiResponse(
            null,
            Hospital::find()
                ->select([
                    'id',
                    'name_short',
                    'name_full',
                    'address_text',
                    'phone',
                ])
                ->where([
                    'or',
                    ['ilike', 'name_short', $name],
                    ['ilike', 'name_full', $name],
                ])
                ->limit(30)
                ->asArray()
                ->all()
        ))->get();
    }
}
```

## api/modules/v1/controllers/PatientArterialPressureController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use common\models\MonitoringArterialPressure;
use Exception;
use Yii;
use api\models\User;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;
use api\resources\Patient;
use api\components\exceptions\UnprocessableContentException;

class PatientArterialPressureController extends BaseController
{
    public function behaviors()
    {

        $behaviors = parent::behaviors();

        $behaviors['authenticator']['class'] = HttpBearerAuth::class;
        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return Yii::$app->user->identity->role === User::ROLE_ADMIN;
                    }
                ],
            ],
        ];



        $behaviors['verbs'] = [
            'class' => VerbFilter::class,
            'actions' => [
                'index' => ['get'],
                'create' => ['post'],
            ]
        ];
        return $behaviors;
    }

    public function actionIndex(int $patientExternalId)
    {
        try {
            return $this->index($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function index(int $patientExternalId): array
    {
        $model = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($model)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (empty($model->card)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_NOT_FOUND);

        return (new ApiResponse(null, $model->arterialPressure))->getAndLog();
    }

    public function actionCreate(int $patientExternalId)
    {
        try {
            return $this->create($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(int $patientExternalId): array
    {
        $patientModel = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($patientModel)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (empty($patientModel->card)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_NOT_FOUND);

        $model = new MonitoringArterialPressure();

        if (!$model->load(array_merge(Yii::$app->request->post(), compact('patientExternalId')), '')) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_ARTERIAL_PRESSURE_CREATE_MODEL_LOAD_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_ARTERIAL_PRESSURE_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_ARTERIAL_PRESSURE_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(ApiResponseMessage::PATIENT_ARTERIAL_PRESSURE_CREATE_SUCCESS, ArrayHelper::merge(
            $model->toArray(), []
        )))->getAndLog();
    }
}
```

## api/modules/v1/controllers/AuthController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\models\ApiLoginForm;
use Exception;
use Yii;
use yii\filters\auth\HttpBearerAuth;
use yii\helpers\ArrayHelper;

class AuthController extends BaseController
{
    public function behaviors()
    {
        return ArrayHelper::merge(parent::behaviors(), [
            'authenticator' => [
                'except' => ['login'],
            ],
        ]);
    }

    public function actionLogin()
    {
        try {
            return $this->login();
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function login(): array
    {
        $model = new ApiLoginForm();
        if (!$model->load(Yii::$app->request->post(), '') || !$model->login()) {
            $e = new InternalServerErrorException(ApiResponseMessage::USER_LOGIN_INCORRECT_LOGIN_OR_PASSWORD);
            $e->setModel($model);
            throw $e;
        }

        $model->password = '';

        return (new ApiResponse(null, ['accessToken' => $model->getUser()->external_token]))->getAndLog();
    }
}
```

## api/modules/v1/controllers/FakeApiController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use Exception;
use Yii;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;
use yii\rest\Controller;

class FakeApiController extends Controller
{
    public function behaviors()
    {
        return [
            'verbs' => [
                'class' => VerbFilter::className(),
                'actions' => [
                    'patient-card-diabetes' => ['get'],
                ],
            ]
        ];
    }

    public function actionPatientCardDiabetes()
    {
        try {
            return $this->patientCardDiabetes();
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function patientCardDiabetes(): array
    {
        return (new ApiResponse(
            null,
            json_decode('{
              "diabetes": {
                "type": "1",
                "disability": "2",
                "monitoring": [
                  "2"
                ],
                "hba1c_level": "9.3",
                "manifest_year": "2008",
                "insulin_method": "0",
                "manifest_month": "0",
                "first_identified": "0",
                "insulin_requiring": "0"
              },
              "diagnosis": {
                "mkb": "14"
              }
        }', 1)
        ))->get();
    }

}
```

## api/modules/v1/controllers/PatientMkbController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\models\User;
use Exception;
use Yii;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;
use api\resources\Patient;

class PatientMkbController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['authenticator']['class'] = HttpBearerAuth::class;
        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return Yii::$app->user->identity->role === User::ROLE_ADMIN;
                    }
                ],
            ],
        ];

        $behaviors['verbs'] = [
            'class' => VerbFilter::class,
            'actions' => [
                'index' => ['get'],
            ]
        ];

        return $behaviors;
    }

    public function actionView(int $patientExternalId)
    {
        try {
            return $this->view($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }


    public function view(int $patientExternalId): array
    {
        $model = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($model)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (empty($model->card)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_NOT_FOUND);

        if (empty(($diabetesType = $model->card->diabetesType))) {
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_UNKNOWN_DIABETES_TYPE);
        }

        if (empty(($mkb = $model->card->mkb))) {
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_UNKNOWN_MKB);
        }

        return (new ApiResponse(null, [
            'diabetes' => [
                'type' => ArrayHelper::getValue($model, 'card.diabetes.type'),
                'name' => ArrayHelper::getValue($diabetesType, 'name'),
            ],
            'diagnosis' => [
                'mkb' => ArrayHelper::getValue($model, 'card.diagnosis.mkb'),
                'name' => ArrayHelper::getValue($mkb, 'name'),
            ],
        ]))->getAndLog();
    }

}
```

## api/modules/v1/controllers/PatientCardController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\models\User;
use common\models\Card;
use common\models\DiabetesType;
use common\models\Mkb;
use Exception;
use Yii;
use api\resources\Patient;
use api\components\exceptions\UnprocessableContentException;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;

class PatientCardController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['authenticator']['class'] = HttpBearerAuth::class;
        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return Yii::$app->user->identity->role === User::ROLE_ADMIN;
                    }
                ],
            ],
        ];

        $behaviors['verbs'] = [
            'class' => VerbFilter::class,
            'actions' => [
                'index' => ['get'],
                'create' => ['post'],
                'update' => ['put', 'patch'],
            ]
        ];

        return $behaviors;
    }

    public function actionView(int $patientExternalId)
    {
        try {
            return $this->view($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function view(int $patientExternalId): array
    {
        $patientModel = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($patientModel))
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (empty($model = Card::findOne(['patient_id' => $patientModel->id])))
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_NOT_FOUND);
        $model->patientExternalId = $patientExternalId;
        $model->updateByApi();
        return (new ApiResponse(null, $model->toArray()))->getAndLog();
    }

    public function actionCreate(int $patientExternalId)
    {
        try {
            return $this->create($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(int $patientExternalId): array
    {
        $patientModel = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($patientModel))
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (!empty($patientModel->card))
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_EXISTS);

        $model = new Card(['scenario' => Card::SCENARIO_API_CREATE]);

        $post = Yii::$app->request->post();

        $externalDiabetesTypeId = ArrayHelper::getValue($post, 'diabetes.typeExternal');
        $externalMkbId = ArrayHelper::getValue($post, 'diagnosis.mkbExternal');

        $cardDiagnosisMkb = Mkb::find()
            ->alias('m')
            ->select('
                m.id as mkb_id,
                m.name as mkb_name,
                dt.id as diabetes_type_id,
                dt.external_id as diabetes_type_external_id,
                dt."name" as diabetes_type_name
            ')
            ->innerJoin('diabetes_type dt', 'dt.id = m.diabetes_type_id')
            ->where(['m.external_id' => $externalMkbId, 'dt.external_id' => $externalDiabetesTypeId])
            ->asArray()
            ->one();

        if (empty($cardDiagnosisMkb)) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_MKB_DOESNT_MATCH_WITH_DIABETES_TYPE);
            $e->setModel($model);
            throw $e;
        }

        $post['diabetes']['type'] = ArrayHelper::getValue($cardDiagnosisMkb, 'diabetes_type_id');
        $post['diagnosis']['mkb'] = ArrayHelper::getValue($cardDiagnosisMkb, 'mkb_id');

        if (!$model->load(array_merge($post, compact('patientExternalId')), '')) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_CREATE_MODEL_LOAD_ERROR);
        }

        $model->patient_id = $model->patientByExternalId->id ?? null;

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(ApiResponseMessage::PATIENT_CARD_CREATE_SUCCESS, $model->toArray()))->getAndLog();
    }

    public function actionUpdate(int $patientExternalId)
    {
        try {
            return $this->update($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function update(int $patientExternalId): array
    {
        $patientModel = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($patientModel))
            throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);

        if (empty($model = $patientModel->card)) return $this->create($patientExternalId);

        $model->scenario = \common\models\Card::SCENARIO_API_UPDATE;
        $post = Yii::$app->request->post();

        $externalDiabetesTypeId = ArrayHelper::getValue($post, 'diabetes.typeExternal');
        $externalMkbId = ArrayHelper::getValue($post, 'diagnosis.mkbExternal');

        $cardDiagnosisMkb = Mkb::find()
            ->alias('m')
            ->select('
                m.id as mkb_id,
                m.name as mkb_name,
                dt.id as diabetes_type_id,
                dt.external_id as diabetes_type_external_id,
                dt."name" as diabetes_type_name
            ')
            ->innerJoin('diabetes_type dt', 'dt.id = m.diabetes_type_id')
            ->where(['m.external_id' => $externalMkbId, 'dt.external_id' => $externalDiabetesTypeId])
            ->asArray()
            ->one();

        if (empty($cardDiagnosisMkb)) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_MKB_DOESNT_MATCH_WITH_DIABETES_TYPE);
            $e->setModel($model);
            throw $e;
        }

        $post['diabetes']['type'] = ArrayHelper::getValue($cardDiagnosisMkb, 'diabetes_type_id');
        $post['diagnosis']['mkb'] = ArrayHelper::getValue($cardDiagnosisMkb, 'mkb_id');

        if (!$model->load(array_merge($post, compact('patientExternalId')), '')) {
            throw new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_UPDATE_MODEL_LOAD_ERROR);
        }


        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_UPDATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_UPDATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(ApiResponseMessage::PATIENT_CARD_UPDATE_SUCCESS, $model->toArray()))->getAndLog();
    }
}
```

## api/modules/v1/controllers/DoctorController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\models\User;
use common\models\EventStatus;
use common\models\RegistryListOfEvent;
use yii\db\ActiveQuery;

class DoctorController extends BaseController
{
    public function actionSearch(string $fullName)
    {
        return (new ApiResponse(
            null,
            User::find()
                ->select([
                    'id',
                    'last_name',
                    'first_name',
                    'patronymic',
                    'phone',
                    'TRIM(CONCAT_WS(\' \', last_name, first_name, patronymic)) as fullname'
                ])
                ->where([
                    'role' => User::ROLE_DOCTOR,
                ])
                ->andFilterWhere(['ilike', 'CONCAT_WS(\' \', last_name, first_name, patronymic)', $fullName])
                ->limit(30)
                ->asArray()
                ->all()
        ))->get();
    }

    public function actionGetRegistryHistoryByEventInitiatorId($eventInitiatorExternalId, string $currentEventId)
    {
        return (new ApiResponse(
            null,
            RegistryListOfEvent::find()
                ->joinWith([
                    'event' => function (ActiveQuery $q) use ($eventInitiatorExternalId) {
                        return $q->select([
                            'id',
                            'user_id',
                            'patient_id',
                            'classifier',
                            'classifier_comment',
                            'priority',
                            'type',
                            'status',
                            'taking_to_work_at',
                            'dispatcher_id_who_took_to_work',
                            'compensation_stage',
                            'diabetes_type',
                            'insulin_requiring',
                            'created_at',
                            'updated_at',
                        ]);
                    },
                ])
                ->where(['event.user_id' => $eventInitiatorExternalId])
                ->andWhere(['<>', 'event.id', $currentEventId])
                ->andFilterWhere(['event.status' => EventStatus::DONE])
                ->all()
        ))->get();
    }

}
```

## api/modules/v1/controllers/BaseController.php
```php
<?php

namespace api\modules\v1\controllers;

use yii\filters\auth\HttpBearerAuth;
use yii\filters\Cors;
use yii\helpers\ArrayHelper;
use yii\rest\Controller;

class BaseController extends Controller
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();
        $behaviors['authenticator'] = [
            'class' => HttpBearerAuth::class,
            'except' => ['options'],
        ];

        return ArrayHelper::merge([
            'corsFilter' => [
                'class' => Cors::class,
                'cors' => [
                    'Origin' => [
                        'https://localhost', 'https://127.0.0.1',
                        'https://routing.ru',
                        'https://185.104.107.24', 'https://routing-diabet.ru'
                    ],
                    'Access-Control-Request-Method' => [
                        'GET',
                        'POST',
                        'PUT', 'PATCH',
                        'DELETE',
                        'HEAD',
                        'OPTIONS'
                    ],
                    'Access-Control-Request-Headers' => ['*'],
                    'Access-Control-Allow-Credentials' => true,
                    'Access-Control-Max-Age' => 86400,
                ]
            ],
        ], $behaviors);
    }
}
```

## api/modules/v1/controllers/DispatcherController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\components\exceptions\UnprocessableContentException;
use api\models\User;
use common\models\DispatcherWorkingStatus;
use common\models\Event;
use common\models\EventStatus;
use common\models\RegistryListOfEvent;
use Exception;
use Yii;
use yii\db\ActiveQuery;

class DispatcherController extends BaseController
{
    public function actionSearch(string $fullName)
    {
        return (new ApiResponse(
            null,
            User::find()
                ->select([
                    'id',
                    'last_name',
                    'first_name',
                    'patronymic',
                    'phone',
                    'TRIM(CONCAT_WS(\' \', last_name, first_name, patronymic)) as fullname'
                ])
                ->where([
                    'role' => User::ROLE_DISPATCHER,
                ])
                ->andFilterWhere(['ilike', 'CONCAT_WS(\' \', last_name, first_name, patronymic)', $fullName])
                ->limit(30)
                ->asArray()
                ->all()
        ))->get();
    }

    public function actionGetRegistryHistoryByEventInitiatorId($eventInitiatorExternalId, string $currentEventId)
    {
        return (new ApiResponse(
            null,
            RegistryListOfEvent::find()
                ->joinWith([
                    'event' => function (ActiveQuery $q) use ($eventInitiatorExternalId) {
                        return $q->select([
                            'id',
                            'user_id',
                            'patient_id',
                            'classifier',
                            'classifier_comment',
                            'priority',
                            'type',
                            'status',
                            'taking_to_work_at',
                            'dispatcher_id_who_took_to_work',
                            'compensation_stage',
                            'diabetes_type',
                            'insulin_requiring',
                            'created_at',
                            'updated_at',
                        ]);
                    },
                ])
                ->where(['event.user_id' => $eventInitiatorExternalId])
                ->andWhere(['<>', 'event.id', $currentEventId])
                ->andFilterWhere(['event.status' => EventStatus::DONE])
                ->all()
        ))->get();
    }

    public function actionDispatcherWorkingStatus()
    {
        try {
            return $this->updateDispatcherWorkingStatus();
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    protected function updateDispatcherWorkingStatus()
    {
        $dispatcher = \common\models\User::findOne(Yii::$app->user->id);
        if (empty($dispatcher)) throw new InternalServerErrorException(ApiResponseMessage::USER_NOT_FOUND);

        $dispatcher->dispatcher_working_status = Yii::$app->request->post('status');

        if (!$dispatcher->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::USER_MODEL_VALIDATE_ERROR);
            $e->setModel($dispatcher);
            throw $e;
        }

        if (!$dispatcher->save()) {
            $e = new UnprocessableContentException(ApiResponseMessage::USER_MODEL_SAVE_ERROR);
            $e->setModel($dispatcher);
            throw $e;
        }

        $pausedDispatchersEventsCount = 0;

        if (Yii::$app->request->post('pauseEventEither', false) === true) {
            $pausedDispatchersEventsCount = Event::updateAll([
                'status' => EventStatus::PAUSED
            ], [
                'dispatcher_id_who_took_to_work' => Yii::$app->user->id,
                'status' => EventStatus::IN_WORK
            ]);
        }

        return (new ApiResponse(
            null,
            [
                'dispatcherWorkingStatus' => $dispatcher->dispatcher_working_status,
                'pausedDispatchersEventsCount' => $pausedDispatchersEventsCount
            ]
        ));
    }
}
```

## api/modules/v1/controllers/PatientGlucoseController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\models\User;
use common\models\MonitoringGlucose;
use Exception;
use Yii;
use yii\filters\AccessControl;
use yii\filters\auth\HttpBearerAuth;
use yii\filters\VerbFilter;
use yii\helpers\ArrayHelper;
use api\resources\Patient;
use api\components\exceptions\UnprocessableContentException;

class PatientGlucoseController extends BaseController
{
    public function behaviors()
    {
        $behaviors = parent::behaviors();

        $behaviors['authenticator']['class'] = HttpBearerAuth::class;
        $behaviors['access'] = [
            'class' => AccessControl::class,
            'rules' => [
                [
                    'allow' => true,
                    'matchCallback' => function ($rule, $action) {
                        return Yii::$app->user->identity->role === User::ROLE_ADMIN;
                    }
                ],
            ],
        ];

        $behaviors['verbs'] = [
            'class' => VerbFilter::class,
            'actions' => [
                'index' => ['get'],
                'create' => ['post'],
            ]
        ];

        return $behaviors;
    }

    public function actionIndex(int $patientExternalId)
    {
        try {
            return $this->index($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function index(int $patientExternalId): array
    {
        $model = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($model)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (empty($model->card)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_NOT_FOUND);

        return (new ApiResponse(null, $model->glucose))->getAndLog();
    }

    public function actionCreate(int $patientExternalId)
    {
        try {
            return $this->create($patientExternalId);
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            return $response->getAndLog();
        }
    }

    public function create(int $patientExternalId): array
    {
        $patientModel = Patient::findOne(['external_id' => $patientExternalId]);

        if (empty($patientModel)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_NOT_FOUND);
        if (empty($patientModel->card)) throw new InternalServerErrorException(ApiResponseMessage::PATIENT_CARD_NOT_FOUND);

        $model = new MonitoringGlucose();

        if (!$model->load(array_merge(Yii::$app->request->post(), compact('patientExternalId')), '')) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_GLUCOSE_CREATE_MODEL_LOAD_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->validate()) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_GLUCOSE_CREATE_MODEL_VALIDATE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if (!$model->save()) {
            $e = new InternalServerErrorException(ApiResponseMessage::PATIENT_GLUCOSE_CREATE_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return (new ApiResponse(ApiResponseMessage::PATIENT_GLUCOSE_CREATE_SUCCESS, ArrayHelper::merge(
            $model->toArray(), []
        )))->getAndLog();
    }
}
```

## api/modules/v1/controllers/HospitalUrgentController.php
```php
<?php

namespace api\modules\v1\controllers;

use api\components\ApiResponse;
use api\models\User;
use common\models\Hospital;

class HospitalUrgentController extends BaseController
{
    public function actionSearch(string $query)
    {
        return (new ApiResponse(
            null,
            Hospital::find()
                ->select([
                    'id',
                    'name_short',
                    'name_full',
                    'address_text',
                    'phone',
                ])
                ->where([
                    'or',
                    ['ilike', 'name_short', $query],
                    ['ilike', 'name_full', $query],
                ])
                ->limit(30)
                ->asArray()
                ->all()
        ))->get();
    }
}
```

## common/models/DiabetesType.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "public.diabetes_type".
 *
 * @property int $id
 * @property string $name
 * @property string $type
 * @property int $external_id
 * @property bool $is_enabled
 */
class DiabetesType extends \yii\db\ActiveRecord
{

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.diabetes_type';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'type', 'external_id'], 'required'],
            [['external_id'], 'default', 'value' => null],
            [['external_id'], 'integer'],
            [['is_enabled'], 'boolean'],
            [['name', 'type'], 'string', 'max' => 255],
            [['type'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'name' => Yii::t('app', 'Name'),
            'type' => Yii::t('app', 'Type'),
            'external_id' => Yii::t('app', 'External ID'),
            'is_enabled' => Yii::t('app', 'Is Enabled'),
        ];
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\DiabetesTypeQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\DiabetesTypeQuery(get_called_class());
    }
}

```

## common/models/Card.php
```php
<?php

namespace common\models;

use api\components\ApiResponse;
use api\components\ApiResponseMessage;
use api\components\exceptions\InternalServerErrorException;
use api\components\exceptions\UnprocessableContentException;
use common\models\Card\CardAim;
use common\models\Card\CardDiabetes;
use common\models\Card\CardDiagnosis;
use common\traits\ConvertedUpdatedAndCreatedDateTimeAttrValuesTrait;
use Exception;
use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\ActiveRecord;
use yii\db\Expression;
use yii\helpers\ArrayHelper;
use yii\httpclient\Client;

/**
 * This is the model class for table "public.card".
 *
 * @property int $patient_id Идентификатор пациента
 * @property int $doctor_id Идентификатор врача
 * @property string|null $diabetes Анамнез (Диабет)
 * @property string|null $aim Цели
 * @property string|null $diagnosis Диагноз
 * @property int|null $status Статус
 * @property string $created_at Дата создания
 * @property string $updated_at Дата изменения
 * @property integer|null $patientExternalId
 *
 * @property-read string|null $diabetesTypeId
 * @property-read DiabetesType|null $diabetesType
 * @property-read string|null $mkbId
 * @property-read Mkb|null $mkb
 * @property-read User|null $doctor
 * @property-read Patient $patient
 * @property-read Patient $patientByExternalId
 */
class Card extends \yii\db\ActiveRecord
{
    const SCENARIO_API_CREATE = 'api_create';
    const SCENARIO_API_CREATE_INTERNAL_PATIENT = 'api_create_internal_patient';
    const SCENARIO_API_UPDATE = 'api_update';
    const SCENARIO_API_UPDATE_THROUGH_SPPVR = 'api_update_through_sppvr';
    const SCENARIO_API_CREATE_EVENT = 'api_create_event';

    public $patientExternalId = null;
    public $diabetesTypeName;

    use ConvertedUpdatedAndCreatedDateTimeAttrValuesTrait;

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.card';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['patient_id', 'patientExternalId'], 'required'],
            [['patient_id', 'doctor_id', 'status', 'patientExternalId'], 'integer'],
            [['patient_id'], 'unique'],
            [['patient_id', 'doctor_id', 'status'], 'default', 'value' => null],

            [['diabetes', 'diagnosis', 'aim'], 'safe'],

            ['diabetes', 'validateDiabetes'],
            ['diagnosis', 'validateDiagnosis'],
            ['aim', 'validateAim'],

            [['patient_id'], 'exist', 'skipOnError' => true, 'targetClass' => Patient::class, 'targetAttribute' => ['patient_id' => 'id']],
            [['doctor_id'], 'exist', 'skipOnError' => true, 'targetClass' => User::class, 'targetAttribute' => ['doctor_id' => 'id']],
        ];
    }

    public function behaviors()
    {
        return [
            'timestamp' => [
                'class' => TimestampBehavior::class,
                'attributes' => [
                    ActiveRecord::EVENT_BEFORE_INSERT => ['created_at', 'updated_at'],
                    ActiveRecord::EVENT_BEFORE_UPDATE => ['updated_at'],
                ],
                'value' => new Expression('NOW()'),
            ]
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'patient_id' => Yii::t('app', 'Patient ID'),
            'patientExternalId' => Yii::t('app', 'Patient External ID'),
            'doctor_id' => Yii::t('app', 'Doctor ID'),
            'diabetes' => Yii::t('app', 'Diabetes'),
            'diagnosis' => Yii::t('app', 'Diagnosis'),
            'status' => Yii::t('app', 'Status'),
            'created_at' => Yii::t('app', 'Created At'),
            'updated_at' => Yii::t('app', 'Updated At'),
        ];
    }

    public function scenarios()
    {
        $scenarios = parent::scenarios();
        $scenarios[self::SCENARIO_API_CREATE] = $scenarios[self::SCENARIO_DEFAULT];
        $scenarios[self::SCENARIO_API_UPDATE] = $scenarios[self::SCENARIO_DEFAULT];
        $scenarios[self::SCENARIO_API_CREATE_EVENT] = [
            'patientExternalId',
            'diabetes',
            'diagnosis',
            'status',
        ];
        $scenarios[self::SCENARIO_API_CREATE_INTERNAL_PATIENT] = [
            'patient_id',
            'diabetes',
            'diagnosis',
        ];
        $scenarios[self::SCENARIO_API_UPDATE_THROUGH_SPPVR] = [
            'diabetes',
            'diagnosis',
        ];
        return $scenarios;
    }

    public function validateDiabetes($attribute, $params, $validator)
    {
        $model = new CardDiabetes();
        switch ($this->scenario) {
            case self::SCENARIO_API_CREATE_EVENT:
                $model->scenario = CardDiabetes::SCENARIO_API_CREATE_EVENT;
                break;
        }
        if (!$model->load($this->{$attribute}, '') || !$model->validate()) {
            $this->addError($attribute, $model->getErrors());
        }
    }

    public function validateDiagnosis($attribute, $params, $validator)
    {
        $model = new CardDiagnosis();
        switch ($this->scenario) {
            case self::SCENARIO_API_CREATE_EVENT:
                $model->scenario = CardDiagnosis::SCENARIO_API_CREATE_EVENT;
                break;
        }
        if (!$model->load($this->{$attribute}, '') || !$model->validate()) {
            $this->addError($attribute, $model->getErrors());
        }
    }

    public function validateAim($attribute, $params, $validator)
    {
        $model = new CardAim();
        if (!$model->load($this->{$attribute}, '') || !$model->validate()) {
            $this->addError($attribute, $model->getErrors());
        }
    }

    public function getDoctor()
    {
        return $this->hasOne(User::class, ['id' => 'doctor_id']);
    }

    public function getDiabetesTypeId()
    {
        return ArrayHelper::getValue($this, 'diabetes.type');
    }

    public function getDiabetesType()
    {
        return DiabetesType::findOne(['external_id' => $this->diabetesTypeId]);
    }

    public function getMkbId()
    {
        return ArrayHelper::getValue($this, 'diagnosis.mkb');
    }

    public function getMkb()
    {
        if (empty(($diabetesType = $this->diabetesType))) return null;
        return Mkb::findOne(['external_id' => $this->mkbId, 'diabetes_type_id' => $diabetesType->id]);
    }

    public function getPatient()
    {
        return $this->hasOne(Patient::class, ['id' => 'patient_id']);
    }

    public function getPatientByExternalId()
    {
        return Patient::findOne(['external_id' => $this->patientExternalId]);
    }

    public function updateByApi()
    {
        $url = $_ENV['SPPVR_BASE_API_URL'] . $_ENV['SPPVR_GET_PATIENT_CARD_API_URL'];

        try {
            $data = $this->getByApi();
            if (empty($data)) return false;
            if (empty($this->patientExternalId)) throw new InternalServerErrorException(Yii::t('app', "Patient External Id is empty while saving Patient Card data from API {url}", [
                'url' => $url,
            ]));

            $model = self::findOne(['patient_id' => $this->patientByExternalId->id ?? null]);
            $model->scenario = self::SCENARIO_API_UPDATE_THROUGH_SPPVR;

            if ($model->load($data, '') === false) {
                $e = new InternalServerErrorException(Yii::t('app', "Can't load Patient Card data from API {url}", [
                    'url' => $url,
                ]));
                $e->setModel($model);
                throw $e;
            }

            if ($model->validate() === false || $model->save() === false) {
                $e = new InternalServerErrorException(Yii::t('app', "Can't save Patient Card data from API {url}", [
                    'url' => $url,
                ]));
                $e->setModel($model);
                throw $e;
            }

            $this->setAttributes($model->getAttributes());
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            $response->log();
        }
    }

    public function getByApi()
    {
        $client = new Client(['baseUrl' => $_ENV['SPPVR_BASE_API_URL']]);

        try {
            $response = $client
                ->get($_ENV['SPPVR_GET_PATIENT_CARD_API_URL'])
                ->setHeaders(['content-type' => 'application/json'])
                ->setOptions([
                    'timeout' => 3,
//                    CURLOPT_CONNECTTIMEOUT => 3, // connection timeout
//                    CURLOPT_TIMEOUT => 5, // data receiving timeout
                ])
                ->send();

            $url = $client->baseUrl . $_ENV['SPPVR_GET_PATIENT_CARD_API_URL'];

            if (!$response->isOk || $response->statusCode != 200) {
                throw new Exception(Yii::t('app', "Can't get Patient Card data from API {url}. Status Code is {statusCode}", [
                    'url' => $url,
                    'statusCode' => $response->statusCode,
                ]));
            }

            if (empty($response->data['data'])) {
                throw new Exception(Yii::t('app', "Patient Card data is empty. API URL: {url}", [
                    'url' => $url,
                ]));
            }

            return $response->data['data'];
        } catch (Exception $e) {
            $response = new ApiResponse();
            $response->setException($e);
            $response->log();
        }
    }

    public function updateOrCreateIfNotExists(array $data, int $patientId): bool
    {
        if ( empty( $model = self::findOne(['patient_id' => $patientId]) ) ) {
            $model = new self(['scenario' => $this->getScenario()]);
            $model->patient_id = $patientId;
        }

        $externalDiabetesTypeId = ArrayHelper::getValue($data, 'diabetes.typeExternal');
        $externalMkbId = ArrayHelper::getValue($data, 'diagnosis.mkbExternal');

        if (!$externalDiabetesTypeId && !$externalMkbId) return false;

        $cardDiagnosisMkb = Mkb::find()
            ->alias('m')
            ->select('m.id as mkb_id, m.name as mkb_name, dt.id as diabetes_type_id, dt.external_id as diabetes_type_external_id, dt."name" as diabetes_type_name')
            ->innerJoin('diabetes_type dt', 'dt.id = m.diabetes_type_id')
            ->where(['m.external_id' => $externalMkbId, 'dt.external_id' => $externalDiabetesTypeId])
            ->asArray()
            ->one();

        if (empty($cardDiagnosisMkb)) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_MKB_DOESNT_MATCH_WITH_DIABETES_TYPE);
            $e->setModel($model);
            throw $e;
        }

        $data['diabetes']['type'] = ArrayHelper::getValue($cardDiagnosisMkb, 'diabetes_type_id');
        $data['diagnosis']['mkb'] = ArrayHelper::getValue($cardDiagnosisMkb, 'mkb_id');

        if ($model->load($data, '') === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_MODEL_LOAD_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $model->doctor_id = User::find()
                ->where(['id' => ArrayHelper::getValue($data, 'doctor_id'), 'role' => User::ROLE_DOCTOR])
                ->one()
                ->id ?? null;

        if ($model->save() === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_CARD_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $this->setAttributes($model->getAttributes());

        return true;
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\CardQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\CardQuery(get_called_class());
    }
}

```

## common/models/Hospital.php
```php
<?php

namespace common\models;

use api\components\ApiResponseMessage;
use api\components\exceptions\UnprocessableContentException;
use Yii;
use yii\helpers\ArrayHelper;

/**
 * This is the model class for table "public.hospital".
 *
 * @property int $id Уникальный идентификатор
 * @property string $name_short Сокращенное наименование
 * @property string $name_full Полное наименование
 * @property string $oid OID
 * @property string $address_text Адрес текст
 * @property string $address_city_fias Адрес населённый пункт
 * @property string $address_street_fias Адрес улица (ФИАС)
 * @property string $address_house_fias Адрес дом (ФИАС)
 * @property string $ogrn ОГРН
 * @property string $okato ОКАТО
 * @property string|null $okpo ОКПО
 * @property string|null $phone Телефон
 * @property string|null $extra Дополнительные данные
 */
class Hospital extends \yii\db\ActiveRecord
{
    const SCENARIO_API_CREATE_EVENT = 'api_create_event';

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.hospital';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'name_short', 'name_full', 'oid', 'address_text', 'address_city_fias', 'address_street_fias', 'ogrn', 'okato'], 'required'],
            [['id'], 'default', 'value' => null],
            [['address_house_fias'], 'default', 'value' => ''],
            [['id'], 'integer'],
            [['extra'], 'safe'],
            [['name_short'], 'string', 'max' => 512],
            [['name_full'], 'string', 'max' => 2048],
            [['oid'], 'string', 'max' => 32],
            [['address_text', 'okato'], 'string', 'max' => 256],
            [['address_city_fias', 'address_street_fias', 'address_house_fias'], 'string', 'max' => 36],
            [['ogrn'], 'string', 'max' => 16],
            [['okpo'], 'string', 'max' => 64],
            [['phone'], 'string', 'max' => 11],
            [['id'], 'unique', 'on' => [self::SCENARIO_DEFAULT]],
        ];
    }

    public function scenarios()
    {
        $scenarios = parent::scenarios();
        $scenarios[self::SCENARIO_API_CREATE_EVENT] = $scenarios[self::SCENARIO_DEFAULT];
        return $scenarios;
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'name_short' => Yii::t('app', 'Name Short'),
            'name_full' => Yii::t('app', 'Name Full'),
            'oid' => Yii::t('app', 'Oid'),
            'address_text' => Yii::t('app', 'Address Text'),
            'address_city_fias' => Yii::t('app', 'Address City Fias'),
            'address_street_fias' => Yii::t('app', 'Address Street Fias'),
            'address_house_fias' => Yii::t('app', 'Address House Fias'),
            'ogrn' => Yii::t('app', 'Ogrn'),
            'okato' => Yii::t('app', 'Okato'),
            'okpo' => Yii::t('app', 'Okpo'),
            'phone' => Yii::t('app', 'Phone'),
            'extra' => Yii::t('app', 'Extra'),
        ];
    }

    public function updateOrCreateIfNotExists(array $data): bool
    {
        if ( empty( $model = self::findOne(['id' => ArrayHelper::getValue($data, 'id')]) ) ) {
            $model = new self(['scenario' => $this->getScenario()]);
        }

        if ($model->load($data, '') === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::HOSPITAL_MODEL_LOAD_ERROR);
            $e->setModel($model);
            throw $e;
        }

        return $model->save();
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\HospitalQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\HospitalQuery(get_called_class());
    }
}

```

## common/models/Event.php
```php
<?php

namespace common\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\ActiveRecord;
use yii\db\Expression;

/**
 * This is the model class for table "event".
 *
 * @property int $id
 * @property int|null $user_id
 * @property int|null $patient_id
 * @property string|null $classifier
 * @property string|null $classifier_comment
 * @property string $priority
 * @property string $type
 * @property string $status
 * @property string|null $taking_to_work_at
 * @property string|null $deadline_at
 * @property string|null $source
 * @property bool $is_system_event Событие, сгенерированное системой
 * @property int|null $dispatcher_id_who_took_to_work
 * @property string|null $compensation_stage
 * @property string|null $diabetes_type
 * @property integer|null $mkb_id
 * @property bool $insulin_requiring
 * @property string $created_at
 * @property string|null $updated_at
 * @property string|null $created_by
 *
 * @property EventClassifier $classifierRel
 * @property User $dispatcherWhoTookToWork
 * @property Patient $patient
 * @property EventPriority $priorityRel
 * @property EventStatus $statusRel
 * @property EventType $typeRel
 * @property User $user
 * @property Mkb $mkb
 * @property RegistryListOfEvent $registryListOfEvent
 */
class Event extends \yii\db\ActiveRecord
{
    const SCENARIO_CREATE_RANDOM_EVENT = 'create_random_event';

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'event';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['user_id', 'patient_id', 'dispatcher_id_who_took_to_work'], 'default', 'value' => null],
            [['user_id', 'patient_id', 'dispatcher_id_who_took_to_work', 'diabetes_type', 'mkb_id'], 'integer'],
            [['classifier_comment'], 'string'],
            [['priority', 'type'], 'required'],
            [['taking_to_work_at', 'deadline_at', 'updated_at'], 'safe'],
            [['is_system_event', 'insulin_requiring'], 'boolean'],
            [['classifier', 'priority', 'type', 'status', 'source', 'compensation_stage'], 'string', 'max' => 255],
            [['created_by'], 'string', 'max' => 10],
            ['status', 'default', 'value' => EventStatus::WAITING],
            [['created_at', 'updated_at'], 'date', 'format' => 'php:Y-m-d H:i:s', 'on' => [self::SCENARIO_CREATE_RANDOM_EVENT]],
            [['classifier'], 'exist', 'skipOnError' => true, 'targetClass' => EventClassifier::class, 'targetAttribute' => ['classifier' => 'name']],
            [['priority'], 'exist', 'skipOnError' => true, 'targetClass' => EventPriority::class, 'targetAttribute' => ['priority' => 'name']],
            [['status'], 'exist', 'skipOnError' => true, 'targetClass' => EventStatus::class, 'targetAttribute' => ['status' => 'name']],
            [['type'], 'exist', 'skipOnError' => true, 'targetClass' => EventType::class, 'targetAttribute' => ['type' => 'name']],
            [['patient_id'], 'exist', 'skipOnError' => true, 'targetClass' => Patient::class, 'targetAttribute' => ['patient_id' => 'id']],
            [['user_id'], 'exist', 'skipOnError' => true, 'targetClass' => User::class, 'targetAttribute' => ['user_id' => 'id']],
            [['dispatcher_id_who_took_to_work'], 'exist', 'skipOnError' => true, 'targetClass' => User::class, 'targetAttribute' => ['dispatcher_id_who_took_to_work' => 'id']],
            [['diabetes_type'], 'exist', 'skipOnError' => true, 'targetClass' => DiabetesType::class, 'targetAttribute' => ['diabetes_type' => 'id']],
            [['mkb_id'], 'exist', 'skipOnError' => true, 'targetClass' => Mkb::class, 'targetAttribute' => ['mkb_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'user_id' => 'User ID',
            'patient_id' => 'Patient ID',
            'classifier' => 'Classifier',
            'classifier_comment' => 'Classifier Comment',
            'priority' => 'Priority',
            'type' => 'Type',
            'status' => 'Status',
            'taking_to_work_at' => 'Taking To Work At',
            'deadline_at' => 'Deadline At',
            'source' => 'Source',
            'is_system_event' => 'Is System Event',
            'dispatcher_id_who_took_to_work' => 'Dispatcher Id Who Took To Work',
            'compensation_stage' => 'Compensation Stage',
            'diabetes_type' => 'Diabetes Type',
            'mkb_id' => 'Mkb ID',
            'insulin_requiring' => 'Insulin Requiring',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'created_by' => 'Created By',
        ];
    }

    public function behaviors()
    {
        if ($this->scenario === self::SCENARIO_CREATE_RANDOM_EVENT) return [];
        return [
            'timestamp' => [
                'class' => TimestampBehavior::class,
                'attributes' => [
                    ActiveRecord::EVENT_BEFORE_INSERT => ['created_at', 'updated_at'],
                    ActiveRecord::EVENT_BEFORE_UPDATE => ['updated_at'],
                ],
                'value' => new Expression('NOW()'),
            ]
        ];
    }

    /**
     * Gets query for [[ClassifierRel]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventClassifierQuery
     */
    public function getClassifierRel()
    {
        return $this->hasOne(EventClassifier::class, ['name' => 'classifier']);
    }

    /**
     * Gets query for [[DispatcherIdWhoTookToWork]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\UserQuery
     */
    public function getDispatcherWhoTookToWork()
    {
        return $this->hasOne(User::class, ['id' => 'dispatcher_id_who_took_to_work']);
    }

    /**
     * Gets query for [[Patient]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\PatientQuery
     */
    public function getPatient()
    {
        return $this->hasOne(Patient::class, ['id' => 'patient_id']);
    }

    /**
     * Gets query for [[PriorityRel]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventPriorityQuery
     */
    public function getPriorityRel()
    {
        return $this->hasOne(EventPriority::class, ['name' => 'priority']);
    }

    /**
     * Gets query for [[StatusRel]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventStatusQuery
     */
    public function getStatusRel()
    {
        return $this->hasOne(EventStatus::class, ['name' => 'status']);
    }

    /**
     * Gets query for [[TypeRel]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventTypeQuery
     */
    public function getTypeRel()
    {
        return $this->hasOne(EventType::class, ['name' => 'type']);
    }

    /**
     * Gets query for [[User]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\UserQuery
     */
    public function getUser()
    {
        return $this->hasOne(User::class, ['id' => 'user_id']);
    }

    /**
     * Gets query for [[Mkb]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\MkbQuery
     */
    public function getMkb()
    {
        return $this->hasOne(Mkb::class, ['id' => 'mkb_id']);
    }

    /**
     * Gets query for [[RegistryListOfEvent]].
     *
     * @return \yii\db\ActiveQuery|\common\models\RegistryListOfEvent
     */
    public function getRegistryListOfEvent()
    {
        return $this->hasOne(RegistryListOfEvent::class, ['event_id' => 'id']);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\EventQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\EventQuery(get_called_class());
    }
}

```

## common/models/Card/CardDiagnosis.php
```php
<?php

namespace common\models\Card;

use common\models\DiabetesType;
use common\models\Mkb;
use Yii;
use yii\base\Model;

/**
 * \common\models\Card->diagnosis json field model
 */
class CardDiagnosis extends Model
{
    public $mkb;
    public $mkbExternal;

    const SCENARIO_API_CREATE_EVENT = 'api_create_event';

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['mkb'], 'required'],
            [['mkb', 'mkbExternal'], 'integer'],
            [['mkb'], 'exist', 'skipOnError' => true, 'targetClass' => Mkb::class, 'targetAttribute' => ['mkb' => 'id']],
            [['mkbExternal'], 'exist', 'skipOnError' => true, 'targetClass' => Mkb::class, 'targetAttribute' => ['mkbExternal' => 'external_id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'mkb' => Yii::t('app', 'Diagnosis Mkb'),
            'mkbExternal' => Yii::t('app', 'Diagnosis Mkb'),
        ];
    }

    public function scenarios()
    {
        $scenarios = parent::scenarios();
        $scenarios[self::SCENARIO_API_CREATE_EVENT] = [
            'mkbExternal',
        ];
        return $scenarios;
    }
}

```

## common/models/Card/CardAim.php
```php
<?php

namespace common\models\Card;

use common\models\AimsCatalog;
use Yii;
use yii\base\Model;

/**
 * \common\models\Card->aim json field model
 */
class CardAim extends Model
{
    public $hba1c;
    public $glucose_preprandial;
    public $glucose_postprandial;
    public $lpnp;
    public $ad;
    public $target_time;


    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['hba1c', 'glucose_preprandial', 'glucose_postprandial', 'lpnp', 'ad', 'target_time'], 'default', 'value' => null],
            [['hba1c', 'glucose_preprandial', 'glucose_postprandial', 'lpnp', 'ad', 'target_time'], 'integer'],

            ['hba1c', 'in', 'range' => AimsCatalog::find()->select('external_id')->typeHba1C()->column()],
            ['glucose_preprandial', 'in', 'range' => AimsCatalog::find()->select('external_id')->typeGlucosePreprandial()->column()],
            ['glucose_postprandial', 'in', 'range' => AimsCatalog::find()->select('external_id')->typeGlucosePostprandial()->column()],
            ['lpnp', 'in', 'range' => AimsCatalog::find()->select('external_id')->typeLpnp()->column()],
            ['ad', 'in', 'range' => AimsCatalog::find()->select('external_id')->typeAd()->column()],
            ['target_time', 'in', 'range' => AimsCatalog::find()->select('external_id')->typeTargetTime()->column()],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'hba1c' => Yii::t('app', 'Hba 1c'),
            'glucose_preprandial' => Yii::t('app', 'Glucose Preprandial'),
            'glucose_postprandial' => Yii::t('app', 'Glucose Postprandial'),
            'lpnp' => Yii::t('app', 'Lpnp'),
            'ad' => Yii::t('app', 'Ad'),
            'target_time' => Yii::t('app', 'Target Time'),
        ];
    }
}

```

## common/models/Card/CardDiabetes.php
```php
<?php

namespace common\models\Card;

use common\components\helpers\ValidateHelper;
use common\models\DiabetesType;
use common\params\OptionParam;
use Yii;
use yii\base\Model;

/**
 * \common\models\Card->diabetes json field model
 */
class CardDiabetes extends Model
{
    public $type;
    public $typeExternal;
    public $first_identified;
    public $manifest_year;
    public $manifest_month;
    public $hba1c_level;
    public $insulin_requiring;
    public $insulin_method;
    public $monitoring;
    public $disability;

    const SCENARIO_API_CREATE_EVENT = 'api_create_event';

    public function rules()
    {
        return [
            [['type'], 'required'],
            [['type', 'typeExternal'], 'integer'],
            [['type'], 'exist', 'skipOnError' => true, 'targetClass' => DiabetesType::class, 'targetAttribute' => ['type' => 'id']],
            [['typeExternal'], 'exist', 'skipOnError' => true, 'targetClass' => DiabetesType::class, 'targetAttribute' => ['typeExternal' => 'external_id']],
            [['first_identified'], 'boolean'],
            [['disability', 'first_identified'], 'default', 'value' => null],
            [['disability', 'manifest_month', 'insulin_method', 'insulin_requiring'], 'integer'],
            ['manifest_year', 'date', 'format' => 'php:Y'],
            'hba1c_level' => [['hba1c_level'], 'number', 'min' => 0, 'max' => 300],
//            [['insulin_method'], 'number', 'min' => 0, 'max' => 2],
//            [['insulin_method'], 'filter', 'filter' => fn($value) => $this->insulin_requiring ? $value : null],
            ['manifest_month', 'number', 'min' => 0, 'max' => 12],
            ['monitoring', 'each', 'rule' => ['integer']],
            [['insulin_method'], 'required', 'when' => fn($model, $attr) => $model->insulin_requiring == 1],
        ];
    }

    public function attributeLabels()
    {
        return [
            'type' => Yii::t('app', 'Diabetes'),
            'typeExternal' => Yii::t('app', 'Diabetes'),
            'first_identified' => Yii::t('app', 'First Identified'),
            'manifest_month' => Yii::t('app', 'Manifest Month'),
            'manifest_year' => Yii::t('app', 'Manifest Year'),
            'duration' => Yii::t('app', 'Diabetes duration'),
            'hba1c_level' => Yii::t('app', 'Hba1c Level'),
            'hba1cExcess' => Yii::t('app', 'Excess from target HbA1c'),
            'insulin_requiring' => Yii::t('app', 'Insulin Requiring'),
            'insulin_method' => Yii::t('app', 'Insulin Method'),
            'monitoring' => Yii::t('app', 'Monitoring'),
            'disability' => Yii::t('app', 'Disability'),
        ];
    }

    public function scenarios()
    {
        $scenarios = parent::scenarios();
        $scenarios[self::SCENARIO_API_CREATE_EVENT] = [
            'mkbExternal',
        ];
        return $scenarios;
    }
}

```

## common/models/Mkb.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "public.mkb".
 *
 * @property int $id
 * @property string $name
 * @property string|null $code
 * @property int $external_id
 * @property int $diabetes_type_id
 * @property bool $is_enabled
 */
class Mkb extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.mkb';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'external_id', 'diabetes_type_id'], 'required'],
            [['external_id', 'diabetes_type_id'], 'default', 'value' => null],
            [['external_id', 'diabetes_type_id'], 'integer'],
            [['is_enabled'], 'boolean'],
            [['name', 'code'], 'string', 'max' => 255],
            [['name'], 'unique'],
            [['diabetes_type_id'], 'exist', 'skipOnError' => true, 'targetClass' => DiabetesType::class, 'targetAttribute' => ['diabetes_type_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'name' => Yii::t('app', 'Name'),
            'code' => Yii::t('app', 'Code'),
            'external_id' => Yii::t('app', 'External ID'),
            'diabetes_type_id' => Yii::t('app', 'Diabetes Type ID'),
            'is_enabled' => Yii::t('app', 'Is Enabled'),
        ];
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\MkbQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\MkbQuery(get_called_class());
    }
}

```

## common/models/Blank.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "public.blank".
 *
 * @property int $id
 * @property int $patient_id Идентификатор пациента
 * @property int $doctor_id Идентификатор врача
 * @property string|null $complaints Жалобы
 * @property string|null $examination Объективный осмотр
 * @property string|null $aims Цели
 * @property string|null $diagnosis Диагноз
 * @property string|null $therapy Терапия
 * @property int|null $self_monitoring Режим самоконтроля
 * @property string|null $diet Питание
 * @property string|null $activity Физическая активность
 * @property string|null $lifestyle Образ жизни (из карты)
 * @property string|null $localis St. Localis
 * @property string|null $reappearance_at Дата повторной явки
 * @property string $created_at Дата создания
 */
class Blank extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.blank';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['patient_id', 'doctor_id', 'created_at'], 'required'],
            [['patient_id', 'doctor_id', 'self_monitoring'], 'default', 'value' => null],
            [['patient_id', 'doctor_id', 'self_monitoring'], 'integer'],
            [['complaints', 'examination', 'aims', 'diagnosis', 'therapy', 'diet', 'activity', 'lifestyle', 'reappearance_at', 'created_at'], 'safe'],
            [['localis'], 'string', 'max' => 1024],
            [['patient_id'], 'exist', 'skipOnError' => true, 'targetClass' => Patient::class, 'targetAttribute' => ['patient_id' => 'id']],
            [['doctor_id'], 'exist', 'skipOnError' => true, 'targetClass' => User::class, 'targetAttribute' => ['doctor_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'patient_id' => Yii::t('app', 'Patient ID'),
            'doctor_id' => Yii::t('app', 'Doctor ID'),
            'complaints' => Yii::t('app', 'Complaints'),
            'examination' => Yii::t('app', 'Examination'),
            'aims' => Yii::t('app', 'Aims'),
            'diagnosis' => Yii::t('app', 'Diagnosis'),
            'therapy' => Yii::t('app', 'Therapy'),
            'self_monitoring' => Yii::t('app', 'Self Monitoring'),
            'diet' => Yii::t('app', 'Diet'),
            'activity' => Yii::t('app', 'Activity'),
            'lifestyle' => Yii::t('app', 'Lifestyle'),
            'localis' => Yii::t('app', 'Localis'),
            'reappearance_at' => Yii::t('app', 'Reappearance At'),
            'created_at' => Yii::t('app', 'Created At'),
        ];
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\BlankQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\BlankQuery(get_called_class());
    }
}

```

## common/models/MonitoringArterialPressure.php
```php
<?php

namespace common\models;

use api\components\ApiResponseMessage;
use common\params\ADParam;
use common\params\StatusColorParam;
use DateTime;
use Yii;

/**
 * This is the model class for table "public.monitoring_arterial_pressure".
 *
 * @property int $id
 * @property int $patient_id Идентификатор пациента
 * @property int|null $aim Терапевтическая цель по АД
 * @property int $systolic Систолическое АД
 * @property int $dystolic Дистолическое АД
 * @property string $taken_at Момент измерения
 * @property int $status Статус
 * @property string $created_at Дата создания
 * @property int|null $moment
 *
 * @property integer|null $patientExternalId
 * @property-read Patient $patientByExternalId
 * @property-read Card $patientCard
 * @property-read AimsCatalog $aimByExternalId
 */
class MonitoringArterialPressure extends \yii\db\ActiveRecord
{

    const MOMENT_NOW = 1;
    const MOMENT_OTHER = 2;

    const MOMENT_LIST = [
        self::MOMENT_NOW => 'На данный момент',
        self::MOMENT_OTHER => 'В другое время',
    ];

    public $patientExternalId = null;
    public $moment = null;

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.monitoring_arterial_pressure';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['patient_id', 'systolic', 'dystolic', 'patientExternalId'], 'required'],
            [['patient_id', 'aim', 'systolic', 'dystolic', 'moment'], 'default', 'value' => null],
            [['patient_id', 'aim', 'systolic', 'dystolic', 'patientExternalId', 'moment'], 'integer'],
            [['taken_at', 'created_at'], 'date', 'format' => 'php:Y-m-d H:i:s'],
            [['created_at'], 'default', 'value' => (new DateTime())->format('Y-m-d H:i:s')],

            ['taken_at', 'default', 'value' => function (self $model, $attribute) {
                if ((int) $model->moment === self::MOMENT_NOW) {
                    return (new DateTime())->format('Y-m-d H:i:s');
                }
                return $model->taken_at;
            }],

            ['status', 'default', 'value' => function (self $model, $attribute) {
                return $this->getStatus();
            }],

            [['taken_at', 'status', 'created_at'], 'required'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'patient_id' => Yii::t('app', 'Patient ID'),
            'patientExternalId' => Yii::t('app', 'Patient External ID'),
            'aim' => Yii::t('app', 'Aim'),
            'systolic' => Yii::t('app', 'Systolic'),
            'dystolic' => Yii::t('app', 'Dystolic'),
            'taken_at' => Yii::t('app', 'Taken At'),
            'status' => Yii::t('app', 'Status'),
            'created_at' => Yii::t('app', 'Created At'),
        ];
    }

    public function load($data, $formName = null)
    {
        $load = parent::load($data, $formName);

        $this->patient_id = $this->patientByExternalId->id;
        $cardModel = $this->patientCard;

        if (empty($cardModel)) {
            $this->addError('patient_id', ApiResponseMessage::PATIENT_CARD_NOT_FOUND);
            return false;
        }

        if (empty($cardModel->aim['ad'])) {
            $this->addError('patient_id', ApiResponseMessage::PATIENT_CARD_AIM_AD_EMPTY);
            return false;
        }

        $this->aim = $cardModel->aim['ad'];

        return $load;
    }

    public function getPatientByExternalId()
    {
        return Patient::findOne(['external_id' => $this->patientExternalId]);
    }

    public function getAimByExternalId()
    {
        return $this->hasOne(AimsCatalog::class, ['external_id' => 'aim'])->andWhere(['type' => AimsCatalog::TYPE_AD]);
    }

    public function getPatientCard()
    {
        if (!empty($patientModel = $this->patientByExternalId)) {
            return $patientModel->card;
        }
        return null;
    }

    /*
     * Определение статуса показателей давления пациента по целевым значениям
     * */
    public function getStatus(): int
    {
        if ($this->dystolic < 70 || $this->dystolic >= 80)
            return StatusColorParam::COLOR_RED;

        if ($this->aim == ADParam::AD_1) {
            return $this->systolic >= 120 && $this->systolic < 130 ? StatusColorParam::COLOR_GREEN : StatusColorParam::COLOR_RED;
        } elseif ($this->aim == ADParam::AD_2) {
            return $this->systolic >= 130 && $this->systolic < 140 ? StatusColorParam::COLOR_GREEN : StatusColorParam::COLOR_RED;
        } else {
            // Если нет цели, то зелёный статус в пределах >= 120 и < 140
            return $this->systolic >= 120 && $this->systolic < 140 ? StatusColorParam::COLOR_GREEN : StatusColorParam::COLOR_RED;
        }
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\MonitoringArterialPressureQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\MonitoringArterialPressureQuery(get_called_class());
    }
}

```

## common/models/User.php
```php
<?php

namespace common\models;

use Yii;
use yii\base\NotSupportedException;
use yii\behaviors\TimestampBehavior;
use yii\db\ActiveRecord;
use yii\db\Expression;
use yii\web\IdentityInterface;

/**
 * User model
 *
 * @property integer $id
 * @property string $email E-mail
 * @property string $first_name Имя
 * @property string $last_name Фамилия
 * @property string|null $patronymic Отчество
 * @property string|null $phone Контактный телефон
 * @property int $role Роль
 * @property int $status Статус
 * @property string|null $auth_key
 * @property string|null $password_hash
 * @property string|null $password_reset_token
 * @property string|null $verification_token
 * @property string $created_at Дата создания
 * @property string $updated_at Дата изменения
 * @property string|null $external_token
 * @property string|null $dispatcher_working_status
 *
 * @property-read string $fullName
 */
class User extends ActiveRecord implements IdentityInterface
{
    const STATUS_DELETED = 0;
    const STATUS_INACTIVE = 9;
    const STATUS_ACTIVE = 10;

    const ROLE_DISPATCHER = 3;
    const ROLE_DOCTOR = 6;
    const ROLE_ADMIN = 10;


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return '{{%user}}';
    }

    public function behaviors()
    {
        return [
            'timestamp' => [
                'class' => TimestampBehavior::class,
                'attributes' => [
                    ActiveRecord::EVENT_BEFORE_INSERT => ['created_at', 'updated_at'],
                    ActiveRecord::EVENT_BEFORE_UPDATE => ['updated_at'],
                ],
                'value' => new Expression('NOW()'),
            ]
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            ['status', 'default', 'value' => self::STATUS_INACTIVE],
            ['status', 'in', 'range' => [self::STATUS_ACTIVE, self::STATUS_INACTIVE, self::STATUS_DELETED]],

            [['email', 'first_name', 'last_name', 'role', 'created_at', 'updated_at'], 'required'],
            [['role', 'status'], 'default', 'value' => null],
            [['role', 'status'], 'integer'],
            [['created_at', 'updated_at'], 'safe'],
            [['email'], 'string', 'max' => 64],
            [['first_name', 'last_name', 'patronymic', 'auth_key'], 'string', 'max' => 32],
            [['phone'], 'string', 'max' => 11],
            [['password_hash'], 'string', 'max' => 60],
            [['password_reset_token', 'verification_token'], 'string', 'max' => 43],
            [['external_token'], 'string', 'max' => 256],
            [['dispatcher_working_status'], 'string'],
            [['email'], 'unique'],
            [['password_reset_token'], 'unique'],
            [['dispatcher_working_status'], 'exist', 'skipOnError' => true, 'targetClass' => DispatcherWorkingStatus::class, 'targetAttribute' => ['dispatcher_working_status' => 'name']],
        ];
    }

    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'email' => Yii::t('app', 'Email'),
            'first_name' => Yii::t('app', 'First Name'),
            'last_name' => Yii::t('app', 'Last Name'),
            'patronymic' => Yii::t('app', 'Patronymic'),
            'fullName' => Yii::t('app', 'Full Name'),
            'phone' => Yii::t('app', 'Phone'),
            'role' => Yii::t('app', 'Role'),
            'status' => Yii::t('app', 'Status'),
            'auth_key' => Yii::t('app', 'Auth Key'),
            'password_hash' => Yii::t('app', 'Password Hash'),
            'password_reset_token' => Yii::t('app', 'Password Reset Token'),
            'verification_token' => Yii::t('app', 'Verification Token'),
            'created_at' => Yii::t('app', 'Created At'),
            'updated_at' => Yii::t('app', 'Updated At'),
            'external_token' => Yii::t('app', 'External Token'),
            'dispatcher_working_status' => Yii::t('app', 'Dispatcher Working Status'),
        ];
    }

    public static function findIdentity($id)
    {
        return static::findOne(['id' => $id, 'status' => self::STATUS_ACTIVE]);
    }

    public static function findIdentityByAccessToken($token, $type = null)
    {
        throw new NotSupportedException('"findIdentityByAccessToken" is not implemented.');
    }

    public static function findByUsername($username)
    {
        return static::findOne(['username' => $username]);
    }

    public static function findByEmail($email)
    {
        return static::findOne(['email' => $email]);
    }

    public static function findByPasswordResetToken($token)
    {
        if (!static::isPasswordResetTokenValid($token)) {
            return null;
        }

        return static::findOne([
            'password_reset_token' => $token,
            'status' => self::STATUS_ACTIVE,
        ]);
    }

    public static function findByVerificationToken($token) {
        return static::findOne([
            'verification_token' => $token,
            'status' => self::STATUS_INACTIVE
        ]);
    }

    public static function isPasswordResetTokenValid($token)
    {
        if (empty($token)) {
            return false;
        }

        $timestamp = (int) substr($token, strrpos($token, '_') + 1);
        $expire = Yii::$app->params['user.passwordResetTokenExpire'];
        return $timestamp + $expire >= time();
    }

    public function getId()
    {
        return $this->getPrimaryKey();
    }

    public function getAuthKey()
    {
        return $this->auth_key;
    }

    public function validateAuthKey($authKey)
    {
        return $this->getAuthKey() === $authKey;
    }

    public function validatePassword($password)
    {
        return Yii::$app->security->validatePassword($password, $this->password_hash);
    }

    public function setPassword($password)
    {
        $this->password_hash = Yii::$app->security->generatePasswordHash($password);
    }

    public function generateAuthKey()
    {
        $this->auth_key = Yii::$app->security->generateRandomString();
    }

    public function generatePasswordResetToken()
    {
        $this->password_reset_token = Yii::$app->security->generateRandomString() . '_' . time();
    }

    public function generateEmailVerificationToken()
    {
        $this->verification_token = Yii::$app->security->generateRandomString() . '_' . time();
    }

    public function removePasswordResetToken()
    {
        $this->password_reset_token = null;
    }

    public function getFullName(): string
    {
        return implode(' ', [$this->last_name, $this->first_name, $this->patronymic]);
    }

    public static function find()
    {
        return new \common\models\query\UserQuery(get_called_class());
    }
}

```

## common/models/EventSearch.php
```php
<?php

namespace common\models;

use common\models\Event;
use Yii;
use yii\base\Model;
use yii\data\ActiveDataProvider;
use yii\data\ArrayDataProvider;
use yii\data\Pagination;
use yii\data\Sort;
use yii\db\ActiveQuery;
use yii\db\Expression;

/**
 * EventSearch represents the model behind the search form of `common\models\Event`.
 */
class EventSearch extends Event
{
    public $eventInitiatorFullName;
    public $dispatcherWhoTookToWork;
    public $page;
    public $createdAtFrom;
    public $createdAtTo;

    const ROUTE_HOME = 'home';
    const ROUTE_SCHEDULED_TASKS = 'scheduled-tasks';
    const ROUTE_ARCHIVE = 'archive';

    const PAGE_SIZE = 10;

    public function rules()
    {
        return [
            [['classifier', 'priority', 'type', 'eventInitiatorFullName', 'status', 'created_at', 'dispatcherWhoTookToWork'], 'string'],
            ['page', 'integer'],
            ['page', 'default', 'value' => 1],
            [['createdAtFrom', 'createdAtTo'], 'date', 'format' => 'php:Y-m-d'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function scenarios()
    {
        // bypass scenarios() implementation in the parent class
        return Model::scenarios();
    }

    /**
     * Creates data provider instance with search query applied
     *
     * @param array $params
     *
     * @return ActiveDataProvider|ArrayDataProvider
     */
    public function search($params, $route)
    {
        $query = Event::find()
            ->distinct()
            ->joinWith([
                'classifierRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title', 'external_id']);
                },
                'typeRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title']);
                },
                'statusRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title']);
                },
                'priorityRel' => function (ActiveQuery $q) {
                    return $q->select(['name', 'title']);
                },
                'patient' => function (ActiveQuery $q) {
                    return $q->select([
                        'patient.id',
                        'patient.first_name',
                        'patient.last_name',
                        'patient.patronymic',
                        'patient.phone',
                        'patient.hospital_id',
                        'patient.external_id',
                        'concat_ws(\' \', patient.last_name, patient.first_name, patient.patronymic)  as full_name',
                    ])
                        ->joinWith([
                            'hospital' => function (ActiveQuery $q) {
                                return $q->select([
                                    'hospital.id',
                                    'hospital.name_short',
                                    'hospital.name_full',
                                ]);
                            },
                        ]);
                },
                'user' => function (ActiveQuery $q) {
                    return $q->alias('u')->select([
                        'u.id',
                        'u.first_name',
                        'u.last_name',
                        'u.patronymic',
                        'u.external_token',
                        'concat_ws(\' \', u.last_name, u.first_name, u.patronymic)  as full_name',
                    ]);
                },
                'dispatcherWhoTookToWork' => function (ActiveQuery $q) {
                    return $q->alias('dwttw')->select([
                        'dwttw.id',
                        'dwttw.first_name',
                        'dwttw.last_name',
                        'dwttw.patronymic',
                        'dwttw.external_token',
                        'concat_ws(\' \', dwttw.last_name, dwttw.first_name, dwttw.patronymic)  as full_name',
                    ]);
                },
            ])
            ->asArray();

        if ($route === self::ROUTE_ARCHIVE) {
            $query->andWhere(['event.status' => EventStatus::DONE]);
        } else {
            $query->andWhere([
                'or',
                [
                    'and',
                    ['is', 'event.dispatcher_id_who_took_to_work', new Expression('null')],
                    ['event.status' => EventStatus::WAITING],
                ],
                [
                    'and',
                    ['event.dispatcher_id_who_took_to_work' => Yii::$app->user->id],
                    ['event.status' => EventStatus::IN_WORK],
                ],
                [
                    'and',
                    ['is not', 'event.dispatcher_id_who_took_to_work', new Expression('null')],
                    ['event.status' => EventStatus::PAUSED],
                ],
            ]);
        }

        switch ($route) {
            case self::ROUTE_HOME:
                $query->priorityHigh();
                break;
            case self::ROUTE_SCHEDULED_TASKS:
                $query->andWhere(['<>', 'event.priority', EventPriority::HIGH]);
                break;
        }

        // add conditions that should always apply here

        $sort = new Sort([
            'attributes' => [
                'created_at',
            ],
            'defaultOrder' => [
                'created_at' => SORT_DESC,
            ]
        ]);

        $this->load($params, '');

        if (!$this->validate()) {
            $count = $query->count();
            $pagination = new Pagination(['totalCount' => $count, 'pageSize' => self::PAGE_SIZE, 'page' => $this->getPaginationPage()]);

            return new ArrayDataProvider([
                'allModels' => $query
                    ->orderBy($sort->orders)
                    ->offset($pagination->offset)
                    ->limit($pagination->limit)
                    ->all(),
                'pagination' => $pagination,
            ]);
        }

        $query->andFilterWhere(['ilike', 'priority', $this->priority])
            ->andFilterWhere(['ilike', 'type', $this->type])
            ->andFilterWhere(['ilike', 'event.status', $this->status]);

        $query->andFilterWhere([
            'or',
            ['=', 'to_char(event.created_at, \'YYYY-MM-DD\')', $this->created_at],
            ['between', 'to_char(event.created_at, \'YYYY-MM-DD\')', $this->createdAtFrom, $this->createdAtTo],
        ]);

        $query->andFilterWhere([
            'or',
            ['ilike', 'classifier_comment', $this->classifier],
            ['ilike', 'event_classifier.title', $this->classifier],
            ['ilike', 'event_classifier.name', $this->classifier],
        ]);

        $query->andFilterWhere([
            'or',
            [
                'and',
                ['type' => EventType::PATIENT],
                ['ilike', 'TRIM(CONCAT_WS(\' \', patient.last_name, patient.first_name, patient.patronymic))', $this->eventInitiatorFullName]
            ],
            [
                'and',
                ['type' => [EventType::DOCTOR, EventType::DISPATCHER]],
                ['ilike', 'TRIM(CONCAT_WS(\' \', u.last_name, u.first_name, u.patronymic))', $this->eventInitiatorFullName]
            ],
        ]);

        $query->andFilterWhere(['ilike', 'trim(concat_ws(\' \', dwttw.last_name, dwttw.first_name, dwttw.patronymic))', $this->dispatcherWhoTookToWork]);

        $count = $query->count();
        $pagination = new Pagination(['totalCount' => $count, 'pageSize' => self::PAGE_SIZE, 'page' => $this->getPaginationPage()]);

        return new ArrayDataProvider([
            'allModels' => $query
                ->orderBy($sort->orders)
                ->offset($pagination->offset)
                ->limit($pagination->limit)
                ->all(),
            'pagination' => $pagination,
        ]);
    }

    private function getPaginationPage(): int
    {
        return $this->page > 0 ? ( $this->page - 1 ) : $this->page;
    }
}

```

## common/models/MonitoringLast.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "public.monitoring_last".
 *
 * @property int $patient_id Идентификатор пациента
 * @property string|null $arterial_pressure Артериальное давление
 * @property string|null $glucose Глюкоза
 * @property string $created_at Дата создания
 * @property string $updated_at Дата изменения
 */
class MonitoringLast extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.monitoring_last';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['patient_id', 'created_at', 'updated_at'], 'required'],
            [['patient_id'], 'default', 'value' => null],
            [['patient_id'], 'integer'],
            [['arterial_pressure', 'glucose', 'created_at', 'updated_at'], 'safe'],
            [['patient_id'], 'unique'],
            [['patient_id'], 'exist', 'skipOnError' => true, 'targetClass' => Patient::class, 'targetAttribute' => ['patient_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'patient_id' => Yii::t('app', 'Patient ID'),
            'arterial_pressure' => Yii::t('app', 'Arterial Pressure'),
            'glucose' => Yii::t('app', 'Glucose'),
            'created_at' => Yii::t('app', 'Created At'),
            'updated_at' => Yii::t('app', 'Updated At'),
        ];
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\MonitoringLastQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\MonitoringLastQuery(get_called_class());
    }
}

```

## common/models/EventPriority.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "event_priority".
 *
 * @property string $name
 * @property string $title
 * @property bool $is_active
 * @property int $order
 *
 * @property Event[] $events
 */
class EventPriority extends \yii\db\ActiveRecord
{
    const HIGH = 'high';
    const MEDIUM = 'medium';
    const LOW = 'low';

    const TITLE = [
        self::HIGH => 'Высокий',
        self::MEDIUM => 'Средний',
        self::LOW => 'Низкий',
    ];

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'event_priority';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'title'], 'required'],
            [['is_active'], 'boolean'],
            [['order'], 'default', 'value' => null],
            [['order'], 'integer'],
            [['name', 'title'], 'string', 'max' => 255],
            [['name'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'name' => 'Name',
            'title' => 'Title',
            'is_active' => 'Is Active',
            'order' => 'Order',
        ];
    }

    /**
     * Gets query for [[Events]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventQuery
     */
    public function getEvents()
    {
        return $this->hasMany(Event::class, ['priority' => 'name']);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\EventPriorityQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\EventPriorityQuery(get_called_class());
    }
}

```

## common/models/EventSocket.php
```php
<?php

namespace common\models;

use Ratchet\ConnectionInterface;
use Ratchet\MessageComponentInterface;

class EventSocket implements MessageComponentInterface
{
    protected $clients;

    public function __construct() {
        $this->clients = new \SplObjectStorage;
    }

    public function onOpen(ConnectionInterface $conn) {
        // Store the new connection to send messages to later
        $this->clients->attach($conn);

        echo "New connection! ({$conn->resourceId})\n";
    }

    public function onMessage(ConnectionInterface $from, $msg) {
        $numRecv = count($this->clients) - 1;
        echo sprintf('Connection %d sending message "%s" to %d other connection%s' . "\n"
            , $from->resourceId, $msg, $numRecv, $numRecv == 1 ? '' : 's');

        foreach ($this->clients as $client) {
//            if ($from !== $client) {
                // The sender is not the receiver, send to each client connected
                $client->send($msg);
//            }
        }
    }

    public function onClose(ConnectionInterface $conn) {
        // The connection is closed, remove it, as we can no longer send it messages
        $this->clients->detach($conn);

        echo "Connection {$conn->resourceId} has disconnected\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e) {
        echo "An error has occurred: {$e->getMessage()}\n";

        $conn->close();
    }
}
```

## common/models/EventStatus.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "event_status".
 *
 * @property string $name
 * @property string $title
 * @property bool $is_active
 * @property int $order
 *
 * @property Event[] $events
 */
class EventStatus extends \yii\db\ActiveRecord
{
    const WAITING = 'waiting';
    const IN_WORK = 'in_work';
    const PAUSED = 'paused';
    const DONE = 'done';
    const DELETED = 'deleted';

    const TITLE = [
        self::WAITING => 'В ожидании',
        self::IN_WORK => 'В работе',
        self::PAUSED => 'Приостановлен',
        self::DONE => 'Обработан',
        self::DELETED => 'Удален',
    ];

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'event_status';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'title'], 'required'],
            [['is_active'], 'boolean'],
            [['order'], 'default', 'value' => null],
            [['order'], 'integer'],
            [['name', 'title'], 'string', 'max' => 255],
            [['name'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'name' => 'Name',
            'title' => 'Title',
            'is_active' => 'Is Active',
            'order' => 'Order',
        ];
    }

    /**
     * Gets query for [[Events]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventQuery
     */
    public function getEvents()
    {
        return $this->hasMany(Event::class, ['status' => 'name']);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\EventStatusQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\EventStatusQuery(get_called_class());
    }
}

```

## common/models/PatientExtra.php
```php
<?php

namespace common\models;

use Yii;
use yii\base\Model;
use yii\helpers\ArrayHelper;

/**
 *
 * PatientExtra class
 * Patient->extra json field model
 *
 * @property string|null $education
 * @property string|null $oms_number
 * @property string|null $profession
 * @property string|null $address_reg
 * @property string|null $nationality
 * @property string|null $oms_company
 * @property string|null $address_match
 * @property string|null $address_residence
 *
 * @property-read null|string $educationName
 */
class PatientExtra extends Model
{
    public $education;
    public $oms_number;
    public $profession;
    public $address_reg;
    public $nationality;
    public $oms_company;
    public $address_match;
    public $address_residence;

    // Образование
    const EDU_HIGHER = 1;
    const EDU_SECONDARY = 2;
    const EDU_GENERAL = 3;
    const EDU_PRIMARY = 4;
    const EDU_ELEMENTARY = 5;
    const EDU_UNKNOWN = 6;

    public static function educationList(): array
    {
        return [
            self::EDU_HIGHER => 'Высшее',
            self::EDU_SECONDARY => 'Среднее',
            self::EDU_GENERAL => 'Общее: среднее',
            self::EDU_PRIMARY => 'Основное',
            self::EDU_ELEMENTARY => 'Начальное',
            self::EDU_UNKNOWN => 'Неизвестно',
        ];
    }

    public function rules()
    {
        return [
            [['address_match'], 'boolean'],
            [['address_match'], 'default', 'value' => false],
            [['address_reg'], 'string', 'max' => 512],
            [['address_residence'], 'string', 'max' => 512],

            [['oms_number'], 'string', 'max' => 16],
            [['oms_number'], 'match', 'pattern' => '/^[0-9]{16}$/', 'message' => Yii::t('app', 'The field "OMS Number" must consist of 16 digits')],
            [['oms_company'], 'string', 'max' => 256],

            [['education'], 'default', 'value' => null],
            [['education'], 'in', 'range' => array_keys(self::educationList()), 'skipOnEmpty' => true],

            [['nationality'], 'string', 'max' => 128],
            [['profession'], 'string', 'max' => 128],
        ];
    }

    public function attributeLabels()
    {
        return [
            'address_match' => Yii::t('app', 'Address Match'),
            'address_reg' => Yii::t('app', 'Address Reg'),
            'address_residence' => Yii::t('app', 'Address Residence'),
            'oms_number' => Yii::t('app', 'Oms Number'),
            'oms_company' => Yii::t('app', 'Oms Company'),
            'nationality' => Yii::t('app', 'Nationality'),
            'profession' => Yii::t('app', 'Profession'),
            'education' => Yii::t('app', 'Education'),
        ];
    }

    public function getEducationName(): ?string
    {
        return ArrayHelper::getValue(self::educationList(), $this->education);
    }

    public function load($data, $formName = null)
    {
        $result = parent::load($data, $formName);

        if ($this->address_match) {
            $this->address_residence = $this->address_reg;
        }

        return $result;
    }
}
```

## common/models/Pusher.php
```php
<?php

namespace common\models;

use Ratchet\ConnectionInterface;
use Ratchet\Wamp\WampServerInterface;

class Pusher implements WampServerInterface
{
    /**
     * A lookup of all the topics clients have subscribed to
     */
    protected $subscribedTopics = [];

    public function onSubscribe(ConnectionInterface $conn, $topic) {
        $this->subscribedTopics[$topic->getId()] = $topic;
    }

    /**
     * @param string JSON'ified string we'll receive from ZeroMQ
     */
    public function onEventEntry($entry)
    {
        $entryData = json_decode($entry, true);

        // If the lookup topic object isn't set there is no one to publish to
        if (!array_key_exists($entryData['priority'], $this->subscribedTopics)) {
            return;
        }

        $topic = $this->subscribedTopics[$entryData['priority']];

        // re-send the data to all the clients subscribed to that category
        $topic->broadcast($entryData);
    }

    public function onUnSubscribe(ConnectionInterface $conn, $topic) {
    }
    public function onOpen(ConnectionInterface $conn) {
    }
    public function onClose(ConnectionInterface $conn) {
    }
    public function onCall(ConnectionInterface $conn, $id, $topic, array $params) {
        // In this application if clients send data it's because the user hacked around in console
        $conn->callError($id, $topic, 'You are not allowed to make calls')->close();
    }
    public function onPublish(ConnectionInterface $conn, $topic, $event, array $exclude, array $eligible) {
        // In this application if clients send data it's because the user hacked around in console
        $conn->close();
    }
    public function onError(ConnectionInterface $conn, \Exception $e) {
    }
}
```

## common/models/DispatcherWorkingStatus.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "dispatcher_working_status".
 *
 * @property string $name
 * @property string $title
 * @property bool $is_active
 * @property int $order
 *
 * @property User[] $users
 */
class DispatcherWorkingStatus extends \yii\db\ActiveRecord
{
    const WORKING = 'working';
    const PAUSED = 'paused';

    const TITLE = [
        self::WORKING => 'Работает',
        self::PAUSED => 'Приостановлен',
    ];

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'dispatcher_working_status';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'title'], 'required'],
            [['is_active'], 'boolean'],
            [['order'], 'default', 'value' => null],
            [['order'], 'integer'],
            [['name', 'title'], 'string', 'max' => 255],
            [['name'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'name' => 'Name',
            'title' => 'Title',
            'is_active' => 'Is Active',
            'order' => 'Order',
        ];
    }

    /**
     * Gets query for [[Users]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getUsers()
    {
        return $this->hasMany(User::class, ['dispatcher_working_status' => 'name']);
    }
}

```

## common/models/AimsCatalog.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "aims_catalog".
 *
 * @property int $id
 * @property string $name
 * @property float $value
 * @property string $type
 * @property int $external_id
 * @property bool $is_enabled
 */
class AimsCatalog extends \yii\db\ActiveRecord
{
    const TYPE_HBA_1_C = 'hba_1_c';
    const TYPE_GLUCOSE_PREPRANDIAL = 'glucose_preprandial';
    const TYPE_GLUCOSE_POSTPRANDIAL = 'glucose_postprandial';
    const TYPE_LPNP = 'lpnp';
    const TYPE_AD = 'ad';
    const TYPE_TARGET_TIME = 'target_time';


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'aims_catalog';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'type', 'external_id'], 'required'],
            [['external_id', 'value'], 'default', 'value' => null],
            [['external_id'], 'integer'],
            [['value'], 'double'],
            [['is_enabled'], 'boolean'],
            [['name', 'type'], 'string', 'max' => 255],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'name' => Yii::t('app', 'Name'),
            'value' => Yii::t('app', 'Value'),
            'type' => Yii::t('app', 'Type'),
            'external_id' => Yii::t('app', 'External ID'),
            'is_enabled' => Yii::t('app', 'Is Enabled'),
        ];
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\AimsCatalogQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\AimsCatalogQuery(get_called_class());
    }
}

```

## common/models/PatientCondition.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "patient_condition".
 *
 * @property string $name
 * @property string $title
 * @property bool $is_active
 * @property int $order
 *
 * @property RegistryListOfEvent[] $registryListOfEvents
 */
class PatientCondition extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'patient_condition';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'title'], 'required'],
            [['is_active'], 'boolean'],
            [['order'], 'default', 'value' => null],
            [['order'], 'integer'],
            [['name', 'title'], 'string', 'max' => 255],
            [['name'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'name' => 'Name',
            'title' => 'Title',
            'is_active' => 'Is Active',
            'order' => 'Order',
        ];
    }

    /**
     * Gets query for [[RegistryListOfEvents]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\RegistryListOfEventQuery
     */
    public function getRegistryListOfEvents()
    {
        return $this->hasMany(RegistryListOfEvent::class, ['patient_condition' => 'name']);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\EventQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\EventQuery(get_called_class());
    }
}

```

## common/models/Patient.php
```php
<?php

namespace common\models;

use api\components\ApiResponseMessage;
use api\components\exceptions\UnprocessableContentException;
use common\models\helpers\DateTimeHelper;
use common\traits\ConvertedUpdatedAndCreatedDateTimeAttrValuesTrait;
use DateTime;
use Yii;
use yii\db\ActiveRecord;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;
use yii\helpers\ArrayHelper;

/**
 * This is the model class for table "public.patient".
 *
 * @property int $id
 * @property string|null $email E-mail
 * @property string $first_name Имя
 * @property string $last_name Фамилия
 * @property string $patronymic Отчество
 * @property string|null $phone Контактный телефон
 * @property string|null $snils СНИЛС
 * @property int|null $gender Пол
 * @property string|null $birth_at Дата рождения
 * @property int|null $hospital_id ЛПУ
 * @property int $status Статус
 * @property string|null $extra Дополнительные данные
 * @property string|null $auth_key Ключ авторизации пароля
 * @property string|null $password_hash Хэш пароля
 * @property string|null $password_reset_token Токен сброса пароля
 * @property string|null $verification_token Токен верификации
 * @property string|null $access_token Токен авторизации
 * @property string $created_at Дата создания
 * @property string $updated_at Дата изменения
 * @property string|null $external_id
 *
 * @property-read string $fullName
 * @property-read string $fullNameWithBirthdayAndAge
 * @property-read string|null $birthAtHumanReadableFormat ДД.ММ.ГГГГ
 * @property-read string|null $age
 * @property-read  Hospital|null $hospital
 * @property-read  Card|null $card
 * @property-read string $updatedAtPhpFormat
 * @property-read string $createdAtPhpFormat
 * @property-read MonitoringArterialPressure[]|array|null $arterialPressure
 * @property-read MonitoringGlucose[]|array|null $glucose
 */
class Patient extends ActiveRecord
{
    use ConvertedUpdatedAndCreatedDateTimeAttrValuesTrait;

    const SCENARIO_API_CREATE = 'api_create';
    const SCENARIO_API_UPDATE = 'api_update';
    const SCENARIO_API_CREATE_EVENT = 'api_create_event';
    const SCENARIO_API_CREATE_INTERNAL_PATIENT = 'api_create_internal_patient';

    const STATUS_DELETED = 0;
    const STATUS_INACTIVE = 9;
    const STATUS_ACTIVE = 10;

    const GENDER_FEMALE = 0;
    const GENDER_MALE = 1;
    const GENDER_INDETERMINATE = 2;

    public $hospitalData;
    public $cardData;
    private ?Hospital $_hospital;

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.patient';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['first_name', 'last_name', 'patronymic'], 'required', 'on' => [self::SCENARIO_API_CREATE, self::SCENARIO_API_CREATE_EVENT, self::SCENARIO_DEFAULT, self::SCENARIO_API_CREATE_INTERNAL_PATIENT]],
            [['external_id'], 'required'],
            [['id', 'external_id'], 'integer'],
            [['id', 'external_id'], 'unique', 'on' => [self::SCENARIO_API_CREATE, self::SCENARIO_DEFAULT, self::SCENARIO_API_CREATE_INTERNAL_PATIENT]],
            [['gender', 'hospital_id', 'status'], 'integer'],
            [['email', 'access_token'], 'string', 'max' => 256],
            [['first_name', 'last_name', 'patronymic', 'auth_key'], 'string', 'max' => 32],
            [['phone', 'snils'], 'string', 'max' => 11],
            [['password_hash'], 'string', 'max' => 60],
            [['password_reset_token', 'verification_token'], 'string', 'max' => 43],

            [['verification_token', 'access_token', 'password_reset_token', 'external_id'], 'unique'],
            ['email', 'unique', 'on' => [self::SCENARIO_DEFAULT]],

            [['gender', 'hospital_id'], 'default', 'value' => null],
            ['status', 'default', 'value' => self::STATUS_INACTIVE],

            ['birth_at', 'date', 'format' => 'php:Y-m-d'],
            ['birthAtHumanReadableFormat', 'string'],

            ['extra', 'validateExtra'],
            [['hospitalData'], 'validateHospital', 'skipOnEmpty' => true, 'skipOnError' => false, 'on' => [self::SCENARIO_API_CREATE_EVENT]],
            [['cardData'], 'validateCard', 'skipOnEmpty' => false, 'skipOnError' => false, 'on' => [self::SCENARIO_API_CREATE_EVENT]],

            ['gender', 'in', 'range' => [self::GENDER_FEMALE, self::GENDER_MALE, self::GENDER_INDETERMINATE]],
            ['status', 'in', 'range' => [self::STATUS_DELETED, self::STATUS_INACTIVE, self::STATUS_ACTIVE]],

            [['hospital_id'], 'exist', 'skipOnError' => true, 'targetClass' => Hospital::class, 'targetAttribute' => ['hospital_id' => 'id'], 'on' => [self::SCENARIO_API_CREATE, self::SCENARIO_API_CREATE_INTERNAL_PATIENT, self::SCENARIO_DEFAULT]],
        ];
    }

    public function behaviors()
    {
        return [
            'timestamp' => [
                'class' => TimestampBehavior::class,
                'attributes' => [
                    ActiveRecord::EVENT_BEFORE_INSERT => ['created_at', 'updated_at'],
                    ActiveRecord::EVENT_BEFORE_UPDATE => ['updated_at'],
                ],
                'value' => new Expression('NOW()'),
            ]
        ];
    }

    public function scenarios()
    {
        $scenarios = parent::scenarios();
        $scenarios[self::SCENARIO_API_CREATE] = [
            'id',
            'email',
            'first_name',
            'last_name',
            'patronymic',
            'phone',
            'snils',
            'gender',
            'birth_at',
            'hospital_id',
            'status',
            'extra',
        ];
        $scenarios[self::SCENARIO_API_CREATE_INTERNAL_PATIENT] = $scenarios[self::SCENARIO_API_CREATE];
        $scenarios[self::SCENARIO_API_CREATE_EVENT] = [
            'email',
            'first_name',
            'last_name',
            'patronymic',
            'phone',
            'snils',
            'gender',
            'birth_at',
            'hospital_id',
            'status',
            'extra',
            'hospitalData',
            'cardData',
        ];
        $scenarios[self::SCENARIO_API_UPDATE] = [
            'email',
            'first_name',
            'last_name',
            'patronymic',
            'phone',
            'snils',
            'gender',
            'birth_at',
            'hospital_id',
            'status',
            'extra',
        ];
        return $scenarios;
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'email' => Yii::t('app', 'Email'),
            'first_name' => Yii::t('app', 'First Name'),
            'last_name' => Yii::t('app', 'Last Name'),
            'patronymic' => Yii::t('app', 'Patronymic'),
            'fullName' => Yii::t('app', 'Full Name'),
            'phone' => Yii::t('app', 'Phone'),
            'snils' => Yii::t('app', 'Snils'),
            'gender' => Yii::t('app', 'Gender'),
            'birth_at' => Yii::t('app', 'Birth At'),
            'birthAtHumanReadableFormat' => Yii::t('app', 'Birth At'),
            'age' => Yii::t('app', 'Age'),
            'hospital_id' => Yii::t('app', 'Hospital ID'),
            'status' => Yii::t('app', 'Status'),
            'extra' => Yii::t('app', 'Extra'),
            'auth_key' => Yii::t('app', 'Auth Key'),
            'password_hash' => Yii::t('app', 'Password Hash'),
            'password_reset_token' => Yii::t('app', 'Password Reset Token'),
            'verification_token' => Yii::t('app', 'Verification Token'),
            'access_token' => Yii::t('app', 'Access Token'),
            'created_at' => Yii::t('app', 'Created At'),
            'updated_at' => Yii::t('app', 'Updated At'),
            'external_id' => Yii::t('app', 'External ID'),
        ];
    }

    public function validateExtra($attribute, $params, $validator)
    {
        $model = new PatientExtra();
        if (!$model->load($this->{$attribute}, '') || !$model->validate()) {
            $this->addError($attribute, $model->getErrors());
        }
    }

    public function validateHospital($attribute, $params, $validator)
    {
        $model = new Hospital();
        // TODO refactor this !
        switch ($this->scenario) {
            case self::SCENARIO_API_CREATE_EVENT:
                $model->scenario = Hospital::SCENARIO_API_CREATE_EVENT;
                break;
        }
        if (!$model->load($this->{$attribute}, '') || !$model->validate()) {
            $this->addError($attribute, $model->getErrors());
        }
    }

    public function validateCard($attribute, $params, $validator)
    {
        $model = new Card();
        switch ($this->scenario) {
            case self::SCENARIO_API_CREATE_EVENT:
                $model->scenario = Card::SCENARIO_API_CREATE_EVENT;
                break;
        }
        if (!$model->load($this->{$attribute}, '') || !$model->validate()) {
            $this->addError($attribute, $model->getErrors());
        }
    }

    public function getHospital()
    {
        return $this->hasOne(Hospital::class, ['id' => 'hospital_id']);
    }

    public function getCard()
    {
        return $this->hasOne(Card::class, ['patient_id' => 'id']);
    }

    public function getArterialPressure()
    {
        return $this->hasMany(MonitoringArterialPressure::class, ['patient_id' => 'id']);
    }

    public function getGlucose()
    {
        return $this->hasMany(MonitoringGlucose::class, ['patient_id' => 'id']);
    }

    public function load($data, $formName = null)
    {
        $load = parent::load($data, $formName);

        switch ($this->scenario) {
            case Patient::SCENARIO_API_CREATE:
                $this->external_id = $this->id;
                break;
        }

        return $load;
    }

    public function beforeSave($insert)
    {
        try {
            switch ($this->scenario) {
                case Patient::SCENARIO_API_CREATE:
                    unset($this->id);
                    break;
                case Patient::SCENARIO_API_CREATE_EVENT:
                    $model = new Hospital(['scenario' => Hospital::SCENARIO_API_CREATE_EVENT]);
                    if (empty($this->hospitalData)) return parent::beforeSave($insert);
                    return parent::beforeSave($insert) && $model->updateOrCreateIfNotExists($this->hospitalData);
            }

            return parent::beforeSave($insert);
        } catch (UnprocessableContentException $e) {
            switch ($e->getMessage()) {
                case ApiResponseMessage::HOSPITAL_MODEL_LOAD_ERROR:
                    $exception = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_HOSPITAL_MODEL_LOAD_ERROR);
                    $exception->setModel($e->getModel());
                    throw $exception;
                default:
                    throw $e;
            }
        } catch (\Exception $e) {
            throw $e;
        }
    }

    public function afterSave($insert, $changedAttributes)
    {
        parent::afterSave($insert, $changedAttributes);

        try {
            switch ($this->scenario) {
                case Patient::SCENARIO_API_CREATE_EVENT:
                    $model = new Card(['scenario' => Card::SCENARIO_API_CREATE_EVENT]);
                    $result = $model->updateOrCreateIfNotExists($this->cardData, $this->id);
                    $this->cardData = $model->attributes;
                    return $result;
            }
        } catch (UnprocessableContentException $e) {
            switch ($e->getMessage()) {
                case ApiResponseMessage::HOSPITAL_MODEL_LOAD_ERROR:
                    $exception = new UnprocessableContentException(ApiResponseMessage::PATIENT_EVENT_CREATE_HOSPITAL_MODEL_LOAD_ERROR);
                    $exception->setModel($e->getModel());
                    throw $exception;
                default:
                    throw $e;
            }
        } catch (\Exception $e) {
            throw $e;
        }
    }

    public function getFullName(): string
    {
        return implode(' ', [$this->last_name, $this->first_name, $this->patronymic]);
    }

    public function getBirthAtHumanReadableFormat()
    {
        return DateTimeHelper::format($this->birth_at, 'Y-m-d', 'd.m.Y');
    }

    public function setBirthAtHumanReadableFormat($date)
    {
        if (!DateTimeHelper::validate($date, 'd.m.Y')) return null;
        return $this->birth_at = DateTime::createFromFormat("d.m.Y", $date)->format("Y-m-d");
    }

    public function getAge()
    {
        if (DateTimeHelper::validate($this->birth_at, 'Y-m-d') === false) {
            return null;
        }

        $datetimeBirth = new DateTime($this->birth_at);
        $datetimeNow = new DateTIme('now');
        $interval = $datetimeBirth->diff($datetimeNow);

        return $interval->format('%y');
    }

    public function getFullNameWithBirthdayAndAge(): string
    {
        return implode("\n", array_filter([
            $this->fullName,
            $this->birthAtHumanReadableFormat,
            (empty($this->age) ? null : "Возраст: " . $this->age)
        ]));
    }

    public function updateOrCreateIfNotExistsByExternalId(array &$data): bool
    {
        $id = ArrayHelper::getValue($data, 'id');

        if ( empty( $model = self::findOne(['external_id' => $id]) ) ) {
            $model = new self(['scenario' => $this->getScenario()]);
            $model->external_id = $id;
        }

        $model->scenario = $this->scenario;

        unset($data['id']);

        if ($model->load($data, '') === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_MODEL_LOAD_ERROR);
            $e->setModel($model);
            throw $e;
        }

        if ($model->save() === false) {
            $e = new UnprocessableContentException(ApiResponseMessage::PATIENT_MODEL_SAVE_ERROR);
            $e->setModel($model);
            throw $e;
        }

        $this->setAttributes($model->getAttributes());
        $this->cardData = $model->cardData;
        $this->hospitalData = $model->hospitalData;

        $data['id'] = $model->id;

        return true;
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\PatientQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\PatientQuery(get_called_class());
    }
}

```

## common/models/query/MonitoringGlucoseQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringGlucose]].
 *
 * @see \common\models\MonitoringGlucose
 */
class MonitoringGlucoseQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringGlucose[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringGlucose|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/UserQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\User]].
 *
 * @see \common\models\User
 */
class UserQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\User[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\User|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/PatientQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Patient]].
 *
 * @see \common\models\Patient
 */
class PatientQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Patient[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Patient|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringSleepDurationQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringSleepDuration]].
 *
 * @see \common\models\MonitoringSleepDuration
 */
class MonitoringSleepDurationQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringSleepDuration[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringSleepDuration|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/EventQuery.php
```php
<?php

namespace common\models\query;

use common\models\Event;
use common\models\EventPriority;
use common\models\EventStatus;

/**
 * This is the ActiveQuery class for [[\common\models\PatientCondition]].
 *
 * @see \common\models\PatientCondition
 */
class EventQuery extends \yii\db\ActiveQuery
{
    public function priorityHigh()
    {
        return $this->andWhere(['event.priority' => EventPriority::HIGH]);
    }

    public function statusWaiting()
    {
        return $this->andWhere(['event.status' => EventStatus::WAITING]);
    }

    public function statusInWork()
    {
        return $this->andWhere(['event.status' => EventStatus::IN_WORK]);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\PatientCondition[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\PatientCondition|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringMenstrualCycleQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringMenstrualCycle]].
 *
 * @see \common\models\MonitoringMenstrualCycle
 */
class MonitoringMenstrualCycleQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringMenstrualCycle[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringMenstrualCycle|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MailQueueQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MailQueue]].
 *
 * @see \common\models\MailQueue
 */
class MailQueueQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MailQueue[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MailQueue|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/InstrumentalResearchQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\InstrumentalResearch]].
 *
 * @see \common\models\InstrumentalResearch
 */
class InstrumentalResearchQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\InstrumentalResearch[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\InstrumentalResearch|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/EventResultQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\EventResult]].
 *
 * @see \common\models\EventResult
 */
class EventResultQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\EventResult[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\EventResult|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringDrugsTakenQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringDrugsTaken]].
 *
 * @see \common\models\MonitoringDrugsTaken
 */
class MonitoringDrugsTakenQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringDrugsTaken[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringDrugsTaken|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringArterialPressureQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringArterialPressure]].
 *
 * @see \common\models\MonitoringArterialPressure
 */
class MonitoringArterialPressureQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringArterialPressure[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringArterialPressure|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/EventTypeQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\EventType]].
 *
 * @see \common\models\EventType
 */
class EventTypeQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\EventType[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\EventType|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/DrugClinicProblemQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\DrugClinicProblem]].
 *
 * @see \common\models\DrugClinicProblem
 */
class DrugClinicProblemQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\DrugClinicProblem[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\DrugClinicProblem|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/CardHealthQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\CardHealth]].
 *
 * @see \common\models\CardHealth
 */
class CardHealthQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\CardHealth[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\CardHealth|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/EventStatusQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\EventStatus]].
 *
 * @see \common\models\EventStatus
 */
class EventStatusQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\EventStatus[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\EventStatus|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringPhysicalActivityQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringPhysicalActivity]].
 *
 * @see \common\models\MonitoringPhysicalActivity
 */
class MonitoringPhysicalActivityQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringPhysicalActivity[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringPhysicalActivity|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/DrugGroupQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\DrugGroup]].
 *
 * @see \common\models\DrugGroup
 */
class DrugGroupQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\DrugGroup[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\DrugGroup|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringLastQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringLast]].
 *
 * @see \common\models\MonitoringLast
 */
class MonitoringLastQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringLast[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringLast|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/ConsultationsQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Consultations]].
 *
 * @see \common\models\Consultations
 */
class ConsultationsQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Consultations[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Consultations|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/HospitalQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Hospital]].
 *
 * @see \common\models\Hospital
 */
class HospitalQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Hospital[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Hospital|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/LaboratoryResearchQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\LaboratoryResearch]].
 *
 * @see \common\models\LaboratoryResearch
 */
class LaboratoryResearchQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\LaboratoryResearch[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\LaboratoryResearch|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/CardHistoryQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\CardHistory]].
 *
 * @see \common\models\CardHistory
 */
class CardHistoryQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\CardHistory[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\CardHistory|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/CardCacheQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\CardCache]].
 *
 * @see \common\models\CardCache
 */
class CardCacheQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\CardCache[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\CardCache|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/DrugGroupIrrationalQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\DrugGroupIrrational]].
 *
 * @see \common\models\DrugGroupIrrational
 */
class DrugGroupIrrationalQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\DrugGroupIrrational[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\DrugGroupIrrational|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/PatientConditionQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\PatientCondition]].
 *
 * @see \common\models\PatientCondition
 */
class PatientConditionQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\PatientCondition[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\PatientCondition|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/DrugsQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Drugs]].
 *
 * @see \common\models\Drugs
 */
class DrugsQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Drugs[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Drugs|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/CardQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Card]].
 *
 * @see \common\models\Card
 */
class CardQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Card[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Card|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MigrationQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Migration]].
 *
 * @see \common\models\Migration
 */
class MigrationQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Migration[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Migration|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MkbQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Mkb]].
 *
 * @see \common\models\Mkb
 */
class MkbQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Mkb[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Mkb|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/BlankQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\Blank]].
 *
 * @see \common\models\Blank
 */
class BlankQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\Blank[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\Blank|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/EventClassifierQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\EventClassifier]].
 *
 * @see \common\models\EventClassifier
 */
class EventClassifierQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\EventClassifier[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\EventClassifier|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/EventPriorityQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\EventPriority]].
 *
 * @see \common\models\EventPriority
 */
class EventPriorityQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\EventPriority[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\EventPriority|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/BlankInstrumentalQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\BlankInstrumental]].
 *
 * @see \common\models\BlankInstrumental
 */
class BlankInstrumentalQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\BlankInstrumental[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\BlankInstrumental|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/BlankConsultationsQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\BlankConsultations]].
 *
 * @see \common\models\BlankConsultations
 */
class BlankConsultationsQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\BlankConsultations[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\BlankConsultations|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/SppvrHistoryQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\SppvrHistory]].
 *
 * @see \common\models\SppvrHistory
 */
class SppvrHistoryQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\SppvrHistory[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\SppvrHistory|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/DrugSchemeGroupQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\DrugSchemeGroup]].
 *
 * @see \common\models\DrugSchemeGroup
 */
class DrugSchemeGroupQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\DrugSchemeGroup[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\DrugSchemeGroup|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/BlankLaboratoryQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\BlankLaboratory]].
 *
 * @see \common\models\BlankLaboratory
 */
class BlankLaboratoryQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\BlankLaboratory[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\BlankLaboratory|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/AimsCatalogQuery.php
```php
<?php

namespace common\models\query;

use common\models\AimsCatalog;

/**
 * This is the ActiveQuery class for [[\common\models\AimsCatalog]].
 *
 * @see \common\models\AimsCatalog
 */
class AimsCatalogQuery extends \yii\db\ActiveQuery
{
    public function active()
    {
        return $this->andWhere(['is_enabled' => true]);
    }

    public function typeHba1C()
    {
        return $this->andWhere(['type' => AimsCatalog::TYPE_HBA_1_C]);
    }

    public function typeGlucosePreprandial()
    {
        return $this->andWhere(['type' => AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL]);
    }

    public function typeGlucosePostprandial()
    {
        return $this->andWhere(['type' => AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL]);
    }

    public function typeLpnp()
    {
        return $this->andWhere(['type' => AimsCatalog::TYPE_LPNP]);
    }

    public function typeAd()
    {
        return $this->andWhere(['type' => AimsCatalog::TYPE_AD]);
    }

    public function typeTargetTime()
    {
        return $this->andWhere(['type' => AimsCatalog::TYPE_TARGET_TIME]);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\AimsCatalog[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\AimsCatalog|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/MonitoringStressLoadQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\MonitoringStressLoad]].
 *
 * @see \common\models\MonitoringStressLoad
 */
class MonitoringStressLoadQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringStressLoad[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\MonitoringStressLoad|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/query/DiabetesTypeQuery.php
```php
<?php

namespace common\models\query;

/**
 * This is the ActiveQuery class for [[\common\models\DiabetesType]].
 *
 * @see \common\models\DiabetesType
 */
class DiabetesTypeQuery extends \yii\db\ActiveQuery
{
    /*public function active()
    {
        return $this->andWhere('[[status]]=1');
    }*/

    /**
     * {@inheritdoc}
     * @return \common\models\DiabetesType[]|array
     */
    public function all($db = null)
    {
        return parent::all($db);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\DiabetesType|array|null
     */
    public function one($db = null)
    {
        return parent::one($db);
    }
}

```

## common/models/MonitoringGlucose.php
```php
<?php

namespace common\models;

use api\components\ApiResponseMessage;
use common\params\GlucoseMomentParam;
use common\params\GlucosePostParam;
use common\params\GlucosePrepParam;
use common\params\StatusColorParam;
use DateTime;
use Yii;

/**
 * This is the model class for table "public.monitoring_glucose".
 *
 * @property int $id
 * @property int $patient_id Идентификатор пациента
 * @property int|null $aim_preprandial Терапевтическая цель по уровню глюкозы (препрандиальный) натощак
 * @property int|null $aim_postprandial Терапевтическая цель по уровню глюкозы (постпрандиальный) через два часа после еды
 * @property float $glucose Показатели глюкозы
 * @property int $condition Состояние пациента во время замера
 * @property int $moment Момент измерения глюкозы
 * @property string $taken_at Другое дата/время замера
 * @property int $status Статус
 * @property string $created_at Дата создания
 *
 * @property integer|null $patientExternalId
 * @property-read Patient $patientByExternalId
 * @property-read Card $patientCard
 * @property-read AimsCatalog[]|null|array $aimPreprandialByExternalId
 * @property-read AimsCatalog[]|null|array $aimPostprandialByExternalId
 */
class MonitoringGlucose extends \yii\db\ActiveRecord
{
    const MOMENT_1 = 1;
    const MOMENT_2 = 2;
    const MOMENT_POST = 3;
    const MOMENT_OTHER = 4;

    const LIST = [
        self::MOMENT_1 => 'Натощак (до завтрака)',
        self::MOMENT_2 => 'Перед едой',
        self::MOMENT_POST => 'После еды',
        self::MOMENT_OTHER => 'Другое',
    ];

    public $patientExternalId = null;

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.monitoring_glucose';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['patient_id', 'glucose', 'condition', 'moment', 'patientExternalId'], 'required'],
            [['patient_id', 'aim_preprandial', 'aim_postprandial', 'condition', 'moment'], 'default', 'value' => null],
            [['patient_id', 'aim_preprandial', 'aim_postprandial', 'condition', 'moment', 'status', 'patientExternalId'], 'integer'],
            [['glucose'], 'number'],
            [['taken_at', 'created_at'], 'date', 'format' => 'php:Y-m-d H:i:s'],
            [['created_at'], 'default', 'value' => (new DateTime())->format('Y-m-d H:i:s')],

            ['taken_at', 'default', 'value' => function (self $model, $attribute) {
                if ((int) $model->moment === self::MOMENT_OTHER) {
                    return (new DateTime())->format('Y-m-d H:i:s');
                }
                return $model->taken_at;
            }],

            ['status', 'default', 'value' => function (self $model, $attribute) {
                return $this->getStatus();
            }],

            [['taken_at', 'status', 'created_at'], 'required'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => Yii::t('app', 'ID'),
            'patient_id' => Yii::t('app', 'Patient ID'),
            'aim_preprandial' => Yii::t('app', 'Aim Preprandial'),
            'aim_postprandial' => Yii::t('app', 'Aim Postprandial'),
            'glucose' => Yii::t('app', 'Glucose'),
            'condition' => Yii::t('app', 'Condition'),
            'moment' => Yii::t('app', 'Moment'),
            'taken_at' => Yii::t('app', 'Taken At'),
            'status' => Yii::t('app', 'Status'),
            'created_at' => Yii::t('app', 'Created At'),
        ];
    }

    public function load($data, $formName = null)
    {
        $load = parent::load($data, $formName);

        $this->patient_id = $this->patientByExternalId->id;
        $cardModel = $this->patientCard;

        if (empty($cardModel)) {
            $this->addError('patient_id', ApiResponseMessage::PATIENT_CARD_NOT_FOUND);
            return false;
        }

        if (empty($cardModel->aim['glucose_preprandial'])) {
            $this->addError('patient_id', ApiResponseMessage::PATIENT_CARD_AIM_GLUCOSE_PREPRANDIAL_EMPTY);
            return false;
        }

        if (empty($cardModel->aim['glucose_postprandial'])) {
            $this->addError('patient_id', ApiResponseMessage::PATIENT_CARD_AIM_GLUCOSE_POSTPRANDIAL_EMPTY);
            return false;
        }

        $this->aim_preprandial = $cardModel->aim['glucose_preprandial'];
        $this->aim_postprandial = $cardModel->aim['glucose_postprandial'];

        return $load;
    }

    public function getPatientByExternalId()
    {
        return Patient::findOne(['external_id' => $this->patientExternalId]);
    }

    public function getAimPreprandialByExternalId()
    {
        return $this->hasOne(AimsCatalog::class, ['external_id' => 'aim_preprandial'])->andWhere(['type' => AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL]);
    }

    public function getAimPostprandialByExternalId()
    {
        return $this->hasOne(AimsCatalog::class, ['external_id' => 'aim_postprandial'])->andWhere(['type' => AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL]);
    }

    public function getPatientCard()
    {
        if (!empty($patientModel = $this->patientByExternalId)) {
            return $patientModel->card;
        }
        return null;
    }

    /**
     * Определение статуса показателей глюкозы пациента по целевым значениям
     */
    public function getStatus(): int
    {
        $norm = $this->moment == self::MOMENT_POST
            ? (GlucosePostParam::value($this->aim_postprandial) ?? 0)
            : (GlucosePrepParam::value($this->aim_preprandial) ?? 0);

        if ($this->glucose < 3 || $this->glucose >= 13) {
            // Неважно есть цель или нет, показатель меньше 3 или больше или равно 13 - красный статус
            return StatusColorParam::COLOR_RED;
        } elseif ($this->glucose <= 3.9 || $this->glucose > $norm) {
            // Если показатель меньше 3.9 или при наличии цели он выше цели - желтый статус
            // Если цели нет, то статус автоматически становится жёлтым
            return StatusColorParam::COLOR_YELLOW;
        }

        return StatusColorParam::COLOR_GREEN;
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\MonitoringGlucoseQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\MonitoringGlucoseQuery(get_called_class());
    }
}

```

## common/models/helpers/DateTimeHelper.php
```php
<?php

namespace common\models\helpers;

use DateTime;

class DateTimeHelper
{

    /**
     * Валидирует дату по заданному формату
     *
     * @param string|null $date
     * @param string $format
     * @return bool
     */
    public static function validate($date, $format = 'Y-m-d'): bool
    {
        $d = DateTime::createFromFormat($format, $date);
        return $d && $d->format($format) === $date;
    }


    /**
     * @param string|null $date дата/время
     * @param string $incoming_format входящий формат
     * @param string $outcome_format исходящий формат
     * @return string|null
     */
    public static function format($date, string $incoming_format, string $outcome_format)
    {
        return (self::validate($date, $incoming_format))
            ? DateTime::createFromFormat($incoming_format, $date)->format($outcome_format)
            : null;
    }

    public static function now(string $format = 'Y-m-d'): string
    {
        return date($format);
    }

    public static function convertPgDateTimeToPhpDateTime($value)
    {
        if (empty($value) || DateTimeHelper::validate($value, 'Y-m-d H:i:s')) return $value;
        return (new DateTime($value))->format('Y-m-d H:i:s');
    }
}
```

## common/models/EventType.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "event_type".
 *
 * @property string $name
 * @property string $title
 * @property bool $is_active
 * @property int $order
 *
 * @property Event[] $events
 */
class EventType extends \yii\db\ActiveRecord
{
    const PATIENT = 'patient';
    const DOCTOR = 'doctor';
    const DISPATCHER = 'dispatcher';
    const SYSTEM = 'system';

    const TITLE = [
        self::PATIENT => 'Пациент',
        self::DOCTOR => 'Доктор',
        self::DISPATCHER => 'Диспетчер',
        self::SYSTEM => 'Система',
    ];

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'event_type';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'title'], 'required'],
            [['is_active'], 'boolean'],
            [['order'], 'default', 'value' => null],
            [['order'], 'integer'],
            [['name', 'title'], 'string', 'max' => 255],
            [['name'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'name' => 'Name',
            'title' => 'Title',
            'is_active' => 'Is Active',
            'order' => 'Order',
        ];
    }

    /**
     * Gets query for [[Events]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventQuery
     */
    public function getEvents()
    {
        return $this->hasMany(Event::class, ['type' => 'name']);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\EventTypeQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\EventTypeQuery(get_called_class());
    }
}

```

## common/models/RegistryListOfEvent.php
```php
<?php

namespace common\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\ActiveRecord;
use yii\db\Expression;

/**
 * This is the model class for table "public.registry_list_of_event".
 *
 * @property int $id
 * @property int $event_id
 * @property bool $limited_mobility
 * @property string|null $patient_condition
 * @property bool $doctor_appointment
 * @property bool $telemedicine
 * @property int|null $doctor_id
 * @property bool $doctor_alert
 * @property bool $doctor_alerted
 * @property string|null $doctor_alerted_at
 * @property int|null $medical_institution_id
 * @property bool $medical_institution_at_place_of_attachment
 * @property bool $medical_institution_alert
 * @property bool $medical_institution_alerted
 * @property string|null $medical_institution_alerted_at
 * @property bool $calling_doctor_at_home
 * @property int|null $medical_institution_urgently_id
 * @property bool $medical_institution_urgently_at_place_of_attachment
 * @property bool $need_calling_an_ambulance
 * @property string $created_at
 * @property string|null $updated_at
 * @property string|null $created_by
 *
 * @property User $doctor
 * @property Event $event
 * @property Hospital $medicalInstitution
 * @property Hospital $medicalInstitutionUrgently
 * @property PatientCondition $patientCondition
 */
class RegistryListOfEvent extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'public.registry_list_of_event';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['event_id'], 'required'],
            [['event_id', 'doctor_id', 'medical_institution_id', 'medical_institution_urgently_id'], 'default', 'value' => null],
            [['event_id', 'doctor_id', 'medical_institution_id', 'medical_institution_urgently_id'], 'integer'],
            [['limited_mobility', 'doctor_appointment', 'telemedicine', 'doctor_alert', 'doctor_alerted', 'medical_institution_at_place_of_attachment', 'medical_institution_alert', 'medical_institution_alerted', 'calling_doctor_at_home', 'medical_institution_urgently_at_place_of_attachment', 'need_calling_an_ambulance'], 'boolean'],
            [['doctor_alerted_at', 'medical_institution_alerted_at'], 'safe'],
            [['patient_condition'], 'string', 'max' => 255],
            [['medical_institution_id'], 'exist', 'skipOnError' => true, 'targetClass' => Hospital::class, 'targetAttribute' => ['medical_institution_id' => 'id']],
            [['medical_institution_urgently_id'], 'exist', 'skipOnError' => true, 'targetClass' => Hospital::class, 'targetAttribute' => ['medical_institution_urgently_id' => 'id']],
            [['patient_condition'], 'exist', 'skipOnError' => true, 'targetClass' => PatientCondition::class, 'targetAttribute' => ['patient_condition' => 'name']],
            [['event_id'], 'exist', 'skipOnError' => true, 'targetClass' => Event::class, 'targetAttribute' => ['event_id' => 'id']],
            [['doctor_id'], 'exist', 'skipOnError' => true, 'targetClass' => User::class, 'targetAttribute' => ['doctor_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'event_id' => 'Event ID',
            'limited_mobility' => 'Limited Mobility',
            'patient_condition' => 'Patient Condition',
            'doctor_appointment' => 'Doctor Appointment',
            'telemedicine' => 'Telemedicine',
            'doctor_id' => 'Doctor ID',
            'doctor_alert' => 'Doctor Alert',
            'doctor_alerted' => 'Doctor Alerted',
            'doctor_alerted_at' => 'Doctor Alerted At',
            'medical_institution_id' => 'Medical Institution ID',
            'medical_institution_at_place_of_attachment' => 'Medical Institution At Place Of Attachment',
            'medical_institution_alert' => 'Medical Institution Alert',
            'medical_institution_alerted' => 'Medical Institution Alerted',
            'medical_institution_alerted_at' => 'Medical Institution Alerted At',
            'calling_doctor_at_home' => 'Calling Doctor At Home',
            'medical_institution_urgently_id' => 'Medical Institution Urgently',
            'medical_institution_urgently_at_place_of_attachment' => 'Medical Institution Urgently At Place Of Attachment',
            'need_calling_an_ambulance' => 'Need Calling An Ambulance',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'created_by' => 'Created By',
        ];
    }

    public function behaviors()
    {
        return [
            'timestamp' => [
                'class' => TimestampBehavior::class,
                'attributes' => [
                    ActiveRecord::EVENT_BEFORE_INSERT => ['created_at', 'updated_at'],
                    ActiveRecord::EVENT_BEFORE_UPDATE => ['updated_at'],
                ],
                'value' => new Expression('NOW()'),
            ]
        ];
    }

    /**
     * Gets query for [[Doctor]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\UserQuery
     */
    public function getDoctor()
    {
        return $this->hasOne(User::class, ['id' => 'doctor_id']);
    }

    /**
     * Gets query for [[Event]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\UserQuery
     */
    public function getEvent()
    {
        return $this->hasOne(Event::class, ['id' => 'event_id']);
    }

    /**
     * Gets query for [[MedicalInstitution]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\HospitalQuery
     */
    public function getMedicalInstitution()
    {
        return $this->hasOne(Hospital::class, ['id' => 'medical_institution_id']);
    }

    /**
     * Gets query for [[MedicalInstitutionUrgently]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\HospitalQuery
     */
    public function getMedicalInstitutionUrgently()
    {
        return $this->hasOne(Hospital::class, ['id' => 'medical_institution_urgently_id']);
    }

    /**
     * Gets query for [[PatientCondition]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\PatientConditionQuery
     */
    public function getPatientCondition()
    {
        return $this->hasOne(PatientCondition::class, ['name' => 'patient_condition']);
    }

    public function castToTypeBoolean(array $fieldNames)
    {
        foreach ($fieldNames as $field) {
            if ($this->hasAttribute($field)) {
                switch ($this->{$field}) {
                    case 'true':
                    case '1':
                    case 'yes':
                        $this->{$field} = true;
                        break;
                    case 'false':
                    case '0':
                    case 'no':
                    case '':
                        $this->{$field} = false;
                        break;
                    default:
                        $this->{$field} = null;
                }
            }
        }
    }
}

```

## common/models/EventClassifier.php
```php
<?php

namespace common\models;

use Yii;

/**
 * This is the model class for table "event_classifier".
 *
 * @property string $name
 * @property string $title
 * @property bool $is_active
 * @property int $order
 * @property string|null $external_id
 *
 * @property Event[] $events
 */
class EventClassifier extends \yii\db\ActiveRecord
{
    const OTHER = 'other';

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'event_classifier';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['name', 'title'], 'required'],
            [['is_active'], 'boolean'],
            [['order'], 'default', 'value' => null],
            [['order'], 'integer'],
            [['name', 'title'], 'string', 'max' => 255],
            [['external_id'], 'string', 'max' => 50],
            [['name'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'name' => 'Name',
            'title' => 'Title',
            'is_active' => 'Is Active',
            'order' => 'Order',
            'external_id' => 'External ID',
        ];
    }

    /**
     * Gets query for [[Events]].
     *
     * @return \yii\db\ActiveQuery|\common\models\query\EventQuery
     */
    public function getEvents()
    {
        return $this->hasMany(Event::class, ['classifier' => 'name']);
    }

    /**
     * {@inheritdoc}
     * @return \common\models\query\EventClassifierQuery the active query used by this AR class.
     */
    public static function find()
    {
        return new \common\models\query\EventClassifierQuery(get_called_class());
    }
}

```

## console/migrations/m221025_203246_create_mkb_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%mkb}}`.
 * Has foreign keys to the tables:
 *
 * - `{{%diabetes_type}}`
 */
class m221025_203246_create_mkb_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%mkb}}', [
            'id' => $this->primaryKey(),
            'name' => $this->string()->unique()->notNull(),
            'code' => $this->string(),
            'external_id' => $this->integer()->notNull(),
            'diabetes_type_id' => $this->integer()->notNull(),
            'is_enabled' => $this->boolean()->defaultValue(true)->notNull(),
        ]);

        // creates index for column `diabetes_type_id`
        $this->createIndex(
            '{{%idx-mkb-diabetes_type_id}}',
            '{{%mkb}}',
            'diabetes_type_id'
        );

        // add foreign key for table `{{%diabetes_type}}`
        $this->addForeignKey(
            '{{%fk-mkb-diabetes_type_id}}',
            '{{%mkb}}',
            'diabetes_type_id',
            '{{%diabetes_type}}',
            'id',
            'RESTRICT'
        );

        $this->batchInsert('{{%mkb}}', ['name', 'code', 'external_id', 'diabetes_type_id'], [
            /* ТИП 1 */
            ['E10.0 - Инсулинозависимый сахарный диабет с комой', 'E10.0', 1, 1],
            ['E10.1 - Инсулинозависимый сахарный диабет с кетоацидозом', 'E10.1', 2, 1],
            ['E10.2 - Инсулинозависимый сахарный диабет с поражением почек', 'E10.2', 3, 1],
            ['E10.3 - Инсулинозависимый сахарный диабет с поражением глаз', 'E10.3', 4, 1],
            ['E10.4 - Инсулинозависимый сахарный диабет с неврологическими осложнениями', 'E10.4', 5, 1],
            ['E10.5 - Инсулинозависимый сахарный диабет с нарушениями периферического кровообращения', 'E10.5', 6, 1],
            ['E10.6 - Инсулинозависимый сахарный диабет с другими уточненными осложнениями', 'E10.6', 7, 1],
            ['E10.7 - Инсулинозависимый сахарный диабет с множественными осложнениями', 'E10.7', 8, 1],
            ['E10.8 - Инсулинозависимый сахарный диабет с неуточненными осложнениями', 'E10.8', 9, 1],
            ['E10.9 - Инсулинозависимый сахарный диабет без осложнений', 'E10.9', 10, 1],
            /* ТИП 2 */
            ['Е11.0 - Инсулиннезависимый сахарный диабет с комой', 'Е11.0', 1, 2],
            ['Е11.1 - Инсулиннезависимый сахарный диабет с кетоацидозом', 'Е11.1', 2, 2],
            ['E11.2 - Инсулиннезависимый сахарный диабет с поражением почек', 'E11.2', 3, 2],
            ['E11.3 - Инсулиннезависимый сахарный диабет с поражениями глаз', 'E11.3', 4, 2],
            ['E11.4 - Инсулиннезависимый сахарный диабет с неврологическими осложнениями', 'E11.4', 5, 2],
            ['E11.5 - Инсулиннезависимый сахарный диабет с нарушениями периферического кровоснабжения', 'E11.5', 6, 2],
            ['E11.6 - Инсулиннезависимый сахарный  диабет с другими  уточненными осложнениями', 'E11.6', 7, 2],
            ['E11.7 - Инсулиннезависимый сахарный диабет с множественными осложнениями', 'E11.7', 8, 2],
            ['E11.8 - Инсулиннезависимый сахарный диабет с неуточненными осложнениями', 'E11.8', 9, 2],
            ['E11.9 - Инсулиннезависимый сахарный диабет без осложнений', 'E11.9', 10, 2],
            ['R73.0 - Отклонения результатов нормы теста на толерантность к глюкозе', 'R73.0', 11, 2],
            ['R73.9 - Гипергликемия неуточненная', 'R73.9', 12, 2],
            ['E66.0 - Ожирение, обусловленное избыточным поступлением энергетических ресурсов', 'E66.0', 14, 2],
        ]);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        // drops foreign key for table `{{%diabetes_type}}`
        $this->dropForeignKey(
            '{{%fk-mkb-diabetes_type_id}}',
            '{{%mkb}}'
        );

        // drops index for column `diabetes_type_id`
        $this->dropIndex(
            '{{%idx-mkb-diabetes_type_id}}',
            '{{%mkb}}'
        );

        $this->dropTable('{{%mkb}}');
    }
}

```

## console/migrations/m221203_091618_drop_event_result_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the dropping of table `{{%event_result}}`.
 */
class m221203_091618_drop_event_result_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->dropForeignKey('fk_event_result_event_id', '{{%event_result}}');
        $this->dropTable('{{%event_result}}');
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->createTable('{{%event_result}}', [
            'event_id' => $this->integer()->unique()->notNull()->comment('Идентификатор события'),
            'reason' => $this->string(256)->notNull()->comment('Причина обращения'),
            'condition' => $this->string(256)->notNull()->comment('Состояние пациента'),
            'text' => $this->string(256)->notNull()->comment('Результат события'),
            'created_at timestamp with time zone NOT NULL',
            'updated_at timestamp with time zone NOT NULL',
        ]);

        $this->addCommentOnColumn('{{%event_result}}', 'created_at', 'Дата создания');
        $this->addCommentOnColumn('{{%event_result}}', 'updated_at', 'Дата изменения');

        $this->addForeignKey('fk_event_result_event_id',
            '{{%event_result}}', 'event_id', '{{%event}}', 'id', 'CASCADE');
    }
}

```

## console/migrations/m221203_091755_create_event_type_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%event_type}}`.
 */
class m221203_091755_create_event_type_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%event_type}}', [
            'name' => $this->string(),
            'title' => $this->string()->notNull(),
            'is_active' => $this->boolean()->notNull()->defaultValue(true),
            'order' => $this->integer()->notNull()->defaultValue(0),
        ]);

        $this->addPrimaryKey('event_type_pkey', 'event_type', ['name']);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%event_type}}');
    }
}

```

## console/migrations/m221018_110910_add_external_id_column_to_patient_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles adding columns to table `{{%patient}}`.
 */
class m221018_110910_add_external_id_column_to_patient_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->addColumn('{{%patient}}', 'external_id', $this->string());
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropColumn('{{%patient}}', 'external_id');
    }
}

```

## console/migrations/m221212_212509_add_check_user_id_or_patient_id_filled_to_event_table.php
```php
<?php

use yii\db\Migration;

/**
 * Class m221212_182509_add_check_user_id_or_patient_id_filled_to_event_table
 */
class m221212_212509_add_check_user_id_or_patient_id_filled_to_event_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->execute('
            ALTER TABLE event 
            ADD CONSTRAINT patient_or_user_id_filled_check CHECK (
                (
                    COALESCE((user_id)::BOOLEAN::INTEGER, 0)
                    +
                    COALESCE((patient_id)::BOOLEAN::INTEGER, 0)
                ) = 1
            )
        ');
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->execute('ALTER TABLE event DROP CONSTRAINT patient_or_user_id_filled_check');
    }

    /*
    // Use up()/down() to run migration code without a transaction.
    public function up()
    {

    }

    public function down()
    {
        echo "m221212_182509_add_check_user_id_or_patient_id_filled_to_event_table cannot be reverted.\n";

        return false;
    }
    */
}

```

## console/migrations/m221203_091805_create_registry_list_of_event_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%registry_list_of_event}}`.
 * Has foreign keys to the tables:
 *
 * - `{{%user}}`
 * - `{{%patient_condition}}`
 * - `{{%user}}`
 * - `{{%hospital}}`
 * - `{{%hospital}}`
 */
class m221203_091805_create_registry_list_of_event_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%registry_list_of_event}}', [
            'id' => $this->primaryKey(),
            'event_id' => $this->integer()->notNull(),
            'limited_mobility' => $this->boolean()->defaultValue(false)->notNull(),
            'patient_condition' => $this->string(),
            'doctor_appointment' => $this->boolean()->notNull()->defaultValue(false),
            'telemedicine' => $this->boolean()->notNull()->defaultValue(false),
            'doctor_id' => $this->integer(),
            'doctor_alert' => $this->boolean()->notNull()->defaultValue(false),
            'doctor_alerted' => $this->boolean()->notNull()->defaultValue(false),
            'doctor_alerted_at' => $this->datetime(),
            'medical_institution_id' => $this->integer(),
            'medical_institution_at_place_of_attachment' => $this->boolean()->notNull()->defaultValue(false),
            'medical_institution_alert' => $this->boolean()->notNull()->defaultValue(false),
            'medical_institution_alerted' => $this->boolean()->notNull()->defaultValue(false),
            'medical_institution_alerted_at' => $this->datetime(),
            'calling_doctor_at_home' => $this->boolean()->notNull()->defaultValue(false),
            'medical_institution_urgently_id' => $this->integer(),
            'medical_institution_urgently_at_place_of_attachment' => $this->boolean()->notNull()->defaultValue(false),
            'need_calling_an_ambulance' => $this->boolean()->notNull()->defaultValue(false),
            'created_at' => $this->datetime()->notNull(),
            'updated_at' => $this->datetime(),
            'created_by' => $this->string(10),
        ]);

        // creates index for column `event_id`
        $this->createIndex(
            '{{%idx-registry_list_of_event-event_id}}',
            '{{%registry_list_of_event}}',
            'event_id'
        );

        // add foreign key for table `{{%user}}`
        $this->addForeignKey(
            '{{%fk-registry_list_of_event-event_id}}',
            '{{%registry_list_of_event}}',
            'event_id',
            '{{%event}}',
            'id',
            'CASCADE'
        );

        // creates index for column `patient_condition`
        $this->createIndex(
            '{{%idx-registry_list_of_event-patient_condition}}',
            '{{%registry_list_of_event}}',
            'patient_condition'
        );

        // add foreign key for table `{{%patient_condition}}`
        $this->addForeignKey(
            '{{%fk-registry_list_of_event-patient_condition}}',
            '{{%registry_list_of_event}}',
            'patient_condition',
            '{{%patient_condition}}',
            'name',
            'CASCADE'
        );

        // creates index for column `doctor_id`
        $this->createIndex(
            '{{%idx-registry_list_of_event-doctor_id}}',
            '{{%registry_list_of_event}}',
            'doctor_id'
        );

        // add foreign key for table `{{%user}}`
        $this->addForeignKey(
            '{{%fk-registry_list_of_event-doctor_id}}',
            '{{%registry_list_of_event}}',
            'doctor_id',
            '{{%user}}',
            'id',
            'CASCADE'
        );

        // creates index for column `medical_institution_id`
        $this->createIndex(
            '{{%idx-registry_list_of_event-medical_institution_id}}',
            '{{%registry_list_of_event}}',
            'medical_institution_id'
        );

        // add foreign key for table `{{%hospital}}`
        $this->addForeignKey(
            '{{%fk-registry_list_of_event-medical_institution_id}}',
            '{{%registry_list_of_event}}',
            'medical_institution_id',
            '{{%hospital}}',
            'id',
            'CASCADE'
        );

        // creates index for column `medical_institution_urgently_id`
        $this->createIndex(
            '{{%idx-registry_list_of_event-medical_institution_urgently_id}}',
            '{{%registry_list_of_event}}',
            'medical_institution_urgently_id'
        );

        // add foreign key for table `{{%hospital}}`
        $this->addForeignKey(
            '{{%fk-registry_list_of_event-medical_institution_urgently_id}}',
            '{{%registry_list_of_event}}',
            'medical_institution_urgently_id',
            '{{%hospital}}',
            'id',
            'CASCADE'
        );
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        // drops foreign key for table `{{%user}}`
        $this->dropForeignKey(
            '{{%fk-registry_list_of_event-event_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops index for column `event_id`
        $this->dropIndex(
            '{{%idx-registry_list_of_event-event_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops foreign key for table `{{%patient_condition}}`
        $this->dropForeignKey(
            '{{%fk-registry_list_of_event-patient_condition}}',
            '{{%registry_list_of_event}}'
        );

        // drops index for column `patient_condition`
        $this->dropIndex(
            '{{%idx-registry_list_of_event-patient_condition}}',
            '{{%registry_list_of_event}}'
        );

        // drops foreign key for table `{{%user}}`
        $this->dropForeignKey(
            '{{%fk-registry_list_of_event-doctor_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops index for column `doctor_id`
        $this->dropIndex(
            '{{%idx-registry_list_of_event-doctor_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops foreign key for table `{{%hospital}}`
        $this->dropForeignKey(
            '{{%fk-registry_list_of_event-medical_institution_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops index for column `medical_institution_id`
        $this->dropIndex(
            '{{%idx-registry_list_of_event-medical_institution_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops foreign key for table `{{%hospital}}`
        $this->dropForeignKey(
            '{{%fk-registry_list_of_event-medical_institution_urgently_id}}',
            '{{%registry_list_of_event}}'
        );

        // drops index for column `medical_institution_urgently_id`
        $this->dropIndex(
            '{{%idx-registry_list_of_event-medical_institution_urgently_id}}',
            '{{%registry_list_of_event}}'
        );

        $this->dropTable('{{%registry_list_of_event}}');
    }
}

```

## console/migrations/m221212_151412_drop_doctor_id_not_null_contstraint_from_card_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the dropping of table `{{%doctor_id_not_null_contstraint_from_card}}`.
 */
class m221212_151412_drop_doctor_id_not_null_contstraint_from_card_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->execute('alter table card alter column doctor_id drop not null;');
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->execute('alter table card alter column doctor_id set not null;');
    }
}

```

## console/migrations/m221025_203031_create_diabetes_type_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%diabetes_type}}`.
 */
class m221025_203031_create_diabetes_type_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%diabetes_type}}', [
            'id' => $this->primaryKey(),
            'name' => $this->string()->notNull(),
            'type' => $this->string()->unique()->notNull(),
            'external_id' => $this->integer()->notNull(),
            'is_enabled' => $this->boolean()->defaultValue(true)->notNull(),
        ]);

        $this->batchInsert('{{%diabetes_type}}', ['id', 'name', 'type', 'external_id'], [
            [1, '1 тип', 'diabetes_type_1', 0],
            [2, '2 тип', 'diabetes_type_2', 1],
        ]);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%diabetes_type}}');
    }
}

```

## console/migrations/m221203_091800_create_event_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%event}}`.
 * Has foreign keys to the tables:
 *
 * - `{{%user}}`
 * - `{{%patient}}`
 * - `{{%event_classifier}}`
 * - `{{%event_type}}`
 * - `{{%event_status}}`
 * - `{{%user}}`
 */
class m221203_091800_create_event_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%event}}', [
            'id' => $this->primaryKey(),
            'user_id' => $this->integer(),
            'patient_id' => $this->integer(),
            'classifier' => $this->string(),
            'classifier_comment' => $this->text(),
            'priority' => $this->string()->notNull(),
            'type' => $this->string()->notNull(),
            'status' => $this->string()->notNull(),
            'taking_to_work_at' => $this->datetime(),
            'deadline_at' => $this->datetime(),
            'source' => $this->string(),
            'is_system_event' => $this->boolean()->defaultValue(false)->notNull()->comment("Событие, сгенерированное системой"),
            'dispatcher_id_who_took_to_work' => $this->integer(),
            'compensation_stage' => $this->string(),
            'diabetes_type' => $this->integer(),
            'mkb_id' => $this->integer(),
            'insulin_requiring' => $this->boolean(),
            'created_at' => $this->datetime()->notNull(),
            'updated_at' => $this->datetime(),
            'created_by' => $this->string(10),
        ]);

        // creates index for column `user_id`
        $this->createIndex(
            '{{%idx-event-user_id}}',
            '{{%event}}',
            'user_id'
        );

        // add foreign key for table `{{%user}}`
        $this->addForeignKey(
            '{{%fk-event-user_id}}',
            '{{%event}}',
            'user_id',
            '{{%user}}',
            'id',
            'CASCADE'
        );

        // creates index for column `patient_id`
        $this->createIndex(
            '{{%idx-event-patient_id}}',
            '{{%event}}',
            'patient_id'
        );

        // add foreign key for table `{{%patient}}`
        $this->addForeignKey(
            '{{%fk-event-patient_id}}',
            '{{%event}}',
            'patient_id',
            '{{%patient}}',
            'id',
            'CASCADE'
        );

        // add foreign key for table `{{%event_classifier}}`
        $this->addForeignKey(
            '{{%fk-event-classifier}}',
            '{{%event}}',
            'classifier',
            '{{%event_classifier}}',
            'name',
            'RESTRICT'
        );

        // add foreign key for table `{{%event_type}}`
        $this->addForeignKey(
            '{{%fk-event-type}}',
            '{{%event}}',
            'type',
            '{{%event_type}}',
            'name',
            'RESTRICT'
        );

        // add foreign key for table `{{%event_status}}`
        $this->addForeignKey(
            '{{%fk-event-status}}',
            '{{%event}}',
            'status',
            '{{%event_status}}',
            'name',
            'RESTRICT'
        );

        // add foreign key for table `{{%event_priority}}`
        $this->addForeignKey(
            '{{%fk-event-priority}}',
            '{{%event}}',
            'priority',
            '{{%event_priority}}',
            'name',
            'RESTRICT'
        );

        // add foreign key for table `{{%user}}`
        $this->addForeignKey(
            '{{%fk-event-dispatcher_id_who_took_to_work}}',
            '{{%event}}',
            'dispatcher_id_who_took_to_work',
            '{{%user}}',
            'id',
            'CASCADE'
        );

        // add foreign key for table `{{%diabetes_type}}`
        $this->addForeignKey(
            '{{%fk-event-diabetes_type}}',
            '{{%event}}',
            'diabetes_type',
            '{{%diabetes_type}}',
            'id',
            'RESTRICT'
        );

        // add foreign key for table `{{%mkb}}`
        $this->addForeignKey(
            '{{%fk-event-mkb}}',
            '{{%event}}',
            'mkb_id',
            '{{%mkb}}',
            'id',
            'RESTRICT'
        );
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        // drops foreign key for table `{{%user}}`
        $this->dropForeignKey(
            '{{%fk-event-user_id}}',
            '{{%event}}'
        );

        // drops index for column `user_id`
        $this->dropIndex(
            '{{%idx-event-user_id}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%patient}}`
        $this->dropForeignKey(
            '{{%fk-event-patient_id}}',
            '{{%event}}'
        );

        // drops index for column `patient_id`
        $this->dropIndex(
            '{{%idx-event-patient_id}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%event_classifier}}`
        $this->dropForeignKey(
            '{{%fk-event-classifier}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%event_type}}`
        $this->dropForeignKey(
            '{{%fk-event-type}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%event_status}}`
        $this->dropForeignKey(
            '{{%fk-event-status}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%event_priority}}`
        $this->dropForeignKey(
            '{{%fk-event-priority}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%user}}`
        $this->dropForeignKey(
            '{{%fk-event-dispatcher_id_who_took_to_work}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%diabetes_type}}`
        $this->dropForeignKey(
            '{{%fk-event-diabetes_type}}',
            '{{%event}}'
        );

        // drops foreign key for table `{{%mkb}}`
        $this->dropForeignKey(
            '{{%fk-event-mkb}}',
            '{{%event}}'
        );

        $this->dropTable('{{%event}}');
    }
}

```

## console/migrations/m230110_100142_add_values_to_dispatcher_working_status_table.php
```php
<?php

use common\models\DispatcherWorkingStatus;
use yii\db\Migration;

/**
 * Class m230110_070142_add_values_to_dispatcher_working_status_table
 */
class m230110_100142_add_values_to_dispatcher_working_status_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->batchInsert('dispatcher_working_status', ['name', 'title'], array_map(function ($name, $title) {
            return [$name, $title];
        }, array_keys(DispatcherWorkingStatus::TITLE),DispatcherWorkingStatus::TITLE));
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        echo "m221208_082113_fill_event_tables cannot be reverted.\n";

        return true;
    }

    /*
    // Use up()/down() to run migration code without a transaction.
    public function up()
    {

    }

    public function down()
    {
        echo "m230110_070142_add_values_to_dispatcher_working_status_table cannot be reverted.\n";

        return false;
    }
    */
}

```

## console/migrations/m230108_125706_add_dispatcher_working_status_column_to_user_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles adding columns to table `{{%user}}`.
 * Has foreign keys to the tables:
 *
 * - `{{%dispatcher_working_status}}`
 */
class m230108_125706_add_dispatcher_working_status_column_to_user_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->addColumn('{{%user}}', 'dispatcher_working_status', $this->string());

        // creates index for column `dispatcher_working_status`
        $this->createIndex(
            '{{%idx-user-dispatcher_working_status}}',
            '{{%user}}',
            'dispatcher_working_status'
        );

        // add foreign key for table `{{%dispatcher_working_status}}`
        $this->addForeignKey(
            '{{%fk-user-dispatcher_working_status}}',
            '{{%user}}',
            'dispatcher_working_status',
            '{{%dispatcher_working_status}}',
            'name',
            'RESTRICT'
        );
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        // drops foreign key for table `{{%dispatcher_working_status}}`
        $this->dropForeignKey(
            '{{%fk-user-dispatcher_working_status}}',
            '{{%user}}'
        );

        // drops index for column `dispatcher_working_status`
        $this->dropIndex(
            '{{%idx-user-dispatcher_working_status}}',
            '{{%user}}'
        );

        $this->dropColumn('{{%user}}', 'dispatcher_working_status');
    }
}

```

## console/migrations/m221203_091619_drop_event_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the dropping of table `{{%event}}`.
 */
class m221203_091619_drop_event_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->dropForeignKey('fk_event_object_id', '{{%event}}');
        $this->dropForeignKey('fk_event_dispatcher_id', '{{%event}}');
        $this->dropTable('{{%event}}');
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->createTable('{{%event}}', [
            'id' => $this->primaryKey(),
            'dispatcher_id' => $this->integer()->defaultValue(null)->comment('Идентификатор диспетчера'),
            'object_id' => $this->integer()->notNull()->comment('Идентификатор объекта'),
            'name' => $this->string(64)->notNull()->comment('Наименование'),
            'priority' => $this->tinyInteger()->notNull()->comment('Приоритет'),
            'type' => $this->tinyInteger()->notNull()->comment('Тип'),
            'status' => $this->tinyInteger()->notNull()->comment('Статус'),
            'created_at timestamp with time zone NOT NULL',
            'updated_at timestamp with time zone NOT NULL',
        ]);

        $this->addCommentOnColumn('{{%event}}', 'created_at', 'Дата создания');
        $this->addCommentOnColumn('{{%event}}', 'updated_at', 'Дата изменения');

        $this->addForeignKey('fk_event_object_id',
            '{{%event}}', 'object_id', '{{%patient}}', 'id', 'CASCADE');
        $this->addForeignKey('fk_event_dispatcher_id',
            '{{%event}}', 'dispatcher_id', '{{%user}}', 'id', 'CASCADE');
    }
}

```

## console/migrations/m221208_082113_fill_event_tables.php
```php
<?php

use common\models\EventPriority;
use common\models\EventStatus;
use common\models\EventType;
use yii\db\Migration;

/**
 * Class m221208_082113_fill_event_tables
 */
class m221208_082113_fill_event_tables extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->execute('TRUNCATE public.event_status CASCADE');
        $this->batchInsert('event_status', ['name', 'title'], array_map(function ($name, $title) {
            return [$name, $title];
        }, array_keys(EventStatus::TITLE),EventStatus::TITLE));

        $this->execute('TRUNCATE public.event_type CASCADE');
        $this->batchInsert('event_type', ['name', 'title'], array_map(function ($name, $title) {
            return [$name, $title];
        }, array_keys(EventType::TITLE),EventType::TITLE));

        $this->execute('TRUNCATE public.event_priority CASCADE');
        $this->batchInsert('event_priority', ['name', 'title'], array_map(function ($name, $title) {
            return [$name, $title];
        }, array_keys(EventPriority::TITLE),EventPriority::TITLE));
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        echo "m221208_082113_fill_event_tables cannot be reverted.\n";

        return true;
    }

    /*
    // Use up()/down() to run migration code without a transaction.
    public function up()
    {

    }

    public function down()
    {
        echo "m221208_082113_fill_event_tables cannot be reverted.\n";

        return false;
    }
    */
}

```

## console/migrations/m221203_091754_create_event_classifier_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%event_classifier}}`.
 */
class m221203_091754_create_event_classifier_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%event_classifier}}', [
            'name' => $this->string(),
            'title' => $this->string()->notNull(),
            'is_active' => $this->boolean()->notNull()->defaultValue(true),
            'order' => $this->integer()->notNull()->defaultValue(0),
            'external_id' => $this->string(50),
        ]);

        $this->addPrimaryKey('event_classifier_pkey', 'event_classifier', ['name']);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%event_classifier}}');
    }
}

```

## console/migrations/m221203_091758_create_event_status_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%event_status}}`.
 */
class m221203_091758_create_event_status_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%event_status}}', [
            'name' => $this->string(),
            'title' => $this->string()->notNull(),
            'is_active' => $this->boolean()->notNull()->defaultValue(true),
            'order' => $this->integer()->notNull()->defaultValue(0),
        ]);

        $this->addPrimaryKey('event_status_pkey', 'event_status', ['name']);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%event_status}}');
    }
}

```

## console/migrations/m221203_091802_create_patient_condition_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%patient_condition}}`.
 */
class m221203_091802_create_patient_condition_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%patient_condition}}', [
            'name' => $this->string(),
            'title' => $this->string()->notNull(),
            'is_active' => $this->boolean()->notNull()->defaultValue(true),
            'order' => $this->integer()->notNull()->defaultValue(0),
        ]);

        $this->addPrimaryKey('patient_condition_pkey', 'patient_condition', ['name']);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%patient_condition}}');
    }
}

```

## console/migrations/m221203_091759_create_event_priority_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%event_priority}}`.
 */
class m221203_091759_create_event_priority_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%event_priority}}', [
            'name' => $this->string(),
            'title' => $this->string()->notNull(),
            'is_active' => $this->boolean()->notNull()->defaultValue(true),
            'order' => $this->integer()->notNull()->defaultValue(0),
        ]);

        $this->addPrimaryKey('event_priority_pkey', 'event_priority', ['name']);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%event_priority}}');
    }
}

```

## console/migrations/m230108_125614_create_dispatcher_working_status_table.php
```php
<?php

use yii\db\Migration;

/**
 * Handles the creation of table `{{%dispatcher_working_status}}`.
 */
class m230108_125614_create_dispatcher_working_status_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%dispatcher_working_status}}', [
            'name' => $this->string(),
            'title' => $this->string()->notNull(),
            'is_active' => $this->boolean()->notNull()->defaultValue(true),
            'order' => $this->integer()->notNull()->defaultValue(0),
        ]);

        $this->addPrimaryKey('dispatcher_working_status_pkey', 'dispatcher_working_status', ['name']);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%dispatcher_working_status}}');
    }
}

```

## console/migrations/m221026_153244_create_aims_catalog_table.php
```php
<?php

use common\models\AimsCatalog;
use common\params\ADParam;
use yii\db\Migration;

/**
 * Handles the creation of table `{{%aims_catalog}}`.
 */
class m221026_153244_create_aims_catalog_table extends Migration
{
    /**
     * {@inheritdoc}
     */
    public function safeUp()
    {
        $this->createTable('{{%aims_catalog}}', [
            'id' => $this->primaryKey(),
            'name' => $this->string()->notNull(),
            'value' => $this->float(),
            'type' => $this->string()->notNull(),
            'external_id' => $this->integer()->notNull(),
            'is_enabled' => $this->boolean()->defaultValue(true)->notNull(),
        ]);

        $this->batchInsert('{{%aims_catalog}}', ['name', 'value', 'type', 'external_id'], [
            /* hba1c */
            ['< 6%', 6, AimsCatalog::TYPE_HBA_1_C, 1],
            ['< 6,5%', 6.5, AimsCatalog::TYPE_HBA_1_C, 2],
            ['< 7,0%', 7, AimsCatalog::TYPE_HBA_1_C, 3],
            ['< 7,5%', 7.5, AimsCatalog::TYPE_HBA_1_C, 4],
            ['< 8,0%', 8, AimsCatalog::TYPE_HBA_1_C, 5],
            ['< 8,5%', 8.5, AimsCatalog::TYPE_HBA_1_C, 6],
            /* glucose_preprandial */
            ['4 ммоль/л', 4, AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL, 1],
            ['< 6,5 ммоль/л', 6.5, AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL, 2],
            ['< 7,0 ммоль/л', 7, AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL, 3],
            ['< 7,5 ммоль/л', 7.5, AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL, 4],
            ['< 8,0 ммоль/л', 8, AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL, 5],
            ['< 8,5 ммоль/л', 8.5, AimsCatalog::TYPE_GLUCOSE_PREPRANDIAL, 6],
            /* glucose_postprandial */
            ['6 ммоль/л', 6, AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL, 1],
            ['< 8,0 ммоль/л', 8, AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL, 2],
            ['< 9,0 ммоль/л', 9, AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL, 3],
            ['< 10,0 ммоль/л', 10, AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL, 4],
            ['< 11,0 ммоль/л', 11, AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL, 5],
            ['< 12,0 ммоль/л', 12, AimsCatalog::TYPE_GLUCOSE_POSTPRANDIAL, 6],
            /* lpnp */
            ['< 1.4 ммоль/л', 1.4, AimsCatalog::TYPE_LPNP, 1],
            ['< 1.8 ммоль/л', 1.8, AimsCatalog::TYPE_LPNP, 2],
            ['< 2.5 ммоль/л', 2.5, AimsCatalog::TYPE_LPNP, 3],
            /* ad */
            [ADParam::name(ADParam::AD_1), null, AimsCatalog::TYPE_AD, ADParam::AD_1],
            [ADParam::name(ADParam::AD_2), null, AimsCatalog::TYPE_AD, ADParam::AD_2],
            /* target_time */
            ['> 70%  (16ч 48 мин)', null, AimsCatalog::TYPE_TARGET_TIME, 1],
            ['> 50% (>12 ч)', null, AimsCatalog::TYPE_TARGET_TIME, 2],
        ]);
    }

    /**
     * {@inheritdoc}
     */
    public function safeDown()
    {
        $this->dropTable('{{%aims_catalog}}');
    }
}

```

## console/models/Sequence.php
```php
<?php

namespace console\models;

use Yii;
use yii\helpers\ArrayHelper;
use yii\helpers\Url;

class Sequence
{
    const SQL_QUERY_TEMPLATE_PATH = '@console/models/sqlQueryTemplates';

    const GET_TABLES_BY_SCHEMA_QUERY_TEMPLATE_FILE = 'getTablesBySchemaQueryTemplate.sql';
    const GET_MAX_VALUE_FOR_TABLES_SEQUENCE_QUERY_TEMPLATE_FILE = 'getMaxValueForTablesSequenceQueryTemplate.sql';
    const CREATE_SEQUENCE_QUERY_TEMPLATE_FILE = 'createSequenceQueryTemplate.sql';
    const UPDATE_SEQ_QUERY_TEMPLATE_FILE = 'updateSequenceQueryTemplate.sql';
    const SET_DEFAULT_SEQUENCE_QUERY_TEMPLATE_FILE = 'setDefaultSequenceQueryTemplate.sql';
    const DROP_SEQUENCE_QUERY_TEMPLATE_FILE = 'dropSequenceQueryTemplate.sql';
    const CHECK_SEQUENCE_EXISTS_QUERY_TEMPLATE_FILE = 'checkSequenceExistsQueryTemplate.sql';
    const CHECK_TABLE_EXISTS_QUERY_TEMPLATE_FILE = 'checkTableExistsQueryTemplate.sql';


    /* @var string $schema название схемы */
    public $schema;
    /* @var string $table таблица в схеме $this->schema */
    public $table;
    /* @var string $column название столбца, для которого используется последовательность */
    public $column;
    /* @var array $tables массив с названиями таблиц, которые есть в схеме $this->schema */
    public $tables = false;
    /**
     * @var array $tables_sequences_max_values Максимальные значения для последовательности
     * Array format:
     * [
     *   'table_name' => 'max_value'
     * ]
     * */
    public $tables_sequences_max_values = [];
    public $executed_queries = [];

    /**
     * Sequence constructor.
     * @param string $table
     * @param string $schema
     */
    public function __construct(string $schema, string $column, string $table = null)
    {
        $this->schema = $schema;
        $this->column = $column;
        $this->table = $table;
    }

    /**
     * Создание sequence'а
     */
    public function create()
    {
        $this->checkTableExists();
        if ($this->sequenceExists()) {
            return;
        }

        Yii::$app->db->createCommand(
            $this->bindParamsToQuery($this->getCreateSequenceSqlQuery(), [
                'sequence' => $this->getSequenceName(),
                'next_value' => $this->getNextValue(),
            ])
        )->execute();
    }

    /**
     * Создание sequence'ов для всех таблиц в схеме $this->schema
     */
    public function createAll()
    {
        foreach ($this->getTablesListBySchemaName() as $this->table) {
            if ($this->sequenceExists()) {
                continue;
            }
            $this->create();
        }
    }

    /**
     * Установка последовательности значением по-умолчанию для столбца
     */
    public function setColumnDefault()
    {
        $this->checkTableExists();
        $this->checkSequenceExists();

        Yii::$app->db->createCommand(
            $this->bindParamsToQuery($this->getSetColumnDefaultSqlQuery(), [
                'sequence' => $this->getSequenceName(),
            ])
        )->execute();
    }

    /**
     * Удаление sequence'а по наименованию таблицы $this->table из схемы $this->schema
     */
    public function delete()
    {
        $this->checkTableExists();
        if ($this->sequenceExists() === false) {
            return;
        }

        Yii::$app->db->createCommand(
            $this->bindParamsToQuery($this->getDropSequenceSqlQuery(), [
                'sequence' => $this->getSequenceName()
            ])
        )->execute();
    }

    /**
     * Удаление всех sequence'ов в схеме
     */
    public function deleteAll()
    {
        foreach ($this->getTablesListBySchemaName() as $this->table) {
            if ($this->sequenceExists() === false) {
                continue;
            }
            $this->delete();
        }
    }



    /**
     * Обновление (Удаление, Создание, Установка последовательности значением по умолч.) sequence'а для таблицы $this->table
     * @see delete()
     * @see create()
     * @see setColumnDefault()
     */
    public function update()
    {
        $this->checkTableExists();
        $this->delete();
        $this->create();
        $this->setColumnDefault();
    }


    /**
     * Обновление (Удаление, Создание, Установка последовательности значением по умолч.) sequence'ов для всех таблиц в схеме $this->schema
     * @see update()
     */
    public function updateAll()
    {
        foreach ($this->getTablesListBySchemaName() as $this->table) {
            $this->update();
        }
    }

    /**
     * Проверят, есть ли таблица $this->table в схеме $this->schema
     * @return bool
     * @throws \yii\db\Exception
     */
    public function tableExists(): bool
    {
        return Yii::$app->db->createCommand(
            $this->bindParamsToQuery($this->getCheckTableExistsSqlQuery())
        )->queryColumn()[0] ?? false;
    }

    /**
     * @see tableExists()
     * Если таблицы нет, то выбрасывает исключение
     * @return void
     * @throws \yii\db\Exception
     */
    protected function checkTableExists(): void
    {
        if ($this->tableExists() === false) {
            throw new \Exception(
                sprintf(
                    'Таблица %s не найдена в схеме %s',
                    $this->table,
                    $this->schema
                )
            );
        }
    }



    /**
     * Проверят, есть ли последовательность $this->getSequenceName(false) в таблице $this->table в схеме $this->schema
     * @return bool
     * @throws \yii\db\Exception
     */
    public function sequenceExists()
    {
        try {
            return !empty($sequence = Yii::$app->db->createCommand(
                $this->bindParamsToQuery($this->getCheckSequenceExistsSqlQuery(), [
                    'sequence' => $this->getSequenceName(false),
                ])
            )->queryColumn()[0]);
        } catch (\Exception $e) {
            return false;
        }
    }


    /**
     * @see sequenceExists()
     * Если таблицы нет, то выбрасывает исключение
     * @return void
     * @throws \yii\db\Exception
     */
    protected function checkSequenceExists(): void
    {
        if ($this->sequenceExists() === false) {
            throw new \Exception(
                sprintf(
                    'Последовательность %s не найдена в %s.%s',
                    $this->getSequenceName(false),
                    $this->schema,
                    $this->table
                )
            );
        }
    }


    /**
     * Получение максимального значения для столца с последовательностью
     * По умолч. столбец: ID
     *
     * @return int
     */
    public function getMaxValue(): int
    {
        return !empty($max = Yii::$app->db->createCommand(
            $this->bindParamsToQuery($this->getMaxValueForTableSqlQuery())
        )->queryColumn()[0]) ? $max : 1;
    }
    
    /**
     * @see getMaxValue() + 1
     * @return int
     * */
    public function getNextValue(): int
    {
        return $this->getMaxValue() + 1;
    }

    /**
     * Получает список таблиц по заданной схеме
     * Необходимые параметры:
     * • @see $schema
     * • @see $column
     * •
     * @return array|null
     * @throws \yii\db\Exception
     */
    public function getTablesListBySchemaName()
    {
        if ($this->tables !== false) return $this->tables;

        $tables = Yii::$app->db->createCommand(
            $this->bindParamsToQuery($this->getTablesListBySchemaSqlQuery())
        )->queryColumn();

        return $this->tables = empty(array_filter($tables)) === false ? $tables : null;
    }


    /**
     * Генерирует наименование последовательности, используя:
     * - Наименование таблицы $this->table
     * - Наименование схемы $this->schema
     * - Наименование столбца для последовательности $this->column
     * @param bool $with_schema добавить префикс с наименованием схемы
     * @return string
     */
    protected function getSequenceName(bool $with_schema = true): string
    {
        if (empty($this->table) || empty($this->schema) || empty($this->column)) {
            throw new \Exception(
                sprintf('Необходимо заполнить все параметры: 1. Наименование таблицы 2. Наименование схемы 3. Наименование столбца')
            );
        }

        $template = ':table_:column_seq';

        if ($with_schema) {
            $template = sprintf(':schema.%s', $template);
        }

        return strtr(
            $template,
            $this->getBindingParams([
                'table' => preg_replace('#([^A-Za-z0-9])#', '_', $this->table),
            ])
        );
    }



    /**
     * Получает содержимое SQL файла с шаблоном запроса
     *
     * @param string $file
     * @return string
     * @throws \Exception
     */
    protected function getSqlQueryTemplate(string $file)
    {
        if (file_exists($this->getSqlQueryTemplatePath($file)) === false) {
            throw new \Exception(
                sprintf('Файл %s отсутсвует в директории %s', $file, self::SQL_QUERY_TEMPLATE_PATH)
            );
        }

        ob_start();
        require $this->getSqlQueryTemplatePath($file);
        $sql = ob_get_contents();
        ob_end_clean();

        return $sql;
    }

    /**
     * Получает путь к файлу с SQL шаблоном
     * @param string $file
     * @return string
     */
    protected function getSqlQueryTemplatePath(string $file)
    {
        return Url::to(
            sprintf(
                '%s/%s',
                rtrim(self::SQL_QUERY_TEMPLATE_PATH, '/'),
                $file
            )
        );
    }


    /**
     * @param string $query
     * @return string
     */
    protected function logAndReturnQuery(string $query): string
    {
        $this->executed_queries[] = $query;
        return $query;
    }

    /**
     * @param array $params
     * @return array
     */
    protected function getBindingParams(array $params = []): array
    {
        $params = array_merge($this->defaultBindingParams(), $params);

        return array_combine(
            array_map(
                function ($k) {return sprintf(':%s', $k);},
                array_keys($params)
            ),
            $params
        );
    }

    protected function defaultBindingParams(): array
    {
        return [
            'schema' => $this->schema,
            'column' => $this->column,
            'table' => $this->table,
            'sequence' => false,
            'max_value' => false,
            'next_value' => false,
        ];
    }

    /**
     * @param string $query
     * @param array $params
     * @return string
     */
    protected function bindParamsToQuery(string $query, array $params = []): string
    {
        return $this->logAndReturnQuery(
            strtr(
                $query,
                $this->getBindingParams($params)
            )
        );
    }

    /**
     * @return array
     */
    public function getExecutedQueries(): array
    {
        return $this->executed_queries;
    }


    /**
     * SQL запрос-шаблон для проверки на существование таблицы $this->table в схеме $this->schema
     *
     * @return string
     */
    public function getCheckTableExistsSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::CHECK_TABLE_EXISTS_QUERY_TEMPLATE_FILE);
    }

    /**
     * SQL запрос-шаблон для проверки на существование последовательности $this->sequence в таблице $this->table в схеме $this->schema
     *
     * @return string
     */
    public function getCheckSequenceExistsSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::CHECK_SEQUENCE_EXISTS_QUERY_TEMPLATE_FILE);
    }

    /**
     * SQL запрос-шаблон для удаление последовательности $this->sequence из таблицы $this->table в схеме $this->schema
     *
     * @return string
     */
    public function getDropSequenceSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::DROP_SEQUENCE_QUERY_TEMPLATE_FILE);
    }

    /**
     * SQL запрос-шаблон для получение максимального значения столбца в таблице $this->table в схеме $this->schema
     *
     * @return string
     */
    public function getMaxValueForTableSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::GET_MAX_VALUE_FOR_TABLES_SEQUENCE_QUERY_TEMPLATE_FILE);
    }

    /**
     * SQL запрос-шаблон для создания последовательности для таблицы $this->table в схеме $this->schema
     * с заданным параметром "START WITH"
     * который задается доп. параметром ":next_value"
     *
     * @return string
     */
    public function getCreateSequenceSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::CREATE_SEQUENCE_QUERY_TEMPLATE_FILE);
    }

    /**
     * SQL запрос-шаблон для установки последовательности значением по-умолчанию для столбца $this->column в таблице $this->table в схеме $this->schema
     *
     * @return string
     */
    public function getSetColumnDefaultSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::SET_DEFAULT_SEQUENCE_QUERY_TEMPLATE_FILE);
    }

    /**
     * SQL запрос-шаблон для получение всех таблиц в схеме $this->schema
     *
     * @return string
     */
    public function getTablesListBySchemaSqlQuery(): string
    {
        return $this->getSqlQueryTemplate(self::GET_TABLES_BY_SCHEMA_QUERY_TEMPLATE_FILE);
    }
}
```

## console/models/RandomEvent.php
```php
<?php

namespace console\models;

use common\models\Event;
use common\models\EventClassifier;
use common\models\EventPriority;
use common\models\EventStatus;
use common\models\EventType;
use common\models\Mkb;
use common\models\Patient;
use common\models\User;
use DateTime;
use Exception;
use Faker\Factory;
use Faker\Generator;
use yii\base\Model;
use yii\helpers\ArrayHelper;


class RandomEvent extends Model
{
    public $priority;
    public $source;
    public $type;
    public $status;
    public $classifierManual = null;
    public $classifier = null;
    private ?Generator $faker;
    public $priorities = null;
    public $types = null;
    public $classifiers = null;
    public $users = null;
    public $patients = null;
    public $diabetesType = false;
    public $mkbList = false;
    private $batchInsertCount = 1;


    public function rules()
    {
        return [
            [['source', 'type', 'status'], 'required'],
            [['priority', 'source', 'type', 'status'], 'string'],

            [['priority'], 'exist', 'skipOnError' => true, 'targetClass' => EventPriority::class, 'targetAttribute' => ['priority' => 'name']],
            [['status'], 'exist', 'skipOnError' => true, 'targetClass' => EventStatus::class, 'targetAttribute' => ['status' => 'name']],
            [['type'], 'exist', 'skipOnError' => true, 'targetClass' => EventType::class, 'targetAttribute' => ['type' => 'name']],
        ];
    }

    public function __construct($config = [])
    {
        $this->faker = Factory::create();
        parent::__construct($config);
    }

    public function setBatchInsertCount(int $count)
    {
        $this->batchInsertCount = max($count, 1);
    }

    public function getBatchInsertCount(): int
    {
        return $this->batchInsertCount;
    }

    public function batchSave(int $count)
    {
        $this->setBatchInsertCount($count);

        foreach (range(1, $this->batchInsertCount) as $k) {
            $model = new self();
            $model->setBatchInsertCount($this->getBatchInsertCount());
            $model->setMkbList($this->getMkbList());

            if (!$model->load([
                'priority' => $this->priority ?? $this->getRandomPriority(),
                'source' => $this->source,
                'type' => $this->type ?? $this->getRandomType(),
                'status' => $this->status,
            ], '')) {
                throw new Exception("Не удалось загрузить модель RandomEvent. Ошибки: " . json_encode($model->errors, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
            }

            if (!$model->validate()) {
                throw new Exception("Ошибка валидации модели RandomEvent. Ошибки: " . json_encode($model->errors, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
            }

            if (!$model->save()) {
                throw new Exception("Ошибка сохранения модели RandomEvent. Ошибки: " . json_encode($model->errors, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
            }
        }
    }

    public function save(): bool
    {
        $model = new Event(['scenario' => Event::SCENARIO_CREATE_RANDOM_EVENT]);

        if (!$model->load(ArrayHelper::merge($this->attributes, [
            'user_id' =>  $this->getUserId(),
            'patient_id' => $this->getPatientId(),
            'classifier' => $this->getClassifier(),
            'classifier_comment' => $this->getClassifierComment(),
            'compensation_stage' => $this->getCompensationStage(),
            'diabetes_type' => $this->getDiabetesType(),
            'mkb_id' => $this->getMkbByDiabetesType(),
            'insulin_requiring' => $this->getInsulinRequiring(),
            'created_by' => 'rand',
        ]), '')) {
            $this->addErrors([
                'Event' => [
                    'message' => 'Ошибка загрузки данных в модель Event',
                    'errors' => $model->errors,
                ]
            ]);
            return false;
        }

        if (!$model->validate()) {
            $this->addErrors([
                'Event' => [
                    'message' => 'Ошибка валидации модели Event',
                    'errors' => $model->errors,
                ]
            ]);
            return false;
        }

        $model->created_at = $this->getRandomCreatedAt();
        $model->updated_at = $model->created_at;
//        throw new Exception(json_encode($model->attributes, JSON_PRETTY_PRINT));

        if (!$model->save()) {
            $this->addErrors([
                'Event' => [
                    'message' => 'Ошибка сохранения модели Event',
                    'errors' => $model->errors,
                ]
            ]);
            return false;
        }

        return true;
    }

    public function getPatientId()
    {
        switch ($this->type) {
            case EventType::PATIENT:
                return $this->getRandomPatientId();
            case EventType::DOCTOR:
            case EventType::SYSTEM:
                return null;
        }
    }

    public function getUserId()
    {
        switch ($this->type) {
            case EventType::DOCTOR:
                return $this->getRandomUserId();
            case EventType::PATIENT:
            case EventType::SYSTEM:
                return null;
        }
    }

    public function getClassifier()
    {
        if ($this->classifier !== null) return $this->classifier;
        return $this->classifier = $this->getClassifiers()[array_rand($this->getClassifiers())];
    }

    public function getClassifierComment()
    {
        return null;
//        if (!$this->getClassifierManual()) return null;
//        return $this->faker->sentence(3, true);
    }

    public function getClassifierManual(): bool
    {
        if ($this->classifierManual !== null) return $this->classifierManual;
        return $this->classifierManual = $this->getClassifier() === EventClassifier::OTHER;
    }

    public function getCompensationStage()
    {
        if ($this->eventTypeIsPatient()) return null;
        $stages = ['compensation', 'decompensation'];
        return $stages[array_rand($stages)];
    }

    public function getDiabetesType()
    {
        if ($this->diabetesType !== false) return $this->diabetesType;
        if ($this->eventTypeIsPatient()) return $this->diabetesType = null;
        return $this->diabetesType = rand(1,2);
    }

    public function getInsulinRequiring()
    {
        if ($this->eventTypeIsPatient()) return null;
        return (bool) rand(0,1);
    }

    public function getMkbList()
    {
        if ($this->mkbList !== false) return $this->mkbList;
        return $this->mkbList = Mkb::find()->asArray()->all();
    }

    public function getMkbByDiabetesType()
    {
        $mkb = $this->getMkbList();
        $diabetesType = $this->getDiabetesType();
        if (!$diabetesType) return null;
        $mkbByType = array_column(array_filter($mkb, function ($item) use ($diabetesType) {
            return $item['diabetes_type_id'] == $diabetesType;
        }), 'id');
        return $mkbByType[array_rand($mkbByType)];
    }

    public function setMkbList($list)
    {
        $this->mkbList = $list;
    }

    private function getPriorities(): array
    {
        if ($this->priorities !== null) return $this->priorities;
        return $this->priorities = [EventPriority::HIGH, EventPriority::MEDIUM, EventPriority::LOW];
    }

    private function getTypes(): array
    {
        if ($this->types !== null) return $this->types;
        return $this->types = [EventType::DOCTOR, EventType::PATIENT];
    }

    private function getClassifiers(): array
    {
        if ($this->classifiers !== null) return $this->classifiers;
        return $this->classifiers = EventClassifier::find()
            ->select('name')
            ->column();
    }

    private function eventTypeIsPatient()
    {
        return $this->type !== EventType::PATIENT;
    }

    private function getRandomPriority(): string
    {
        return $this->getPriorities()[array_rand($this->getPriorities())];
    }

    private function getRandomType(): string
    {
        return $this->getTypes()[array_rand($this->getTypes())];
    }

    private function getUserIds(): array
    {
        if ($this->users !== null) return $this->users;
        return $this->users = User::find()
            ->select('id')
            ->where(['status' => User::STATUS_ACTIVE, 'role' => User::ROLE_DOCTOR])
            ->limit($this->getBatchInsertCount())
            ->column();
    }

    private function getRandomUserId(): int
    {
        if (!count($this->getUserIds()))
            throw new Exception("Не удалось найти ни одного пользователя с типом: " . $this->type);

        return $this->getUserIds()[array_rand($this->getUserIds())];
    }

    private function getPatientIds(): array
    {
        if ($this->patients !== null) return $this->patients;
        return $this->patients = Patient::find()
            ->select('id')
            ->limit($this->getBatchInsertCount())
            ->column();
    }

    private function getRandomPatientId(): int
    {
        if (!count($this->getPatientIds()))
            throw new Exception("Не удалось найти ни одного пациента");

        return $this->getPatientIds()[array_rand($this->getPatientIds())];
    }

    private function getRandomCreatedAt(): string
    {
        $rand = rand(0, 24);
        return (new DateTime())->sub((new \DateInterval("PT{$rand}H")))->format('Y-m-d H:i:s');
    }

}
```

## console/controllers/EventController.php
```php
<?php

namespace console\controllers;

use common\models\Event;
use common\models\EventPriority;
use common\models\EventStatus;
use common\models\EventType;
use console\models\RandomEvent;
use Exception;
use Yii;
use yii\console\Controller;

class EventController extends Controller
{
    public $randomEventCount = 1;
    public $randomEventPriority = null;
    public $randomEventSource = 'sppvr';
    public $randomEventType;
    public $randomEventStatus = EventStatus::WAITING;

    public function options($actionID): array
    {
        switch ($actionID) {
            case 'generate-random':
                return [
                    'randomEventCount',
                    'randomEventPriority',
                    'randomEventSource',
                    'randomEventType',
                    'randomEventStatus',
                ];
            default:
                return [];
        }
    }

    public function optionAliases(): array
    {
        return [
            'count' => 'randomEventCount',
            'priority' => 'randomEventPriority',
            'source' => 'randomEventSource',
            'type' => 'randomEventType',
            'status' => 'randomEventStatus',
        ];
    }

    public function actionGenerateRandom()
    {
        $transaction = Yii::$app->db->beginTransaction();
        try {
            echo $this->generateRandom();
            $transaction->commit();
        } catch (Exception $e) {
            $transaction->rollBack();
            echo $e->getMessage() . PHP_EOL;
        }
    }

    private function generateRandom(): string
    {
        $model = new RandomEvent();
        $model->load([
            'priority' => $this->randomEventPriority,
            'source' => $this->randomEventSource,
            'type' => $this->randomEventType,
            'status' => $this->randomEventStatus,
        ], '');

        $model->batchSave($this->randomEventCount);

        return sprintf("Сгенерированы события: %d\n", $model->getBatchInsertCount());
    }
}
```

## console/controllers/SequenceController.php
```php
<?php

namespace console\controllers;

use console\models\Sequence;
use Yii;
use yii\console\Controller;

class SequenceController extends Controller
{
    public $table;
    /* @var string $column название столбца, для которого используется последовательность */
    public $column = 'id';
    /* @var string $schema название схемы */
    public $schema = 'medmarketdb';
    /* @var $sequence Sequence */
    protected $sequence;

    public function options($actionID)
    {
        return ['table', 'schema', 'column'];
    }

    /**
     * Удаление sequence'а по наименованию таблицы
     * Использование:
     * • php yii sequence/delete patients
     * • php yii sequence/delete --table=patients
     * @param string $table
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionDelete(string $table = null, string $schema = null, string $column = null)
    {
        if (!empty($table)) $this->table = $table;
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column, $this->table);
        $sequence->delete();
    }

    /**
     * Удаление всех sequence'ов в схеме
     * Использование:
     * • php yii sequence/delete-all
     * • php yii sequence/delete-all medmarketdb
     * • php yii sequence/delete-all --schema=medmarketdb
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionDeleteAll(string $schema = null, string $column = null)
    {
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column);
        $sequence->deleteAll();
    }

    /**
     * Создание sequence'а
     * Использование:
     * • php yii sequence/create patients
     * • php yii sequence/create --table=patients
     * @param string $table
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionCreate(string $table, string $schema = null, string $column = null)
    {
        if (!empty($table)) $this->table = $table;
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column, $this->table);
        $sequence->create();
    }

    /**
     * Создание sequence'а
     * Использование:
     * • php yii sequence/create-all
     * • php yii sequence/create-all  medmarketdb
     * • php yii sequence/create-all  --schema=medmarketdb
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionCreateAll(string $schema = null, string $column = null)
    {
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column);
        $sequence->createAll();
    }

    /**
     * Обновление (Удаление и Создание) sequence'а для заданной таблицы
     * Использование:
     * • php yii sequence/update patients
     * • php yii sequence/update --table=patients
     * @param string $table
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionUpdate(string $table, string $schema = null, string $column = null)
    {
        if (!empty($table)) $this->table = $table;
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column, $this->table);
        $sequence->update();
    }

    /**
     * Обновление (Удаление и Создание) sequence'ов для всех таблиц в схеме $this->schema
     * Использование:
     * • php yii sequence/update-all
     * • php yii sequence/update-all  medmarketdb
     * • php yii sequence/update-all  --schema=medmarketdb
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionUpdateAll(string $schema = null, string $column = null)
    {
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column);
        $sequence->updateAll();
    }

    /**
     * Установка последовательности значением по-умолчанию для столбца
     * Использование:
     * • php yii sequence/set-column-default patients
     * • php yii sequence/set-column-default --table=patients
     * @param string $table
     * @param string|null $schema
     * @param string|null $column
     */
    public function actionSetColumnDefault(string $table = null, string $schema = null, string $column = null)
    {
        if (!empty($table)) $this->table = $table;
        if (!empty($schema)) $this->schema = $schema;
        if (!empty($column)) $this->column = $column;
        $sequence = new Sequence($this->schema, $this->column, $this->table);
        $sequence->setColumnDefault();
    }
}
```

## console/controllers/EventSocketController.php
```php
<?php

namespace console\controllers;

use common\models\Pusher;
use Ratchet\Wamp\WampServer;
use React\EventLoop\Loop;
use React\Socket\SocketServer;
use React\ZMQ\Context;
use yii\console\Controller;
use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use \common\models\EventSocket as SocketComponent;
use ZMQ;
use ZMQContext;
use ZMQSocket;

class EventSocketController extends Controller
{

    public $dsn;

    public function beforeAction($action)
    {
        $this->dsn = "tcp://localhost:{$_ENV['SOCKET_EXPOSE_PORT']}";
        return parent::beforeAction($action); // TODO: Change the autogenerated stub
    }

    public function actionTest()
    {
        /*$server = IoServer::factory(
            new HttpServer(
                new WsServer(
                    new SocketComponent()
                )
            ),
            $_ENV['SOCKET_EXPOSE_PORT']
        );*/

        /*$server = IoServer::factory(
            new SocketComponent(),
            $_ENV['SOCKET_EXPOSE_PORT']
        );

        $server->run();*/


        /*$socket->on('connection', function (\React\Socket\ConnectionInterface $connection) {
            $connection->write("Hello " . $connection->getRemoteAddress() . "!\n");
            $connection->write("Welcome to this amazing server!\n");
            $connection->write("Here's a tip: don't say anything.\n");

            $connection->on('data', function ($data) use ($connection) {
                $connection->close();
            });
        });*/

        $loop = Loop::get();
        $pusher = new Pusher;

        // Listen for the web server to make a ZeroMQ push after an ajax request
        $context = new Context($loop);
        $pull = $context->getSocket(ZMQ::SOCKET_PULL);
        $pull->bind('tcp://127.0.0.1:' . $_ENV['ZMQ_EXPOSE_PORT']); // Binding to 127.0.0.1 means the only client that can connect is itself
        $pull->on('message', [$pusher, 'onEventEntry']);

        // Set up our WebSocket server for clients wanting real-time updates
        $webSock = new SocketServer("0.0.0.0:{$_ENV['SOCKET_EXPOSE_PORT']}", [], $loop); // Binding to 0.0.0.0 means remotes can connect
        $webServer = new IoServer(
            new HttpServer(
                new WsServer(
                    new WampServer(
                        $pusher
                    )
                )
            ),
            $webSock
        );

        $loop->run();
    }

    public function actionZmqClient()
    {
        $context = new ZMQContext();

        echo "Connecting to hello world server ...\n";
        $requester = new ZMQSocket($context, ZMQ::SOCKET_REQ);
        $requester->connect("tcp://localhost:{$_ENV['SOCKET_EXPOSE_PORT']}");


        for ($request_nbr = 0; $request_nbr != 10; $request_nbr++) {
            printf("Sending request %d...\n", $request_nbr);
            $requester->send('Hello');

            $reply = $requester->recv();
            printf("Received reply %d: [%s]\n", $request_nbr, $reply);
        }
    }

    public function actionZmqServer()
    {
        $context = new ZMQContext(1);

        $responder = new ZMQSocket($context, ZMQ::SOCKET_REP);
        $responder->bind("tcp://*:${_ENV['SOCKET_EXPOSE_PORT']}");

        while (true) {
            $request = $responder->recv();
            printf("Received request: [%s]\n", $request);

            sleep(1);

            $responder->send('World');
        }
    }

    public function actionWuserver()
    {
        $context = new ZMQContext();
        $publisher = $context->getSocket(ZMQ::SOCKET_PUB);
        $publisher->bind('tcp://*:5556');
        $publisher->bind('ipc://weather.ipc');

        while (true) {
            $zipcode = mt_rand(0, 100000);
            $temperature = mt_rand(-40, 60);
            $relhumidity = mt_rand(10, 60);
            $update = sprintf('%05d %d %d', $zipcode, $temperature, $relhumidity);
            $publisher->send($update);
        }
    }

    public function actionWuclient()
    {
        $context = new ZMQContext();
        echo "Collecting updates from weather server...\n";

        $subscriber = new ZMQSocket($context, ZMQ::SOCKET_SUB);
        $subscriber->connect('tcp://localhost:5556');

//        $filter = $_SERVER['argc'] > 1 ? $_SERVER['argv'][1] : '10001';
        $filter = '10001';
        $subscriber->setSockOpt(ZMQ::SOCKOPT_SUBSCRIBE, $filter);

        $total_temp = 0;

        for ($update_nbr = 0; $update_nbr < 100; $update_nbr++) {
            $string = $subscriber->recv();
            sscanf($string, '%d %d %d', $zipcode, $temperature, $relhumidity);
            $total_temp += $temperature;
        }

        printf("Average temperature for zipcode '%s' was %dF\n", $filter, (int) ($total_temp / $update_nbr));
    }
}
```

## vue-app/index.html
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Маршрутизация</title>
  </head>
  <body>
    <div id="app"></div>
    <div class="modals-container"></div>
    <!--suppress HtmlUnknownTarget, HtmlUnknownTarget -->
    <script type="module" src="/src/main.js"></script>
  </body>
</html>

```

## vue-app/src/App.vue
```js
<template>
  <NavBar />

  <div class='container-xxl px-2 py-4'>
    <RouterView />
  </div>

  <notifications />

  <notifications group="errorWithCopyToClipboardBtn">
    <template #body="props">
      <div class="vue-notification-template vue-notification error">
        <p class="notification-title">
          {{ props.item.title }}
        </p>
        <div class="notification-content my-2" style="max-height: 200px; overflow: auto;" v-html="props.item.text"/>
        <button class="btn btn-sm mx-1"
                :class="[ copied ? 'btn-success' : 'btn-warning' ]"
                :disabled="copied"
                v-if="permissionWrite"
                @click="copy(props.item.text)">
          {{ copied ? 'Скопировано' : 'Скопировать' }}
        </button>
        <button class="btn btn-secondary btn-sm mx-1" @click="props.close">
          Закрыть
        </button>
      </div>
    </template>
  </notifications>
</template>

<script setup>
import {computed, onMounted} from 'vue'
import { RouterView } from 'vue-router'
import NavBar from '@/components/layouts/NavBar.vue'
import { useAuthStore } from '@/stores/authStore.js'
import { useClipboard, usePermission } from '@vueuse/core'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'

const authStore = useAuthStore(),
    dateTimeStore = useDateTimeStore()

onMounted(() => {
  if (authStore.isAuthenticated)
    authStore.getUser()

  dateTimeStore.getCurrentTimestamp()
})

const { text, copy, copied, isSupported } = useClipboard()

const permissionWrite = usePermission('clipboard-write')
</script>

<style>
@import 'bootstrap/dist/css/bootstrap.min.css';
@import 'vue-multiselect/dist/vue-multiselect.css';
@import '@vuepic/vue-datepicker/dist/main.css';
</style>

```

## vue-app/src/js/axios.js
```js
import axios from 'axios'

axios.defaults.baseURL = 'https://routing.ru:8443/api/v1'

```

## vue-app/src/js/chat.js
```js
import $ from 'jquery'

/**
 * Chat update page controller
 */
const chatController = (function() {
    'use strict';

    let _socket = null;

    let _settings = {};

    let _defaults = {
        server: '',
        chat_id: '',
        client_id: '',
        target_id: '',
        auth_type: 'key',
        auth_key: '',
        debug: false,
        reconnect_timeout: 10000, // default 10 seconds
    };

    let reconnectTimeout = _defaults.reconnect_timeout;

    /**
     * Инициализация чата
     * @param settings
     */
    let init = function(settings = {}) {

        let page = $(location).attr('href');
        if (!page.includes('chat')) {
            return;
        }

        _settings = $.extend(_defaults, settings);

        reconnectTimeout = _settings.reconnect_timeout;

        debug('chat', settings);

        if (_settings.server === '') {
            debug('server', 'Не указан адрес сервера');
            alert('Не указан адрес сервера');
            return;
        }
        if (_settings.chat_id === '') {
            debug('chat_id', 'Не указан идентификатор чата');
            alert('Не указан идентификатор чата');
            return;
        }
        if (_settings.auth_type === '') {
            debug('auth_type', 'Не указан способ авторизации');
            alert('Не указан способ авторизации');
            return;
        }
        if (_settings.auth_key === '') {
            debug('auth_key', 'Не указан ключ авторизации');
            alert('Не указан ключ авторизации');
            return;
        }

        $('.chat-message-send').on('click', sendMessage)
        $('.chat-message-text').on('keypress', function (e) {
            if (e.which === 13) {
                sendMessage();
                return false;
            }
        });

        socketConnect();
    };

    /**
     * Вывод сообщения в консоль
     * @param name
     * @param data
     */
    let debug = function (name, data) {
        if (_settings.debug) {
            console.log('chatController '+name, data);
        }
    }

    /**
     * Отправка сообщения
     */
    let sendMessage = function() {
        let $input = $('.chat-message-text');
        let message = $input.val();
        socketSend({action: 'send_message', message: message});
        $input.val('');
    }

    /**
     * Показать служебное сообщение
     * @param message
     */
    let showSystemMessage = function (message) {
        let html = renderSystemMessage(message);
        $('.direct-chat-system-msg').remove();
        $('.direct-chat-messages').append(html);
        scrollDown();
    }

    /**
     * Подключение к серверу
     */
    let socketConnect = function() {

        if (_socket) {
            _socket.close(3001);
        } else {
            showSystemMessage('Подключение...');
            debug('socket', 'Подключение');
            _socket = new WebSocket(_settings.server);

            _socket.onopen = function() {
                debug('socket', 'Соединение установлено.');
                socketSend({
                    action: 'connect',
                    chat_id: _settings.chat_id,
                    auth_type: _settings.auth_type,
                    auth_key: _settings.auth_key,
                });
            };

            _socket.onclose = function(event) {
                if (event.wasClean) {
                    debug('socket', 'Соединение закрыто чисто, код='+event.code+' причина='+event.reason);
                } else {
                    debug('socket', 'Соединения оборвано, код='+event.code+' причина='+event.reason); // например, "убит" процесс сервера
                }
                _socket = null;
                reconnectTimeout+= 15 * 1000;

                setTimeout(socketConnect, reconnectTimeout);
            };

            _socket.onmessage = function(event) {
                let json = JSON.parse(event.data)
                debug('Получены данные:', json);

                let $directChat = $('.direct-chat-messages');

                if (json.hasOwnProperty('error')) {
                    let error = json.error;
                    debug('error', error);
                    $directChat.html(renderSystemMessage(error));
                    scrollDown();
                }

                if (json.action === 'init') {
                    let messages = json.messages;
                    _settings.client_id = json.client_id;
                    reconnectTimeout+= _settings.reconnect_timeout;
                    debug('messages', messages);
                    $directChat.html(renderMessageList(messages));
                    scrollDown();
                }

                if (json.action === 'add_message') {
                    let messages = json.messages;
                    debug('messages', messages);
                    $directChat.append(renderMessageList(messages));
                    scrollDown();
                }
            };

            _socket.onerror = function(error) {
                if (_socket.readyState === 1) {
                    debug('socket', 'Ошибка ' + error.message);
                }
            };
        }
    }

    /**
     * Отправка данных на сокет
     * @param data
     */
    let socketSend = function(data) {
        try {
            _socket.send(JSON.stringify(data));
        } catch (err) {
            debug('socket', 'Данные не отправлены, ошибка соединения');
        }
    };

    /**
     * Формирование служебного сообщения
     * @param message
     * @returns {`<div class="direct-chat-system-msg text-center text-gray"><small><i>${string}</i></small></div>`}
     */
    let renderSystemMessage = function(message) {
        return `<div class="direct-chat-system-msg text-center text-gray"><small><i>${message}</i></small></div>`;
    }

    /**
     * Формирование списка сообщений
     * @param data
     * @returns {string}
     */
    let renderMessageList = function(data) {
        let html = '';
        for(let k in data) {
            html+= renderMessage(data[k])
        }
        return html;
    }

    /**
     * Формирование сообщения
     * @param data
     * @returns {string}
     */
    let renderMessage = function(data) {
        let isMy = data.client_id === _settings.client_id;
        let icon = data.client_id.indexOf('patient') === 0 ? 'fas fa-user' : 'fas fa-headset';
        if (_settings.target_id && data.client_id !== _settings.target_id) {
            isMy = true;
            data.name = data.first_name + ' (Диспетчер)';
            icon = 'fas fa-headset';
        }
        if (!_settings.target_id && data.client_id !== _settings.client_id) {
            data.name = data.first_name + ' (Диспетчер)';
            icon = 'fas fa-headset';
        }

        let classRight = isMy ? 'right' : '';
        let classFloatName = isMy ? 'float-right' : 'float-left';
        let classFloatTime = !isMy ? 'float-right' : 'float-left';

        data.text = escapeHtml(data.text);
        return `
        <div class="direct-chat-msg ${classRight}" data-message-id="${data.id}">
            <div class="direct-chat-infos clearfix">
                <span class="direct-chat-name ${classFloatName}">${data.name}</span>
                <span class="direct-chat-timestamp ${classFloatTime}">${data.created_at}</span>
            </div>
            <div class="direct-chat-img"><i class="${icon}"></i></div>
            <div class="direct-chat-text">
                ${data.text}
            </div>
        </div>
        `;
    }

    /**
     * Экранирование символов сообщения
     * @param text
     * @returns {*}
     */
    let escapeHtml = function (text) {
        let map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, function(m) { return map[m]; });
    }

    /**
     * Скроллинг чата вниз
     */
    let scrollDown = function () {
        let $directChat = $('.direct-chat-messages');
        $directChat.animate({ scrollTop: $directChat[0].scrollHeight }, 300);
    }

    return {
        init: init,
    };
})();


$(document).ready(function () {
    let chatSettings = {};
    if (window.hasOwnProperty('chatAddress')) chatSettings.server = window.chatAddress;
    if (window.hasOwnProperty('chatID')) chatSettings.chat_id = window.chatID;
    if (window.hasOwnProperty('targetID')) chatSettings.target_id = window.targetID;
    if (window.hasOwnProperty('authType')) chatSettings.auth_type = window.authType;
    if (window.hasOwnProperty('authKey')) chatSettings.auth_key = window.authKey;

    chatController.init(chatSettings);
});
```

## vue-app/src/stores/dateTimeStore.js
```js
import { defineStore } from 'pinia'
import { reactive, ref } from 'vue'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { notify } from '@kyvg/vue3-notification'

export const useDateTimeStore = defineStore('dateTimeStore', {
    state: () => ({
        timestamp: false
    }),
    getters: {

    },
    actions: {
        async getCurrentTimestamp() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            if (this.timestamp !== false) return new Promise(resolve => resolve(this.timestamp))

            return await helpGetWithCredentials(`/date-time/current-timestamp`)
                .then(response => response?.data?.timestamp ?? null)
                .then(ts => this.timestamp = ts)
                .catch(err => {
                    console.log(err)
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при загрузке timestamp',
                    })
                    throw err
                })
        },
        isValidDate(d) {
            return d instanceof Date && !isNaN(d);
        },
    }
})
```

## vue-app/src/stores/hospitalStore.js
```js
import { defineStore } from 'pinia'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { useEventStore } from '@/stores/eventStore.js'
import _cloneDeep from 'lodash/cloneDeep'

export const useHospitalStore = defineStore('hospitalStore', {
    state: () => {
        return {
            controller: null,
        }
    },
    getters: {

    },
    actions: {
        async searchByName(name) {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            if (!name) return false

            if (this.controller instanceof AbortController) {
                this.controller.abort()
            }

            this.controller = await new AbortController()

            return helpGetWithCredentials(`/hospital/search?` + new URLSearchParams({ name }), { signal: this.controller.signal })
                .then(response => response.data)
                .then(data => data)
                .catch(error => error)
        },
    },
})
```

## vue-app/src/stores/doctorStore.js
```js
import { defineStore } from 'pinia'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { useEventStore } from '@/stores/eventStore.js'
import _cloneDeep from 'lodash/cloneDeep'

export const useDoctorStore = defineStore('doctorStore', {
    state: () => {
        return {
            controller: null,
        }
    },
    getters: {

    },
    actions: {
        async searchByFullName(fullName) {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            if (!fullName) return false

            if (this.controller instanceof AbortController) {
                this.controller.abort()
            }

            this.controller = await new AbortController()

            return helpGetWithCredentials(`/doctor/search?` + new URLSearchParams({ fullName }), { signal: this.controller.signal })
                .then(response => response.data)
                .then(data => data)
                .catch(error => error)
        },
    },
})
```

## vue-app/src/stores/patientStore.js
```js
import { defineStore } from 'pinia'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { useEventStore } from '@/stores/eventStore.js'
import _cloneDeep from 'lodash/cloneDeep'

export const usePatientStore = defineStore('patientStore', {
    state: () => {
        const initial = {
                id: null,
                firstName: null,
                lastName: null,
                patronymic: null,
                fullName: null,
                birthday: null,
                birthdayFormatted: null,
                phone: null,
                hospitalId: null,
                hospital: {
                    id: null,
                    name_short: null,
                },
                externalId: null,

                controller: null,

                birthAtDatepicker: null,

                hasChanges: false,
            },
            initialCard = {
                diabetes: {
                    type: null,
                    firstIdentified: null,
                    manifestYear: null,
                    manifestMonth: null,
                    insulinRequiring: null,
                    insulinMethod: null,
                },
                diagnosis: {
                    mkb: null,
                },
            }

        const model = _cloneDeep(initial),
            card = _cloneDeep(initialCard)
        return {
            ...model,
            card,

            initial,
            initialCard,

            fullNameValidateRegex: new RegExp(/^([а-яА-Я0-9\-\_\s]+)(?:\.|\s)([а-яА-Я0-9\-\_]+)(?:\.|\s)([а-яА-Я0-9\-\_]+)\.?$/),
        }
    },
    getters: {
        manifestMonth() {
            let month = this.card.diabetes.manifestMonth;
            return Boolean(month) ? (parseInt(month) - 1) : month
        },
        manifestMonthName() {
            if (!this.manifestMonth) return null;
            return this.$moment().month(this.manifestMonth).format('MMMM')
        },
        diabetesDuration() {
            if (!this.card.diabetes.manifestYear) return null

            const dateTimeStore = useDateTimeStore()
            if (!dateTimeStore.timestamp) return null

            return this.$moment
                .unix(dateTimeStore.timestamp)
                .diff(
                    this.$moment().year(this.card.diabetes.manifestYear).month(this.manifestMonth ?? 0),
                    'years'
                )
        },
        diabetesDurationTitle() {
            return `Год манифестации: ${ !this.card.diabetes.manifestYear }\nМесяц манифестации: ${ this.diabetesManifestMonthName }`
        },
    },
    actions: {
        load(patient) {
            const dateTimeStore = useDateTimeStore()

            this.id = patient.id
            this.firstName = patient.first_name
            this.lastName = patient.last_name
            this.patronymic = patient.patronymic
            this.fullName = patient.full_name
            this.phone = patient.phone
            this.birthday = patient.birth_at
            this.birthdayFormatted = patient.birth_at_formatted
            this.externalId = patient.external_id

            this.hospitalId = patient.hospital_id
            this.hospital.id = patient.hospital?.id ?? null
            this.hospital.name_short = patient.hospital?.name_short ?? null

            if (this.birthday && dateTimeStore.isValidDate(new Date(this.birthday))) {
                this.birthAtDatepicker = new Date(this.birthday)
            }
        },
        loadCard(card) {
            if (!card || typeof card !== 'object') return false
            this.loadCardDiabetes(card)
            setTimeout(() => this.loadCardDiagnosis(card), 0)
        },
        loadCardDiabetes(card) {
            this.card.diabetes.type = this.jsonDecodeCardDiabetes(card)?.type ?? null
            this.loadFirstIdentified(card)
            this.card.diabetes.manifestYear = this.jsonDecodeCardDiabetes(card)?.manifest_year ?? null
            this.card.diabetes.manifestMonth = this.jsonDecodeCardDiabetes(card)?.manifest_month ?? null
            this.loadInsulinRequiring(card)
            this.card.diabetes.insulinMethod = this.jsonDecodeCardDiabetes(card)?.insulin_method ?? null
        },
        loadCardDiagnosis(card) {
            this.card.diagnosis.mkb = this.jsonDecodeCardDiagnosis(card)?.mkb ?? null
        },
        loadFirstIdentified(card) {
            if (this.jsonDecodeCardDiabetes(card)?.first_identified === undefined) return this.card.diabetes.firstIdentified = null
            this.card.diabetes.firstIdentified = this.jsonDecodeCardDiabetes(card)?.first_identified == '1'
        },
        loadInsulinRequiring(card) {
            if (this.jsonDecodeCardDiabetes(card)?.insulin_requiring === undefined) return this.card.diabetes.insulinRequiring = null
            this.card.diabetes.insulinRequiring = this.jsonDecodeCardDiabetes(card)?.insulin_requiring == '1'
        },
        jsonDecodeCardDiabetes(card) {
            return card?.diabetes ? JSON.parse(card.diabetes) : {}
        },
        jsonDecodeCardDiagnosis(card) {
            return card?.diagnosis ? JSON.parse(card.diagnosis) : {}
        },
        validateFullName() {
            if (!this.fullName) return false
            this.fullNameValidateRegex.lastIndex = 0
            return this.fullNameValidateRegex.test(this.fullName.trim())
        },
        explodeFullName() {
            if (!this.validateFullName()) return false
            let match = this.fullName.trim().match(this.fullNameValidateRegex)
            this.lastName = match[1]
            this.firstName = match[2]
            this.patronymic = match[3]
        },
        clear() {
            Object.keys(this.initial).forEach(key => this[key] = _cloneDeep(this.initial[key]))
            this.card = _cloneDeep(this.initialCard)
        },
        async searchByFullName(fullName) {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            if (!fullName) return false

            if (this.controller instanceof AbortController) {
                this.controller.abort()
            }

            this.controller = await new AbortController()

            return helpGetWithCredentials(`/patient/search?` + new URLSearchParams({ fullName }), { signal: this.controller.signal })
                .then(response => response.data)
                .then(data => data)
                .catch(error => error)
        },
    },
})
```

## vue-app/src/stores/registryListOfEventStore.js
```js
import { defineStore } from 'pinia'
import axios from 'axios'
import { useAuthStore } from './authStore'
import { useHospitalStore } from '@/stores/hospitalStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import { useDoctorStore } from '@/stores/doctorStore.js'
import { useEventStore } from './eventStore.js'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { usePatientFormData } from '@/use/usePatientFormData.js'
import { useTimeoutPromise } from '@/use/useTimeoutPromise.js'
import { useApiResponse } from '@/use/useApiResponse.js'
import { notify } from '@kyvg/vue3-notification'
import _cloneDeep from 'lodash/cloneDeep'
import { useRoute } from 'vue-router/dist/vue-router'

export const useRegistryListOfEvent = defineStore('registryListOfEvent', {
    state: () => {
        const initial = {
                id: null,
                limitedMobility: 'false',
                patientCondition: null,
                doctorAppointment: 'false',
                telemedicine: 'false',
                doctorId: null,
                doctor: {
                    id: null,
                    fullName: null,
                    lastName: null,
                    firstName: null,
                    patronymic: null,
                    phone: null,
                },
                doctorAlert: 'false',
                medicalInstitutionId: null,
                medicalInstitution: {
                    id: null,
                    nameShort: null,
                    nameFull: null,
                },
                medicalInstitutionAtPlaceOfAttachment: 'false',
                medicalInstitutionAlert: 'false',
                callingDoctorAtHome: 'false',
                medicalInstitutionUrgentlyId: null,
                medicalInstitutionUrgently: {
                    id: null,
                    nameShort: null,
                    nameFull: null,
                },
                needCallingAnAmbulance: 'false',
        },
            model = _cloneDeep(initial)

        return {
            initial,

            ...model,
            hasChanges: false,

            registryListOfEventHistory: [],

            searchTimeout: 1000,

            doctors: [],
            doctorsIsLoading: false,
            doctorController: null,
            doctorSearchTimeout: null,

            hospitals: [],
            hospitalsIsLoading: false,
            hospitalController: null,
            hospitalSearchTimeout: null,

            hospitalsUrgent: [],
            hospitalsUrgentIsLoading: false,
            hospitalUrgentController: null,
            hospitalUrgentSearchTimeout: null,
        }
    },
    getters: {
        /*doctorId() {
            if (this.doctor?.id) return this.doctor.id
            return ''
        },
        medicalInstitutionId() {
            if (this.medicalInstitution?.id) return this.medicalInstitution.id
            return ''
        },
        medicalInstitutionUrgentlyId() {
            if (this.medicalInstitutionUrgently?.id) return this.medicalInstitutionUrgently.id
            return ''
        },*/
        registryListOfEventExists() {
            return Boolean(this.id)
        },
    },
    actions: {
        async getHistory() {
            const eventStore = useEventStore()

            const { helpGetWithCredentials } = useAxiosApiHelper()

            if (!eventStore.id) return this.registryListOfEventHistory = []
            let eventInitiatorType = eventStore.type

            this.registryListOfEventHistory = await helpGetWithCredentials(`/${ eventInitiatorType }/${ eventStore.eventInitiatorId }/registry-list-of-event/history`, { params: { currentEventId: eventStore.id } })
                .then(response => {
                    if ( !response?.data ) return []
                    return response.data
                })
                .then(history => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'История обращений пациента загружена',
                        duration: 1000,
                    })
                    return history
                })
                .catch(err => {
                    notify(
                        {
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении истории обращений пациента',
                    })
                    console.log(err)
                })
        },
        clearHistory() {
            this.history = []
        },
        clear() {
            Object.keys(this.initial).forEach(key => this[key] = _cloneDeep(this.initial[key]))
        },
        clearBeforeLeave() {
            this.clearHistory()
            this.doctors = this.hospitals = this.hospitalsUrgent = []
            this.doctorController = this.hospitalController = this.hospitalUrgentControllernull = null
            this.clear()
        },
        async create() {
            const { helpPostWithCredentials } = useAxiosApiHelper()
            const { formData } = usePatientFormData()
            const patientStore = usePatientStore(),
                registryListOfEventStore = useRegistryListOfEvent(),
                eventStore = useEventStore(),
                { delay } = useTimeoutPromise(0)

            return helpPostWithCredentials(`/event/${ eventStore.id }/registry-list-of-event`, formData)
                .then(response => response.data)
                .then(async data => {
                    if (data?.id) {
                        this.id = data.id
                        notify({
                            type: 'success',
                            title: 'Учетный лист сохранен',
                        })
                        delay().then(() => this.hasChanges = patientStore.hasChanges = registryListOfEventStore.hasChanges = false)
                    }
                })
                .catch(this.catchSaveError)
        },
        async update() {
            const { helpPatchWithCredentials } = useAxiosApiHelper()
            const { formData } = usePatientFormData()
            const patientStore = usePatientStore(),
                registryListOfEventStore = useRegistryListOfEvent(),
                eventStore = useEventStore(),
                { delay } = useTimeoutPromise(0)

            return helpPatchWithCredentials(`/event/${ eventStore.id }/registry-list-of-event`, formData)
                .then(response => response.data)
                .then(async data => {
                    notify({
                        type: 'success',
                        title: 'Учетный лист обновлен',
                    })
                    delay().then(() => this.hasChanges = patientStore.hasChanges = registryListOfEventStore.hasChanges = false)
                })
                .catch(this.catchSaveError)
        },
        catchSaveError(error) {
            const { getDescription, hasDescription } = useApiResponse()

            if ( error.response?.status === 403 ) {
                return notify({
                    type: 'error',
                    title: error.response?.data?.message,
                    text: ``,
                })
            }

            let errorMessage = error?.response?.data?.message,
                errorTitle = `Произошла непредвиденная ошибка`,
                errorGroup = `errorWithCopyToClipboardBtn`,
                errorText = `<br>Error: <pre>${ JSON.stringify(error?.response) }</pre>`

            if (hasDescription(errorMessage)) {
                errorTitle = getDescription(errorMessage)
            }

            notify({
                type: 'error',
                title: errorTitle,
                text: errorText,
                duration: 10000,
                closeOnClick: false,
                pauseOnHover: true,
                group: errorGroup,
            })
        },
        action(routeName) {
            switch (routeName) {
                case 'registryListOfEventCreate':
                    return this.registryListOfEventExists ? 'update' : 'create'
                case 'eventCreate':
                    return 'create-event'
            }
        },
        load(registryListOfEvent) {
            if (Boolean(registryListOfEvent) === false) return false

            this.id = registryListOfEvent.id
            this.limitedMobility = registryListOfEvent.limited_mobility
            this.patientCondition = registryListOfEvent.patient_condition
            this.doctorAppointment = registryListOfEvent.doctor_appointment
            this.telemedicine = registryListOfEvent.telemedicine
            this.doctorId = registryListOfEvent.doctor_id
            this.loadDoctor(registryListOfEvent.doctor)
            this.doctorAlert = registryListOfEvent.doctor_alert
            this.medicalInstitutionId = registryListOfEvent.medical_institution_id
            this.loadMedicalInstitution(registryListOfEvent.medicalInstitution)
            this.medicalInstitutionAtPlaceOfAttachment = registryListOfEvent.medical_institution_at_place_of_attachment
            this.medicalInstitutionAlert = registryListOfEvent.medical_institution_alert
            this.callingDoctorAtHome = registryListOfEvent.calling_doctor_at_home
            this.medicalInstitutionUrgentlyId = registryListOfEvent.medical_institution_urgently_id
            this.loadMedicalInstitutionUrgently(registryListOfEvent.medicalInstitutionUrgently)
            this.needCallingAnAmbulance = registryListOfEvent.need_calling_an_ambulance
        },
        loadDoctor(doctor) {
            if (doctor?.id) {
                this.doctor = {
                    id: doctor.id,
                    fullName: doctor.fullname,
                    lastName: doctor.last_name,
                    firstName: doctor.first_name,
                    patronymic: doctor.patronymic,
                    phone: doctor.phone,
                }
                this.doctors.push(this.doctor)
            }
        },
        loadMedicalInstitution(medicalInstitution) {
            if (medicalInstitution?.id) {
                this.medicalInstitution = {
                    id: medicalInstitution.id,
                    nameShort: medicalInstitution.name_short,
                    nameFull: medicalInstitution.name_full,
                }
                this.hospitals.push(this.medicalInstitution)
            }
        },
        loadMedicalInstitutionUrgently(medicalInstitutionUrgently) {
            if (medicalInstitutionUrgently?.id) {
                this.medicalInstitutionUrgently = {
                    id: medicalInstitutionUrgently.id,
                    nameShort: medicalInstitutionUrgently.name_short,
                    nameFull: medicalInstitutionUrgently.name_full,
                }
                this.hospitalsUrgent.push(this.medicalInstitutionUrgently)
            }
        },
        searchDoctor(fullName) {
            const doctorStore = useDoctorStore()

            this.doctors = []
            this.doctorsIsLoading = true

            doctorStore.searchByFullName(fullName)
                .then(doctors => {
                    if (Array.isArray(doctors))
                        this.doctors = doctors.map(doctor => ({
                            id: doctor.id,
                            fullName: doctor.fullname,
                            lastName: doctor.last_name,
                            firstName: doctor.first_name,
                            patronymic: doctor.patronymic,
                            phone: doctor.phone,
                        }))
                })
                .catch(error => console.error(error))
            this.doctorsIsLoading = false
        },
        searchHospital(name) {
            this.hospitals = []
            this.hospitalsIsLoading = true

            this.searchHospitalByName(name)
                .then(hospitals => this.hospitals = hospitals)
                .catch(error => console.error(error))

            this.hospitalsIsLoading = false
        },
        async searchHospitalUrgent(name) {
            this.hospitalsUrgent = []
            this.hospitalsUrgentIsLoading = true

            this.searchHospitalByName(name)
                .then(hospitals => this.hospitalsUrgent = hospitals)
                .catch(error => console.error(error))

            this.hospitalsUrgentIsLoading = false
        },
        searchHospitalByName(name) {
            const hospitalStore = useHospitalStore()

            return hospitalStore.searchByName(name)
                .then(hospitals => {
                    if (Array.isArray(hospitals))
                        return hospitals.map(hospital => ({
                            id: hospital.id,
                            nameShort: hospital.name_short,
                            nameFull: hospital.name_full,
                        }))
                    return []
                })
                .catch(error => {
                    throw error
                })
        }
    },
})

```

## vue-app/src/stores/chatStore.js
```js
import { defineStore } from 'pinia'
import { reactive, ref } from 'vue'
import { notify } from '@kyvg/vue3-notification'
import _cloneDeep from 'lodash/cloneDeep'
import { helpers, required, requiredIf, maxLength } from '@vuelidate/validators'
import { useVuelidate } from '@vuelidate/core'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'

export const useChatStore = defineStore('chatStore', {
    state: () => {
        const initial = {
            connection: null,
            apiBaseUrl: `https://sppvr.med-market.ru/api`,
            wsServer: '',
            messages: [],
            message: null,
            settings: {
                server: '',
                chatId: '',
                clientId: '',
                targetId: '',
                authType: 'key',
                authKey: '',
                debug: false,
                reconnectTimeout: 10000,
            },
            settingsValidateRules: {
                server: {
                    required: helpers.withMessage('Не указан адрес сервера', required),
                },
                chatId: {
                    required: helpers.withMessage('Не указан идентификатор чата', required),
                },
                authType: {
                    required: helpers.withMessage('Не указан способ авторизации', required),
                },
                authKey: {
                    required: helpers.withMessage('Не указан ключ авторизации', required),
                },
            },

            participants: [ // TODO hard-coded
                {
                    id: 195,
                    name: 'Предеин Вячеслав',
                },
                {
                    id: 46,
                    name: 'Dispatcher Test',
                }
            ],
            titleImageUrl: 'https://a.slack-edge.com/66f9/img/avatars-teams/ava_0001-34.png',
            messageList: [],
            newMessagesCount: 0,
            isChatOpen: false,
            colors: {
                header: {
                    bg: '#4e8cff',
                    text: '#ffffff'
                },
                launcher: {
                    bg: '#4e8cff'
                },
                messageList: {
                    bg: '#ffffff'
                },
                sentMessage: {
                    bg: '#4e8cff',
                    text: '#ffffff'
                },
                receivedMessage: {
                    bg: '#eaeaea',
                    text: '#222222'
                },
                userInput: {
                    bg: '#f4f7f9',
                    text: '#565867'
                }
            },
            alwaysScrollToBottom: false, // when set to true always scrolls the chat to the bottom when new events are in (new message, user starts typing...)
            messageStyling: true // enables *bold* /emph/ _underline_ and such (more info at github.com/mattezza/msgdown)
        }
        const state = _cloneDeep(initial)
        return {
            initial,
            ...state,
        }
    },
    getters: {

    },
    actions: {
        getPatientsChatServer(patientId) {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            // todo hard coded
            let hardCodedResponse = {
                "data": {
                    "chat_id": 37,
                    "server": "wss://sppvr.med-market.ru:2346"
                }
            }

            // todo hard coded
            return new Promise(resolve => {
                setTimeout(() => {
                    resolve(hardCodedResponse)
                }, 1500)
            })
            return helpGetWithCredentials(`${ this.apiBaseUrl }/patient/${ patientId }/chat`)
                .then(response => response.data)
                .then(data => {
                    console.log(data)
                })
                .catch(error => error)
        },
        initConnection() {
            if (this.validateSettings() === false) return false
            if (this.connection) {
                console.error('Попытка повторной инициализации соединения web socket')
                return false
            }

            console.log(`Подключение к серверу ${ this.settings.server }...`)

            this.connection = new WebSocket(this.settings.server);

            this.connection.onopen = () => {
                console.log(`Соединение к серверу ${ this.settings.server } установлено`)
                let dispatcherId = 46 // TODO hard coded dispatcher id
                this.sendMessage({
                    action: 'connect',
                    chat_id: this.settings.chatId,
                    auth_type: this.settings.authType,
                    target_id: dispatcherId,
                    auth_key: btoa(`user:${ dispatcherId }:${ this.settings.authKey }`),
                })
            };

            this.connection.onmessage = event => {
                console.log('connection:onmessage', event)
                const data = JSON.parse(event.data)

                if (data.hasOwnProperty('error')) {
                    console.error('Error connection:onmessage', data.error)
                }

                switch (data.action) {
                    case 'init':
                        this.settings.clientId = data.client_id
                        if (data?.messages) {
                            Object.keys(data.messages).forEach(key => this.messages.push(data.messages[key]))
                        }
                        break
                    case 'add_message':
                        this.messages.push(Object.values(data.messages).at(0))
                        break
                }
            }

            this.connection.onclose = event => {
                if (event.wasClean) {
                    console.log(`Соединение c сервером ${ this.settings.server } закрыто чисто. Код ${ event.code }. Причина: ${ event.reason }`)
                } else {
                    console.error(`Соединение c сервером ${ this.settings.server } оборвано. Код ${ event.code }. Причина: ${ event.reason }`)
                }
                this.connection = null
            }
            
            this.connection.onerror = error => {
                if (this.connection.readyState === 1) {
                    console.log(`Ошибка ${ error.message }`)
                }
            }
        },
        setSettings(settings = {}) {
            if ( typeof settings !== 'object' ||
                Array.isArray(settings) ||
                settings === null
            ) {
                console.error('Настройки web socket\'а должны типа Object{}')
                return false
            }
            Object.assign(this.settings, settings)
        },
        async validateSettings() {
            const v$ = useVuelidate(this.settingsValidateRules, this.settings)
            const valid = await v$.value.$validate()

            if (valid === false) {
                console.error('Ошибка валидации настроек web socket: ', v$.value.$errors[0].$message)
            }

            return valid
        },
        sendMessage(data) {
            try {
                console.log('Send Message', data)
                this.connection.send(JSON.stringify(data));
            } catch (err) {
                console.error(`Данные не отправлены`, JSON.stringify(data), 'Error: ', err)
            }
        },
        onMessageWasSent(messageObj) {
            this.sendMessage({
                action: 'send_message',
                message: messageObj.data.text
            })
        },
        openChat () {
            this.isChatOpen = true
            this.newMessagesCount = 0
        },
        closeChat () {
            // called when the user clicks on the botton to close the chat
            this.isChatOpen = false
        },
    }
})
```

## vue-app/src/stores/eventStore.js
```js
import { defineStore } from 'pinia'
import { reactive, ref } from 'vue'
import { useDateFormat, useTimeAgo } from '@vueuse/core'
import { useVuelidate } from '@vuelidate/core/dist/index.esm'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { notify } from '@kyvg/vue3-notification'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import { useRegistryListOfEvent } from '@/stores/registryListOfEventStore.js'
import { useReferenceStore } from '@/stores/referenceStore.js'
import { usePatientFormData } from '@/use/usePatientFormData.js'
import { useTimeoutPromise } from '@/use/useTimeoutPromise.js'
import { useApiResponse } from '@/use/useApiResponse.js'
import _cloneDeep from 'lodash/cloneDeep'

export const useEventStore = defineStore('eventStore', {
    state: () => {
        const initial = {
            id: null,
            classifier: null,
            classifierComment: null,
            type: null,
            priority: null,
            status: null,
            takingToWorkAt: null,
            isSystemEvent: null,
            dispatcherIdWhoTookToWork: null,
            compensationStage: null,
            insulinRequiring: null,
            eventInitiator: {},

            events: [],
            loading: false,

            selectedPatient: {
                id: null,
                fullName: null,
                fullNameWithBirthdate: null,
                lastName: null,
                firstName: null,
                patronymic: null,
                birthday: null,
                birthdayFormatted: null,
                phone: null,
                card: null,
            },

            patients: [],
            patientsIsLoading: false,

            hasChanges: false,
            redirectToEventAfterCreate: false,

            /* Filters */
            filters: {
                page: 1,
                classifier: null,
                priority: null,
                type: null,
                eventInitiatorFullName: null,
                status: null,
                createdAtFrom: null,
                createdAtTo: null,
            },
            needToResetPage: false,
            createdAtFilter: [],
            // createdAtFromFilter: null,
            // createdAtToFilter: null,

            /* Pagination */
            records: null,
            totalPages: null,
            perPage: 10,
        }
         const model = _cloneDeep(initial)
        return {
            initial,
            ...model,
        }
    },
    getters: {
        eventTypeIsPatient() {
            return this.type === 'patient'
        },
        eventClassifierIsOther() {
            return this.classifier === 'other'
        },
        classifierCommentDisabled() {
            return !this.eventClassifierIsOther
        },
        eventInitiatorId() {
            return this.eventInitiator?.id ?? null
        },
    },
    actions: {
        async getEventLog(filters = {}, route) {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            this.loading = true

            await helpGetWithCredentials(`/event/log`, {params: {filters, route}})
                .then(response => response.data)
                .then(response => {
                    this.events = response.events
                    this.records = response.totalCount
                    this.totalPages = response.pageCount
                })
                .catch(err => {
                    // TODO modal с кнопкой скопировать ошибку
                    console.log(err)
                    alert(err)
                })

            this.loading = false
        },
        async getEventById(eventId) {
            const { helpGetWithCredentials } = useAxiosApiHelper()
            const registryListOfEventStore = useRegistryListOfEvent(),
                patientStore = usePatientStore()

            return await helpGetWithCredentials(`/event/${ eventId }`)
                .then(response => response.data)
                .then(event => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Событие загружено',
                    })
                    return event
                })
                .catch(error => {
                    if ( error.response?.status === 403 ) {
                        notify({
                            type: 'error',
                            title: error.response?.data?.message,
                        })
                        throw error
                    }

                    console.log(error)

                    let errorMessage = error.response.data.message,
                        errorTitle = `Произошла непредвиденная ошибка`,
                        errorGroup = `errorWithCopyToClipboardBtn`,
                        errorText = `<br>Error: <pre>${ JSON.stringify(error?.response) }</pre>`

                    switch (errorMessage) {
                        case 'app.event.notFound':
                            errorTitle = `Ошибка`
                            errorText = `Событие не найдено`
                            errorGroup = null
                            break
                    }

                    notify({
                        type: 'error',
                        title: errorTitle,
                        text: errorText,
                        duration: 10000,
                        closeOnClick: false,
                        pauseOnHover: true,
                        group: errorGroup,
                    })

                    // TODO hasChanges
                    this.hasChanges = registryListOfEventStore.hasChanges = false

                    throw error
                })
        },
        getEventByIndex(index) {
            return this.events[index] ?? {}
        },
        getEventTypeRuName(event) {
            switch (event.type) {
                case 'patient':
                    return 'Пациент'
                case 'doctor':
                    return 'Доктор'
                case 'dispatcher':
                    return 'Диспетчер'
                case 'system':
                    return 'Система'
                default:
                    return 'неизвестный тип события'
            }
        },
        deleteEventByIndex(index) {
            this.events.splice(index, 1)
        },
        deleteEventById(id) {
            let index = this.events.findIndex(e => e.id === id)
            if (index === -1) return false
            this.deleteEventByIndex(index)
        },
        async takeInWork(eventId) {
            const { helpPostWithCredentials } = useAxiosApiHelper()
            return await helpPostWithCredentials(`/event/${ eventId }/take-in-work`, {})
        },
        loadModel(event) {
            this.id = event.id
            this.classifier = event.classifier
            this.classifierComment = event.classifier_comment
            this.type = event.type
            this.priority = event.priority
            this.status = event.status
            this.takingToWorkAt = event.taking_to_work_at
            this.isSystemEvent = event.is_system_event
            this.dispatcherIdWhoTookToWork = event.dispatcher_id_who_took_to_work
            this.compensationStage = event.compensation_stage
            this.insulinRequiring = event.insulin_requiring
            switch (event.type) {
                case 'patient':
                    this.eventInitiator = event.patient
                    break
                case 'dispatcher':
                case 'doctor':
                    this.eventInitiator = event.user
                    break
            }
        },
        clearBeforeLeave() {
            this.clear()
        },
        clear() {
            let eventType = this.type
            Object.keys(this.initial).forEach(key => this[key] = _cloneDeep(this.initial[key]))
            this.type = eventType ?? null
            this.createdAtFilter = null
        },
        create() {
            const { helpPostWithCredentials } = useAxiosApiHelper()
            const { formData } = usePatientFormData()
            const patientStore = usePatientStore(),
                registryListOfEventStore = useRegistryListOfEvent(),
                { getDescription, hasDescription } = useApiResponse(),
                { delay } = useTimeoutPromise(0)

            return helpPostWithCredentials(`/event/create`, formData)
                .then(response => response.data)
                .then(async data => {
                    if (data?.id) {
                        notify({
                            type: 'success',
                            title: 'Событие создано',
                        })

                        let redirectToEventAfterCreate = this.redirectToEventAfterCreate
                        this.clear()
                        patientStore.clear()
                        registryListOfEventStore.clearBeforeLeave()

                        delay().then(() => this.hasChanges = patientStore.hasChanges = registryListOfEventStore.hasChanges = false)

                        if (redirectToEventAfterCreate) return this.router.push(`/event/${ data.id }/registry-list-of-event`)
                    }
                })
                .catch(error => {

                    if ( error.response?.status === 403 ) {
                        return notify({
                            type: 'error',
                            title: error.response?.data?.message,
                            text: ``,
                        })
                    }

                    let errorMessage = error?.response?.data?.message,
                        errorTitle = `Произошла непредвиденная ошибка`,
                        errorGroup = `errorWithCopyToClipboardBtn`,
                        errorText = `<br>Error: <pre>${ JSON.stringify(error?.response) }</pre>`

                    if (hasDescription(errorMessage)) {
                        errorTitle = getDescription(errorMessage)
                    }

                    notify({
                        type: 'error',
                        title: errorTitle,
                        text: errorText,
                        duration: 10000,
                        closeOnClick: false,
                        pauseOnHover: true,
                        group: errorGroup,
                    })
                })
        },
    }
})
```

## vue-app/src/stores/referenceStore.js
```js
import { defineStore } from 'pinia'
import { reactive, ref } from 'vue'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { usePatientStore } from './patientStore'
import { notify } from '@kyvg/vue3-notification'

export const useReferenceStore = defineStore('referenceStore', {
    state: () => ({
        classifiers: null,
        priorities: null,
        types: null,
        patientConditions: null,
        diabetesTypes: null,
        mkb: null,

        referencesLoaded: false,
    }),
    getters: {
        patientConditionsFormatted() {
            if ( !this.patientConditions ) return []
            return Object.keys(this.patientConditions).map(name => ({
                name,
                title: this.patientConditions[name]
            }))
        },
        mkbFilteredByDiabetesType() {
            const patientStore = usePatientStore()

            if (!patientStore.card.diabetes.type || !this.mkb) return []
            return this.mkb.filter(mkb => mkb.diabetes_type_id == patientStore.card.diabetes.type)
        },
    },
    actions: {
        async getReferences() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/references`)
                .then(response => response.data)
                .then(references => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Справочники загружены',
                        duration: 50,
                    })

                    this.referencesLoaded = true

                    this.classifiers = references?.classifiers ?? []
                    this.priorities = references?.priorities ?? []
                    this.types = references?.types ?? []
                    this.diabetesTypes = references?.diabetesType ?? []
                    this.mkb = references?.mkbList ?? []
                    this.patientConditions = references?.patientConditions ?? []
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении справочников',
                    })
                    console.log(err)
                })
        },
        async getClassifiers() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/classifiers`)
                .then(response => response.data)
                .then(classifiers => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Классификаторы загружены',
                        duration: 50,
                    })
                    this.classifiers = classifiers
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении классификаторов (причин обращения)',
                    })
                    console.log(err)
                })
        },
        async getPriorities() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/priorities`)
                .then(response => response.data)
                .then(priorities => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Приоритеты событий загружены',
                        duration: 50,
                    })
                    this.priorities = priorities
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении приоритетов событий',
                    })
                    console.log(err)
                })
        },
        async getTypes() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/types`)
                .then(response => response.data)
                .then(types => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Типы событий загружены',
                        duration: 50,
                    })
                    this.types = types
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении типов событий',
                    })
                    console.log(err)
                })
        },
        async getPatientConditions() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/patient-conditions`)
                .then(response => response.data)
                .then(patientConditions => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Состояния пациентов загружены',
                        duration: 50,
                    })
                    this.patientConditions = patientConditions
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении состояний пациентов',
                    })
                    console.log(err)
                })
        },
        async getDiabetesType() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/diabetes-type`)
                .then(response => response.data)
                .then(diabetesTypes => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'Типы диабета загружены',
                        duration: 50,
                    })
                    this.diabetesTypes = diabetesTypes
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении типов диабета',
                    })
                    console.log(err)
                })
        },
        async getMkb() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            await helpGetWithCredentials(`/event/mkb-list`)
                .then(response => response.data)
                .then(mkb => {
                    notify({
                        type: 'success',
                        title: '',
                        text: 'МКБ загружены',
                        duration: 50,
                    })
                    this.mkb = mkb
                })
                .catch(err => {
                    notify({
                        type: 'error',
                        title: '',
                        text: 'Ошибка при получении МКБ',
                    })
                    console.log(err)
                })
        },
    },
})
```

## vue-app/src/stores/authStore.js
```js
import { defineStore } from 'pinia'
import { useStorage } from '@vueuse/core'
import { useAxiosApiHelper } from '@/use/useAxiosApiHelper.js'
import { useApiResponse } from '@/use/useApiResponse.js'
import { notify } from '@kyvg/vue3-notification'

export const useAuthStore = defineStore('authStore', {
    state: () => ({
        credentials: {
            login: 'dispatcher@mm.ru',
            password: '123456',
        },
        token: useStorage('token', null),
        user: {},
        modalIsShow: false,
        errorMessage: null,
        showCopyToClipboardBtn: false,
        loading: false,
    }),
    getters: {
        isAuthenticated() {
            return this.token !== null
        }
    },
    actions: {
        async login() {
            const { helpPost } = useAxiosApiHelper()

            this.showCopyToClipboardBtn = false
            this.loading = true

            return await helpPost('/login', {
                login: this.credentials.login,
                password: this.credentials.password
            })
                .then(response => {
                    this.loading = false

                    if (!response.success || !response?.data?.accessToken) {
                        this.showError(`Произошла непредвиденная ошибка:<br>response: <pre>${ JSON.stringify(response) }</pre>`, true)
                        return null
                    }
                    return response.data.accessToken
                })
                .then(async accessToken => {
                    this.token = accessToken

                    await this.getUser()
                    await this.router.push('/')
                })
                .catch(error => {
                    this.loading = false

                    if ( !error?.response?.data?.message ) {
                        return this.showError(`Произошла непредвиденная ошибка:<br>Error: <pre>${ JSON.stringify(error) }</pre>`, true)
                    }

                    let errorMessage = error.response.data.message

                    if (errorMessage === 'app.user.login.incorrectLoginOrPassword') {
                        this.showError('Не верный логин или пароль!')
                    } else {
                        this.showError(`Произошла непредвиденная ошибка:<br>Error: <pre>${ JSON.stringify(error?.response) }</pre>`, true)
                    }
                })
        },
        getUser() {
            const { helpGetWithCredentials } = useAxiosApiHelper()

            helpGetWithCredentials(`/user/get`)
                .then(response => {
                    if (response?.data?.user === undefined) {
                        this.showError(`Произошла непредвиденная ошибка:<br>response: <pre>${ JSON.stringify(response) }</pre>`, true)
                        return {}
                    }

                    return response.data.user
                })
                .then(user => this.user = user)
                .catch(error => {
                    this.showError(`Произошла непредвиденная ошибка:<br>Error: <pre>${ JSON.stringify(error) }</pre>`, true)
                })
        },
        async logout() {
            this.token = this.user = null
            await this.router.replace('/login')
        },
        showError(err, showCopyToClipboardBtn = false) {
            this.errorMessage = err
            this.modalIsShow = true
            this.showCopyToClipboardBtn = showCopyToClipboardBtn
        },
        pauseWork() {
            return this.changeDispatcherWorkingStatus('paused')
        },
        pauseWorkWithEvents() {
            return this.changeDispatcherWorkingStatus('paused', true)
        },
        resumeWork() {
            return this.changeDispatcherWorkingStatus('working')
        },
        changeDispatcherWorkingStatus(status, pauseEventEither = false) {
            const { helpPostWithCredentials } = useAxiosApiHelper()
            const { getDescription, hasDescription } = useApiResponse()


            return helpPostWithCredentials(`/dispatcher/dispatcher-working-status`, { status, pauseEventEither })
                .then(response => response.data)
                .then(result => {
                    if (result.dispatcherWorkingStatus === undefined) {
                        throw Error('Непредвиденная ошибка при попытке смене статуса работы диспетчера')
                    }

                    switch (result.dispatcherWorkingStatus) {
                        case 'paused':
                            notify({
                                type: 'success',
                                title: 'Работа приостановлена',
                                text: pauseEventEither && result?.pausedDispatchersEventsCount > 0 ? `Кол-во приостановленных событий: ${ result?.pausedDispatchersEventsCount }` : '',
                            })
                            break
                        case 'working':
                            notify({
                                type: 'success',
                                title: 'Работа возобновлена',
                                text: '',
                            })
                            break
                    }
                    this.user.dispatcher_working_status = result.dispatcherWorkingStatus
                })
                .catch(error => {
                    let errorMessage = error?.response?.data?.message,
                        errorTitle = `Произошла непредвиденная ошибка`,
                        errorGroup = `errorWithCopyToClipboardBtn`,
                        errorText = `<br>Error: <pre>${ JSON.stringify(error?.response) }</pre>`

                    if (hasDescription(errorMessage)) {
                        errorTitle = getDescription(errorMessage)
                    }

                    notify({
                        type: 'error',
                        title: errorTitle,
                        text: errorText,
                        duration: 10000,
                        closeOnClick: false,
                        pauseOnHover: true,
                        group: errorGroup,
                    })
                })
        },
    },
})
```

## vue-app/src/use/useTimeoutPromise.js
```js
import { ref, unref } from "vue";

export function useTimeoutPromise(timeout = 1500) {
    const timer = ref(null)
    timeout = unref(timeout)

    const delay = () => {
        return new Promise(resolve => {
            clearTimeout(timer.value)
            timer.value = setTimeout(() => {
                timer.value = null
                resolve(true)
            }, timeout)
        })
    }

    return {
        delay
    }
}
```

## vue-app/src/use/useBodyOverflow.js
```js
import { onMounted, onUnmounted } from "vue";

export function useBodyOverflow() {
    const setBodyOverflowHidden = () => document.body.style.overflow = 'hidden'
    const setBodyOverflowAuto = () => document.body.style.overflow = 'auto'

    return {
        setBodyOverflowHidden,
        setBodyOverflowAuto,
    }
}
```

## vue-app/src/use/usePatientFormValidation.js
```js
import { computed, reactive } from 'vue'
import { helpers, required, requiredIf, maxLength } from '@vuelidate/validators'
import { useVuelidate } from '@vuelidate/core'
import { useEventStore } from '@/stores/eventStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import { useRegistryListOfEvent } from '@/stores/registryListOfEventStore.js'

export function usePatientFormValidation(route) {
    const eventStore = useEventStore(),
        patientStore = usePatientStore(),
        registryListOfEventStore = useRegistryListOfEvent()

    const eventExists = computed(() => Boolean(eventStore.id))
    const registryPage = computed(() => route.name === 'registryListOfEventCreate')
    const updateRegistryPage = computed(() => registryPage.value && eventExists.value)
    const eventCreatePage = computed(() => route.name === 'eventCreate')
    const patientIsSelected = computed(() => Boolean(eventStore.selectedPatient?.id))

    const validateFullName = fullName => {
        if (patientIsSelected.value || registryPage.value) return true
        if (!fullName) return false
        patientStore.fullNameValidateRegex.lastIndex = 0
        return patientStore.fullNameValidateRegex.test(fullName.trim())
    }

    const rules = computed(() => ({
        fullName: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле ФИО`,
                requiredIf(eventCreatePage.value)
            ),
            validateFullName: helpers.withMessage(
                () => `ФИО заполнено не корректно`,
                validateFullName
            )
        },
        birthday: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Дата рождения`,
                // only if event.type = patient
                requiredIf(eventCreatePage.value)
            ),
        },
        phone: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Телефон`,
                requiredIf(eventCreatePage.value && !patientIsSelected.value)
            ),
            maxLength: helpers.withMessage(
                () => `Максимальная длина поле Телефон 11 символов`,
                maxLength(11)
            )
        },
        classifier: {
            required: helpers.withMessage('Пожалуйста, заполните поле Причина обращения', required),
        },
        classifier_comment: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Комментарий к обращению`,
                requiredIf(registryPage.value && eventStore.eventClassifierIsOther)
            ),
        },
        patientCondition: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Состояние пациента`,
                requiredIf(registryPage.value)
            ),
        },
        diabetesType: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Тип диабета`,
                requiredIf(
                    eventCreatePage.value &&
                    patientIsSelected.value === false
                )
            ),
        },
        diagnosisMkb: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле МКБ`,
                requiredIf(
                    eventCreatePage.value &&
                    patientIsSelected.value === false  &&
                    patientStore.card.diabetes.type
                )
            ),
        },
        priority: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Приоритет события`,
                requiredIf(eventCreatePage.value)
            ),
        },
        insulinMethod: {
            requiredIf: helpers.withMessage(
                () => `Пожалуйста, заполните поле Метод введения инсулина`,
                requiredIf(
                    eventCreatePage.value &&
                    patientStore.card.diabetes.insulinRequiring &&
                    patientIsSelected.value === false
                )
            ),
        },
    }))

    const state = reactive({
        birthday: computed(() => patientStore.birthAtDatepicker),
        phone: computed(() => patientStore.phone),
        diabetesType: computed(() => patientStore.card.diabetes.type),
        diagnosisMkb: computed(() => patientStore.card.diagnosis.mkb),
        insulinMethod: computed(() => patientStore.card.diabetes.insulinMethod),
        patientCondition: computed(() => registryListOfEventStore.patientCondition),
        priority: computed(() => eventStore.priority),
        fullName: computed(() => eventStore.selectedPatient?.fullNameWithBirthdate),
        classifier: computed(() => eventStore.classifier),
        classifier_comment: computed(() => eventStore.classifierComment),
    })

    const v$ = useVuelidate(rules, state)

    return {
        rules,
        state,
        v$
    }
}
```

## vue-app/src/use/useAxiosApiHelper.js
```js
import axios from 'axios'
import { useAuthStore } from '@/stores/authStore.js'

export function useAxiosApiHelper() {
    const authStore = useAuthStore()

    const authConfigs = {
        headers: {
            Authorization: `Bearer ${ authStore.token }`
        }
    }

    const axiosClient = axios.create({
        responseType: 'json',
        headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
        },
    })

    const helpGet = (url, configs) => axiosClient.get(url, configs).then(res => res.data)
    const helpPost = (url, data, configs) => axiosClient.post(url, data, configs).then(res => res.data)
    const helpPatch = (url, data, configs) => axiosClient.patch(url, data, configs).then(res => res.data)
    const helpDelete = (url, configs) => axiosClient.delete(url, configs)

    const helpGetWithCredentials = (url, configs) => axiosClient.get(url, {...authConfigs, ...configs}).then(res => res.data)
    const helpPostWithCredentials = (url, data, configs) => axiosClient.post(url, data, {...authConfigs, ...configs}).then(res => res.data)
    const helpPatchWithCredentials = (url, data, configs) => axiosClient.patch(url, data, {...authConfigs, ...configs}).then(res => res.data)
    const helpDeleteWithCredentials = (url, configs) => axiosClient.delete(url, {...authConfigs, ...configs})

    return {
        helpGet,
        helpPost,
        helpPatch,
        helpDelete,
        helpGetWithCredentials,
        helpPostWithCredentials,
        helpPatchWithCredentials,
        helpDeleteWithCredentials,
    }
}

```

## vue-app/src/use/useApiResponse.js
```js
export function useApiResponse() {
    const messages = {
        'app.event.notFound': 'Не удалось найти событие',
        'app.event.statusIsInWork': 'Событие уже взято в работу другим оператором',
        'app.event.statusIsDeleted': 'Событие удалено',
        'app.event.priorityIsNotHigh': 'Приоритет события не Высокий',
        'app.event.modelLoadError': 'Ошибка загрузки данных в модель События. Обратитесь в тех.поддержку',
        'app.event.modelValidateError': 'Ошибка валидации данных модели Событие. Обратитесь в тех.поддержку',
        'app.event.modelSaveError': 'Ошибка сохранения данных модели Событие. Обратитесь в тех.поддержку',
        'api.patient.create.modelLoadError': 'Ошибка при загрузке модели Пациент',
        'api.patient.create.modelValidateError': 'Ошибка при валидации модели Пациент',
        'api.patient.create.modelSaveError': 'Ошибка при сохранении модели Пациент',
        'app.patient.card.create.modelLoadError': 'Ошибка при загрузке модели Карта пациента',
        'app.patient.card.create.modelValidateError': 'Ошибка при валидации модели Карта пациента',
        'app.patient.card.create.modelSaveError': 'Ошибка при сохранении модели Карта пациента',
        'app.patient.event.create.modelLoadError': 'Ошибка при загрузке модели Событие',
        'app.patient.event.create.modelValidateError': 'Ошибка при валидации модели Событие',
        'app.patient.event.create.modelSaveError': 'Ошибка при сохранении модели Событие',
        'app.registryListOfEvent.alreadyExists': 'Учетный лист для данного события уже был сохранен ранее',
        'app.registryListOfEvent.modelLoadError': 'Ошибка при загрузке модели Учетный лист события',
        'app.registryListOfEvent.modelValidateError': 'Ошибка при валидации модели Учетный лист события',
        'app.registryListOfEvent.modelSaveError': 'Ошибка при сохранении модели Учетный лист события',
        'app.registryListOfEvent.classifierComment.required': 'Пожалуйста, заполните поле Комментарий к обращению',
        'app.user.notFound': 'Пользователь не найден',
        'app.user.dispatcherWorkingStatusAlreadyPaused': 'Работа уже приостановлена',
        'app.user.modelValidateError': 'Ошибка при валидации модели Пользователь',
        'app.user.modelSaveError': 'Ошибка при сохранении модели Пользователь',
        'app.user.dispatcherWorkingStatusIsPaused': 'Статус работы диспетчера - приостановлен',
    }

    const getDescription = code => messages[code] ?? null
    const hasDescription = code => Boolean(getDescription(code))

    return {
        getDescription,
        hasDescription,
    }
}
```

## vue-app/src/use/useBaseModalValue.js
```js
import { computed, defineProps, defineEmits } from "vue";

export function useBaseModalValue() {
    const props = defineProps({
        modelValue: {
            type: Boolean,
            default: false,
        },
    })

    const emit = defineEmits(['update:modelValue'])

    const value = computed({
        get() {
            return props.modelValue
        },
        set(value) {
            emit('update:modelValue', value)
        }
    })

    return {
        props,
        emit,
        value
    }
}
```

## vue-app/src/use/usePatientFormData.js
```js
import { computed, reactive } from 'vue'
import { useEventStore } from '@/stores/eventStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import { useRegistryListOfEvent } from '@/stores/registryListOfEventStore.js'

export function usePatientFormData() {
    const eventStore = useEventStore(),
        patientStore = usePatientStore(),
        registryListOfEventStore = useRegistryListOfEvent()

    const formData = new FormData()

    const form = {
        // patient
        patient_id: eventStore.selectedPatient?.id ?? null,
        full_name: patientStore.fullName,
        birthday: patientStore.birthday,
        birth_at_formatted: patientStore.birthdayFormatted,
        phone: patientStore.phone,
        // patient card
        diabetes_type: patientStore.card.diabetes.type,
        first_identified_diabetes: patientStore.card.diabetes.firstIdentified,
        manifest_year_diabetes: patientStore.card.diabetes.manifestYear,
        manifest_month_diabetes: patientStore.card.diabetes.manifestMonth,
        insulin_requiring_diabetes: patientStore.card.diabetes.insulinRequiring,
        insulin_method_diabetes: patientStore.card.diabetes.insulinMethod,
        diagnosis_mkb: patientStore.card.diagnosis.mkb,
        // event
        classifier: eventStore.classifier,
        classifier_comment: eventStore.classifierComment,
        event_type: eventStore.type,
        event_status: eventStore.status,
        event_priority: eventStore.priority,
        compensation_stage: eventStore.compensationStage,
        // registry
        limited_mobility: registryListOfEventStore.limitedMobility,
        patient_condition: registryListOfEventStore.patientCondition,
        doctor_appointment: registryListOfEventStore.doctorAppointment,
        telemedicine: registryListOfEventStore.telemedicine,
        doctor_id: registryListOfEventStore.doctorId,
        doctor_alert: registryListOfEventStore.doctorAlert,
        medical_institution_id: registryListOfEventStore.medicalInstitutionId,
        medical_institution_urgently_id: registryListOfEventStore.medicalInstitutionUrgentlyId,
        calling_doctor_at_home: registryListOfEventStore.callingDoctorAtHome,
        need_calling_an_ambulance: registryListOfEventStore.needCallingAnAmbulance,
    }

    if (eventStore.redirectToEventAfterCreate) {
        form.event_status = 'in_work'
    }

    Object.keys(form).forEach((key) => {
        let value = form[key]
        if (!value) value = ''
        formData.append(key, value)
    })

    return {
        form,
        formData
    }
}
```

## vue-app/src/main.js
```js
import { createApp, markRaw } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import Notifications from '@kyvg/vue3-notification'
import moment from 'moment/min/moment-with-locales';
import Chat from 'vue3-beautiful-chat'

import './assets/main.css'
// import 'bootstrap/dist/js/bootstrap.bundle'
import '@/js/axios'

/* import the fontawesome core */
import { library } from '@fortawesome/fontawesome-svg-core'

/* import font awesome icon component */
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'

/* import specific icons */
import { faAnglesLeft, faPhoneVolume, faMessage, faDeleteLeft } from '@fortawesome/free-solid-svg-icons'
/* add icons to the library */
library.add(faAnglesLeft)
library.add(faPhoneVolume)
library.add(faMessage)
library.add(faDeleteLeft)


const pinia = createPinia()

pinia.use(({ store }) => {
    store.router = markRaw(router)
})

pinia.use(({ store }) => {
    store.$moment = markRaw(moment)
})

const app = createApp(App)

app.use(pinia)
app.use(router)
app.use(Notifications)
app.use(Chat)

/* moment.js */
moment.locale('ru');
app.config.globalProperties.$moment=moment;

/* add font awesome icon component */
app.component('font-awesome-icon', FontAwesomeIcon)

app.mount('#app')

```

## vue-app/src/components/EventLogTable.vue
```js
<template>
  <div class="table-responsive mb-2">
    <table class="table table-bordered table-striped table-hover my-2">
      <thead>
        <tr>
          <td>№</td>
          <td>Наименование</td>
          <td>Приоритет</td>
          <td>Тип</td>
          <td>ФИО</td>
          <td>Статус</td>
          <td>
            Дата/время начала
          </td>
          <td>Время ожидания</td>
          <td>Диспетчер</td>
        </tr>
        <tr>
          <td></td>
          <td>
            <input type="text"
                   class="form-control"
                   id="classifier"
                   name="eventFilter[classifier]"
                   v-model.lazy="eventStore.filters['classifier']"
            >
          </td>
          <td>
            <select
                name="eventFilter[priority]"
                class="form-select"
                id="priority"
                v-model="eventStore.filters['priority']"
                v-if="route.name !== 'home'"
            >
              <option value=""></option>
              <option value="medium">Средний</option>
              <option value="low">Низкий</option>
            </select>
          </td>
          <td>
            <select
                name="eventFilter[type]"
                class="form-select"
                id="type"
                v-model="eventStore.filters['type']"
            >
              <option value=""></option>
              <option value="patient">Пациент</option>
              <option value="doctor">Доктор</option>
              <option value="dispatcher">Диспетчер</option>
            </select>
          </td>
          <td>
            <input type="text"
                   class="form-control"
                   id="eventInitiatorFullName"
                   name="eventFilter[eventInitiatorFullName]"
                   v-model.lazy="eventStore.filters['eventInitiatorFullName']"
            >
          </td>
          <td>
            <select
                name="eventFilter[status]"
                class="form-select"
                id="status"
                v-model="eventStore.filters['status']"
                v-if="route.name !== 'archive'"
            >
              <option value=""></option>
              <option value="waiting">В ожидании</option>
              <option value="in_work">В работе</option>
              <option value="paused">Приостановлен</option>
            </select>
          </td>
          <td>
            <Datepicker v-model="eventStore.createdAtFilter"
                        class="form-control"
                        range
                        multi-calendars
                        multi-calendars-solo
                        :enable-time-picker="false"
                        locale="ru"
                        text-input
            />
          </td>
          <td></td>
          <td>
            <input type="text"
                   class="form-control"
                   id="dispatcher_who_took_to_work"
                   name="eventFilter[dispatcher_who_took_to_work]"
                   v-model.lazy="eventStore.filters['dispatcherWhoTookToWork']"
            >
          </td>
        </tr>
      </thead>
      <tbody>
        <tr
            is="vue:event-log-table-row"
            v-for="(event, index) of eventStore.events"
            :key="event.id"
            class="event-row"
            @click="clickOnEventHandler(event)"
            :index="index"
        ></tr>
      </tbody>
    </table>
  </div>

  <pagination
      v-if="eventStore.records"
      v-model="eventStore.filters.page"
      :records="eventStore.records"
      :per-page="eventStore.perPage"
      :options="{ theme: 'bootstrap4', texts: { count: 'Показаны {from}-{to} из {count} записи' } }"
  />

  <teleport to='.modals-container'>
    <template v-if='isRevealed'>
      <div
          class='modal fade show'
          id='takeEventInWorkModal'
          tabindex='-1'
          aria-labelledby='takeEventInWorkModalLabel'
          data-bs-backdrop='static'
          data-bs-keyboard='false'
          aria-hidden='true'
          style='display: block'
      >
        <div class='modal-dialog modal-dialog-centered' ref='modal'>
          <div class='modal-content'>
            <div class='modal-header'>
              <h5 class='modal-title' id='takeEventInWorkModalLabel'>
                {{ modalHeaderContent }}
              </h5>
              <button
                  @click='cancel'
                  type='button'
                  class='btn-close
                  bg-light'
                  data-bs-dismiss='modal'
                  aria-label='Close'
              ></button>
            </div>
            <div class='modal-body'>
              {{ event.fullname }}
            </div>
            <div class='modal-footer'>
              <slot name='footer'>
                <button
                    @click='cancel'
                    type='button'
                    class='btn
                    btn-secondary'
                    data-bs-dismiss='modal'
                >Закрыть</button>
                <button
                    @click='takeInWork'
                    type='button'
                    class='btn
                    btn-success'
                    data-bs-dismiss='modal'
                    :disabled="!takeInWorkBtnEnabled"
                >Взять в работу</button>
              </slot>
            </div>
          </div>
        </div>
      </div>
      <div class='modal-backdrop fade show' style="z-index: 0"></div>
    </template>
  </teleport>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useEventStore } from '@/stores/eventStore.js'
import { useRouter } from 'vue-router'
import { useConfirmDialog } from '@vueuse/core'
import { useAuthStore } from '@/stores/authStore'
import { onClickOutside, useMagicKeys, useUrlSearchParams } from '@vueuse/core/index'
import { notify } from '@kyvg/vue3-notification'
import { useBodyOverflow } from '@/use/useBodyOverflow.js'
import Datepicker from '@vuepic/vue-datepicker'
import { ru } from 'date-fns/locale'
import { format } from "date-fns";
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { useRoute } from 'vue-router'
import Pagination from 'v-pagination-3'
import EventLogTableRow from '@/components/EventLogTableRow.vue'
import { useApiResponse } from '@/use/useApiResponse.js'

/* define stores */
const eventStore = useEventStore(),
    router = useRouter(),
    authStore = useAuthStore(),
    dateTimeStore = useDateTimeStore(),
    route = useRoute()

/* URL SEARCH PARAMS */
const props = defineProps(['params'])

const params = props.params

onMounted(async () => {
  if (!params.page) params.page = '1'
  eventStore.needToResetPage = false
  Object.assign(eventStore.filters, params)

  if (params?.createdAtFrom) eventStore.createdAtFilter[0] = new Date(params.createdAtFrom)
  if (params?.createdAtTo) eventStore.createdAtFilter[1] = new Date(params.createdAtTo)
})

const eventInitial = {
  id: null,
  fullname: null,
  classifier: null,
  classifier_comment: null,
}

const event = reactive({...eventInitial}),
    modal = ref(null),
    takeInWorkBtnEnabled = ref(true)

const { getDescription } = useApiResponse();

const eventId = computed(() => event.id)
const timestamp = computed(() => dateTimeStore.timestamp)

const deleteCurrentEventFromList = () => eventStore.deleteEventById(eventStore.eventId)

const setEvent = e => {
  event.id = e.id
  event.classifier_comment = e.classifier_comment
  event.fullname = getFullName(e)
  event.classifier = e.classifierRel?.title ?? null
}

const clearEvent = () => Object.assign(event, {...eventInitial})

const getFullName = e => {
  switch (e.type) {
    case 'patient':
      return e.patient.full_name
    case 'doctor':
    case 'dispatcher':
      return e.user.full_name
  }
}

/* TAKE IN WORK modal */
const { escape } = useMagicKeys()
const { setBodyOverflowHidden, setBodyOverflowAuto } = useBodyOverflow()
const {
  isRevealed,
  reveal,
  confirm,
  cancel,
  onReveal,
  onConfirm,
  onCancel,
} = useConfirmDialog()

watch(escape, () => cancel())
onClickOutside(modal, () => cancel())

onReveal(e => {
  setBodyOverflowHidden()
})

onCancel(() => {
  setBodyOverflowAuto()
  clearEvent()
})

const modalHeaderContent = computed(() => {
  if (Boolean(event.classifier_comment)) return event.classifier_comment
  return event.classifier
})

const url = computed(() => `/event/${ eventId.value }/registry-list-of-event`)

const takeInWork = async () => {
  takeInWorkBtnEnabled.value = false
  await eventStore.takeInWork(eventId.value)
      .then(() => {
        notify({
          type: 'success',
          title: '',
          text: 'Событие взято в работу',
        })
        confirm(true)
        setBodyOverflowAuto()
        router.push(url.value)
      })
      .catch(err => {

        if (err?.response?.data?.message === undefined) return false

        switch (err.response.data.message) {
          case 'app.event.notFound':
          case 'app.event.statusIsInWork':
          case 'app.event.statusIsDeleted':
          case 'app.event.priorityIsNotHigh':
            deleteCurrentEventFromList()
            cancel(true)
            break
        }

        notify({
          type: 'error',
          title: 'Не удалось взять в работу',
          text: getDescription(err.response.data.message),
        })

        console.error(err)
      })

  takeInWorkBtnEnabled.value = true
}

const clickOnEventHandler = e => {
  if (authStore.user?.dispatcher_working_status === 'paused') {
    notify({
      type: 'error',
      title: 'Работа приостановлена',
      text: 'Пожалуйста, возобновите работу',
    })
    return false
  }
  setEvent(e)
  if (e.dispatcher_id_who_took_to_work === authStore.user.id) {
    // todo eventStore.set Tmp Event
    return router.push(url.value)
  }
  reveal(e)
}

watch(() => eventStore.createdAtFilter, date => {
  if (!date) return eventStore.filters.createdAtFrom = eventStore.filters.createdAtTo = null

  let [createdAtFrom, createdAtTo] = date
  if (!createdAtFrom) return eventStore.filters.created_at_from = eventStore.filters.createdAtTo = null
  if (!createdAtTo) createdAtTo = createdAtFrom

  eventStore.filters.createdAtFrom = format(new Date(createdAtFrom), 'yyyy-MM-dd')
  eventStore.filters.createdAtTo = format(new Date(createdAtTo), 'yyyy-MM-dd')
})


</script>

<style scoped>
.event-row {
  cursor: pointer;
}
</style>
```

## vue-app/src/components/OldForm.vue
```js
<template>
  <form rel="form"
        class='need-validation'
        novalidate>
    <div class="row">

      <!--  LEFT COLUMN   -->
      <div class="col-md-12 col-lg-6 d-flex flex-column position-relative">


        <!--    ФИО     -->
        <div class="row my-2">
          <div class="col-md-4 py-2 border d-flex align-items-center">
            <label for="full_name" class="form-check-label w-100">
              ФИО
            </label>
          </div>
          <div class="col-md-8 py-2 border d-flex align-items-center position-relative">
            <input
                type="text"
                class="form-control"
                id="full_name"
                disabled
                v-if="registryListOfEventPage"
                v-model="patientStore.fullName"
            >
            <template v-else>
              <VueMultiselect
                  v-model="eventStore.selectedPatient"
                  :options="eventStore.patients"
                  :multiple="false"
                  :taggable="true"
                  @tag="addUserOrPatient"
                  :searchable="true"
                  :internal-search="false"
                  :clear-on-select="false"
                  :close-on-select="true"
                  :options-limit="30"
                  :limit="10"
                  @search-change="eventStore.findUserOrPatient"
                  placeholder="Введите ФИО"
                  label="fullname"
                  :custom-label="eventStore.userOrPatientCustomLabel"
                  :show-labels="false"
                  track-by="id"
                  :showNoOptions="true"
                  :showNoResults="true"
                  :loading="eventStore.userOrPatientIsLoading"
                  :class="{'is-invalid': v$.fullName.$error}"
              >
                <template #noResult>{{ eventStore.getEventTypeRuName }} не найден</template>
                <template #noOptions>Список пуст</template>
              </VueMultiselect>
              <div class='invalid-tooltip' v-if='v$.fullName.$error'>
                {{v$.fullName.$errors[0].$message}}
              </div>
            </template>
          </div>
        </div>

        <!--    Дата рождения     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient">
          <div class="col-md-4 py-2 border d-flex align-items-center">
            <label for="birthday" class="form-check-label w-100">
              Дата рождения
            </label>
          </div>
          <div class="col-md-8 py-2 border d-flex align-items-center position-relative">
            <Datepicker
                class="form-control"
                id="birthday"
                :disabled="eventStore.birthDatePickerDisabled(route.name)"
                inputFormat="dd.MM.yyyy"
                :locale="ru"
                weekdayFormat="EEEEEE"
                :upper-limit="new Date()"
                :typeable="true"
                v-model="eventStore.birthAtDatepicker"
                ref="datePickerRef"
                :class="{'is-invalid': v$.birthday.$error}"
            />
            <div class='invalid-tooltip' v-if='v$.birthday.$error'>
              {{v$.birthday.$errors[0].$message}}
            </div>
            <button class="btn btn-outline-danger ms-1"
                    @click.prevent="clearDatePicker"
                    :disabled="eventStore.birthDatePickerDisabled(route.name)"
                    v-if="eventStore.birthAtDatepicker">
              <font-awesome-icon icon="fa-solid fa-delete-left" />&nbsp;
            </button>
          </div>
        </div>

        <!--    Статус: маломобильный     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient && registryListOfEventStore.action(route.name) !== 'create-event'">
          <div class="col-10 py-2 border d-flex align-items-center">
            <label for="status_limited_mobility" class="form-check-label w-100">
              Статус: маломобильный
            </label>
          </div>
          <div class="col-2 py-2 border d-flex align-items-center">
            <input
                type="checkbox"
                class="form-check-input d-block ms-auto my-1 p-2"
                id="status_limited_mobility"
                v-model="model.limited_mobility"
                true-value="true"
                false-value="false"
            >
          </div>
        </div>

        <!--    Телефон и кнопка Вызов     -->
        <div class="row my-2">
          <div class="col-md-3 py-2 border d-flex align-items-center">
            <label for="phone" class="form-check-label w-100">
              Телефон
            </label>
          </div>
          <div class="col-md-6 py-2 border d-flex align-items-center position-relative">
            <input
                type="text"
                class="form-control"
                id="phone"
                :disabled="registryListOfEventPage || route.name === 'eventCreate' && eventStore.selectedPatient?.id"
                v-model="patientStore.phone"
                :class="{'is-invalid': v$.phone.$error}"
            >
            <div class='invalid-tooltip' v-if='v$.phone.$error'>
              {{v$.phone.$errors[0].$message}}
            </div>
          </div>
          <div class="col-md-3 py-2 border d-flex align-items-center">
            <button class="btn btn-primary btn-sm" @click.prevent="callBtnHandle" v-if="registryListOfEventStore.action(route.name) !== 'create-event'">
              <font-awesome-icon icon="fa-solid fa-phone-volume" />&nbsp;
              Звонок
            </button>
          </div>
        </div>

        <!--    Кнопка Перейти в чат     -->
        <div class="row d-flex" v-if="registryListOfEventStore.action(route.name) !== 'create-event'">
          <button class="btn btn-outline-primary btn-sm" @click.prevent="goToChatBtnHandle">
            <font-awesome-icon icon="fa-solid fa-message" />&nbsp;
            Перейти в чат
          </button>
        </div>

        <!--    История обращений:     -->
        <div class="row my-2 p-2 border list-group flex-row history flex-grow-1 position-relative" v-if="registryListOfEventStore.action(route.name) !== 'create-event'">
          <div v-if="registryListOfEventStore.registryListOfEventHistory?.length" class="position-absolute h-100 overflow-auto">
            <label class="form-check-label mb-2">
              История обращений:
            </label>
            <RouterLink
                to="/"
                v-for="link of registryListOfEventStore.registryListOfEventHistory"
                class="list-group-item list-group-item-action"
            >{{ link.created_at }}</RouterLink>
          </div>
          <div v-else>
            <label class="form-check-label mb-2">
              История обращений:
            </label>
            <p class="text-muted">Обращений не найдено</p>
          </div>
        </div>

      </div>

      <!--  RIGHT COLUMN   -->
      <div class="col-md-12 col-lg-6">

        <!--    Причина обращения     -->
        <div class="row my-2">
          <div class="col py-2 d-flex align-items-center position-relative">
            <select
                class="form-select"
                id="reason_id"
                aria-label="Причина обращения"
                v-model="eventStore.model.classifier"
                :disabled="eventStore.classifierDisabled(route.name)"
                :class="{'is-invalid': v$.classifier.$error}"
            >
              <option selected disabled>Причина обращения</option>
              <option v-for="(name, classifier) of eventStore.classifiers" :value="classifier">{{ name }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.classifier.$error'>
              {{v$.classifier.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Причина обращения текстовое поле     -->
        <div class="row my-2" v-if="registryListOfEventStore.action(route.name) !== 'create-event'">
          <div class="col py-2 d-flex align-items-center position-relative">
            <input
                type="text"
                class="form-control"
                :class="{'is-invalid': v$.classifier_comment.$error}"
                id="reason_text"
                placeholder="Ввод причины обращения вручную"
                v-model="eventStore.model.classifierComment"
                :disabled="eventStore.classifierCommentDisabled"
            >
            <div class='invalid-tooltip' v-if='v$.classifier_comment.$error'>
              {{v$.classifier_comment.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Тип диабета     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient">
          <div class="col py-1 d-flex align-items-center position-relative">
            <select
                class="form-select"
                :class="{'is-invalid': v$.diabetesType.$error}"
                id="diabetes_type"
                aria-label="Тип диабета"
                v-model="patientStore.card.diabetes.type"
                :disabled="eventStore.event?.id || eventStore.event?.userOrPatient?.id || eventStore.diabetesTypeFromPatientCard"
            >
              <option selected disabled>Тип диабета</option>
              <option v-for="(name, id) of eventStore.diabetesTypes" :value="id">{{ name }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.diabetesType.$error'>
              {{v$.diabetesType.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Диагноз     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient">
          <div class="col py-2 d-flex align-items-center position-relative">
            <select
                class="form-select"
                :class="{'is-invalid': v$.diagnosisMkb.$error}"
                id="diagnosis"
                aria-label="Диагноз"
                v-model="patientStore.card.diagnosis.mkb"
                :disabled="eventStore.event?.id || eventStore.event?.userOrPatient?.id || eventStore.mkbFromPatientCard"
            >
              <option selected disabled>Диагноз</option>
              <option v-for="mkb of eventStore.mkbListFilteredByDiabetesType" :value="mkb.id">{{ mkb.name }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.diagnosisMkb.$error'>
              {{v$.diagnosisMkb.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Сахарный диабет впервые выявленный     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient">
          <div class="col-10 ms-md-2 py-2 border d-flex align-items-center">
            <label for="first_diagnosed_diabetes" class="form-check-label w-100">
              Сахарный диабет впервые выявленный
            </label>
          </div>
          <div class="col py-2 border d-flex align-items-center">
            <input
                type="checkbox"
                class="form-check-input d-block ms-auto my-1 p-2"
                id="first_diagnosed_diabetes"
                v-model="eventStore.model.firstIdentifiedDiabetes"
                :disabled="eventStore.event?.id || eventStore.event?.userOrPatient?.id || eventStore.firstIdentifiedDiabetesFromPatientCard"
            >
          </div>
        </div>

        <!--    Длительность диабета     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient">
          <div class="col-md-6 ms-2 py-2 border d-flex align-items-center">
            <label for="diabetes_duration" class="form-check-label w-100">
              Длительность диабета
            </label>
          </div>
          <div class="col-md py-2 border d-flex align-items-center">
            <input
                type="text"
                class="form-control"
                id="diabetes_duration"
                disabled
                :value="eventStore.diabetesDuration"
                :title="eventStore.diabetesDurationTitle"
            >
          </div>
        </div>

        <!--    Инсулинопотребный     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient">
          <div class="col-10 ms-md-2 py-2 border d-flex align-items-center">
            <label for="insulin_requiring" class="form-check-label w-100">
              Инсулинопотребный
            </label>
          </div>
          <div class="col py-2 border d-flex align-items-center">
            <input
                type="checkbox"
                class="form-check-input d-block ms-auto my-1 p-2"
                id="insulin_requiring"
                v-model="eventStore.model.insulinRequiringDiabetes"
                :disabled="eventStore.event?.id || eventStore.event?.userOrPatient?.id">
          </div>
        </div>

        <!--    Метод введения инсулина     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient && eventStore.insulinRequiringDiabetes">
          <div class="col-6 ms-md-2 py-2 border d-flex align-items-center">
            <label for="insulin_method" class="form-check-label w-100">
              Метод введения инсулина
            </label>
          </div>
          <div class="col py-2 border d-flex align-items-center position-relative">
            <select
                class="form-select"
                :class="{'is-invalid': v$.insulinMethodDiabetes.$error}"
                id="insulin_method"
                aria-label="Тип диабета"
                v-model="eventStore.model.insulinMethodDiabetes"
                :disabled="eventStore.event?.id || eventStore.event?.userOrPatient?.id"
            >
              <option value="0">Шприц</option>
              <option value="1">Шприц-ручка</option>
              <option value="2">Инсулиновая помпа</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.insulinMethodDiabetes.$error'>
              {{v$.insulinMethodDiabetes.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Состояние пациента     -->
        <div class="row my-2" v-if="eventStore.eventTypeIsPatient && registryListOfEventStore.action(route.name) !== 'create-event'">
          <div class="col py-1 position-relative">
            <VueMultiselect
                v-model="model.patientCondition"
                :options="eventStore.patientConditionsWithIdAndNameKeys"
                :multiple="false"
                :searchable="false"
                placeholder="Состояние пациента"
                :showNoOptions="true"
                :showNoResults="true"
                label="title"
                track-by="name"
                :class="{'is-invalid': v$.patientCondition.$error}"
            >
              <template #noOptions>Список состояний пациента пуст</template>
            </VueMultiselect>
            <div class='invalid-tooltip' v-if='v$.patientCondition.$error'>
              {{v$.patientCondition.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Блоки: Запись к врачу и Телемедицина     -->
        <div class="row my-2 px-3" v-if="registryListOfEventStore.action(route.name) !== 'create-event'">
          <!--    Запись к врачу     -->
          <div class="col-md-8 col-lg py-1 my-md-1 border" v-if="eventStore.eventTypeIsPatient">
            <label for="doctor_appointment" class="form-check-label w-100">
              Запись к врачу
            </label>
            <div class="row px-2">
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="doctorAppointment"
                       id="doctor_appointment_yes"
                       autocomplete="off"
                       value="true"
                       v-model="model.doctor_appointment"
                >
                <label class="btn btn-outline-success w-100" for="doctor_appointment_yes">
                  Да
                </label>
              </div>
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="doctorAppointment"
                       id="doctor_appointment_no"
                       autocomplete="off"
                       value="false"
                       v-model="model.doctor_appointment"
                >
                <label class="btn btn-outline-danger w-100" for="doctor_appointment_no">
                  Нет
                </label>
              </div>
            </div>
          </div>

          <!--    Телемедицина     -->
          <div class="col-md-8 col-lg py-1 my-md-1 border" v-if="eventStore.eventTypeIsPatient">
            <label for="telemedicine" class="form-check-label w-100">
              Телемедицина
            </label>
            <div class="row px-2">
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="telemedicine"
                       id="telemedicine_yes"
                       autocomplete="off"
                       value="true"
                       v-model="model.telemedicine"
                >
                <label class="btn btn-outline-success w-100" for="telemedicine_yes">
                  Да
                </label>
              </div>
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="telemedicine"
                       id="telemedicine_no"
                       autocomplete="off"
                       value="false"
                       v-model="model.telemedicine"
                >
                <label class="btn btn-outline-danger w-100" for="telemedicine_no">
                  Нет
                </label>
              </div>
            </div>
          </div>
        </div>

      </div>

    </div>

    <!--  SECOND ROW: врач, мед.учр., мед.учр.экстренно   -->

    <!--    Врач, оповещение     -->
    <div class="row mb-md-4" v-if="eventStore.eventTypeIsPatient && registryListOfEventStore.action(route.name) !== 'create-event'">
      <div class="col-lg-2 py-2 border d-flex align-items-center">
        <label for="doctor" class="form-check-label w-100">
          Врач
        </label>
      </div>
      <div class="col-lg-4 py-2 border d-flex align-items-center">
        <VueMultiselect
            v-model="model.doctor"
            :options="registryListOfEventStore.doctors"
            :multiple="false"
            :searchable="true"
            :internal-search="false"
            :clear-on-select="false"
            :close-on-select="true"
            :options-limit="30"
            :limit="10"
            @search-change="registryListOfEventStore.findDoctors"
            placeholder="Введите ФИО доктора"
            label="fullname"
            track-by="id"
            :showNoOptions="true"
            :showNoResults="true"
            :loading="registryListOfEventStore.doctorsIsLoading"
        >
          <template #noResult>Врач не найден</template>
          <template #noOptions>Список врачей пуст</template>
        </VueMultiselect>
      </div>
      <div class="col-lg py-2 mx-1 row">

        <div class="form-check form-switch">
          <input class="form-check-input"
                 id="doctor_alert"
                 type="checkbox"
                 v-model="model.doctor_alert"
                 true-value="true"
                 false-value="false"
          >
          <label class="form-check-label" for="doctor_alert">Оповещение врача</label>
        </div>
      </div>
    </div>

    <!--    мед.учр, оповещение     -->
    <div class="row mb-md-4" v-if="eventStore.eventTypeIsPatient && registryListOfEventStore.action(route.name) !== 'create-event'">
      <div class="col-lg-2 py-2 border d-flex align-items-center">
        <label for="emergency_medical_institution" class="form-check-label w-100">
          Мед Учреждение
        </label>
      </div>

      <div class="col-lg-4 py-2 border d-flex align-items-center">
        <VueMultiselect
            v-model="model.medicalInstitution"
            :options="registryListOfEventStore.hospitals"
            :multiple="false"
            :searchable="true"
            :internal-search="false"
            :clear-on-select="false"
            :close-on-select="true"
            :options-limit="30"
            :limit="10"
            @search-change="registryListOfEventStore.findHospitals"
            placeholder="Введите наименование"
            label="name_short"
            track-by="id"
            :showNoOptions="true"
            :showNoResults="true"
            :loading="registryListOfEventStore.hospitalsIsLoading"
        >
          <template #noResult>Мед Учреждение не найдено</template>
          <template #noOptions>Список мед учр. пуст</template>
        </VueMultiselect>
      </div>

      <div class="col-lg mx-1 row">
        <div class="form-check form-switch">
          <input class="form-check-input"
                 id="need_calling_an_ambulance"
                 type="checkbox"
                 v-model="model.need_calling_an_ambulance"
                 true-value="true"
                 false-value="false"
          >
          <label class="form-check-label" for="need_calling_an_ambulance">Вызов скорой помощи</label>
        </div>
      </div>

    </div>

    <!--    мед.учр.экстренно, оповещение     -->
    <div class="row mb-md-4" v-if="eventStore.eventTypeIsPatient && registryListOfEventStore.action(route.name) !== 'create-event'">
      <div class="col-lg-2 py-2 border d-flex align-items-center">
        <label for="medical_institution" class="form-check-label w-100">
          Мед Учреждение Экстренно
        </label>
      </div>

      <div class="col-lg-4 py-2 border d-flex align-items-center">
        <VueMultiselect
            v-model="model.medicalInstitutionUrgently"
            :options="registryListOfEventStore.hospitalsUrgent"
            :multiple="false"
            :searchable="true"
            :internal-search="false"
            :clear-on-select="false"
            :close-on-select="true"
            :options-limit="30"
            :limit="10"
            @search-change="registryListOfEventStore.findHospitalsUrgent"
            placeholder="Введите наименование"
            label="name_short"
            track-by="id"
            :showNoOptions="true"
            :showNoResults="true"
            :loading="registryListOfEventStore.hospitalsUrgentIsLoading"
        >
          <template #noResult>Мед Учреждение Экстренно не найдено</template>
          <template #noOptions>Список экстренных мед учр.  пуст</template>
        </VueMultiselect>
      </div>

      <div class="col-lg py-2 mx-1 row">
        <div class="form-check form-switch">
          <input class="form-check-input"
                 id="calling_doctor_at_home"
                 type="checkbox"
                 v-model="model.calling_doctor_at_home"
                 true-value="true"
                 false-value="false"
          >
          <label class="form-check-label" for="calling_doctor_at_home">Вызов врача на дом</label>
        </div>
      </div>

    </div>

    <!--   Приоритет, Стадия компенсации   -->
    <div class="row" v-if="registryListOfEventStore.action(route.name) === 'create-event'">
      <div class="col col-md-6">
        <div class="form-group position-relative">
          <label for="event_priority" class="mb-2">Приоритет</label>
          <select
              name="event_priority"
              class="form-select"
              id="event_priority"
              v-model="eventStore.event.priority"
              :class="{'is-invalid': v$.priority.$error}"
          >
            <option value="high">Высокий</option>
            <option value="medium">Средний</option>
            <option value="low">Низкий</option>
          </select>
          <div class='invalid-tooltip' v-if='v$.priority.$error'>
            {{v$.priority.$errors[0].$message}}
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6" v-if="registryListOfEventStore.action(route.name) === 'update'">
        <label class="form-check-label" for="status">Статус</label>
        <select
            class="form-select"
            id="status"
            aria-label=""
            v-model="eventStore.event.status"
        >
          <option selected disabled>Статус</option>
          <option value="in_work">В работе</option>
          <option value="done">Обработан</option>
          <option value="paused">Приостановлен</option>
        </select>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-3 row justify-content-end mx-1">
        <label style="color: white">-</label>
        <button class="btn btn-success" @click.prevent="saveBtnHandle">
          {{ registryListOfEventStore.action(route.name) === 'update' ? 'Обновить' : 'Создать' }}
        </button>
      </div>
      <div class="col-12 col-md-3 row justify-content-end mx-1" v-if="route.name === 'eventCreate'">
        <label style="color: white">-</label>
        <button class="btn btn-success" @click.prevent="saveAndRedirectBtnHandle">
          Создать и перейти
        </button>
      </div>
    </div>

    <div class="row my-4" v-if="registryListOfEventPage">
      <div class="col-12 col-md-6">
        <RouterLink to="/" class="btn btn-primary">
          <font-awesome-icon icon="fa-solid fa-angles-left" />
          Назад к журналу событий
        </RouterLink>
      </div>
    </div>
  </form>
</template>

<script setup>
import { onMounted, onUnmounted, reactive, ref, computed, watch } from 'vue'
import { useRoute, onBeforeRouteLeave } from 'vue-router'
import { useRegistryListOfEvent } from '@/stores/registryListOfEventStore.js'
import { useEventStore } from '@/stores/eventStore.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import VueMultiselect from 'vue-multiselect'
import { helpers, required, requiredIf, maxLength } from '@vuelidate/validators'
import { useVuelidate } from '@vuelidate/core'
import { notify } from '@kyvg/vue3-notification'
import Datepicker from 'vue3-datepicker'
import { format } from 'date-fns'
import { ru } from 'date-fns/locale'

const registryListOfEventStore = useRegistryListOfEvent(),
    eventStore = useEventStore(),
    patientStore = usePatientStore(),
    dateTimeStore = useDateTimeStore(),
    route = useRoute()

const form = ref(null),
    datePickerRef = ref(null)

const { getObjectFullName, getObjectBirthdayFormatted, getObjectPhone, getReferences, fetchEvent } = eventStore
const {
  getHistory
} = registryListOfEventStore

const model = computed(() => registryListOfEventStore.model)

const fullNameValidateRegex = /^(?<last_name>[а-яА-Я0-9\-\_\s]+)(?:\.|\s)(?<first_name>[а-яА-Я0-9\-\_]+)(?:\.|\s)(?<patronymic>[а-яА-Я0-9\-\_]+)\.?$/g;
const validateFullName = fullName => {
  if (eventStore.selectedPatient?.id) return true
  return !fullName ? false : fullName.trim().match(fullNameValidateRegex)
}

const rules = computed(() => ({
  fullName: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле ФИО`,
        requiredIf(registryListOfEventStore.action(route.name) === 'create-event')
    ),
    validateFullName: helpers.withMessage(
        () => `ФИО заполнено не корректно`,
        validateFullName
    )
  },
  birthday: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Дата рождения`,
        requiredIf(registryListOfEventStore.action(route.name) === 'create-event' && eventStore.eventTypeIsPatient)
    ),
  },
  phone: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Телефон`,
        requiredIf(registryListOfEventStore.action(route.name) === 'create-event' && !eventStore.selectedPatient?.id)
    ),
    maxLength: helpers.withMessage(
        () => `Максимальная длина поле Телефон 11 символов`,
        maxLength(11)
    )
  },
  classifier: {
    required: helpers.withMessage('Пожалуйста, заполните поле Причина обращения', required),
  },
  classifier_comment: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Комментарий к обращению`,
        requiredIf(registryListOfEventStore.action(route.name) !== 'create-event' && eventStore.eventClassifierIsOther)
    ),
  },
  patientCondition: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Состояние пациента`,
        requiredIf(registryListOfEventStore.action(route.name) !== 'create-event' && eventStore.eventTypeIsPatient)
    ),
  },
  insulinMethodDiabetes: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Метод введения инсулина`,
        requiredIf(
            registryListOfEventStore.action(route.name) === 'create-event' &&
            eventStore.eventTypeIsPatient &&
            eventStore.model.insulinRequiringDiabetes &&
            !eventStore.event?.userOrPatient?.id
        )
    ),
  },
  diabetesType: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Тип диабета`,
        requiredIf(
            registryListOfEventStore.action(route.name) === 'create-event' &&
            eventStore.eventTypeIsPatient &&
            !eventStore.event?.userOrPatient?.id
        )
    ),
  },
  diagnosisMkb: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле МКБ`,
        requiredIf(
            registryListOfEventStore.action(route.name) === 'create-event' &&
            eventStore.eventTypeIsPatient &&
            patientStore.card.diabetes.type &&
            !eventStore.event?.userOrPatient?.id
        )
    ),
  },
  priority: {
    requiredIf: helpers.withMessage(
        () => `Пожалуйста, заполните поле Приоритет события`,
        requiredIf(registryListOfEventStore.action(route.name) === 'create-event')
    ),
  },
}))


let state = reactive({
  fullName: computed(() => patientStore.fullName),
  birthday: computed(() => eventStore.model.birthday),
  patientCondition: computed(() => registryListOfEventStore.model.patientCondition),
  insulinMethodDiabetes: computed(() => eventStore.model.insulinMethodDiabetes),
  diabetesType: computed(() => patientStore.card.diabetes.type),
  diagnosisMkb: computed(() => patientStore.card.diagnosis.mkb),
  classifier_comment: computed(() => eventStore.model.classifierComment),
  phone: computed(() => patientStore.phone),
  classifier: computed(() => eventStore.model.classifier),
  priority: computed(() => eventStore.event.priority),
  compensation_stage: computed(() => eventStore.event.compensation_stage),
})

const v$ = useVuelidate(rules, state)

watch(() => getObjectBirthdayFormatted(eventStore.event), date => {
  eventStore.event.birth_at_formatted = date

  if (eventStore.getObjectBirthday(eventStore.event)) {
    eventStore.birthAtDatepicker = new Date(eventStore.getObjectBirthday(eventStore.event))
  }
})

watch(() => eventStore.birthAtDatepicker, date => {
  if (
      !date
      ||
      !dateTimeStore.isValidDate(new Date(date))
      ||
      (new Date(date)) > (new Date())
  ) {
    return clearDatePicker()
  }
  eventStore.event.birth_at_formatted = format(new Date(date), 'dd.MM.yyyy')
  patientStore.birthday = format(new Date(date), 'yyyy-MM-dd')
})

watch(() => eventStore.selectedPatient, value => {
  console.log('watch(() => eventStore.selectedPatient', value)
  if (!value) {
    eventStore.event.patient = null
    patientStore.fullName = null
    patientStore.birthday = null
    eventStore.birthAtDatepicker = null
    return false
  }
  switch (eventStore.event?.type) {
    case 'patient':
      eventStore.event.patient = value
      patientStore.fullName = value.fullname
      patientStore.birthday = dateTimeStore.isValidDate(value?.birth_at) ? value?.birth_at : null
      eventStore.birthAtDatepicker = patientStore.birthday ? new Date(value?.birth_at) : null
      eventStore.fillPatientCardModels()
      break;
    case 'doctor':
    case 'dispatcher':
      eventStore.event.user = value
      patientStore.fullName = value.fullname
      break;
  }
})

watch(() => patientStore.card.diabetes.type, (newValue, oldValue) => {
  if (Boolean(oldValue) && Boolean(newValue))
    patientStore.card.diagnosis.mkb = null
})

watch(() => eventStore.model.classifier, (newValue, oldValue) => {
  if (oldValue === 'other')
    eventStore.model.classifierComment = null
})

watch(() => eventStore.model.manifestMonthDiabetes, month => {
  eventStore.model.manifestMonthDiabetes = month > 1 && month <= 12
      ? month
      : 1
})

watch(() => eventStore.model.manifestYearDiabetes, year => {
  let currentDate = new Date(dateTimeStore.timestamp * 1000)
  eventStore.model.manifestYearDiabetes = year > currentDate.getFullYear()
      ? null
      : year
})

watch([
  () => eventStore.model,
  () => registryListOfEventStore.model,
  () => eventStore.event.type,
  () => eventStore.event.status,
  () => eventStore.event.priority,
  () => eventStore.event.compensation_stage
], () => {
  eventStore.hasChanges = registryListOfEventStore.hasChanges = true
}, { deep: true })

onMounted(async () => {
  if (registryListOfEventPage) {
    await fetchEvent(route.params.id).then(() => {
      console.log(eventStore.event.patient)
      getHistory()
      if (!eventStore.referencesLoaded) getReferences()
      dateTimeStore.getCurrentTimestamp()
    })
  }

  setTimeout(() => eventStore.hasChanges = registryListOfEventStore.hasChanges = false, 0)
})

onUnmounted(() => {
  console.log('eventStore.clearBeforeLeave() registry list of event')
  eventStore.clearBeforeLeave()
  eventStore.clearFilters()
  registryListOfEventStore.clearBeforeLeave()
})

onBeforeRouteLeave((to, from) => {
  if (eventStore.hasChanges || registryListOfEventStore.hasChanges) {
    const answer = window.confirm('Вы действительно хотите покинуть страницу? Все несохраненные изменения будут потеряны')
    if (!answer) return false
  }
})

const callBtnHandle = () => {
  alert('Функционал находится в разработке')
}

const goToChatBtnHandle = () => {
  alert('Функционал находится в разработке')
}

const saveBtnHandle = () => {
  registryListOfEventStore.redirectToEventAfterCreate = false
  save()
}

const saveAndRedirectBtnHandle = () => {
  registryListOfEventStore.redirectToEventAfterCreate = true
  save()
}

const save = async () => {
  if (eventStore.event.type !== 'patient') {
    return notify({
      type: 'error',
      title: 'Функционал в разработке',
      text: 'На данный момент можно создавать только события типа "Пациент"'
    })
  }

  const formData = new FormData(),
      isFormCorrect = await v$.value.$validate(),
      form = {
        // patient
        patient_id: eventStore.event?.userOrPatient?.id ?? null,
        full_name: patientStore.fullName,
        birthday: patientStore.birthday,
        birth_at_formatted: eventStore.event?.birth_at_formatted,
        phone: patientStore.phone,
        // patient card
        diabetes_type: patientStore.card.diabetes.type,
        diagnosis_mkb: patientStore.card.diagnosis.mkb,
        first_identified_diabetes: eventStore.model.firstIdentifiedDiabetes,
        manifest_year_diabetes: eventStore.model.manifestYearDiabetes,
        manifest_month_diabetes: eventStore.model.manifestMonthDiabetes,
        insulin_requiring_diabetes: eventStore.model.insulinRequiringDiabetes,
        insulin_method_diabetes: eventStore.model.insulinMethodDiabetes,
        // event and registry list of event
        classifier: eventStore.model.classifier,
        classifier_comment: eventStore.model.classifierComment,
        limited_mobility: model.value.limited_mobility,
        patient_condition: registryListOfEventStore.patientConditionName,
        doctor_appointment: model.value.doctor_appointment,
        telemedicine: model.value.telemedicine,
        doctor_id: registryListOfEventStore.doctorId,
        doctor_alert: model.value.doctor_alert,
        medical_institution_id: registryListOfEventStore.medicalInstitutionId,
        medical_institution_urgently_id: registryListOfEventStore.medicalInstitutionUrgentlyId,
        calling_doctor_at_home: model.value.calling_doctor_at_home,
        need_calling_an_ambulance: model.value.need_calling_an_ambulance,
        event_type: eventStore.event.type,
        event_status: eventStore.event.status,
        event_priority: eventStore.event.priority,
        compensation_stage: eventStore.event.compensation_stage,
      }


  if (!isFormCorrect) {
    return notify({
      type: 'error',
      title: 'Ошибка валидации',
      text: v$.value.$errors[0].$message,
    })
  }

  Object.keys(form).forEach((key) => {
    let value = form[key]
    if (!value) value = ''
    formData.append(key, value)
  })

  v$.value.$reset()

  if (eventStore.eventId || registryListOfEventStore.action(route.name) === 'create-event') {
    return registryListOfEventStore.save(formData, route.name)
  }
}

const addUserOrPatient = fullname => {
  eventStore.patients = []
  fullname = fullname ? fullname.trim() : null

  let object = {
    fullname,
    fullnameWithBirthdate: fullname
  }

  eventStore.patients.push(object)
  eventStore.selectedPatient = object
}

const clearDatePicker = () => {
  eventStore.birthAtDatepicker = null
}


const registryListOfEventPage = computed(() => route.name === 'registryListOfEventCreate')
</script>

<style>
.history {
  overflow: hidden;
  align-content: flex-start;
  display: flex;
  min-height: 200px;
}

.multiselect.is-invalid > .multiselect__tags {
  border-color: #dc3545;
  padding-right: calc(1.5em + 0.75rem);
  background-repeat: no-repeat;
  background-position: right calc(0.375em + 0.1875rem) center;
  background-size: calc(0.75em + 0.375rem) calc(0.75em + 0.375rem);
}
</style>
```

## vue-app/src/components/DispatcherForm.vue
```js
<template>
  <div class="alert alert-warning">Функционал находится в разработке</div>
</template>

<script setup>

</script>

<style>

</style>
```

## vue-app/src/components/modals/CopyErrMsgToClipboardBtn.vue
```js
<template>
  <template v-if='isSupported'>
    <button
        v-if='copied'
        class='btn btn-success d-block ms-auto'
    >Скопировано!</button>
    <button
        v-else
        @click.prevent='copy(error)'
        class='btn btn-primary d-block ms-auto'
    >Скопировать текст ошибки</button>
  </template>
</template>

<script setup>
import { useClipboard, usePermission } from '@vueuse/core'
import { computed } from 'vue'

const props = defineProps({
  errorMessage: {
    type: String,
    default: ''
  }
})

const error = computed(() => props.errorMessage)

const { text, copy, copied, isSupported } = useClipboard({ error })

const permissionRead = usePermission('clipboard-read')
const permissionWrite = usePermission('clipboard-write')
</script>

<style scoped>

</style>
```

## vue-app/src/components/DoctorForm.vue
```js
<template>
  <div class="alert alert-warning">Функционал находится в разработке</div>
</template>

<script setup>

</script>

<style>

</style>
```

## vue-app/src/components/layouts/NavBar.vue
```js
<template>
  <nav class='navbar navbar-expand-md navbar-light bg-light'>
    <div class='container-fluid'>
      <button
          @click='showMobileNav = !showMobileNav'
          ref='navbarBurger'
          class='navbar-toggler'
          type='button'
          data-bs-toggle='collapse'
          data-bs-target='#navbarTogglerDemo01'
          aria-controls='navbarTogglerDemo01'
          aria-expanded='false'
          aria-label='Toggle navigation'>
        <span class='navbar-toggler-icon'></span>
      </button>
      <div
          :class='{show: showMobileNav}'
          ref='navbarRef'
          class='collapse navbar-collapse'
          id='navbarTogglerDemo01'>
        <a class='navbar-brand' href='#'>Routing</a>
        <ul class='navbar-nav me-auto mb-2 mb-lg-0'>
          <li class='nav-item'>
            <a @click.prevent="goHomeBtnHandler" style="cursor:pointer">Главная</a>
          </li>
        </ul>
        <div class='nav-item'>
          <RouterLink
              v-if='!authStore.isAuthenticated'
              to='/login'
              active-class='active'
              @click='closeNavBar'
              class='nav-link'
              aria-current='page'>Вход</RouterLink>
          <button
              v-else
              @click='logout'
              class='btn btn-danger btn-sm'
              aria-current='page'>Выйти {{ !authStore.user?.last_name ? '' : `( ${authStore.user.last_name} )` }}</button>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { RouterLink, useRouter } from 'vue-router'
import { onMounted, ref } from 'vue'
import { onClickOutside } from '@vueuse/core'
import { useAuthStore } from '@/stores/authStore'
import { useEventStore } from '@/stores/eventStore.js'
import { useUrlSearchParams } from '@vueuse/core'

const authStore = useAuthStore(),
    eventStore = useEventStore()

const showMobileNav = ref(false),
    navbarRef = ref(null),
    navbarBurger = ref(null),
    router = useRouter()

const params = useUrlSearchParams('history')

const closeNavBar = () => showMobileNav.value = false

const logout = () => {
  closeNavBar()
  authStore.logout()
}

onClickOutside(navbarRef, () => closeNavBar(), {
  ignore: [navbarBurger]
})

const goHomeBtnHandler = () => {
  if (params) Object.keys(params).forEach(key => params[key] = null)
  params['page'] = 1
  eventStore.filters = Object.assign({}, params)
  return router.push({name: 'home'})
}

</script>

<style scoped>

</style>
```

## vue-app/src/components/layouts/NavTab.vue
```js
<template>
  <ul class='nav nav-tabs flex-column flex-sm-row'>
    <li class='nav-item flex-md-row my-2'>
      <RouterLink
          to='/'
          active-class='active'
          class='nav-link'
          aria-current='page'>Журнал событий</RouterLink>
    </li>
    <li class='nav-item flex-md-row my-2'>
      <RouterLink
          to='/scheduled-tasks'
          active-class='active'
          class='nav-link'
          aria-current='page'>Плановые задачи</RouterLink>
    </li>
    <li class='nav-item flex-md-row my-2'>
      <RouterLink
          to='/archive'
          active-class='active'
          class='nav-link'
          aria-current='page'>Архив</RouterLink>
    </li>
    <li class='nav-item flex-md-row my-2 ms-lg-auto'>
      <button class='btn btn-warning btn-sm m-1 d-sm-block d-md-inline' @click.prevent="authStore.resumeWork" v-if="authStore.user?.dispatcher_working_status === 'paused'">Возобновить работу</button>
      <button class='btn btn-warning btn-sm m-1 d-sm-block d-md-inline' @click.prevent="reveal" v-else>Приостановить работу</button>
      <RouterLink
          :to='{ name: "eventCreate" }'
          class='btn btn-primary btn-sm m-1 d-sm-block d-md-inline'
          aria-current='page'
          v-if="authStore.user?.dispatcher_working_status !== 'paused'"
      >Создать событие</RouterLink>
    </li>
  </ul>

  <teleport to='.modals-container'>
    <template v-if='isRevealed'>
      <div
          class='modal fade show'
          id='takeEventInWorkModal'
          tabindex='-1'
          aria-labelledby='takeEventInWorkModalLabel'
          data-bs-backdrop='static'
          data-bs-keyboard='false'
          aria-hidden='true'
          style='display: block'
      >
        <div class='modal-dialog modal-dialog-centered' ref='modal'>
          <div class='modal-content'>
            <div class='modal-header'>
              <h5 class='modal-title' id='takeEventInWorkModalLabel'>
                Приостановить работу
              </h5>
              <button
                  @click='cancel'
                  type='button'
                  class='btn-close
                  bg-light'
                  data-bs-dismiss='modal'
                  aria-label='Close'
              ></button>
            </div>
            <div class='modal-body'>
              Приостановить вместе с взятыми в работу событиями?
            </div>
            <div class='modal-footer'>
              <slot name='footer'>
                <button
                    @click='pauseWork'
                    type='button'
                    class='btn btn-warning'
                    data-bs-dismiss='modal'
                >Только работу</button>
                <button
                    @click='pauseWorkWithEvents'
                    type='button'
                    class='btn btn-secondary'
                    data-bs-dismiss='modal'
                >Вместе с событиями</button>
              </slot>
            </div>
          </div>
        </div>
      </div>
      <div class='modal-backdrop fade show' style="z-index: 0"></div>
    </template>
  </teleport>
</template>

<script setup>
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/authStore.js'

import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useConfirmDialog } from '@vueuse/core'
import { onClickOutside, useMagicKeys, useUrlSearchParams } from '@vueuse/core/index'
import { useBodyOverflow } from '@/use/useBodyOverflow.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'

const authStore = useAuthStore(),
    router = useRouter()
const modal = ref(null)

/* TAKE IN WORK modal */
const { escape } = useMagicKeys()
const { setBodyOverflowHidden, setBodyOverflowAuto } = useBodyOverflow()
const {
  isRevealed,
  reveal,
  confirm,
  cancel,
  onReveal,
  onConfirm,
  onCancel,
} = useConfirmDialog()

watch(escape, () => cancel())
onClickOutside(modal, () => cancel())

onReveal(e => {
  setBodyOverflowHidden()
})

onCancel(() => {
  setBodyOverflowAuto()
})

const pauseWork = () => {
  authStore.pauseWork()
  cancel()
}
const pauseWorkWithEvents = () => {
  authStore.pauseWorkWithEvents()
  cancel()
  setTimeout(() => router.go(), 1000)
}

</script>

<style scoped>

</style>
```

## vue-app/src/components/FormDependOnEventType.vue
```js
<template>
  <component v-if="eventType" :is="component" />
</template>

<script setup>
import { computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useEventStore } from '@/stores/eventStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import { useRegistryListOfEvent } from '@/stores/registryListOfEventStore.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { useReferenceStore } from '@/stores/referenceStore.js'
import PatientForm from '@/components/PatientForm.vue'
import DoctorForm from '@/components/DoctorForm.vue'
import DispatcherForm from '@/components/DispatcherForm.vue'

const eventStore = useEventStore(),
    patientStore = usePatientStore(),
    registryListOfEventStore = useRegistryListOfEvent(),
    dateTimeStore = useDateTimeStore(),
    referenceStore = useReferenceStore(),
    route = useRoute()

const eventExists = computed(() => Boolean(eventStore.id))

const eventType = computed(() => eventStore.type)
const component = computed(() => {
  switch (eventType.value) {
    case 'patient':
      return PatientForm
    case 'dispatcher':
      return DispatcherForm
    case 'doctor':
      return DoctorForm
  }
})

const registryPage = computed(() => route.name === 'registryListOfEventCreate')

onMounted(async () => {
  if (!referenceStore.referencesLoaded) await referenceStore.getReferences()
  if (registryPage.value) {
    await getEventWithHistory()
  }

  // TODO where should i place this ?
  setTimeout(() => eventStore.hasChanges = registryListOfEventStore.hasChanges = false, 0)
})


const getEventWithHistory = async () => {
  await eventStore.getEventById(route.params.id)
      .then(e => {
        eventStore.loadModel(e)

        switch (e.type) {
          case 'patient':
            patientStore.load(e.patient)
            patientStore.loadCard(e.patient.card)
            break
        }

        registryListOfEventStore.load(e?.registryListOfEvent)
      })
      .then(() => registryListOfEventStore.getHistory())
}

watch(() => route.params.id, async (newId, oldId) => {
  eventStore.clear()
  registryListOfEventStore.clear()
  patientStore.clear()
  await getEventWithHistory()
})

onUnmounted(async () => {
  eventStore.clear()
  registryListOfEventStore.clear()
  patientStore.clear()
})
</script>

<style>

</style>
```

## vue-app/src/components/EventLogTableRow.vue
```js
<template>
    <tr>
      <td>{{ rowNumber }}</td>
      <td>{{ classifierCommentOrClassifier }}</td>
      <td>{{ event.priorityRel.title }}</td>
      <td>{{ event.typeRel.title }}</td>
      <td>{{ getFullName }}</td>
      <td>{{ event.statusRel.title }}</td>
      <td>{{ dateFormatted(event.created_at) }}</td>
      <td>{{ timeAgo(event.created_at) }}</td>
      <td>{{ event.dispatcher_id_who_took_to_work ? event.dispatcherWhoTookToWork.full_name : '??' }}</td>
    </tr>
</template>

<script setup>
import { computed, getCurrentInstance } from 'vue'
import { useDateFormat } from '@vueuse/core'
import { useEventStore } from '@/stores/eventStore.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'

/* define stores */
const eventStore = useEventStore(),
    dateTimeStore = useDateTimeStore()

const internalInstance = getCurrentInstance()

const { $moment } = internalInstance.appContext.config.globalProperties

const props = defineProps({
  index: {
    type: Number,
    required: true,
  },
})

const rowNumber = computed(() => props.index + 1),
    event = computed(() => eventStore.getEventByIndex(props.index))

const classifierCommentOrClassifier = computed(() => {
  if (Boolean(event.value.classifier_comment)) return event.value.classifier_comment
  return event.value.classifierRel?.title ?? null
})

const getFullName = computed( () => {
  switch (event.value.type) {
    case 'patient':
      return event.value.patient.full_name
    case 'doctor':
    case 'dispatcher':
      return event.value.user.full_name
  }
})

const timeAgo = (createdAt) => $moment(createdAt, 'YYYY-MM-DD hh:mm:ss').from(currentMomentDate())

const currentMomentDate = () => $moment.unix(dateTimeStore.timestamp)

const dateFormatted = date => useDateFormat(new Date(date), 'DD.MM.YYYY HH:mm').value

</script>

<style scoped>

</style>
```

## vue-app/src/components/PatientForm.vue
```js
<template>
  <form rel="form"
        class='need-validation patient-form'
        novalidate>

    <div class="row">

      <!--  LEFT COLUMN   -->
      <div class="col-md-12 col-lg-6 d-flex flex-column position-relative">

        <!--    Patient ID     -->
        <div class="row my-2" v-if="registryPage">
          <div class="col-md-4 py-2 border d-flex align-items-center">
            <label for="id" class="form-check-label w-100">
              ID пациента
            </label>
          </div>
          <div class="col-md-8 py-2 border">
            <input
                type="text"
                class="form-control"
                id="id"
                disabled
                :value="patientStore.id">
          </div>
        </div>

        <!--    ФИО     -->
        <div class="row my-2">
          <div class="col-md-4 py-2 border d-flex align-items-center">
            <label for="full_name" class="form-check-label w-100">
              ФИО пациента
            </label>
          </div>
          <div class="col-md-8 py-2 border d-flex align-items-center position-relative">
            <input
                type="text"
                class="form-control"
                id="full_name"
                disabled
                v-if="registryPage"
                v-model="patientStore.fullName"
            >
            <template v-else-if="eventCreatePage">
              <VueMultiselect
                  v-model="eventStore.selectedPatient"
                  :options="eventStore.patients"
                  :multiple="false"
                  :taggable="true"
                  @tag="addPatient"
                  :searchable="true"
                  :internal-search="false"
                  :clear-on-select="false"
                  :close-on-select="true"
                  :options-limit="30"
                  :limit="10"
                  @search-change="searchPatient"
                  placeholder="Введите ФИО"
                  label="fullName"
                  :custom-label="({ fullNameWithBirthdate }) => fullNameWithBirthdate"
                  :show-labels="false"
                  track-by="id"
                  :showNoOptions="true"
                  :showNoResults="true"
                  :loading="eventStore.patientsIsLoading"
                  :class="{'is-invalid': v$.fullName.$error}"
              >
                <template #noResult>{{ eventStore.getEventTypeRuName }} не найден</template>
                <template #noOptions>Список пуст</template>
              </VueMultiselect>
              <div class='invalid-tooltip' v-if='v$.fullName.$error'>
                {{ v$.fullName.$errors[0].$message }}
              </div>
            </template>
          </div>
        </div>

        <!--    Дата рождения     -->
        <div class="row my-2">
          <div class="col-md-4 py-2 border d-flex align-items-center">
            <label for="birthday" class="form-check-label w-100">
              Дата рождения
            </label>
          </div>
          <div class="col-md-8 py-2 border d-flex align-items-center position-relative">
            <Datepicker
                class="form-control"
                id="birthday"
                :disabled="registryPage || patientIsSelected"
                :format="birthdayInputFormat"
                locale="ru"
                :max-date="new Date()"
                :enable-time-picker="false"
                prevent-min-max-navigation
                :space-confirm="true"
                v-model="patientStore.birthAtDatepicker"
                :class="{'is-invalid': v$.birthday.$error}"
                text-input
                :text-input-options="birthdayInputOptions"
            />
            <div class='invalid-tooltip' v-if='v$.birthday.$error'>
              {{v$.birthday.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Статус: маломобильный     -->
        <div class="row my-2" v-if="registryPage">
          <div class="col-10 py-2 border d-flex align-items-center">
            <label for="limited_mobility" class="form-check-label w-100">
              Статус: маломобильный
            </label>
          </div>
          <div class="col-2 py-2 border d-flex align-items-center">
            <input
                type="checkbox"
                class="form-check-input d-block ms-auto my-1 p-2"
                id="limited_mobility"
                v-model="registryListOfEventStore.limitedMobility"
                true-value="true"
                false-value="false"
            >
          </div>
        </div>

        <!--    Телефон и кнопка Вызов     -->
        <div class="row my-2">
          <div class="col-md-3 py-2 border d-flex align-items-center">
            <label for="phone" class="form-check-label w-100">
              Телефон
            </label>
          </div>
          <div class="col-md-6 py-2 border d-flex align-items-center position-relative">
            <input
                type="text"
                class="form-control"
                id="phone"
                :disabled="registryPage || patientIsSelected"
                v-model="patientStore.phone"
                :class="{'is-invalid': v$.phone.$error}"
            >
            <div class='invalid-tooltip' v-if='v$.phone.$error'>
              {{v$.phone.$errors[0].$message}}
            </div>
          </div>
          <div class="col-md-3 py-2 border d-flex align-items-center">
            <button class="btn btn-primary btn-sm" @click.prevent="callBtnHandle" v-if="registryPage">
              <font-awesome-icon icon="fa-solid fa-phone-volume" />&nbsp;
              Звонок
            </button>
          </div>
        </div>

        <!--    Кнопка Перейти в чат     -->
        <div class="row d-flex" v-if="registryPage">
          <button class="btn btn-outline-primary btn-sm" @click.prevent="goToChatBtnHandle">
            <font-awesome-icon icon="fa-solid fa-message" />&nbsp;
            Перейти в чат
          </button>
        </div>

        <!--    История обращений:     -->
        <div class="row my-2 p-2 border list-group flex-row history flex-grow-1 position-relative" v-if="registryPage">
          <div v-if="registryListOfEventStore.registryListOfEventHistory?.length" class="position-absolute h-100 overflow-auto">
            <label class="form-check-label mb-2">
              История обращений:
            </label>
            <RouterLink
                :to="`/event/${ link.event_id }/registry-list-of-event`"
                v-for="link of registryListOfEventStore.registryListOfEventHistory"
                class="list-group-item list-group-item-action"
            >{{ link.created_at }}</RouterLink>
          </div>
          <div v-else>
            <label class="form-check-label mb-2">
              История обращений:
            </label>
            <p class="text-muted">Обращений не найдено</p>
          </div>
        </div>

      </div>

      <!--  RIGHT COLUMN   -->
      <div class="col-md-12 col-lg-6">

        <!--    Причина обращения     -->
        <div class="row my-2">
          <div class="col py-2 d-flex align-items-center position-relative">
            <select
                class="form-select"
                id="reason_id"
                aria-label="Причина обращения"
                v-model="eventStore.classifier"
                :disabled="eventExists"
                :class="{'is-invalid': v$.classifier.$error}"
            >
              <option selected disabled>Причина обращения</option>
              <option v-for="(name, classifier) of referenceStore.classifiers" :value="classifier">{{ name }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.classifier.$error'>
              {{v$.classifier.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Причина обращения текстовое поле     -->
        <div class="row my-2" v-if="registryPage">
          <div class="col py-2 d-flex align-items-center position-relative">
            <input
                type="text"
                class="form-control"
                :class="{'is-invalid': v$.classifier_comment.$error}"
                id="reason_text"
                placeholder="Ввод причины обращения вручную"
                v-model="eventStore.classifierComment"
                :disabled="!eventStore.eventClassifierIsOther"
            >
            <div class='invalid-tooltip' v-if='v$.classifier_comment.$error'>
              {{v$.classifier_comment.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Тип диабета     -->
        <div class="row my-2">
          <div class="col py-1 d-flex align-items-center position-relative">
            <select
                class="form-select"
                :class="{'is-invalid': v$.diabetesType.$error}"
                id="diabetes_type"
                aria-label="Тип диабета"
                v-model="patientStore.card.diabetes.type"
                :disabled="eventExists || patientIsSelected"
            >
              <option selected disabled>Тип диабета</option>
              <option v-for="(name, id) of referenceStore.diabetesTypes" :value="id">{{ name }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.diabetesType.$error'>
              {{v$.diabetesType.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Диагноз     -->
        <div class="row my-2">
          <div class="col py-2 d-flex align-items-center position-relative">
            <select
                class="form-select"
                :class="{'is-invalid': v$.diagnosisMkb.$error}"
                id="diagnosis"
                aria-label="Диагноз"
                v-model="patientStore.card.diagnosis.mkb"
                :disabled="eventExists || patientIsSelected"
            >
              <option selected disabled>Диагноз</option>
              <option v-for="mkb of referenceStore.mkbFilteredByDiabetesType" :value="mkb.id">{{ mkb.name }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.diagnosisMkb.$error'>
              {{v$.diagnosisMkb.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Сахарный диабет впервые выявленный     -->
        <div class="row my-2">
          <div class="col-10 ms-md-2 py-2 border d-flex align-items-center">
            <label for="first_diagnosed_diabetes" class="form-check-label w-100">
              Сахарный диабет впервые выявленный
            </label>
          </div>
          <div class="col py-2 border d-flex align-items-center">
            <input
                type="checkbox"
                class="form-check-input d-block ms-auto my-1 p-2"
                id="first_diagnosed_diabetes"
                v-model="patientStore.card.diabetes.firstIdentified"
                :disabled="eventExists || patientIsSelected"
            >
          </div>
        </div>

        <!--    Длительность диабета     -->
        <div class="row my-2">
          <div class="col-md-6 ms-2 py-2 border d-flex align-items-center">
            <label for="diabetes_duration" class="form-check-label w-100">
              Длительность диабета
            </label>
          </div>
          <div class="col-md py-2 border d-flex align-items-center">
            <input
                type="text"
                class="form-control"
                id="diabetes_duration"
                disabled
                :value="patientStore.diabetesDuration"
                :title="patientStore.diabetesDurationTitle"
            >
          </div>
        </div>

        <!--    Инсулинопотребный     -->
        <div class="row my-2">
          <div class="col-10 ms-md-2 py-2 border d-flex align-items-center">
            <label for="insulin_requiring" class="form-check-label w-100">
              Инсулинопотребный
            </label>
          </div>
          <div class="col py-2 border d-flex align-items-center">
            <input
                type="checkbox"
                class="form-check-input d-block ms-auto my-1 p-2"
                id="insulin_requiring"
                v-model="patientStore.card.diabetes.insulinRequiring"
                :disabled="eventExists || patientIsSelected"
            >
          </div>
        </div>

        <div class="row my-2" v-if="patientStore.card.diabetes.insulinRequiring">
          <div class="col-6 ms-md-2 py-2 border d-flex align-items-center">
            <label for="insulin_method" class="form-check-label w-100">
              Метод введения инсулина
            </label>
          </div>
          <div class="col py-2 border d-flex align-items-center position-relative">
            <select
                class="form-select"
                :class="{'is-invalid': v$.insulinMethod.$error}"
                id="insulin_method"
                aria-label="Тип диабета"
                v-model="patientStore.card.diabetes.insulinMethod"
                :disabled="eventExists || patientIsSelected"
            >
              <option value="0">Шприц</option>
              <option value="1">Шприц-ручка</option>
              <option value="2">Инсулиновая помпа</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.insulinMethod.$error'>
              {{v$.insulinMethod.$errors[0].$message}}
            </div>
          </div>
        </div>


        <!--    Состояние пациента     -->
        <div class="row my-2" v-if="registryPage">
          <div class="col py-1 position-relative">
            <label for="condition">Состояние пациента</label>
            <select
                class="form-select"
                :class="{'is-invalid': v$.patientCondition.$error}"
                id="condition"
                aria-label="Состояние пациента"
                v-model="registryListOfEventStore.patientCondition"
            >
              <option selected disabled>Состояние пациента</option>
              <option v-for="condition of referenceStore.patientConditionsFormatted" :value="condition.name">{{ condition.title }}</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.patientCondition.$error'>
              {{v$.patientCondition.$errors[0].$message}}
            </div>
          </div>
        </div>

        <!--    Блоки: Запись к врачу и Телемедицина     -->
        <div class="row my-2 px-3" v-if="registryPage">
          <!--    Запись к врачу     -->
          <div class="col-md-8 col-lg py-1 my-md-1 border">
            <label for="doctor_appointment" class="form-check-label w-100">
              Запись к врачу
            </label>
            <div class="row px-2">
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="doctorAppointment"
                       id="doctor_appointment_yes"
                       autocomplete="off"
                       value="true"
                       v-model="registryListOfEventStore.doctorAppointment"
                >
                <label class="btn btn-outline-success w-100" for="doctor_appointment_yes">
                  Да
                </label>
              </div>
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="doctorAppointment"
                       id="doctor_appointment_no"
                       autocomplete="off"
                       value="false"
                       v-model="registryListOfEventStore.doctorAppointment"
                >
                <label class="btn btn-outline-danger w-100" for="doctor_appointment_no">
                  Нет
                </label>
              </div>
            </div>
          </div>

          <!--    Телемедицина     -->
          <div class="col-md-8 col-lg py-1 my-md-1 border">
            <label for="telemedicine" class="form-check-label w-100">
              Телемедицина
            </label>
            <div class="row px-2">
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="telemedicine"
                       id="telemedicine_yes"
                       autocomplete="off"
                       value="true"
                       v-model="registryListOfEventStore.telemedicine"
                >
                <label class="btn btn-outline-success w-100" for="telemedicine_yes">
                  Да
                </label>
              </div>
              <div class="col-6">
                <input type="radio"
                       class="btn-check"
                       name="telemedicine"
                       id="telemedicine_no"
                       autocomplete="off"
                       value="false"
                       v-model="registryListOfEventStore.telemedicine"
                >
                <label class="btn btn-outline-danger w-100" for="telemedicine_no">
                  Нет
                </label>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!--  SECOND ROW: врач, мед.учр., мед.учр.экстренно   -->

      <!--    Врач, оповещение     -->
      <div class="row mb-md-4" v-if="registryPage">
        <div class="col-lg-2 py-2 border d-flex align-items-center">
          <label for="doctor" class="form-check-label w-100">
            Врач
          </label>
        </div>
        <div class="col-lg-4 py-2 border d-flex align-items-center">
          <VueMultiselect
              v-model="registryListOfEventStore.doctor"
              :options="registryListOfEventStore.doctors"
              :multiple="false"
              :searchable="true"
              :internal-search="false"
              :clear-on-select="false"
              :close-on-select="true"
              :options-limit="30"
              :limit="10"
              @search-change="searchDoctor"
              placeholder="Введите ФИО доктора"
              label="fullName"
              track-by="id"
              :showNoOptions="true"
              :showNoResults="true"
              :loading="registryListOfEventStore.doctorsIsLoading"
          >
            <template #noResult>Врач не найден</template>
            <template #noOptions>Список врачей пуст</template>
          </VueMultiselect>
        </div>
        <div class="col-lg py-2 mx-1 row">
          <div class="form-check form-switch">
            <input class="form-check-input"
                   id="doctor_alert"
                   type="checkbox"
                   v-model="registryListOfEventStore.doctorAlert"
                   true-value="true"
                   false-value="false"
            >
            <label class="form-check-label" for="doctor_alert">Оповещение врача</label>
          </div>
        </div>
      </div>

      <!--    мед.учр, оповещение     -->
      <div class="row mb-md-4" v-if="registryPage">
        <div class="col-lg-2 py-2 border d-flex align-items-center">
          <label for="emergency_medical_institution" class="form-check-label w-100">
            Мед Учреждение
          </label>
        </div>

        <div class="col-lg-4 py-2 border d-flex align-items-center">
          <VueMultiselect
              v-model="registryListOfEventStore.medicalInstitution"
              :options="registryListOfEventStore.hospitals"
              :multiple="false"
              :searchable="true"
              :internal-search="false"
              :clear-on-select="false"
              :close-on-select="true"
              :options-limit="30"
              :limit="10"
              @search-change="searchHospital"
              placeholder="Введите наименование"
              label="nameShort"
              track-by="id"
              :showNoOptions="true"
              :showNoResults="true"
              :loading="registryListOfEventStore.hospitalsIsLoading"
          >
            <template #noResult>Мед Учреждение не найдено</template>
            <template #noOptions>Список мед учр. пуст</template>
          </VueMultiselect>
        </div>

        <div class="col-lg mx-1 row">
          <div class="form-check form-switch">
            <input class="form-check-input"
                   id="need_calling_an_ambulance"
                   type="checkbox"
                   v-model="registryListOfEventStore.needCallingAnAmbulance"
                   true-value="true"
                   false-value="false"
            >
            <label class="form-check-label" for="need_calling_an_ambulance">Вызов скорой помощи</label>
          </div>
        </div>

      </div>

      <!--    мед.учр.экстренно, оповещение     -->
      <div class="row mb-md-4" v-if="registryPage">
        <div class="col-lg-2 py-2 border d-flex align-items-center">
          <label for="medical_institution" class="form-check-label w-100">
            Мед Учреждение Экстренно
          </label>
        </div>

        <div class="col-lg-4 py-2 border d-flex align-items-center">
          <VueMultiselect
              v-model="registryListOfEventStore.medicalInstitutionUrgently"
              :options="registryListOfEventStore.hospitalsUrgent"
              :multiple="false"
              :searchable="true"
              :internal-search="false"
              :clear-on-select="false"
              :close-on-select="true"
              :options-limit="30"
              :limit="10"
              @search-change="searchHospitalUrgent"
              placeholder="Введите наименование"
              label="nameShort"
              track-by="id"
              :showNoOptions="true"
              :showNoResults="true"
              :loading="registryListOfEventStore.hospitalsUrgentIsLoading"
          >
            <template #noResult>Мед Учреждение Экстренно не найдено</template>
            <template #noOptions>Список экстренных мед учр.  пуст</template>
          </VueMultiselect>
        </div>

        <div class="col-lg py-2 mx-1 row">
          <div class="form-check form-switch">
            <input class="form-check-input"
                   id="calling_doctor_at_home"
                   type="checkbox"
                   v-model="registryListOfEventStore.callingDoctorAtHome"
                   true-value="true"
                   false-value="false"
            >
            <label class="form-check-label" for="calling_doctor_at_home">Вызов врача на дом</label>
          </div>
        </div>

      </div>

      <!--   Приоритет   -->
      <div class="row" v-if="eventCreatePage">
        <div class="col col-md-6">
          <div class="form-group position-relative">
            <label for="event_priority" class="mb-2">Приоритет</label>
            <select
                name="event_priority"
                class="form-select"
                id="event_priority"
                v-model="eventStore.priority"
                :class="{'is-invalid': v$.priority.$error}"
            >
              <option value="high">Высокий</option>
              <option value="medium">Средний</option>
              <option value="low">Низкий</option>
            </select>
            <div class='invalid-tooltip' v-if='v$.priority.$error'>
              {{v$.priority.$errors[0].$message}}
            </div>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="col-12 col-md-6" v-if="updateRegistryPage">
          <label class="form-check-label" for="status">Статус</label>
          <select
              class="form-select"
              id="status"
              aria-label=""
              v-model="eventStore.status"
          >
            <option selected disabled>Статус</option>
            <option value="in_work">В работе</option>
            <option value="done">Обработан</option>
            <option value="paused">Приостановлен</option>
          </select>
        </div>
      </div>

    </div>

    <div class="row">
      <div class="col-12 col-md-3 row justify-content-end mx-1">
        <label style="color: white">-</label>
        <button class="btn btn-success" @click.prevent="saveBtnHandle">
          {{ updateRegistryPage ? 'Обновить' : 'Создать' }}
        </button>
      </div>
      <div class="col-12 col-md-3 row justify-content-end mx-1" v-if="eventCreatePage">
        <label style="color: white">-</label>
        <button class="btn btn-success" @click.prevent="confirmSaveAndRedirectBtnHandle">
          Создать и перейти
        </button>
      </div>
    </div>

    <button @click.prevent="fill" style="display: none">fill</button>

    <div>
      <beautiful-chat
          :participants="chatStore.participants"
          :onMessageWasSent="chatStore.onMessageWasSent"
          :sendMessage="chatStore.sendMessageTemp"
          :messageList="chatStore.messageList"
          :newMessagesCount="chatStore.newMessagesCount"
          :isOpen="chatStore.isChatOpen"
          :close="chatStore.closeChat"
          :icons="chatStore.icons"
          :open="chatStore.openChat"
          :showEmoji="true"
          :showFile="false"
          :showEdition="false"
          :showDeletion="false"
          :deletionConfirmation="true"
          :showLauncher="true"
          :showCloseButton="true"
          :colors="chatStore.colors"
          :alwaysScrollToBottom="chatStore.alwaysScrollToBottom"
          :disableUserListToggle="false"
          :messageStyling="chatStore.messageStyling" >
        <template #header>
          {{ chatStore.participants.map(m=>m.name).join(' & ') }}
        </template>
      </beautiful-chat>
    </div>
  </form>

  <teleport to='.modals-container'>
    <template v-if='isRevealed'>
      <div
          class='modal fade show'
          id='takeEventInWorkModal'
          tabindex='-1'
          aria-labelledby='takeEventInWorkModalLabel'
          data-bs-backdrop='static'
          data-bs-keyboard='false'
          aria-hidden='true'
          style='display: block'
      >
        <div class='modal-dialog modal-dialog-centered' ref='modal'>
          <div class='modal-content'>
            <div class='modal-header'>
              <h5 class='modal-title' id='takeEventInWorkModalLabel'>
                Предупреждение
              </h5>
              <button
                  @click='cancel'
                  type='button'
                  class='btn-close
                  bg-light'
                  data-bs-dismiss='modal'
                  aria-label='Close'
              ></button>
            </div>
            <div class='modal-body'>
              При сохранении и переходе на страницу событие автоматически будет взято в работу
            </div>
            <div class='modal-footer'>
              <slot name='footer'>
                <button
                    @click='cancel'
                    type='button'
                    class='btn
                    btn-secondary'
                    data-bs-dismiss='modal'
                >Закрыть</button>
                <button
                    @click='saveAndRedirectBtnHandle'
                    type='button'
                    class='btn
                    btn-success'
                    data-bs-dismiss='modal'
                >Создать и перейти</button>
              </slot>
            </div>
          </div>
        </div>
      </div>
      <div class='modal-backdrop fade show' style="z-index: 0"></div>
    </template>
  </teleport>
</template>

<script setup>
import { computed, onMounted, onUnmounted, reactive, ref, unref, watch } from 'vue'
import { useRoute } from 'vue-router'
import VueMultiselect from 'vue-multiselect'
import Datepicker from '@vuepic/vue-datepicker'
import { useEventStore } from '@/stores/eventStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import { useDoctorStore } from '@/stores/doctorStore.js'
import { useHospitalStore } from '@/stores/hospitalStore.js'
import { useRegistryListOfEvent } from '@/stores/registryListOfEventStore.js'
import { useChatStore } from '@/stores/chatStore.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { useReferenceStore } from '@/stores/referenceStore.js'
import { useTimeoutPromise } from '@/use/useTimeoutPromise.js'
import { usePatientFormValidation } from '@/use/usePatientFormValidation.js'
import { notify } from '@kyvg/vue3-notification'
import _cloneDeep from 'lodash/cloneDeep'
import moment from 'moment/min/moment.min'
import { useBodyOverflow } from '@/use/useBodyOverflow.js'
import { useConfirmDialog } from '@vueuse/core'
import { onClickOutside, useMagicKeys } from '@vueuse/core/index'

const eventStore = useEventStore(),
    patientStore = usePatientStore(),
    doctorStore = useDoctorStore(),
    hospitalStore = useHospitalStore(),
    registryListOfEventStore = useRegistryListOfEvent(),
    dateTimeStore = useDateTimeStore(),
    referenceStore = useReferenceStore(),
    chatStore = useChatStore(),
    route = useRoute()

onMounted(async () => {
  await chatStore.getPatientsChatServer(195) // TODO hard-coded patient is
      .then(response => response?.data ?? {})
      .then(data => {
        if (data?.server) chatStore.settings.server = data.server
        if (data?.chat_id) chatStore.settings.chatId = data.chat_id
      })

  chatStore.setSettings({
    authType: 'key',
    authKey: 'iwayr9812rhdoaiwu2o3hndqo821', // todo change this hard-coded line
  })

  chatStore.initConnection()
  /*console.log(chatController)
  chatController.init({
    server: 'wss://sppvr.med-market.ru:2346', // Адрес чат сервера
    chat_id: 38, target_id: '', auth_type: 'key', auth_key: 'iwayr9812rhdoaiwu2o3hndqo821',
  });*/
})

const { delay } = useTimeoutPromise()
const { v$ } = usePatientFormValidation(route)

const birthdayInputOptions = ref({
  format: 'dd.MM.yyyy'
})

const eventExists = computed(() => Boolean(eventStore.id))
const registryPage = computed(() => route.name === 'registryListOfEventCreate')
const updateRegistryPage = computed(() => registryPage.value && registryListOfEventStore.registryListOfEventExists)
const eventCreatePage = computed(() => route.name === 'eventCreate')
const patientIsSelected = computed(() => Boolean(eventStore.selectedPatient?.id))

// const birthdayInputFormat = date => `${ date.getDate() }.${ ('0' + (date.getMonth() + 1)).slice(-2) }.${ date.getFullYear() }`
const birthdayInputFormat = date => !date || !dateTimeStore.isValidDate(date) ? null : date.toLocaleDateString('ru-RU', {
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
})

const addPatient = fullName => {
  eventStore.clear()
  patientStore.clear()
  fullName = fullName ? fullName.trim() : null
  let emptyAttrs = [
    'id',
    'lastName',
    'firstName',
    'patronymic',
    'birthday',
    'birthdayFormatted',
    'phone',
    'card',
  ]
  eventStore.selectedPatient = {
    fullName,
    fullNameWithBirthdate: fullName,
  }
  emptyAttrs.forEach(attr => eventStore.selectedPatient[attr] = null)
  eventStore.patients.push(_cloneDeep(eventStore.selectedPatient))
}

const searchPatient = async fullName => {
  if (!fullName) return false
  eventStore.patients = []
  eventStore.patientsIsLoading = true
  await delay()
  patientStore.searchByFullName(fullName)
      .then(patients => {
        if (Array.isArray(patients))
          eventStore.patients = patients.map(patient => ({
            id: patient.id,
            fullName: patient.fullname,
            fullNameWithBirthdate: patient.fullname_with_birthdate,
            lastName: patient.last_name,
            firstName: patient.first_name,
            patronymic: patient.patronymic,
            birthday: patient.birth_at,
            birthdayFormatted: patient.birth_at_formatted,
            phone: patient.phone,
            card: _cloneDeep(patient.card),
          }))
      })
      .catch(error => console.error(error))
  eventStore.patientsIsLoading = false
}

const searchDoctor = async fullName => {
  if (!fullName) return false
  delay().then(() => registryListOfEventStore.searchDoctor(fullName))
}

const searchHospital = async name => {
  if (!name) return false
  delay().then(() => registryListOfEventStore.searchHospital(name))
}

const searchHospitalUrgent = async name => {
  if (!name) return false
  delay().then(() => registryListOfEventStore.searchHospitalUrgent(name))
}

watch(() => eventStore.selectedPatient?.birthday, birthday => {
  if (birthday && dateTimeStore.isValidDate(new Date(birthday))) {
    patientStore.birthAtDatepicker = new Date(birthday)
  }
})

watch(() => patientStore.birthAtDatepicker, date => patientStore.birthday = date ? moment(date).format('YYYY-MM-DD') : null)

watch(() => patientStore.card.diabetes.type, () => patientStore.card.diagnosis.mkb = null)

watch(() => eventStore.selectedPatient, patient => {
  patientStore.load({
    id: patient.id,
    first_name: patient.firstName,
    last_name: patient.lastName,
    patronymic: patient.patronymic,
    full_name: patient.fullName,
    fullname_with_birthdate: patient.fullNameWithBirthdate,
    phone: patient.phone,
    birth_at: patient.birthday,
    birth_at_formatted: patient.birthdayFormatted,
    external_id: patient.externalId,
    hospital_id: patient.hospitalId,
  })
  patientStore.loadCard(patient.card)
  patientStore.explodeFullName()
})

watch(() => registryListOfEventStore.doctor?.id, id => registryListOfEventStore.doctorId = id ?? null)

watch(() => registryListOfEventStore.medicalInstitution?.id, id => registryListOfEventStore.medicalInstitutionId = id ?? null)

watch(() => registryListOfEventStore.medicalInstitutionUrgently?.id, id => registryListOfEventStore.medicalInstitutionUrgentlyId = id ?? null)

const callBtnHandle = () => alert('Функционал находится в разработке')

const save = async () => {
  const isFormCorrect = await v$.value.$validate()

  if (!isFormCorrect) {
    return notify({
      type: 'error',
      title: 'Ошибка валидации',
      text: v$.value.$errors[0].$message,
    })
  }

  v$.value.$reset()

   if (updateRegistryPage.value) {
     await registryListOfEventStore.update()
   } else if (registryPage.value) {
     await registryListOfEventStore.create()
   } else if (eventCreatePage.value) {
     setBodyOverflowAuto()
     await eventStore.create()
   }
}

const saveBtnHandle = () => {
  eventStore.redirectToEventAfterCreate = false
  save()
}

const saveAndRedirectBtnHandle = () => (eventStore.redirectToEventAfterCreate = true) && save()

const goToChatBtnHandle = () => alert('Функционал находится в разработке')

onUnmounted(() => {
  patientStore.clear()
})

const fill = () => {
  eventStore.classifier = 'other'
  eventStore.priority = 'high'
  eventStore.selectedPatient = {
    id: null,
    fullName: 'Бов-Вов Г Дич',
    fullNameWithBirthdate: 'Бов-Вов Г Дич',
    lastName: null,
    firstName: null,
    patronymic: null,
    birthday: '1998-01-01',
    birthdayFormatted: null,
    phone: '70001112233',
    card: {
      diabetes: JSON.stringify({
        type: 1,
        firstIdentified: true,
        insulinRequiring: true,
        insulinMethod: '0',
      }),
      diagnosis: JSON.stringify({
        mkb: 1
      })
    },
  }
  setTimeout(() => {
    patientStore.card.diabetes.firstIdentified = true
    patientStore.card.diabetes.insulinRequiring = true
  }, 0)
}

/* confirm save and redirect modal */
const modal = ref(null)
const { escape } = useMagicKeys()
const { setBodyOverflowHidden, setBodyOverflowAuto } = useBodyOverflow()
const {
  isRevealed,
  reveal,
  confirm,
  cancel,
  onReveal,
  onConfirm,
  onCancel,
} = useConfirmDialog()
watch(escape, () => cancel())
onClickOutside(modal, () => cancel())

onReveal(e => {
  setBodyOverflowHidden()
})

onCancel(() => {
  setBodyOverflowAuto()
})

const confirmSaveAndRedirectBtnHandle = async () => {
  const isFormCorrect = await v$.value.$validate()

  if (!isFormCorrect) {
    return notify({
      type: 'error',
      title: 'Ошибка валидации',
      text: v$.value.$errors[0].$message,
    })
  }

  reveal()
}

watch(chatStore.messages, messages => {
  chatStore.messageList = []
  messages.forEach(message => {
    const clientId = message.client_id.substring(message.client_id.indexOf('-')+1);
    chatStore.messageList.push({
      type: 'text',
      author: clientId == 46 ? `me` : message.name, // todo hard-coded
      data: { text: message.text }
    })
  })
})


</script>

<style>
.history {
  overflow: hidden;
  align-content: flex-start;
  display: flex;
  min-height: 200px;
}

.multiselect.is-invalid > .multiselect__tags {
  border-color: #dc3545;
  padding-right: calc(1.5em + 0.75rem);
  background-repeat: no-repeat;
  background-position: right calc(0.375em + 0.1875rem) center;
  background-size: calc(0.75em + 0.375rem) calc(0.75em + 0.375rem);
}
</style>
```

## vue-app/src/views/ArchiveView.vue
```js
<template>
  <NabTab />

  <div class="progress my-1" v-if="eventStore.loading">
    <div
        class="progress-bar progress-bar-striped progress-bar-animated"
        role="progressbar"
        aria-valuenow="100"
        aria-valuemin="0"
        aria-valuemax="100"
        style="width: 100%"
    ></div>
  </div>
  <template v-else>
    <EventLogTable :params="params" />

    <div v-if="!eventStore.events.length" class="h6 text-muted text-center my-4">
      События не найдены
    </div>

  </template>
</template>

<script setup>
import { onMounted, onUnmounted, watch } from 'vue'
import NabTab from '@/components/layouts/NavTab.vue'
import { useEventStore } from '@/stores/eventStore.js'
import EventLogTable from '@/components/EventLogTable.vue'
import { useUrlSearchParams } from '@vueuse/core'
import _cloneDeep from 'lodash/cloneDeep'

const eventStore = useEventStore()

/* URL SEARCH PARAMS */
const params = useUrlSearchParams('history')

onMounted(async () => {
  if (Object.keys(params).length === 1 && params.page === '1') await eventStore.getEventLog(params, 'archive')
})


watch([
  () => eventStore.filters.classifier,
  () => eventStore.filters.priority,
  () => eventStore.filters.type,
  () => eventStore.filters.eventInitiatorFullName,
  () => eventStore.filters.status,
  () => eventStore.filters.createdAtFrom,
  () => eventStore.filters.createdAtTo,
  () => eventStore.filters.dispatcherWhoTookToWork,
], async (filters, beforeChange) => {
  let keys = ['classifier', 'priority', 'type', 'eventInitiatorFullName', 'status', 'createdAtFrom', 'createdAtTo', 'dispatcherWhoTookToWork']
  keys.forEach((key, index) => params[key] = filters[index] === '' ? null : filters[index])
  if (eventStore.filters?.page != '1' && eventStore.needToResetPage === true) return eventStore.filters.page = '1'
  eventStore.getEventLog(Object.assign(...keys.map((key, index) => ({[key]: filters[index]}))), 'archive')
  eventStore.needToResetPage = true
})

watch(() => eventStore.filters.page, page => {
  if (params['page'] == page) return false
  params['page'] = page
  eventStore.getEventLog(params, 'archive')
})

watch(() => eventStore.filters?.type, type => eventStore.type = type)

onUnmounted(() => {
  eventStore.clear()
})

</script>
```

## vue-app/src/views/EventCreateView.vue
```js
<template>
  <div class="row">
    <div class="col col-md-6">
      <div class="form-group">
        <label for="event_type" class="mb-2">Тип события</label>
        <select
            name="event_type"
            class="form-select"
            id="event_type"
            v-model="eventStore.type"
        >
          <option value="patient">Пациент</option>
          <option value="doctor">Доктор</option>
          <option value="dispatcher">Диспетчер</option>
        </select>
      </div>
    </div>
  </div>

  <div class="registry-list-of-event-container my-4" v-if="eventStore.type">
    <FormDependOnEventType />
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useEventStore } from '@/stores/eventStore.js'
import { useDateTimeStore } from '@/stores/dateTimeStore.js'
import { usePatientStore } from '@/stores/patientStore.js'
import FormDependOnEventType from '@/components/FormDependOnEventType.vue'

const eventStore = useEventStore(),
    dateTimeStore = useDateTimeStore(),
    patientStore = usePatientStore(),
    route = useRoute()

const timestamp = computed(() => dateTimeStore.timestamp)
const eventCreatePage = computed(() => route.name === 'eventCreate')

onMounted(async () => {
  if (eventCreatePage.value) {
    eventStore.type = 'patient'
  }
})

</script>

<style scoped>

</style>
```

## vue-app/src/views/ScheduledTasksView.vue
```js
<template>
  <NabTab />

  <div class="progress my-1" v-if="eventStore.loading">
    <div
        class="progress-bar progress-bar-striped progress-bar-animated"
        role="progressbar"
        aria-valuenow="100"
        aria-valuemin="0"
        aria-valuemax="100"
        style="width: 100%"
    ></div>
  </div>
  <template v-else>
    <EventLogTable :params="params" />

    <div v-if="!eventStore.events.length" class="h6 text-muted text-center my-4">
      События не найдены
    </div>

  </template>
</template>

<script setup>
import { onMounted, onUnmounted, watch } from 'vue'
import NabTab from '@/components/layouts/NavTab.vue'
import { useEventStore } from '@/stores/eventStore.js'
import EventLogTable from '@/components/EventLogTable.vue'
import { useUrlSearchParams } from '@vueuse/core'
import _cloneDeep from 'lodash/cloneDeep'

const eventStore = useEventStore()

/* URL SEARCH PARAMS */
const params = useUrlSearchParams('history')

onMounted(async () => {
  console.log('mounted')
  // if (!params.page) params.page = '1'
  // eventStore.needToResetPage = false
  // Object.assign(eventStore.filters, params)
  //
  // if (params?.createdAtFrom) eventStore.createdAtFilter[0] = new Date(params.createdAtFrom)
  // if (params?.createdAtTo) eventStore.createdAtFilter[1] = new Date(params.createdAtTo)
  console.log(Object.keys(params))
  if (Object.keys(params).length === 1 && params.page === '1') await eventStore.getEventLog(params, 'scheduled-tasks')
})


watch([
  () => eventStore.filters.classifier,
  () => eventStore.filters.priority,
  () => eventStore.filters.type,
  () => eventStore.filters.eventInitiatorFullName,
  () => eventStore.filters.status,
  () => eventStore.filters.createdAtFrom,
  () => eventStore.filters.createdAtTo,
  () => eventStore.filters.dispatcherWhoTookToWork,
], async (filters, beforeChange) => {
  let keys = ['classifier', 'priority', 'type', 'eventInitiatorFullName', 'status', 'createdAtFrom', 'createdAtTo', 'dispatcherWhoTookToWork']
  keys.forEach((key, index) => params[key] = filters[index] === '' ? null : filters[index])
  if (eventStore.filters?.page != '1' && eventStore.needToResetPage === true) return eventStore.filters.page = '1'
  eventStore.getEventLog(Object.assign(...keys.map((key, index) => ({[key]: filters[index]}))), 'scheduled-tasks')
  eventStore.needToResetPage = true
})

watch(() => eventStore.filters.page, page => {
  if (params['page'] == page) return false
  params['page'] = page
  eventStore.getEventLog(params, 'scheduled-tasks')
})

watch(() => eventStore.filters?.type, type => eventStore.type = type)

onUnmounted(() => {
  eventStore.clear()
})

</script>
```

## vue-app/src/views/LoginView.vue
```js
<template>
  <form
      @submit.prevent='login'
      class='login-form col-md-8 col-lg-6 col-xl-4 mx-auto need-validation'
      novalidate
  >

    <div class='mb-3 position-relative'>
      <label for='inputLogin' class='form-label'>Логин</label>
        <input
            v-model='authStore.credentials.login'
            type='text'
            id='inputLogin'
            class='form-control'
            :class="{'is-invalid': v$.login.$error}"
            aria-describedby='loginHelp'
        >
        <div class='invalid-tooltip' v-if='v$.login.$error'>
          {{v$.login.$errors[0].$message}}
        </div>
    </div>

    <div class='mb-3 position-relative'>
      <label for='inputPassword' class='form-label'>Пароль</label>
      <input
          v-model='authStore.credentials.password'
          type='password'
          id='inputPassword'
          class='form-control'
          :class="{'is-invalid': v$.password.$error}"
          placeholder='******'
      >
      <div class='invalid-tooltip' v-if='v$.password.$error'>
        {{v$.password.$errors[0].$message}}
      </div>
    </div>

    <button type='submit' class='btn btn-primary d-block ms-auto' :disabled="authStore.loading">Войти</button>

  </form>

  <teleport to='.modals-container'>
    <template v-if='isRevealed'>
      <div
          class='modal fade show'
          id='exampleModal'
          tabindex='-1'
          aria-labelledby='exampleModalLabel'
          data-bs-backdrop='static'
          data-bs-keyboard='false'
          aria-hidden='true'
          style='display: block'
      >
        <div class='modal-dialog modal-dialog-centered' ref='modal'>
          <div class='modal-content'>
            <div class='modal-header bg-danger'>
              <h5 class='modal-title text-light' id='exampleModalLabel'>
                Ошибка
              </h5>
              <button
                  @click='cancel'
                  type='button'
                  class='btn-close
                  bg-light'
                  data-bs-dismiss='modal'
                  aria-label='Close'
              ></button>
            </div>
            <div class='modal-body'>
              <pre class='error-message' v-html='authStore.errorMessage'></pre>
            </div>
            <div class='modal-footer'>
              <slot name='footer'>
                <button
                    @click='cancel'
                    type='button'
                    class='btn
                    btn-secondary'
                    data-bs-dismiss='modal'
                >Закрыть</button>

                <CopyErrMsgToClipboardBtn :errorMessage='authStore.errorMessage' v-if='authStore.showCopyToClipboardBtn'/>
              </slot>
            </div>
          </div>
        </div>
      </div>
      <div class='modal-backdrop fade show' style="z-index: 0"></div>
    </template>
  </teleport>

</template>

<script setup>
import { useAuthStore } from '@/stores/authStore'
import { reactive, ref, computed, watch } from 'vue'
import { useVuelidate } from '@vuelidate/core'
import { helpers, required, minLength } from '@vuelidate/validators'
import { useConfirmDialog, useMagicKeys } from '@vueuse/core'
import CopyErrMsgToClipboardBtn from '@/components/modals/CopyErrMsgToClipboardBtn.vue'
import { useBodyOverflow } from '@/use/useBodyOverflow.js'
import { onClickOutside } from "@vueuse/core/index"

const authStore = useAuthStore()
const modal = ref(null)

const {
  isRevealed,
  reveal,
  confirm,
  cancel,
  onReveal,
  onCancel,
} = useConfirmDialog()

const { escape } = useMagicKeys()
const { setBodyOverflowHidden, setBodyOverflowAuto } = useBodyOverflow()

watch(escape, () => cancel())

const requiredLoginLength = ref(4),
    requiredPasswordLength = ref(4)

const rules = computed(() => {
  return {
    login: {
      required: helpers.withMessage('Пожалуйста, заполните поле Логин', required),
      minLength: helpers.withMessage(
          ({
             $pending,
             $invalid,
             $params,
             $model
           }) => `Минимальная длина поля Логин: ${$params.min}`,
          minLength(requiredLoginLength.value)
      ),
    },
    password: {
      required: helpers.withMessage('Пожалуйста, заполните поле Пароль', required),
      minLength: helpers.withMessage(
          ({
             $pending,
             $invalid,
             $params,
             $model
           }) => `Минимальная длина поля Пароль: ${$params.min}`,
          minLength(requiredPasswordLength.value)
      ),
    }
  }
})

const v$ = useVuelidate(rules, authStore.credentials)

const login = async () => {
  try {
    try {
      await _login()
    } catch (e) {
      if (e.name !== 'SyntaxError') throw e
      authStore.showError(e.message)
    }
  } catch (unknownError) {
    authStore.showError(`Произошла непредвиденная ошибка:<br>
Name: ${ unknownError.name }<br>
Message: ${ unknownError.message }<br>
Stack: ${ unknownError.stack }<br>
`, true)
  }
}

const _login = async () => {
  authStore.showCopyToClipboardBtn = false
  const isFormCorrect = await v$.value.$validate()
  if (!isFormCorrect)
    throw new SyntaxError(v$.value.$errors[0].$message)

  await authStore.login()
}

watch(() => authStore.modalIsShow, value => {
  if (value) reveal(true)
})

onReveal(() => {
  setBodyOverflowHidden()
})

onCancel(() => {
  authStore.modalIsShow = false
  setBodyOverflowAuto()
})

onClickOutside(modal, () => cancel())

</script>

<style scoped>
.error-message {
  white-space: normal;
  overflow: hidden;
}
</style>
```

## vue-app/src/views/RegistryListOfEventView.vue
```js
<template>
  <div class="content">
    <h5>Учетный лист события</h5>

    <FormDependOnEventType />
  </div>
</template>

<script setup>
import FormDependOnEventType from '@/components/FormDependOnEventType.vue'
</script>
```

## vue-app/src/views/HomeView.vue
```js
<template>
  <NabTab />

  <div class="progress my-1" v-if="eventStore.loading">
    <div
        class="progress-bar progress-bar-striped progress-bar-animated"
        role="progressbar"
        aria-valuenow="100"
        aria-valuemin="0"
        aria-valuemax="100"
        style="width: 100%"
    ></div>
  </div>
  <template v-else>
    <EventLogTable :params="params" />

    <div v-if="!eventStore.events.length" class="h6 text-muted text-center my-4">
      Событий с приоритетом <b>Высокий</b> не найдено
    </div>

  </template>
</template>

<script setup>
import { onMounted, onUnmounted, watch } from 'vue'
import NabTab from '@/components/layouts/NavTab.vue'
import { useEventStore } from '@/stores/eventStore.js'
import EventLogTable from '@/components/EventLogTable.vue'
import { useUrlSearchParams } from '@vueuse/core'
import _cloneDeep from 'lodash/cloneDeep'

const eventStore = useEventStore()

/* URL SEARCH PARAMS */
const params = useUrlSearchParams('history')

onMounted(async () => {
  if (Object.keys(params).length === 1 && params.page === '1') await eventStore.getEventLog({}, 'home')
})


watch([
  () => eventStore.filters.classifier,
  () => eventStore.filters.type,
  () => eventStore.filters.eventInitiatorFullName,
  () => eventStore.filters.status,
  () => eventStore.filters.createdAtFrom,
  () => eventStore.filters.createdAtTo,
  () => eventStore.filters.dispatcherWhoTookToWork,
], async (filters, beforeChange) => {
  let keys = ['classifier', 'type', 'eventInitiatorFullName', 'status', 'createdAtFrom', 'createdAtTo', 'dispatcherWhoTookToWork']
  keys.forEach((key, index) => params[key] = filters[index] === '' ? null : filters[index])
  if (eventStore.filters?.page != '1' && eventStore.needToResetPage === true) return eventStore.filters.page = '1'
  eventStore.getEventLog(Object.assign(...keys.map((key, index) => ({[key]: filters[index]}))), 'home')
  eventStore.needToResetPage = true
})

watch(() => eventStore.filters.page, page => {
  if (params['page'] == page) return false
  params['page'] = page
  eventStore.getEventLog(params, 'home')
})

watch(() => eventStore.filters?.type, type => eventStore.type = type)

onUnmounted(() => {
  eventStore.clear()
})

</script>
```

## vue-app/src/views/NotFoundView.vue
```js
<template>
  <h1 class="text-center my-4">Страница не найдена</h1>
</template>

<script setup>

</script>

<style scoped>

</style>
```

## vue-app/src/router/index.js
```js
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/authStore.js'
import NotFoundView from '@/views/NotFoundView.vue'
import HomeView from '@/views/HomeView.vue'
import LoginView from '@/views/LoginView.vue'
import ScheduledTasksView from '@/views/ScheduledTasksView.vue'
import ArchiveView from '@/views/ArchiveView.vue'
import RegistryListOfEventView from '@/views/RegistryListOfEventView.vue'
import EventCreateView from '@/views/EventCreateView.vue'


const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
      meta: {
        requiresAuth: true
      },
    },
    {
      path: '/scheduled-tasks',
      name: 'scheduledTasks',
      component: ScheduledTasksView,
      meta: {
        requiresAuth: true
      },
    },
    {
      path: '/archive',
      name: 'archive',
      component: ArchiveView,
      meta: {
        requiresAuth: true
      },
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      alias: ['/signin', '/sign-in']
    },
    // {
    //   path: '/registry-list-of-event',
    //   redirect: { name: 'home' },
    //   component: RegistryListOfEventView,
    //   meta: { requiresAuth: true },
    //   children: [
    //     {
    //       path: 'create',
    //       name: 'registryListOfEventCreate',
    //     },
    //     {
    //       path: ':id(\\d+)',
    //       name: 'registryListOfEventUpdate',
    //     }
    //   ],
    // },
    // Отдельный route для create и для update
    {
      path: '/event/:id(\\d+)/registry-list-of-event',
      name: 'registryListOfEventCreate',
      component: RegistryListOfEventView,
      meta: { requiresAuth: true },
    },
    {
      path: '/event/create',
      name: 'eventCreate',
      component: EventCreateView,
      meta: { requiresAuth: true },
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'NotFound',
      component: NotFoundView,
    },
  ]
})


router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (authStore.isAuthenticated && ['login'].includes(to.name)) {
    next({ name: 'home' })
  }

  // noinspection JSUnresolvedVariable
  if (to.matched.some(record => record.meta.requiresAuth)) {
    if (!authStore.isAuthenticated) {
      next({
        path: '/login',
        // save the location we were at to come back later
        query: { redirect: to.fullPath },
      })
    } else {
      next()
    }
  } else {
    next()
  }
})


export default router

```

