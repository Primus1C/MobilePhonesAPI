&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var IsEventLogEnable;
	
	If Not AccessRight("ActiveUsers", Metadata) Then
		Cancel = True;
		Return;
	EndIf;
	SortColumnName = "User";
	SortDirection = "Asc";
	FillUsersList();
	IsEventLogEnable = AccessRight("EventLog", Metadata);
	Items.EventsJournal.Enabled = IsEventLogEnable;
	Items.UserActivity.Enabled = IsEventLogEnable;
	Items.EventsJournal1.Enabled = IsEventLogEnable;
	Items.UserActivity1.Enabled = IsEventLogEnable;
	
	//2016.02.22
	стрМонопольныйРежим = "М О Н О П О Л Ь Н Ы Й   Р Е Ж И М";
EndProcedure

&AtClient
Procedure FillList()

	Var CurrentSession, CurrentData;
	
	CurrentSession = Undefined;
	CurrentData = Items.UsersList.CurrentData;
	If CurrentData <> Undefined Then
		CurrentSession = CurrentData.Session;
	EndIf;
	
	FillUsersList();
	If CurrentSession <> Undefined Then
		FindStructure = New Structure;
		FindStructure.Insert("Session", CurrentSession);
		SessionsFinded = UsersList.FindRows(FindStructure);
		If SessionsFinded.Count() = 1 Then
			Items.UsersList.CurrentRow = SessionsFinded[0].GetId();
			Items.UsersList.SelectedRows.Clear();
			Items.UsersList.SelectedRows.Add(Items.UsersList.CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function GetEventsJournalFormName()
	
	Var ToReturn, EventLog;
	
	ToReturn = Undefined;
	If AccessRight("EventLog", Metadata) Then
		EventLog = Undefined;
		Try
			EventLog = New("ExternalDataProcessorObject.StandardEventLog");
			
		Except
			Try
				ExternalDataProcessors.Connect("v8res://mngbase/StandardEventLog.epf", , False);
				EventLog = New("ExternalDataProcessorObject.StandardEventLog");
			Except
				Message(ErrorDescription());
			EndTry;
		EndTry;
		If EventLog <> Undefined Then
			ToReturn = "ExternalDataProcessor.StandardEventLog.Form";
		EndIf;
	EndIf;
	Return ToReturn;
	
EndFunction

&AtClient
Procedure OpenEventsJournal()
	
	Var EL_FormName;
	
	EL_FormName = GetEventsJournalFormName();
	If Not EL_FormName = Undefined Then
		EventsJournal = OpenForm(EL_FormName);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenEventsJournalByUser()
	
	Var CurrentData, UserName, EL_FormName;
	
	CurrentData = Items.UsersList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	OpenEventsJournalWithUserFilter(CurrentData.UserName);
	
EndProcedure

&AtClient
Procedure DoRefresh()
	
	FillList();
	
EndProcedure

&AtClient
Procedure SortByColumn(Direction)
	
	Var Column;
	
	Column = Items.UsersList.CurrentItem;
	If Column = Undefined Then
		
		Return;
		
	EndIf;
	
	SortColumnName = Column.Name;
	SortDirection = Direction;
	
	FillList();
	
EndProcedure

&AtClient
Procedure SortAsc()
	
	SortByColumn("Asc");
	
EndProcedure

&AtClient
Procedure Sortdesc()
	
	SortByColumn("Desc");
	
EndProcedure

&AtServer
Procedure FillUsersList()
	
	Var VT_UsersList, IBSessions, IBSession, UserRow;
	
	VT_UsersList = FormAttributeToValue("UsersList");
	VT_UsersList.Clear();
	
	IBSessions = GetInfoBaseSessions();
	If IBSessions <> Undefined Then
		For Each IBSession In IBSessions Do
			UserRow = VT_UsersList.Add();
			UserRow.Application   = ApplicationPresentation(IBSession.ApplicationName);
			UserRow.SessionStart = IBSession.SessionStarted;
			UserRow.Computer    = IBSession.ComputerName;
			UserRow.Session        = IBSession.SessionNumber;
			UserRow.Picture = PictureLib.User;
			If IBSession.User <> Undefined Then
				UserRow.User = IBSession.User.Name;
				UserRow.UserName = IBSession.User.Name;
			EndIf;
			UserRow.Current = (IBSession.SessionNumber = InfoBaseSessionNumber());
		EndDo;
	EndIf;
	ActiveUsersCount = IBSessions.Count();
	VT_UsersList.Sort(SortColumnName + " " + SortDirection);
	ValueToFormAttribute(VT_UsersList, "UsersList");
	
EndProcedure

&AtClient
Procedure UsersListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field.Name = "User" Then
		StandardProcessing = True;
		CurrentData = UsersList.FindByID(SelectedRow);
		If CurrentData = Undefined Then
			Return;
		EndIf;
		OpenEventsJournalWithUserFilter(CurrentData.UserName);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenEventsJournalWithUserFilter(UserName)
	
	EL_FormName = GetEventsJournalFormName();
	If Not EL_FormName = Undefined Then
		OpenForm(EL_FormName, New Structure("User", UserName));
	EndIf;
	
EndProcedure

&НаСервереБезКонтекста
Процедура УстановитьМонопольныйРежимСервер(Режим)
//2016.02.22	
	УстановитьМонопольныйРежим(Режим);
КонецПроцедуры 

&НаКлиенте
Процедура ВключитьМонопольныйРежим(Команда)
//2016.02.22	
	Элементы.стрМонопольныйРежим.Видимость = гоМонопольныйРежим();
	
	Если гоМонопольныйРежим() Тогда клОшибка("Уже включен!"); Возврат; КонецЕсли;
	
	Попытка
		УстановитьМонопольныйРежимСервер(Истина);
	Исключение
	    клОшибка(ОписаниеОшибки());
		
		//раз ошибка, то выключим
		Попытка
			УстановитьМонопольныйРежимСервер(Ложь);
		Исключение
			//и уже ничего не сообщим
		    Сообщить(ОписаниеОшибки());
		КонецПопытки; 
	КонецПопытки; 
	Элементы.стрМонопольныйРежим.Видимость = гоМонопольныйРежим();
КонецПроцедуры

&НаКлиенте
Процедура ВыключитьМонопольныйРежим(Команда)
//2016.02.22	
	Элементы.стрМонопольныйРежим.Видимость = гоМонопольныйРежим();
	
	Если НЕ гоМонопольныйРежим() Тогда клОшибка("Уже выключен!"); Возврат; КонецЕсли;
	
	Попытка
		УстановитьМонопольныйРежимСервер(Ложь);
	Исключение
	    клОшибка(ОписаниеОшибки());
	КонецПопытки; 
	Элементы.стрМонопольныйРежим.Видимость = гоМонопольныйРежим();
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
//2016.02.22	
	Элементы.стрМонопольныйРежим.Видимость = гоМонопольныйРежим();
КонецПроцедуры

&НаКлиенте
Процедура ЗавершитьРаботуПользователей(Команда)
	
	ЗавершитьРаботуПользователейНаСервере();
	
КонецПроцедуры

Процедура ЗавершитьРаботуПользователейНаСервере()

	Если Найти(СтрокаСоединенияИнформационнойБазы(), "Srvr") > 0 Тогда
		// серверный вариант
		Поиск1 = Найти(СтрокаСоединенияИнформационнойБазы(), "Srvr=");
		ПодстрокаПоиска = Сред(СтрокаСоединенияИнформационнойБазы(), Поиск1 + 6);
		ИмяСервера = Лев(ПодстрокаПоиска, Найти(ПодстрокаПоиска, """") - 1);
		// теперь ищем имя базы
		Поиск1 = Найти(СтрокаСоединенияИнформационнойБазы(), "Ref=");
		ПодстрокаПоиска = Сред(СтрокаСоединенияИнформационнойБазы(), Поиск1 + 5);
		ИмяБазы = Лев(ПодстрокаПоиска, Найти(ПодстрокаПоиска, """") - 1);
	Иначе
		// для других способов подключения алгоритм не актуален
		Возврат;
	КонецЕсли;
	
	Коннектор = Новый COMОбъект("v83.COMConnector");
	Агент = Коннектор.ConnectAgent(ИмяСервера);
	Кластеры = Агент.GetClusters();
	Для каждого Кластер из Кластеры Цикл
		АдминистраторКластера = "";
		ПарольКластера = "";
		Агент.Authenticate(Кластер, АдминистраторКластера, ПарольКластера);
		Процессы = Агент.GetWorkingProcesses(Кластер);
		Для каждого Процесс из Процессы Цикл
			Порт = Процесс.MainPort;
			// теперь есть адрес и порт для подключения к рабочему процессу
			РабПроц = Коннектор.ConnectWorkingProcess(ИмяСервера + ":" + СтрЗаменить(Порт, Символы.НПП, ""));
			РабПроц.AddAuthentication("Администратор", "37182");
			
			ИнформационнаяБаза = "";
			
			Базы = Агент.GetInfoBases(Кластер);
			Для каждого База из Базы Цикл
				Если База.Name = ИмяБазы Тогда
					ИнформационнаяБаза = База;
					Прервать;
				КонецЕсли;
			КонецЦикла;
			Если ИнформационнаяБаза = "" Тогда
				// база не найдена
			КонецЕсли;
			
			Сеансы = Агент.GetInfoBaseSessions(Кластер, ИнформационнаяБаза);
			Для каждого Сеанс из Сеансы Цикл
				Если нРег(Сеанс.AppID) = "backgroundjob" ИЛИ нРег(Сеанс.AppID) = "designer" Тогда
					// если это сеансы конфигуратора или фонового задания, то не отключаем
					Продолжить;
				КонецЕсли;
				Если Сеанс.UserName = ИмяПользователя() Тогда
					// это текущий пользователь
					Продолжить;
				КонецЕсли;
				Агент.TerminateSession(Кластер, Сеанс);
			КонецЦикла;
			
			//СоединенияБазы = Агент.GetInfoBaseConnections(Кластер, ИнформационнаяБаза);
			//// Разорвать соединения клиентских приложений.
			//Для Каждого Соединение Из СоединенияБазы Цикл
			//	Если нРег(Соединение.Application) = "backgroundjob" ИЛИ нРег(Соединение.Application) = "designer" Тогда
			//		// если это соединение конфигуратора или фонового задания, то не отключаем
			//		Продолжить;
			//	КонецЕсли;
			//	Если Соединение.UserName = ИмяПользователя() Тогда
			//		// это текущий пользователь
			//		Продолжить;
			//	КонецЕсли;
			//	РабПроц.Disconnect(Соединение);
			//КонецЦикла;
		КонецЦикла;
	КонецЦикла;
	
КонецПроцедуры

