///////////////////////////////////////////////////////////////
// Events processing

&AtServer
Procedure OnCreateAtServer(Cancel, StantardProcessing)
	
	Var Text;
	
	Items.DeleteMode.ChoiceList.Clear();
	Text = NStr("ru = 'Полное удаление%1Удаление всех помеченных объектов'; sys = 'RemoveObjects.Mode.Full'", "ru");
	Text = StrReplace(Text, "%1", Chars.LF); 
	Items.DeleteMode.ChoiceList.Add("Full", Text);
	Text = NStr("ru = 'Выборочное удаление%1Позволяет предварительно выбрать объекты%1для удаления из списка помеченных'; sys = 'RemoveObjects.Mode.Selected'", "ru");
	Text = StrReplace(Text, "%1", Chars.LF); 
	Items.DeleteMode.ChoiceList.Add("Selected", Text);
	
	DeleteMode = "Full";
	
EndProcedure

&AtServer
Function FindOrCreateTreeNode(TreeRows, Value, Presentation, Mark, CanDelete, CanOpen, Picture)
	
	Var Node;
	
	// Try to find existing node in TreeRows without childs
	Node = TreeRows.Find(Value, "Value", False);
	If Node = Undefined Then
		
		// Such node not exists, let`s create new
		Node = TreeRows.Add();
		Node.Value			= Value;
		Node.Presentation	= Presentation;
		Node.CanDelete		= CanDelete;
		Node.CanOpen		= CanOpen;
		Node.Mark			= ?(CanDelete, Mark, False);
		Node.Picture		= Picture;
		
	EndIf;

	Return Node;
	
EndFunction

&AtServer
Function FindOrCreateTreeNodeWithPicture(TreeRows, Value, Presentation, Picture, CanOpen)
	
	Var Node;
	
	// Try to find existing node in TreeRows without childs
	Node = TreeRows.Find(Value, "Value", False);
	If Node = Undefined Then
		
		// Such node not exists, let`s create new
		Node = TreeRows.Add();
		Node.Value      = Value;
		Node.Presentation = Presentation;
		Node.Picture = Picture;
		Node.CanOpen = CanOpen;
		
	EndIf;

	Return Node;
	
EndFunction

&AtServer
Procedure FillTreeOfMarked()
	
	Var TreeOfMarked, ArrayOfMarked, TitleString, ArrayOfMarkedItem;
	Var MetadataObject, MetadataObjectPresentation, CanDelete;
	Var Picture, MetadataObjectRow;
	
	// fill tree of marked
	TreeOfMarked = FormAttributeToValue("ListOfMarked");
	TreeOfMarked.Rows.Clear();
	// marked processing
	ArrayOfMarked = FindMarkedForDeletion();
	TitleString = NStr("ru = 'Объекты, помеченные на удаление (всего объектов: %1)';sys = ''", "ru");
	Items.ListOfMarked.Title = StrReplace(TitleString, "%1", ArrayOfMarked.Count());
	
	For Each ArrayOfMarkedItem In ArrayOfMarked Do
		
		MetadataObject = ArrayOfMarkedItem.Metadata();
		MetadataObjectPresentation = MetadataObject.Presentation();
		CanDelete = AccessRight("InteractiveDeleteMarked", MetadataObject);
		If Not CanDelete Then
		
			Continue;
			
		EndIf;
		
		Picture = GetPictureFromMetadata(MetadataObject);
		MetadataObjectRow = FindOrCreateTreeNode(TreeOfMarked.Rows, String(MetadataObject), MetadataObjectPresentation, True, CanDelete, 0, Picture);
		FindOrCreateTreeNode(MetadataObjectRow.Rows, ArrayOfMarkedItem, GetDataPresentation(MetadataObject, ArrayOfMarkedItem) + " (" + MetadataObjectPresentation + ")", True, CanDelete, IsObjectCanOpen(MetadataObject), Picture);
		
	EndDo;
	
	TreeOfMarked.Rows.Sort("Value", True);
	For Each MetadataObjectRow In TreeOfMarked.Rows Do
		
		// create presentation for rows of metadata object
		MetadataObjectRow.Presentation = MetadataObjectRow.Presentation + " (" + MetadataObjectRow.Rows.Count() + ")";
		
	EndDo;
	
	ValueToFormAttribute(TreeOfMarked, "ListOfMarked");
	
