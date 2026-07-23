
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var Doc, Sequence, TableString;
	
	For Each Doc In Metadata.Documents Do
		If Doc.Posting = Metadata.ObjectProperties.Posting.Allow 
				And AccessRight("InteractivePosting", Doc) Then
			DocumentsList.Add(Doc.Name, Doc.Presentation());
		EndIf;	
	EndDo;
	DocumentsList.SortByPresentation();
	For Each Sequence in Metadata.Sequences Do
		if Not AccessRight("Update", Sequence) Then
			Continue;
		EndIf;
		TableString = SequenceList.Add();
		TableString.MetaName = Sequence.Name;
		TableString.Picture = PictureLib.DocumentJournal;
		TableString.Name = Sequence.Presentation();
	EndDo;
	SequenceList.Sort("Name Asc");
	UpdateSequenceListAtServer();
	Items.RestoreSequence.Enabled = ?(SequenceList.Count() = 0, False, True);
	
	MetaPath = FormAttributeToValue("Object").Metadata().FullName();
	FlagRepost = True;
	FlagUnpost = True;
	DatePeriodVariant.Variant = StandardPeriodVariant.Month;
	PeriodPresentation = MakePeriodPresentation(DatePeriodVariant.StartDate, DatePeriodVariant.EndDate);
	
	If DocumentsList.Count() = 0 Then
		Items.DoPost.Enabled = False;
		Items.AddAll.Enabled = False;
		Items.AddSelected.Enabled = False;
		Items.RemoveAll.Enabled = False;
		Items.RemoveSelected.Enabled = False;
	EndIf;
	if AccessRight("DataAdministration", Metadata) AND DocumentsList.Count() = 0 Then
		Items.SaveParameters.Enabled = False;
		Items.LoadParameters.Enabled = False;
	EndIf;
	Items.DoPost.DefaultButton = True;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Var SelectedList, DeletedItems, SelectedDoc, Item, Period;
	
	SelectedList = Settings.Get("SelectedDocumentsList");
	If SelectedList <> Undefined Then
		DeletedItems = New Array;
		For Each SelectedDoc in SelectedList Do
			If DocumentsList.FindByValue(SelectedDoc.Value) = Undefined Then
				DeletedItems.Add(SelectedDoc);
			EndIf;
		EndDo;
		For Each Item in DeletedItems Do
			SelectedList.Delete(Item);
		EndDo;
	EndIf;
	Period = Settings.Get("DatePeriodVariant");
	PeriodPresentation = MakePeriodPresentation(Period.StartDate, Period.EndDate);
	Items.DoPost.Enabled = FlagRepost OR FlagUnpost;
	
EndProcedure

&AtServer
Procedure RemoveFromSelection()
	
	Var Index;
	
	For Each Index in Items.SelectedDocumentsList.SelectedRows Do
		SelectedDocumentsList.Delete(SelectedDocumentsList.FindById(Index));
	EndDo;
	
EndProcedure

&AtServer
Procedure AddToSelection()
	
	Var Index, DocItem;
	
	For Each Index in Items.DocumentsList.SelectedRows Do
		DocItem = DocumentsList.FindById(Index);
		If SelectedDocumentsList.FindByValue(DocItem.Value) = Undefined Then
			SelectedDocumentsList.Add(DocItem.Value, DocItem.Presentation);
		EndIf;
	EndDo;
	SelectedDocumentsList.SortByPresentation();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Var Msg, Index;
	
	If DocumentsList.Count() = 0 Then
		Msg = New UserMessage;
		Msg.Field = "DocumentsList";
		Msg.Text = NStr("ru='Для проведения недоступен ни один вид документов или в системе нет документов с возможностью проведения';sys='Processing.Error.DocTypesNotAccessed'", "ru");
		Msg.Message();
		Cancel = True;
	EndIf;
	
	If NOT FlagRepost AND NOT FlagUnpost Then
		Msg = New UserMessage;
		Msg.Field = "DoPost";
		Msg.Text = NStr("ru='Не выбран режим проведения документов';sys='Processing.Error.PostModeNotSelected'", "ru");
		Msg.Message();
		Cancel = True;
	EndIf;
	
	Index = CheckedAttributes.Find("SelectedDocumentsList");
	If Index <> Undefined Then
		CheckedAttributes.Delete(Index);
		If SelectedDocumentsList.Count() = 0 Then
			Msg = New UserMessage;
			Msg.Field = "SelectedDocumentsList";
			Msg.Text = NStr("ru='Для проведения не выбран ни один вид документов';sys='Processing.Error.DocTypesNotSelected'", "ru");
			Msg.Message();
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateSequenceListAtServer()
	
	Var TableString;
	
	For Each TableString in SequenceList Do
		TableString.ActualData = String(Sequences[TableString.MetaName].GetBound());
	EndDo;
	
