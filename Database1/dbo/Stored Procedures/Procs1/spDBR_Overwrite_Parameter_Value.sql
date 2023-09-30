Create Procedure dbo.spDBR_Overwrite_Parameter_Value
@reportid int,
@paramid int,
@value text
AS
 	 create table #Cols
 	 (
 	  	 rowid int,
 	  	 Col nvarchar(4)
 	 )
 	 create table #Rows
 	 (
 	  	 rowid int,
 	  	 Row nvarchar(4)
 	 )
 	 create table #Values
 	 (
 	  	 rowid int,
 	  	 Value nvarchar(2000)
 	 )
 	 create table #ParamValue
 	 (
 	  	 Row int,
 	  	 Col int,
 	  	 Value nvarchar(2000)
 	 )
 	 declare @hDoc int
 	 Exec sp_xml_preparedocument @hDoc OUTPUT, @value 
 	 
 	 insert into #Cols (rowid, col)
 	  	 (select (select b.parentid from OpenXML(@hDoc, N'/root/PARAMETER/ROWENTRY/COLUMN') b where b.id = a.parentid), a.text from OpenXML(@hDoc, N'/root/PARAMETER/ROWENTRY/COLUMN') a where not a.text is NULL)
 	 insert into #Rows (rowid, row)
 	  	 (select (select b.parentid from OpenXML(@hDoc, N'/root/PARAMETER/ROWENTRY/ROW') b where b.id = a.parentid), a.text from OpenXML(@hDoc, N'/root/PARAMETER/ROWENTRY/ROW') a where not a.text is NULL)
 	 insert into #Values (rowid, Value)
 	  	 (select (select b.parentid from OpenXML(@hDoc, N'/root/PARAMETER/ROWENTRY/VALUE') b where b.id = a.parentid), a.text from OpenXML(@hDoc, N'/root/PARAMETER/ROWENTRY/VALUE') a where not a.text is NULL)
exec sp_xml_removedocument @hdoc
 	  insert into #ParamValue (Row, Col, Value)
 	  	 (select CONVERT(int,r.Row),CONVERT(int,c.Col), v.Value 
 	  	  	 from #Cols c, #Rows r, #Values v
 	  	  	 where c.rowid = r.rowid and r.rowid =  v.rowid)
 	 EXECUTE spDBR_Delete_Parameter_Value @reportid, @paramid
 	 declare 	 @@col int, @@row int, @@value varchar(4000)
 	 Declare Value_Cursor INSENSITIVE CURSOR
   	 For Select col, row, value from #paramvalue order by row, col
   	 For Read Only
   	 Open Value_Cursor 
 	 Value_Loop:
   	  	 Fetch Next From Value_Cursor Into @@col, @@row, @@value
   	  	 If (@@Fetch_Status = 0)
   	   	 Begin
 	  	  	 execute spDBR_Update_Parameter_Value @reportid, @paramid, @@row, @@col, @@value
       	  	  	 Goto Value_Loop
     	  	 End 	 
 	 Close Value_Cursor 
 	 Deallocate Value_Cursor