EndProcedure

&AtServer
Function DoRemoveAtServer()
	
	Var ToRemove, RemovedList, Types, Tree, RemoveObject, MetadaRowsCollection, MetadataObjectRow;
	Var ReferenceRowsCollection, ReferenceRow, ObjectType, NowActivePage, FindedItems, NeedExclusiveMode;
	Var UnremovedTypes, FindedItem, UnremovedItem, UnremovedMetadata, UnremovedMetadataPresentation,UnremovedObjectPresentation;
	Var ReferencedItem, ReferenceMetadata, ReferencedMetadataPresentation, ReferenceObjectPresentation;
	Var UnremovedBDObjectReferenceRow, RemovedTypes, UnremovedObjectsCount, RemovedObjectsCount;
	
	// List of marked objects
	ToRemove = New Array;
	// List of deleted objects
	RemovedList = New Array;
	// List of types of removal
	Types = New Array;
	
	If DeleteMode = "Full" Then
		// Let's get whole marked list
		ToRemove = FindMarkedForDeletion();
		For Each RemoveObject in ToRemove Do
			If AccessRight("InteractiveDeleteMarked", RemoveObject.Metadata()) Then
				RemovedList.Add(RemoveObject);
			EndIf;
		EndDo;
	Else
		// Fill an array by references to selected marked items
		MetadataRowsCollection = ListOfMarked.GetItems();
		For Each MetadataObjectRow In MetadataRowsCollection Do
			ReferenceRowsCollection = MetadataObjectRow.GetItems();
			For Each ReferenceRow In ReferenceRowsCollection Do
				If ReferenceRow.Mark Then
					RemovedList.Add(ReferenceRow.Value);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	
	For Each RemoveObject in RemovedList Do
		ObjectType = TypeOf(RemoveObject);
		If Types.Find(ObjectType) = Undefined Then
			Types.Add(ObjectType);
		EndIf;
	EndDo;
	
	NowActivePage = Items.FormPages.CurrentPage;
	Items.FormPages.CurrentPage = Items.RemoveResults;
	// removing doing 
	FindedItems = New ValueTable;
	Try
		NeedExclusiveMode = (Not ExclusiveMode()) AND IsExclusiveModeNeeded();
		If NeedExclusiveMode Then 
			SetExclusiveMode(True);
		EndIf;
		DeleteObjects(RemovedList, True, FindedItems);
		FindedItems.Columns.Add("Counter", New TypeDescription("Number"));
		FindedItems.FillValues(1, "Counter");
		If NeedExclusiveMode Then 
			SetExclusiveMode(False);
		EndIf;
	Except
		If NeedExclusiveMode AND ExclusiveMode() Then 
			SetExclusiveMode(False);
		EndIf;
		Items.FormPages.CurrentPage = NowActivePage;
		Raise;
		
	EndTry;
	
	// create the table of unremoved items
	UnremovedTypes = New Array;
	TreeOfUnremoved.GetItems().Clear();
	Tree = FormAttributeToValue("TreeOfUnremoved");
	For Each FindedItem In FindedItems Do
		
		// unremoved item
		UnremovedItem = FindedItem[0];
		UnremovedMetadata = UnremovedItem.Metadata();
		UnremovedMetadataPresentation = UnremovedItem.Metadata().Presentation();
		UnremovedObjectPresentation = GetDataPresentation(UnremovedItem.Metadata(), UnremovedItem);
		
		// reference item
		ReferencedItem = FindedItem[1];
		ReferenceMetadata = FindedItem[2];
		ReferencedMetadataPresentation = ReferenceMetadata.Presentation();
		ReferenceObjectPresentation = GetDataPresentation(ReferenceMetadata, ReferencedItem);
		
		//metadata node
		MetadataObjectRow = FindOrCreateTreeNodeWithPicture(Tree.Rows, String(UnremovedMetadata), UnremovedMetadataPresentation, GetPictureFromMetadata(UnremovedItem.Metadata()), 0);
		//unremoved object node
		UnremovedBDObjectReferenceRow = FindOrCreateTreeNodeWithPicture(MetadataObjectRow.Rows, UnremovedItem, UnremovedObjectPresentation, GetPictureFromMetadata(UnremovedItem.Metadata()), IsObjectCanOpen(UnremovedMetadata));
		//unremoved object reference node
		FindOrCreateTreeNodeWithPicture(UnremovedBDObjectReferenceRow.Rows, ReferencedItem, ReferenceObjectPresentation + " (" + ReferencedMetadataPresentation + ")", GetPictureFromMetadata(ReferenceMetadata), IsObjectCanOpen(ReferenceMetadata));
		
		ObjectType = TypeOf(UnremovedItem);
		If UnremovedTypes.Find(ObjectType) = Undefined Then
			UnremovedTypes.Add(ObjectType);
		EndIf;
	EndDo;
	
	Tree.Rows.Sort("Value", True);
	ValueToFormAttribute(Tree, "TreeOfUnremoved");
	
	// calculate unremoved objects
	FindedItems.GroupBy(FindedItems.Columns[0].Name, "Counter");
	UnremovedObjectsCount = FindedItems.Count();
	RemovedObjectsCount = RemovedList.Count() - UnremovedObjectsCount;
	
	// notify object list with success removing
	RemovedTypes = New Array;
	For Each RemoveType in Types Do
		If UnremovedTypes.Find(RemoveType) = Undefined Then
			RemovedTypes.Add(RemoveType);
		EndIf;
	EndDo;
	
	ResultsString = NStr("ru='Удалено объектов:';sys='Processing.RemoveObjects'", "ru") + " " + RemovedObjectsCount;
	If UnremovedObjectsCount > 0 Then
		ResultsString = ResultsString + Chars.LF;
		ResultsString = ResultsString + NStr("ru='Невозможно удалить объектов:';sys='Processing.UnremovedObjects'", "ru") + " " + UnremovedObjectsCount + NStr("ru=', т.к. в информационной базе на них ссылаются другие объекты.';sys='Processing.InfoString'", "ru") + Chars.LF;
		ResultsString = ResultsString + NStr("ru='Для просмотра списка таких объектов нажмите кнопку Далее >>';sys='Processing.UnremoveListView'", "ru");
	EndIf;
	
	Return RemovedTypes;
	