EndProcedure // UpdateSequenceListAtServer()

&AtServerNoContext
Function RestoreSequenceAtServer(SeqName, ErrAddr)
	
	Var Manager, Ok, ErrString, ErrInfo, Msg;
	
	Manager = Sequences[SeqName];
	Ok = True;
	Try
		ErrString = NStr("ru='Ошибка восстановления последовательности!';sys='Processing.Error.SequenceRestore'", "ru");
		Manager.Restore();
	Except
		ErrInfo = ErrorInfo();
		Msg = New UserMessage;
		Msg.Field = ErrAddr;
		Msg.Text = ErrString + Chars.LF + ErrInfo.Description;
		Msg.Message();
		Ok = False;
	EndTry;
	Return Ok;
	
EndFunction // RestoreSequenceAtServer()

&AtServerNoContext
Function MakeResultQueryWithMove(Query, TempCount)
	
	Var Union, QueryTemplate, ConstTableLimit, QueryText, SubQuery, IntoTemplate, BlockCount;
	Var Counter, Count, DownLimit, UpperLimit;
	
	Union = "UNION ALL";
	QueryTemplate = "
	                |SELECT
	                |	Doc.Ref,
	                |	Doc.PointInTime
	                |FROM
					|	TEMP%TEMPNUMBER% AS Doc
	                |";
	
	// if temporary tables more than 255 - do special action:
	// convert every 255 tables into another and after this make union query
	ConstTableLimit = 255;
	If TempCount < ConstTableLimit Then
		QueryText = "";
		// simple union query
		For Counter = 1 To TempCount Do
			SubQuery = StrReplace(QueryTemplate, "%TEMPNUMBER%", Format(Counter, "ЧГ=0"));
			QueryText = QueryText + ?(StrLen(QueryText) = 0, "", Chars.LF + Union + Chars.LF) + SubQuery;
		EndDo;
	Else
		QueryTemplate = "
		                |SELECT
		                |	Doc.Ref,
		                |	Doc.PointInTime
						|%INTO%
		                |FROM
						|	TEMP%TEMPNUMBER% AS Doc
		                |";
		IntoTemplate = "INTO TEMP256_%NEWNUMBER%";
		BlockCount = Int(TempCount / ConstTableLimit);
		For Counter = 1 To BlockCount + 1 Do
			QueryText = "";			
			DownLimit = (Counter - 1) * ConstTableLimit + 1;
			UpperLimit =  (Counter - 1) * ConstTableLimit + ConstTableLimit;
			UpperLimit = ?(UpperLimit > TempCount, TempCount, UpperLimit);
			For Count = DownLimit To UpperLimit Do
				SubQuery = StrReplace(QueryTemplate, "%INTO%", ?(Count = DownLimit, IntoTemplate, ""));
				SubQuery = StrReplace(SubQuery, "%TEMPNUMBER%", Format(Count, "ЧГ=0"));
				SubQuery = StrReplace(SubQuery, "%NEWNUMBER%", Format(Counter, "ЧГ=0"));
				QueryText = QueryText + ?(StrLen(QueryText) = 0, "", Chars.LF + Union + Chars.LF) + SubQuery;
			EndDo;
			Query.Text = QueryText;
			Query.Execute();
		EndDo;
		// generate result query
		QueryTemplate = "
		                |SELECT
		                |	Doc.Ref,
		                |	Doc.PointInTime
		                |FROM
						|	TEMP256_%TEMPNUMBER% AS Doc
		                |";
		QueryText = "";
		For Counter = 1 To BlockCount + 1 Do
			SubQuery = StrReplace(QueryTemplate, "%TEMPNUMBER%", Format(Counter, "ЧГ=0"));
			QueryText = QueryText + ?(StrLen(QueryText) = 0, "", Chars.LF + Union + Chars.LF) + SubQuery;
		EndDo;
	EndIf;
	Return QueryText;
	
EndFunction

