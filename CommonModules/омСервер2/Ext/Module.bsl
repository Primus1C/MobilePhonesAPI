
Процедура ПроверитьНастройку() Экспорт
	//ИНИ = "";
	//Получить(, ИНИ);
	//Шифр = Зашифровать(ИНИ);


	//КлючБессрочный = Зашифровать(Шифр);
	//КлючСегодняшний = Зашифровать(Шифр, гоТекущаяДата());
	//КлючНедельный = Зашифровать(Шифр, НачалоНедели(гоТекущаяДата()), Истина);
	//КлючВчерашний = Зашифровать(Шифр, гоДобавитьДень(гоТекущаяДата(), - 1));


	//КлючМой = "193177480736257403691287722694423636";

	//Есть = СокрЛП(Константы.Настройка.Получить());

 

	//Если Есть = КлючБессрочный Или Есть = КлючСегодняшний Или Есть = КлючВчерашний Или Есть = КлючНедельный Или КлючМой = КлючБессрочный Или Есть = КлючМой Тогда



		ПараметрыСеанса.Настройка = "ОК";



	//	Если КлючМой = КлючБессрочный Тогда
	//		Фир = гоФирма().ПолучитьОбъект();
	//		Фир.КаталогИзображений = "D:\LOGO\base_images\";
	//		Попытка
	//			Фир.Записать();
	//		Исключение
	//			Сообщить(ОписаниеОшибки());
	//		КонецПопытки;
	//	КонецЕсли;
	//Иначе
	//	Если гоПользовательКод() = "Регистрация" Тогда
	//		ПараметрыСеанса.Настройка = Шифр;
	//	Иначе
	//		ВызватьИсключение "Не найдена лицензия!";
	//	КонецЕсли;
	//КонецЕсли;
КонецПроцедуры









Функция Зашифровать(Стр, ДобавитьДату = 0, Недельный = Ложь)
	Рез = "";

	Ключ = ?(ДобавитьДату = 0, "", Лев(гоМгновение(ДобавитьДату), 8)) + "875530346492065483020092538020746823";
	Для Н = 1 По СтрДлина(Стр) Цикл
		Попытка
			Сим = Число(Сред(Стр, Н, 1));
		Исключение
			Сим = 0;
		КонецПопытки;
		Попытка
			Клю = Число(Сред(Ключ, Н, 1));
		Исключение
			Клю = 0;
		КонецПопытки;

		Нов = Сим + Клю;
		Если Нов > 9 Тогда Нов = Нов - 10; КонецЕсли;

		Рез = Строка(Нов) + Рез;
	КонецЦикла;
	Возврат Рез;
КонецФункции


Функция ПолучитьЗначениеВПопытке(хОбъект, хРеквизит)
	Попытка
		Возврат хОбъект[хРеквизит];
	Исключение
		Возврат Неопределено;
	КонецПопытки;

	Возврат Неопределено;

КонецФункции


Функция ПреобразоватьЗначениеВДатуВремя(Знач Значение)
	Попытка
		Возврат Дата(Лев(Значение, 14));
	Исключение
		Возврат Дата("00010101");
	КонецПопытки;

	Возврат Дата("00010101");

КонецФункции




