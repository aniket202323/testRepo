CREATE PROCEDURE dbo.spRS_AdminXMLToRS
@MyXML varchar(8000)
 AS
Declare @intDoc int
/*
-----------------------------------
-- Takes XML string and makes a result set
-----------------------------------
Exec spRS_AdminXMLToRS '<root><item name="FileName" value="br549"/><item name="ReportName" value="BR 549"/><item name="MasterUnit" value="10"/></root>'
Exec spRS_AdminXMLToRS '<root><item name="ParameterName" value="ParameterValue"/></root>'
*/
if @MyXML Is Not Null
Begin
 	 If LTrim(RTrim(@MyXML)) = ''
 	  	 Select @MyXML = Null
End
-- put the xml doc into memory
exec sp_xml_prepareDocument @intDoc output, @MyXML
-- Extract the xml into a local result set
Select * Into #xml From OpenXML(@intDoc, '/root/item', 0) 
With (name varchar(20) '@name', value varchar(20) '@value')
-- Remove the XML document from memory
exec sp_xml_removeDocument @intDoc
-- Return The Result Set
Select * From #xml
Drop Table #xml