&AtServerNoContext
Function FindBorderDocAtServer(DocList, Direction, PostMode, MinBorderDate, MaxBorderDate)
	
	Var Condition, Result, SortDirect, ConditionType, DateConditionID, PostedType;
	Var QueryTemplate, TempMngr, Query, PostConditionID, ConditionTemplate;
	Var TempCounter, Doc, QueryText, QueryResult, SelectionDetailRecords;
	
	Condition = New Structure("Posted,Unposted,All", 1, 2, 0);
	Result = New Structure("Doc, Date", Undefined, Date('00010101'));
	SortDirect = New Structure("Min, Max", "ASC", "DESC");
	
	ConditionType = New Array;
	ConditionType.Add("");
	ConditionType.Add(Chars.LF + " Doc.Date BETWEEN &MinBorderDate AND &MaxBorderDate");
	ConditionType.Add(Chars.LF + " Doc.Date >= &MinBorderDate");
	ConditionType.Add(Chars.LF + " Doc.Date <= &MaxBorderDate");
	DateConditionID = 0;
	If ValueIsFilled(MinBorderDate) AND ValueIsFilled(MaxBorderDate) Then
		DateConditionID = 1;
	ElsIf ValueIsFilled(MinBorderDate) AND Not ValueIsFilled(MaxBorderDate) Then
		DateConditionID = 2;
	ElsIf Not ValueIsFilled(MinBorderDate) AND ValueIsFilled(MaxBorderDate) Then
		DateConditionID = 3;
	EndIf;
	
	PostedType = New Array;
	PostedType.Add("");
	PostedType.Add(Chars.LF + "%AND% Doc.Posted = TRUE");
	PostedType.Add(Chars.LF + "%AND% Doc.Posted = FALSE");
	PostConditionID = Condition[PostMode];
	
	// Prepare all temp table
	// if Direction = "Min": find minimum documents
	// if Direction = "Max": find maximum documents
	QueryTemplate = "
	                |SELECT ALLOWED TOP 1
	                |	Doc.Ref,
	                |	Doc.PointInTime
					|INTO TEMP%TEMPNUMBER%
	                |FROM
					|	Document.%TABLE% AS Doc
	                |%CONDITION%
					|ORDER BY PointInTime %DIRECTION%
	                |";
	TempMngr = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempMngr;
	Query.SetParameter("MinBorderDate", MinBorderDate);
	Query.SetParameter("MaxBorderDate", MaxBorderDate);
	
	QueryTemplate = StrReplace(QueryTemplate, "%DIRECTION%", SortDirect[Direction]);
	If DateConditionID = 0 AND PostConditionID = 0 Then
		QueryTemplate = StrReplace(QueryTemplate, "%CONDITION%", "");
	Else
		ConditionTemplate = "WHERE";
		ConditionTemplate = ConditionTemplate + ConditionType[DateConditionID];
		ConditionTemplate = ConditionTemplate + StrReplace(PostedType[PostConditionID], "%AND%", ?(DateConditionID = 0, "", "AND"));
		QueryTemplate = StrReplace(QueryTemplate, "%CONDITION%", ConditionTemplate);
	EndIf;
	
	TempCounter = 0;
	For Each Doc in DocList Do
		TempCounter = TempCounter + 1;
		QueryText = StrReplace(QueryTemplate, "%TABLE%", Doc.Value);
		QueryText = StrReplace(QueryText, "%TEMPNUMBER%", Format(TempCounter, "ЧГ=0"));
		Query.Text = QueryText;
		Query.Execute();
	EndDo;
	
	// Calculate desired time moment
	QueryText = MakeResultQueryWithMove(Query, TempCounter);
	QueryText = "SELECT TOP 1 Docs.Ref, Docs.PointInTime FROM ( " + QueryText + ") AS Docs ORDER BY PointInTime " + SortDirect[Direction];
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Choose();
	While SelectionDetailRecords.Next() Do
		Result.Doc = SelectionDetailRecords.Ref;
		Result.Date = SelectionDetailRecords.Ref.Date;
	EndDo;
	Return Result;

EndFunction

&AtServerNoContext
Function PrepareErrorListAtServer(FormUUID, DontPostedDocsListAddr)
	
	Var DontPosted;
	
	// clear temporary storage (if have), and create new value list from temporary storage to save
	// unposted documents and error description
	If Not IsBlankString(DontPostedDocsListAddr) Then
		If IsTempStorageURL(DontPostedDocsListAddr) Then
			DeleteFromTempStorage(DontPostedDocsListAddr);
		Else
			DontPostedDocsListAddr = "";
		EndIf;
	EndIf;
	DontPosted = New ValueTable;
	DontPosted.Columns.Add("Doc");
	DontPosted.Columns.Add("Error");
	DontPostedDocsListAddr = PutToTempStorage(DontPosted, FormUUID);
	Return DontPostedDocsListAddr;

EndFunction

&AtServerNoContext
Function DoPortionPostAtServer(DocList, PostMode, BorderDate, BreakAfterError, DontPostedAddr)
	
	Var Condition, Result, TempMngr, Query, PostedTemplate, SortTemplate, Union;
	Var TempCounter, Doc, QueryText, QueryResult, DontPosted, SelectionDetailRecords;
	Var DocObject, Messages, Error, Row;
	
	Condition = New Structure("Posted,Unposted,All", True, False, Undefined);
	Result = New Structure("HaveError, Total, Posted, Unposted", False, 0, 0, 0);
	
	// make posting list with temporary table (because MS SQL Server have 256 tables in query restriction)
	TempMngr = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempMngr;
	Query.SetParameter("Posted", Condition[PostMode]);
	Query.SetParameter("BeginDate", BegOfDay(BorderDate));
	Query.SetParameter("EndDate", EndOfDay(BorderDate));
	
	PostedTemplate = Chars.LF + "AND Doc.Posted = &Posted";
	SortTemplate = Chars.LF + "ORDER BY Docs.PointInTime";
	Union = "UNION ALL";
	QueryTemplate = "
					|SELECT ALLOWED
	                |	Doc.Ref,
	                |	Doc.PointInTime
					|INTO TEMP%TempNumber%
	                |FROM
	                |	Document.%Table% AS Doc
	                |WHERE
	                |	Doc.Date BETWEEN &BeginDate AND &EndDate
	                |	AND Doc.DeletionMark = FALSE";

	TempCounter = 0;
	For Each Doc in DocList Do
		TempCounter = TempCounter + 1;
		QueryText = StrReplace(QueryTemplate, "%Table%", Doc.Value);
		QueryText = StrReplace(QueryText, "%TempNumber%", Format(TempCounter, "ЧГ=0"));
		QueryText = QueryText + ?(PostMode <> "All", PostedTemplate, "");
		Query.Text = QueryText;
		Query.Execute();
	EndDo;
	
	// result documents list
	QueryText = MakeResultQueryWithMove(Query, TempCounter);
	Query.Text = "SELECT Docs.Ref, Docs.PointInTime FROM ( " + QueryText + ") AS Docs" + SortTemplate;
	QueryResult = Query.Execute();
	TempMngr.Close();

	DontPosted = GetFromTempStorage(DontPostedAddr);
	SelectionDetailRecords = QueryResult.Choose();
	While SelectionDetailRecords.Next() Do
		Try
			Result.Total = Result.Total + 1;
			DocObject = SelectionDetailRecords.Ref.GetObject();
			DocObject.Write(DocumentWriteMode.Posting);
			Result.Posted = Result.Posted + 1;
		Except
			Result.HaveError = True;
			Result.Unposted = Result.Unposted + 1;
			Messages = GetUserMessages(True);
			If Messages.Count() <> 0 Then
				For Each Error in Messages Do
					Row = DontPosted.Add();
					Row.Doc = SelectionDetailRecords.Ref;
					Row.Error = Error.Text;
				EndDo;
			Else
				Row = DontPosted.Add();
				Row.Doc = SelectionDetailRecords.Ref;
				Row.Error = NStr("ru='Ошибка проведения документа';sys='Processing.Error.UnmessagesError'", "ru");
			EndIf;
			If BreakAfterError Then
				Break;
			EndIf;
		EndTry;
	EndDo;
	If Result.HaveError Then
		PutToTempStorage(DontPosted, DontPostedAddr);
	EndIf;
	Return Result;

EndFunction

&AtClientAtServerNoContext
Function MakePeriodPresentation(StartDate, EndDate)
	
	Var Result;
	
	Result = "";
	If Not (ValueIsFilled(StartDate) OR ValueIsFilled(EndDate)) Then
		Result = NStr("ru='Без ограничения периода';sys='WithoutPeriodLimitation'", "ru");
	Else
		Result = PeriodPresentation(StartDate, EndDate);
	EndIf;
	Return "( " + Result + " )";
	
EndFunction

&AtClient
Procedure UpdateSequence()

	UpdateSequenceListAtServer();
	
EndProcedure

&AtClient
Procedure SetSequence()
	
	Var Result, Selected, BarStep, Counter, SelectRow;
	
	If SequenceList.Count() = 0 Then
		//DoMessageBox(NStr("ru='Не выбрана ни одна последовательность';sys='Processing.Error.SequenceNotSelected'", "ru"));
		ShowMessageBox( , NStr("ru='Не выбрана ни одна последовательность';sys='Processing.Error.SequenceNotSelected'", "ru"));
		Return;
	EndIf;
	Result = True;
	ClearMessages();
	Selected = Items.SequenceList.SelectedRows;
	BarStep = 100/Selected.Count();
	
	For Counter=1 To Selected.Count() Do
		SelectRow = SequenceList[Selected[Counter-1]];
		Status(NStr("ru='Восстановление последовательностей';sys='Processing.RestoreSequences'", "ru"), Counter*BarStep, SelectRow.Name);
		Result = RestoreSequenceAtServer(SelectRow.MetaName, "SequenceList[" + Selected[Counter-1] + "].Name");
		UserInterruptProcessing();
		If Not Result AND BreakAfterSeqError Then
			Break;
		EndIf;
	EndDo;
	UpdateSequenceListAtServer();
	Status(NStr("ru='Восстановление последовательностей завершено';sys='Processing.RestoreSequencesEnd'", "ru"));
	
EndProcedure

&AtClient
Procedure SetSequenceAll(Command)
	
	Var Result, BarStep, SelectRow, Counter;
	
	Result = True;
	ClearMessages();
	If SequenceList.Count() = 0 Then
		//DoMessageBox(NStr("ru='Отсутствуют последовательности для восстановления';sys='Processing.Error.NoSequence'", "ru"));
		ShowMessageBox(, NStr("ru='Отсутствуют последовательности для восстановления';sys='Processing.Error.NoSequence'", "ru"));
		Return;
	EndIf;
	BarStep = 100/SequenceList.Count();
	For Each SelectRow In SequenceList Do
		Counter = SequenceList.IndexOf(SelectRow);
		Status(Nstr("ru='Восстановление последовательностей ...';sys='Processing.RestoreSequencesText'", "ru"), Counter*BarStep, SelectRow.Name);
		Result = RestoreSequenceAtServer(SelectRow.MetaName, "SequenceList[" + Format(Counter, "NG=0") + "].Name");
		UserInterruptProcessing();
		If Not Result AND BreakAfterSeqError Then
			Break;
		EndIf;
	EndDo;
	UpdateSequenceListAtServer();
	Status(Nstr("ru='Восстановление последовательностей завершено';sys='Processing.RestoreSequencesEnd'", "ru"));
	
EndProcedure