EndFunction

&AtServerNoContext
Function Is833OrHigherCompatible()
	
  Return 
    Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_3_2
		 And	Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_3_1
		 And	Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_16
		 And	Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		 And	Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1;
	
EndFunction	

&AtServerNoContext
Function GetPictureFromMetadata(MetaObject)
	
	Var PicArray;
	
	PicArray = New Array;
	PicArray.Add(New Picture); // 0
	PicArray.Add(PictureLib.Constant); // 1
	PicArray.Add(PictureLib.CatalogObject); // 2 
	PicArray.Add(PictureLib.DocumentObject); // 3
	PicArray.Add(PictureLib.AccumulationRegister); // 4
	PicArray.Add(PictureLib.AccountingRegister); // 5
	PicArray.Add(PictureLib.CalculationRegister); // 6
	PicArray.Add(PictureLib.InformationRegister); // 7
	PicArray.Add(PictureLib.BusinessProcessObject); // 8
	PicArray.Add(PictureLib.TaskObject); // 9
	PicArray.Add(PictureLib.ChartOfCharacteristicTypesObject); // 10
	PicArray.Add(PictureLib.ChartOfCalculationTypesObject); // 11
	PicArray.Add(PictureLib.ChartOfAccountsObject); // 12
	PicArray.Add(PictureLib.ExternalDataSourceTable); // 13
	PicArray.Add(PictureLib.ExternalDataSourceTable); // 14
	
	Return PicArray[GetMetaType(MetaObject)];
	
EndFunction

&AtServerNoContext
Function GetMetaType(MetaObject)
	
	Var MetaType, ExtSource;
	
	MetaType = 0;
	If Metadata.Constants.Contains(MetaObject) Then
		
		MetaType = 1;
	ElsIf Metadata.Catalogs.Contains(MetaObject) Then
		
		MetaType = 2;
	ElsIf Metadata.Documents.Contains(MetaObject) Then
		
		MetaType = 3;
	ElsIf Metadata.AccumulationRegisters.Contains(MetaObject) Then
		
		MetaType = 4;
	ElsIf Metadata.AccountingRegisters.Contains(MetaObject) Then
		
		MetaType = 5;
	ElsIf Metadata.CalculationRegisters.Contains(MetaObject) Then
		
		MetaType = 6;
	ElsIf Metadata.InformationRegisters.Contains(MetaObject) Then
		
		MetaType = 7;
	ElsIf Metadata.BusinessProcesses.Contains(MetaObject) Then
		
		MetaType = 8;
	ElsIf Metadata.Tasks.Contains(MetaObject) Then
		
		MetaType = 9;
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetaObject) Then
		
		MetaType = 10;
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetaObject) Then
		
		MetaType = 11;
	ElsIf Metadata.ChartsOfAccounts.Contains(MetaObject) Then
		
		MetaType = 12;
	Else
		For Each ExtSource In Metadata.ExternalDataSources Do
			
			If ExtSource.Tables.Contains(MetaObject) Then
				
				If MetaObject.TableDataType = Metadata.ObjectProperties.ExternalDataSourceTableDataType.ObjectData Then
					
					MetaType = 14; // object table
					
				Else
					
					MetaType = 13; // non-object table
					
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return MetaType;
	
EndFunction

&AtServerNoContext
Function GetDataPresentation(MetaObject, DataObject)
	
	Var Presentation, Dim, MetaType;
	
	MetaType = GetMetaType(MetaObject);
	Presentation = String(DataObject);
	If MetaType = 2 OR MetaType = 3 OR MetaType = 8 OR MetaType = 9 OR MetaType = 10 OR MetaType = 11 OR MetaType = 12 OR MetaType = 14 Then
		
		Presentation = String(DataObject);
		
	ElsIf MetaType = 4 OR MetaType = 5 OR MetaType = 6 OR MetaType = 7 Then
		
		Presentation = "";
		If MetaObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			
			Presentation = String(DataObject.Period);
			
		EndIf;
		
		If MetaObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
			
			Presentation = ?(StrLen(Presentation) = 0, "", Presentation  + "; ") + String(DataObject.Recorder);
			
		EndIf;
		
		For Each Dim in MetaObject.Dimensions Do
			
			Presentation = ?(StrLen(Presentation) = 0, "", Presentation + "; ") + String(DataObject[Dim.Name]);
			
		EndDo;
		
	ElsIf MetaType = 13 Then
		
		Presentation = "";
		For Each Dim in MetaObject.KeyFields Do
			
			Presentation = ?(StrLen(Presentation) = 0, "", Presentation + "; ") + String(DataObject[Dim.Name]);
			
		EndDo;
		
	EndIf;
	
	Return Presentation;
	
EndFunction

&AtServerNoContext
Function IsObjectCanOpen(MetaObject)
	
	Var CanOpen;
	
	CanOpen = New Array;
	CanOpen.Add(False); // 0
	CanOpen.Add(True); // 1
	CanOpen.Add(True); // 2 
	CanOpen.Add(True); // 3
	CanOpen.Add(False); // 4
	CanOpen.Add(False); // 5
	CanOpen.Add(False); // 6
	CanOpen.Add(True); // 7
	CanOpen.Add(True); // 8
	CanOpen.Add(True); // 9
	CanOpen.Add(True); // 10
	CanOpen.Add(True); // 11
	CanOpen.Add(True); // 12
	CanOpen.Add(True); // 13 non-object table
	CanOpen.Add(True); // 14 object table
	
	Return CanOpen[GetMetaType(MetaObject)];
	
EndFunction

// Определяет, разделитель отключен или нет с помощью условного разделения
&AtServerNoContext
Function IsConditionalSeparatedOff(Separator)
	
	Var MetadataObject, CommonAttribute, caUse;
	
	If Separator.ConditionalSeparation = Undefined Then
		// разделитель не использует условного разделения - он условно НЕ выключен
		Return False;
	EndIf;
	
	// проверим, что разделитель отключен условным разделением
	If Metadata.Constants.Contains(Separator.ConditionalSeparation) Then
		// условное разделение задано константой
		
		// константа Истина - включено разделение, возврат FALSE
		// константа Ложь - отключено разделение, возврат ИСТИНА
		Return Not Constants[Separator.ConditionalSeparation.Name].Get();
	Else
		// условное разделение может быть реквизитом ссылочного типа
		// надо получить тип объекта, чей реквизит используется, найти разделитель с таким типом и из параметра сеанса достать значение реквизита
		
		// получим родительский объект для реквизита - сам объект вида справочник, документ и т.д.
		MetadataObject = Separator.ConditionalSeparation.Parent;
		// найдем общий реквизит соответствующего типа
		For Each CommonAttribute In Metadata.CommonAttributes Do
			If CommonAttribute.Type = MetadataObject Then
				If CommonAttribute.DataSeparationUse = Undefined Then
					// у данного реквизита не используется условное разделение
					caUse = SessionParameters[CommonAttribute.DataSeparationUse.Name];
					caValue = SessionParameters[CommonAttribute.DataSeparationValue.Name];
					if caUse AND caValue.EmptyRef() Then
						// общий реквизит используется и пустая ссылка - включено разделение
						Return False;
					ElsIf Not caUse Then
						// общий реквизит не используется - отключено разделение
						Return True;
					Else
						// реквизит Истина - включено разделение, возврат FALSE
						// реквизит Ложь - выключено разделение, возврат ИСТИНА
						Return Not caValue[Separator.ConditionalSeparation.Name];
					EndIf;
				Else
					// у данного реквизита используется условное разделение
					Return IsConditionalSeparatedOff(CommonAttribute);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return True;
		
EndFunction

&AtServerNoContext
Function IsExclusiveModeNeeded()
	
	Var SetExclusiveMode, CommonAttribute;
	
	If Is833OrHigherCompatible() Then
		// если режим совместимости выше версии 8.3.2 - всегда нужен монопольный режим
		// если нет - проверяем все как раньше
		Return True;
	EndIf;
	SetExclusiveMode = True;
	SetPrivilegedMode(True);
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			If SessionParameters[CommonAttribute.DataSeparationUse.Name] AND Not IsConditionalSeparatedOff(CommonAttribute) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	Return SetExclusiveMode;
	
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	
	Items.FormPages.PagesRepresentation = FormPagesRepresentation.None;
	ButtonVisibility();
	
EndProcedure

&AtClient
Procedure SetMarkInList(Data, Mark, CheckParent)
	
	Var RowElements, Parent, ParentMark;
	
	Data.Mark = Mark;
	
	// set to childs
	RowElements = Data.GetItems();
	For Each Item In RowElements Do
		SetMarkInList(Item, Mark, False);
	EndDo;
	
	// Check parent
	Parent = Data.GetParent();
	If CheckParent And Parent <> Undefined Then 
		ParentMark = True;
		RowElements = Parent.GetItems();
		For Each Item In RowElements Do
			If Not Item.Mark Then
				ParentMark = False;
				Break;
			EndIf;
		EndDo;
		If ParentMark <> Parent.Mark Then
			Parent.Mark = ParentMark;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnDeleteModeChanged(Item)
	
	ButtonVisibility();
	
EndProcedure

&AtClient
Procedure OnMarkChanged(Item)
	
	Var CurrentData;
	
	CurrentData = Items.ListOfMarked.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentData.CanDelete Then
		CurrentData.Mark = False;
		Return;
	EndIf; 
	SetMarkInList(CurrentData, CurrentData.Mark, True);
	
EndProcedure

&AtClient
Procedure DoMarkedSetAll(Command)
	
	Var ListItems;
	
	ListItems = ListOfMarked.GetItems();
	For Each Item In ListItems Do
		SetMarkInList(Item, True, True);
	EndDo;
	
EndProcedure

&AtClient
Procedure DoMarkedClearAll(Command)
	
	Var ListItems;
	
	ListItems = ListOfMarked.GetItems();
	For Each Item In ListItems Do
		SetMarkInList(Item, False, True);
	EndDo;
	
EndProcedure

&AtClient
Procedure OnTreeOfUnremovedSelection(Item, SelectedRow, Field, StantardProcessing)
	
	Var CurrentData;
	
	CurrentData = Items.TreeOfUnremoved.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() = 0 and CurrentData.CanOpen Then
		// this is row of object due to which is impossible to delete marked and selected
		StantardProcessing = False;
		//OpenValue(CurrentData.Value);
		ShowValue(, CurrentData.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnListOfMarkedChoice(Item, SelectedRow, Field, StantardProcessing)
	
	Var CurrentData;
	
	CurrentData = Items.ListOfMarked.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	If CurrentData.GetItems().Count() = 0 and CurrentData.CanOpen Then
		// this is the row of marked object
		StantardProcessing = False;
		//OpenValue(CurrentData.Value);
		ShowValue(, CurrentData.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure DoForward()
	
	Var CurentPage;
	
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.RemoveModeChoice AND DeleteMode = "Selected" Then
		Status(NStr("ru='Выполняется поиск помеченных на удаление объектов';sys='Processing.DoFindTip'", "ru"));
		FillTreeOfMarked();
		Items.FormPages.CurrentPage = Items.Marked;
	ElsIf CurrentPage = Items.RemoveModeChoice AND DeleteMode = "Full" Then
		DoRemove();
		Items.FormPages.CurrentPage = Items.RemoveResults;
	ElsIf CurrentPage = Items.Marked Then
		DoRemove();
		Items.FormPages.CurrentPage = Items.RemoveResults;
	ElsIf CurrentPage = Items.RemoveResults Then
		If TreeOfUnremoved.GetItems().Count() <> 0 Then
			Items.FormPages.CurrentPage = Items.UnremoveReasons;
		EndIf;
	EndIf;
	ButtonVisibility();
	
EndProcedure

&AtClient
Procedure DoBack(Command)
	
	Var CurrentPage;
	
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.Marked Then
		Items.FormPages.CurrentPage = Items.RemoveModeChoice;
	EndIf;
	ButtonVisibility();
	
EndProcedure

&AtClient
Procedure ButtonVisibility()
	
	Var CurrentPage, ForwardTitle;
	
	CurrentPage = Items.FormPages.CurrentPage;
	ForwardTitle = NStr("ru='Далее >>';sys='Processing.Next'", "ru");
	If CurrentPage = Items.RemoveModeChoice Then
		Items.CommandForward.DefaultButton = True;
		Items.CommandBack.Visible = False;
		Items.CommandForward.Visible = True;
		ForwardTitle = ?(DeleteMode = "Full", NStr("ru='Удалить';sys='Processing.Remove'", "ru"), ForwardTitle);
	ElsIf CurrentPage = Items.RemoveResults Then
		If TreeOfUnremoved.GetItems().Count() = 0 Then
			Items.Close.DefaultButton = True;
			Items.CommandBack.Visible = False;
			Items.CommandForward.Visible = False;
		Else
			Items.CommandForward.DefaultButton = True;
			Items.CommandBack.Visible = False;
			Items.CommandForward.Visible = True;
		EndIf;
	ElsIf CurrentPage = Items.Marked Then
		Items.CommandForward.DefaultButton = True;
		Items.CommandBack.Visible = True;
		Items.CommandForward.Visible = True;
		ForwardTitle = NStr("ru='Удалить';sys='Processing.Remove'", "ru");
	ElsIf CurrentPage = Items.UnremoveReasons Then
		Items.Close.DefaultButton = True;
		Items.CommandBack.Visible = False;
		Items.CommandForward.Visible = False;
	EndIf;
	Items.CommandForward.Title = ForwardTitle;
	
EndProcedure

&AtClient
Procedure DoRemove()
	
	Var RemovedTypes;
	
	If DeleteMode = "Full" Then
		Status(NStr("ru='Выполняется поиск и удаление помеченных объектов';sys='Processing.DoFindRemoveTip'", "ru"));
	Else
		Status(NStr("ru='Выполняется удаление выбранных объектов';sys='Processing.RemovingProcess'", "ru"));
	EndIf;
	
	RemovedTypes = DoRemoveAtServer();
	For Each RemoveType in RemovedTypes Do
		NotifyChanged(RemoveType);
	EndDo;
	
	If TreeOfUnremoved.GetItems().Count() = 0 Then
		Status(NStr("ru='Удаление завершено успешно';sys='Processing.RemoveSuccessComplet'", "ru"));
	Else
		Status(NStr("ru='Обнаружены объекты, которые невозможно удалить';sys='Processing.FoundedUnremoveObjects'", "ru"), , , PictureLib.Stop);
	EndIf;
	
EndProcedure