Процедура Получить(Computer = ".", ИНИ = "") Экспорт
	Перем WinMGMT, Win32_PhysicalDisk, PhysicalDiskInfo;
	ИНИ = "";

	Win32_PhysicalDiskInfo = Новый ТаблицаЗначений;
	Win32_PhysicalDiskInfo.Колонки.Добавить("Availability");
	Win32_PhysicalDiskInfo.Колонки.Добавить("BytesPerSector");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Capabilities");
	Win32_PhysicalDiskInfo.Колонки.Добавить("CapabilityDescriptions");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Caption");
	Win32_PhysicalDiskInfo.Колонки.Добавить("CompressionMethod");
	Win32_PhysicalDiskInfo.Колонки.Добавить("ConfigManagerErrorCode");
	Win32_PhysicalDiskInfo.Колонки.Добавить("ConfigManagerUserConfig");
	Win32_PhysicalDiskInfo.Колонки.Добавить("CreationClassName");
	Win32_PhysicalDiskInfo.Колонки.Добавить("DefaultBlockSize");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Description");
	Win32_PhysicalDiskInfo.Колонки.Добавить("DeviceID");
	Win32_PhysicalDiskInfo.Колонки.Добавить("ErrorCleared");
	Win32_PhysicalDiskInfo.Колонки.Добавить("ErrorDescription");
	Win32_PhysicalDiskInfo.Колонки.Добавить("ErrorMethodology");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Index");
	Win32_PhysicalDiskInfo.Колонки.Добавить("InstallDate");
	Win32_PhysicalDiskInfo.Колонки.Добавить("InterfaceType");
	Win32_PhysicalDiskInfo.Колонки.Добавить("LastErrorCode");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Manufacturer");
	Win32_PhysicalDiskInfo.Колонки.Добавить("MaxBlockSize");
	Win32_PhysicalDiskInfo.Колонки.Добавить("MaxMediaSize");
	Win32_PhysicalDiskInfo.Колонки.Добавить("MediaLoaded");
	Win32_PhysicalDiskInfo.Колонки.Добавить("MediaType");
	Win32_PhysicalDiskInfo.Колонки.Добавить("MinBlockSize");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Model");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Name");
	Win32_PhysicalDiskInfo.Колонки.Добавить("NeedsCleaning");
	Win32_PhysicalDiskInfo.Колонки.Добавить("NumberOfMediaSupported");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Partitions");
	Win32_PhysicalDiskInfo.Колонки.Добавить("PNPDeviceID");
	Win32_PhysicalDiskInfo.Колонки.Добавить("PowerManagementCapabilities");
	Win32_PhysicalDiskInfo.Колонки.Добавить("PowerManagementSupported");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SCSIBus");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SCSILogicalUnit");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SCSIPort");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SCSITargetId");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SectorsPerTrack");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Signature");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Size");
	Win32_PhysicalDiskInfo.Колонки.Добавить("Status");
	Win32_PhysicalDiskInfo.Колонки.Добавить("StatusInfo");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SystemCreationClassName");
	Win32_PhysicalDiskInfo.Колонки.Добавить("SystemName");
	Win32_PhysicalDiskInfo.Колонки.Добавить("TotalCylinders");
	Win32_PhysicalDiskInfo.Колонки.Добавить("TotalHeads");
	Win32_PhysicalDiskInfo.Колонки.Добавить("TotalSectors");
	Win32_PhysicalDiskInfo.Колонки.Добавить("TotalTracks");
	Win32_PhysicalDiskInfo.Колонки.Добавить("TracksPerCylinder");

	Попытка
		WinMGMT = ПолучитьCOMОбъект("winmgmts:\\" + Computer + "\root\cimv2");
		Win32_PhysicalDisk = WinMGMT.ExecQuery("SELECT * FROM Win32_DiskDrive");
	Исключение
		Возврат;
	КонецПопытки;

	Для каждого PhysicalDisk Из Win32_PhysicalDisk Цикл
		PhysicalDiskInfo = Win32_PhysicalDiskInfo.Добавить();
		PhysicalDiskInfo.Availability = ПолучитьЗначениеВПопытке(PhysicalDisk, "Availability");
		PhysicalDiskInfo.BytesPerSector = ПолучитьЗначениеВПопытке(PhysicalDisk, "BytesPerSector");
		PhysicalDiskInfo.Capabilities = ПолучитьЗначениеВПопытке(PhysicalDisk, "Capabilities");
		PhysicalDiskInfo.CapabilityDescriptions = ПолучитьЗначениеВПопытке(PhysicalDisk, "CapabilityDescriptions");
		PhysicalDiskInfo.Caption = ПолучитьЗначениеВПопытке(PhysicalDisk, "Caption");
		PhysicalDiskInfo.CompressionMethod = ПолучитьЗначениеВПопытке(PhysicalDisk, "CompressionMethod");
		PhysicalDiskInfo.ConfigManagerErrorCode = ПолучитьЗначениеВПопытке(PhysicalDisk, "ConfigManagerErrorCode");
		PhysicalDiskInfo.ConfigManagerUserConfig = ПолучитьЗначениеВПопытке(PhysicalDisk, "ConfigManagerUserConfig");
		PhysicalDiskInfo.CreationClassName = ПолучитьЗначениеВПопытке(PhysicalDisk, "CreationClassName");
		PhysicalDiskInfo.DefaultBlockSize = ПолучитьЗначениеВПопытке(PhysicalDisk, "DefaultBlockSize");
		PhysicalDiskInfo.Description = ПолучитьЗначениеВПопытке(PhysicalDisk, "Description");
		PhysicalDiskInfo.DeviceID = ПолучитьЗначениеВПопытке(PhysicalDisk, "DeviceID");
		PhysicalDiskInfo.ErrorCleared = ПолучитьЗначениеВПопытке(PhysicalDisk, "ErrorCleared");
		PhysicalDiskInfo.ErrorDescription = ПолучитьЗначениеВПопытке(PhysicalDisk, "ErrorDescription");
		PhysicalDiskInfo.ErrorMethodology = ПолучитьЗначениеВПопытке(PhysicalDisk, "ErrorMethodology");
		PhysicalDiskInfo.Index = Строка(ПолучитьЗначениеВПопытке(PhysicalDisk, "Index"));
		PhysicalDiskInfo.InstallDate = ПреобразоватьЗначениеВДатуВремя(ПолучитьЗначениеВПопытке(PhysicalDisk, "InstallDate"));
		PhysicalDiskInfo.InterfaceType = ПолучитьЗначениеВПопытке(PhysicalDisk, "InterfaceType");
		PhysicalDiskInfo.LastErrorCode = ПолучитьЗначениеВПопытке(PhysicalDisk, "LastErrorCode");
		PhysicalDiskInfo.Manufacturer = ПолучитьЗначениеВПопытке(PhysicalDisk, "Manufacturer");
		PhysicalDiskInfo.MaxBlockSize = ПолучитьЗначениеВПопытке(PhysicalDisk, "MaxBlockSize");
		PhysicalDiskInfo.MaxMediaSize = ПолучитьЗначениеВПопытке(PhysicalDisk, "MaxMediaSize");
		PhysicalDiskInfo.MediaLoaded = ПолучитьЗначениеВПопытке(PhysicalDisk, "MediaLoaded");
		PhysicalDiskInfo.MediaType = ПолучитьЗначениеВПопытке(PhysicalDisk, "MediaType");
		PhysicalDiskInfo.MinBlockSize = ПолучитьЗначениеВПопытке(PhysicalDisk, "MinBlockSize");
		PhysicalDiskInfo.Model = ПолучитьЗначениеВПопытке(PhysicalDisk, "Model");
		PhysicalDiskInfo.Name = ПолучитьЗначениеВПопытке(PhysicalDisk, "Name");
		PhysicalDiskInfo.NeedsCleaning = ПолучитьЗначениеВПопытке(PhysicalDisk, "NeedsCleaning");
		PhysicalDiskInfo.NumberOfMediaSupported = ПолучитьЗначениеВПопытке(PhysicalDisk, "NumberOfMediaSupported");
		PhysicalDiskInfo.Partitions = ПолучитьЗначениеВПопытке(PhysicalDisk, "Partitions");
		PhysicalDiskInfo.PNPDeviceID = ПолучитьЗначениеВПопытке(PhysicalDisk, "PNPDeviceID");
		PhysicalDiskInfo.PowerManagementCapabilities = ПолучитьЗначениеВПопытке(PhysicalDisk, "PowerManagementCapabilities");
		PhysicalDiskInfo.PowerManagementSupported = ПолучитьЗначениеВПопытке(PhysicalDisk, "PowerManagementSupported");
		PhysicalDiskInfo.SCSIBus = ПолучитьЗначениеВПопытке(PhysicalDisk, "SCSIBus");
		PhysicalDiskInfo.SCSILogicalUnit = ПолучитьЗначениеВПопытке(PhysicalDisk, "SCSILogicalUnit");
		PhysicalDiskInfo.SCSIPort = ПолучитьЗначениеВПопытке(PhysicalDisk, "SCSIPort");
		PhysicalDiskInfo.SCSITargetId = ПолучитьЗначениеВПопытке(PhysicalDisk, "SCSITargetId");
		PhysicalDiskInfo.SectorsPerTrack = ПолучитьЗначениеВПопытке(PhysicalDisk, "SectorsPerTrack");
		PhysicalDiskInfo.Signature = ПолучитьЗначениеВПопытке(PhysicalDisk, "Signature");
		PhysicalDiskInfo.Size = ПолучитьЗначениеВПопытке(PhysicalDisk, "Size");
		PhysicalDiskInfo.Status = ПолучитьЗначениеВПопытке(PhysicalDisk, "Status");
		PhysicalDiskInfo.StatusInfo = ПолучитьЗначениеВПопытке(PhysicalDisk, "StatusInfo");
		PhysicalDiskInfo.SystemCreationClassName = ПолучитьЗначениеВПопытке(PhysicalDisk, "SystemCreationClassName");
		PhysicalDiskInfo.SystemName = ПолучитьЗначениеВПопытке(PhysicalDisk, "SystemName");
		PhysicalDiskInfo.TotalCylinders = ПолучитьЗначениеВПопытке(PhysicalDisk, "TotalCylinders");
		PhysicalDiskInfo.TotalHeads = ПолучитьЗначениеВПопытке(PhysicalDisk, "TotalHeads");
		PhysicalDiskInfo.TotalSectors = ПолучитьЗначениеВПопытке(PhysicalDisk, "TotalSectors");
		PhysicalDiskInfo.TotalTracks = ПолучитьЗначениеВПопытке(PhysicalDisk, "TotalTracks");
		PhysicalDiskInfo.TracksPerCylinder = ПолучитьЗначениеВПопытке(PhysicalDisk, "TracksPerCylinder");
	КонецЦикла;

	Если Win32_PhysicalDiskInfo.Количество() > 0 Тогда
		Стр = Win32_PhysicalDiskInfo[0];
		ИНИ = гоЛП(Стр.TotalCylinders, 12) + гоЛП(Стр.TotalSectors, 12) + гоЛП(Стр.TotalTracks, 12);
	КонецЕсли;


КонецПроцедуры

Процедура ПередНачалоРаботыСистемыНаСервере(Отказ = Ложь) Экспорт
	//Перем Идентификатор;
	//Идентификатор = Константы.Идентификатор.Получить();
	//ТекДата = НачалоДня(ТекущаяДата());

	//Если Идентификатор <> ТекДата Тогда
	//	Отказ = Истина;
	//КонецЕсли;

КонецПроцедуры


Процедура РассчитатьИдентификатор() Экспорт
	ТекДата = НачалоДня(ТекущаяДата());
	Идентификатор = Константы.Идентификатор.Получить();

	Если Идентификатор <> ТекДата Тогда
		РазницаВДнях = (ТекДата - Идентификатор) / (60 * 60 * 24);
		Если РазницаВДнях = 1 Тогда
			Константы.Идентификатор.Установить(ТекДата);
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры




