
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var DontPosted, DPObject, Template, HeaderArea, DocArea, ErrArea, i, CurDoc, Doc;
	
	DontPosted = GetFromTempStorage(Parameters.StorageAddr);
	DPObject = FormAttributeToValue("Object");
	Template = DPObject.GetTemplate("UnpostedDocs");
	
	HeaderArea = Template.GetArea("Header");
	DocArea = Template.GetArea("Doc");
	ErrArea = Template.GetArea("Error");
	
	UnpostedList.Clear();
	HeaderArea.Parameters.Total = Parameters.DocTotal;
	HeaderArea.Parameters.Posted = Parameters.DocPosted;
	HeaderArea.Parameters.Unposted = Parameters.DocUnposted;
	UnpostedList.Put(HeaderArea);
	UnpostedList.StartRowAutoGrouping();

	i = 1;
	CurDoc = Undefined;
	For Each Doc in DontPosted Do
		
		If Doc.Doc <> CurDoc Then
			
			DocArea.Parameters.Count = i;
			DocArea.Parameters.Document = Doc.Doc;
			UnpostedList.Put(DocArea, 1, , True);
			
			ErrArea.Parameters.ErrorText = Doc.Error;
			UnpostedList.Put(ErrArea, 2, , False);
			
			CurDoc = Doc.Doc;
			i = i + 1;
			
		Else
			
			ErrArea.Parameters.ErrorText = Doc.Error;
			UnpostedList.Put(ErrArea, 2, , False);
			
		EndIf;
	EndDo;

	UnpostedList.EndRowAutoGrouping();

EndProcedure