&AtClient
Procedure DoPost()

	Var Totals, MinDoc, MaxDoc, DontPostedDocsListAddr, Success, BarStep, i;
	Var CurrentDate, DescriptionText, Description, Result, SelectedDocument;
	Var TitleOk, TitleErr, Processed, Posted, UnPosted, Params;
	
	If FlagRepost AND FlagUnpost Then
		PostMode = "All";
	ElsIf FlagRepost AND NOT FlagUnpost Then
		PostMode = "Posted";
	ElsIf NOT FlagRepost AND FlagUnpost Then
		PostMode = "Unposted";
	EndIf;
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	if SelectedDocumentsList.Count() > 65535 Then
		ShowMessageBox(, NStr("ru='Не поддерживается более 65535 видов документов.';sys='Processing.TooManyDocumentsKind'", "ru"));
		Return;
	EndIf;
		
	Totals = New Structure("Total, Posted, Unposted", 0, 0, 0);
	Status(NStr("ru = 'Выполняется определение первого проводимого документа...'; sys= 'Processing.DetectFirstDoc'", "ru"), , , PictureLib.Post);
	MinDoc = FindBorderDocAtServer(SelectedDocumentsList, "Min", PostMode, DatePeriodVariant.StartDate, DatePeriodVariant.EndDate);
	Status(NStr("ru = 'Выполняется определение последнего проводимого документа...'; sys= 'Processing.DetectLastDoc'", "ru"), , , PictureLib.Post);
	MaxDoc = FindBorderDocAtServer(SelectedDocumentsList, "Max", PostMode, DatePeriodVariant.StartDate, DatePeriodVariant.EndDate);
	DontPostedDocsListAddr = PrepareErrorListAtServer(UUID, DontPostedDocsListAddr);
	Success = True;
	StatusTitle = NStr("ru='Выполняется проведение документов ([1] - [2])';sys='Processing.ProceedDocsPeriod'", "ru");
	StatusTitle = StrReplace(StatusTitle, "[1]", Format(MinDoc.Date, "DLF=D"));
	StatusTitle = StrReplace(StatusTitle, "[2]", Format(MaxDoc.Date, "DLF=D"));
	
	// © Primus1C  07.05.2026  НАЧАЛО ►  
	омСервер.УстановитьПараметрСеанса("ГрупповоеПерепроведениеДокументов", Истина);
	// © Primus1C  ОКОНЧАНИЕ ◄
	
	BarStep = 100/Max((MaxDoc.Date - MinDoc.Date) / 86400, 1);
	i=0;
	CurrentDate = BegOfDay(MinDoc.Date);
	DescriptionText = NStr("ru='Проводятся документы за [1]. Всего: [2]';sys='Processing.PostingText'", "ru");
	Description = StrReplace(DescriptionText, "[1]", Format(CurrentDate, "DLF=D"));
	Description = StrReplace(Description, "[2]", 0);
	While CurrentDate <= BegOfDay(MaxDoc.Date) Do
		Status(StatusTitle, i*BarStep, Description, PictureLib.Post);
		UserInterruptProcessing();
		Result = DoPortionPostAtServer(SelectedDocumentsList, PostMode, CurrentDate, BreakAfterError, DontPostedDocsListAddr);
		Totals.Total = Totals.Total + Result.Total;
		Totals.Posted = Totals.Posted + Result.Posted;
		Totals.Unposted = Totals.Unposted + Result.Unposted;
		
		CurrentDate = CurrentDate + 86400;
		i = i + 1;
		
		Description = StrReplace(DescriptionText, "[1]", Format(CurrentDate, "DLF=D"));
		Description = StrReplace(Description, "[2]", Totals.Total);
		Success= ?(Not Result.HaveError, Success, False);
		If BreakAfterError AND Not Success Then
			Break;
		EndIf;
	EndDo;
	
	// © Primus1C  07.05.2026  НАЧАЛО ►
	омСервер.УстановитьПараметрСеанса("ГрупповоеПерепроведениеДокументов", Ложь);
	// © Primus1C  ОКОНЧАНИЕ ◄
	
	Status(StatusTitle, 100, Description, PictureLib.Post);
	For Each SelectedDocument in SelectedDocumentsList Do
		NotifyChanged(Type("DocumentRef."+SelectedDocument.Value));
	EndDo;
	TitleOk = NStr("ru='Проведение выполнено';sys='Processing.PostingComplete'", "ru");
	TitleErr = NStr("ru='Во время проведения обнаружены ошибки';sys='Processing.ErrorFound'", "ru");
	Processed = StrReplace(NStr("ru='Всего обработано документов: [1]';sys='Processing.ProceedDocs'", "ru"), "[1]", Totals.Total);
	Posted = StrReplace(NStr("ru='Проведено документов: [1]';sys='Processing.PostedText'", "ru"), "[1]", Totals.Posted);
	UnPosted = StrReplace(NStr("ru='Не проведено документов: [1]';sys='Processing.Error.ErrorPosted'", "ru"), "[1]", Totals.Unposted);
	If Success Then
		Status(TitleOk, , Processed + Chars.LF + Posted, PictureLib.Post);
		//DoMessageBox(Processed + Chars.LF + Posted, , TitleOk);
		ShowMessageBox(, Processed + Chars.LF + Posted, , TitleOk);
	Else
		Status(TitleErr, , Processed + Chars.LF + Posted + Chars.LF + UnPosted, PictureLib.Stop);
		Params = New Structure;
		Params.Insert("StorageAddr", DontPostedDocsListAddr);
		Params.Insert("DocTotal", Totals.Total);
		Params.Insert("DocPosted", Totals.Posted);
		Params.Insert("DocUnposted", Totals.Unposted);
		OpenForm(MetaPath+".Form.DontPosted", Params);
	EndIf;
	UpdateSequenceListAtServer();
	
EndProcedure

&AtClient
Procedure DocumentsListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	AddToSelection();
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectedDocumentsListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	RemoveFromSelection();
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AddSelected(Command)
	
	AddToSelection();
	
EndProcedure

&AtClient
Procedure RemoveSelected(Command)
	
	RemoveFromSelection();
	
EndProcedure

&AtClient
Procedure AddAll(Command)
	
	Var Item;
	
	SelectedDocumentsList.Clear();
	For Each Item in DocumentsList Do
		SelectedDocumentsList.Add(Item.Value, Item.Presentation);
	EndDo;
	SelectedDocumentsList.SortByPresentation();
	
EndProcedure

&AtClient
Procedure RemoveAll(Command)

	SelectedDocumentsList.Clear();
	
EndProcedure

&AtClient
Procedure DatePeriodVariantOnChange(Item)
	
	PeriodPresentation = MakePeriodPresentation(DatePeriodVariant.StartDate, DatePeriodVariant.EndDate);
	
EndProcedure

&AtClient
Procedure SelectedDocumentsListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ModesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.Posting Then
		Items.DoPost.DefaultButton = True;
	ElsIf CurrentPage = Items.RestoreSequence Then
		Items.SequenceListDoRestore.DefaultButton = True;
	Else
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsListDragStart(Item, DragParameters, Perform)
	
	Var Data, INdex;
	
	DragParameters.Action = DragAction.Copy;
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	Data = New ValueList;
	For Each Index In Items.DocumentsList.SelectedRows Do
		Item = DocumentsList.FindById(Index);
		Data.Add(Item.Value, Item.Presentation);
	EndDo;
	DragParameters.Value = Data;
	
EndProcedure

&AtClient
Procedure DocumentsListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If TypeOf(DragParameters.Value) <> Type("Array") Then
		DragParameters.Action = DragAction.Cancel;
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
		StandardProcessing = False;
	Else
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsListDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	Var Result;
	
	StandardProcessing = False;
	For Each ValueItem In DragParameters.Value Do
		Result = SelectedDocumentsList.FindByValue(ValueItem);
		If Result <> Undefined Then
			SelectedDocumentsList.Delete(Result);
		EndIf;
	EndDo;
	//SelectedDocumentsList.SortByPresentation(SortDirection.Asc);
	ThisForm.CurrentItem = Items.SelectedDocumentsList;
	
EndProcedure

&AtClient
Procedure SelectedDocumentsListDragStart(Item, DragParameters, Perform)

	Var Index, Data;
	
	DragParameters.Action = DragAction.Move;
	DragParameters.AllowedActions = DragAllowedActions.Move;
	Data = New Array;
	For Each Index In Items.SelectedDocumentsList.SelectedRows Do
		Item = SelectedDocumentsList.FindById(Index);
		Data.Add(Item.Value);
	EndDo;
	DragParameters.Value = Data;
	
EndProcedure

&AtClient
Procedure SelectedDocumentsListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If TypeOf(DragParameters.Value) <> Type("ValueList") Then
		DragParameters.Action = DragAction.Cancel;
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
		StandardProcessing = False;
	Else
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedDocumentsListDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	Var ValueItem;
	
	StandardProcessing = False;
	For Each ValueItem In DragParameters.Value Do
		Result = SelectedDocumentsList.FindByValue(ValueItem.Value);
		If Result = Undefined Then
			Data = SelectedDocumentsList.Add();
			Data.Value = ValueItem.Value;
			Data.Presentation = ValueItem.Presentation;
		EndIf;
	EndDo;
	SelectedDocumentsList.SortByPresentation(SortDirection.Asc);
	Items.SelectedDocumentsList.CurrentRow = SelectedDocumentsList[0].GetID();
	ThisForm.CurrentItem = Items.DocumentsList;
	
EndProcedure

&AtClient
Procedure PeriodEdit(Command)
	
	Editor = New StandardPeriodEditDialog;
	Editor.Period = DatePeriodVariant;
	Callback = New NotifyDescription("PeriodEditCallback", ThisForm);
	Editor.Show(Callback);
	
EndProcedure

&AtClient
Procedure PeriodEditCallback(Result, ExtraParameters) Export
	
	If Result <> Undefined Then
		DatePeriodVariant = Result;
		PeriodPresentation = MakePeriodPresentation(DatePeriodVariant.StartDate, DatePeriodVariant.EndDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure PostModeChanged(Item)
	
	Items.DoPost.Enabled = FlagRepost OR FlagUnpost;
	
EndProcedure
