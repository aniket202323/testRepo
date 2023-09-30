CREATE PROCedure dbo.spSupport_ExportPrototypes
@All int = 0,
@Like varchar(255) = null 
AS
set nocount on 
Create TABLE #Status(Updated bit)
Insert Into #Status Select 1
--support tables
If @All = 1 
  BEGIN
    Insert Into #Status Select 0
/*
    Select 'SET IDENTITY_INSERT client_sp_locktypes on'
    SELECT 'INSERT INTO CLIENT_SP_LOCKTYPES (LockType_Id, LockType_Desc,LockType_Value )VALUES(' + CONVERT(VARCHAR(10), LOCKTYPE_ID) + ',''' + locktype_desc + ''',' + CONVERT(VARCHAR(10), LOCKTYPE_VALUE) + ')' from client_sp_locktypes 
    Select 'SET IDENTITY_INSERT client_sp_locktypes off'
    Select 'SET IDENTITY_INSERT client_sp_cursortypes on'
    SELECT 'INSERT INTO CLIENT_SP_CURSORTYPES (CursorType_Id, CursorType_Desc, CursorType_Value) VALUES(' + CONVERT(VARCHAR(10), CursorType_Id) + ',''' + CursorType_Desc + ''',' + CONVERT(VARCHAR(10), CursorType_Value) + ')' from client_sp_CURSORtypes 
    Select 'SET IDENTITY_INSERT client_sp_cursortypes off'
*/
  END
If @All = 2
  Insert Into #Status Select 0
Declare
  @Id int, 
  @cmd varchar(255),
  @values varchar(255),
  @desc varchar(255), 
  @appid int, 
  @SQL varchar(255)
if @Like IS null 
  Select @SQL = 'Select Client_SP_Id from client_sp_prototypes Where Updated in (Select Updated from #Status)'
else
  Select @SQL = 'Select Client_SP_Id from client_sp_prototypes Where sp_name like ''%' + @like + '%'' and Updated in (Select Updated from #Status)'
Set NoCount on 
Create Table #cmd (cmd varchar(255))
exec ('Declare MyCursor CURSOR Global Static
  For (' + @SQL + ')
  For Read Only')
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @Id
  If (@@Fetch_Status = 0)
    Begin
/*
Insert Into #cmd  
 select 'DELETE Client_SP_Prototypes Where SP_Name = ' +  '''' + SP_Name + '''' 
 from client_sp_prototypes 
  where Client_sp_id = @id
*/
Insert Into #cmd
 select 'DECLARE @Input int, @Input_Output int, @Output int'
Insert Into #cmd
 select 'SELECT @Input = ' + CONVERT(VARCHAR(10), input) + ', @Input_Output = ' + CONVERT(VARCHAR(10), input_output) + ', @Output = ' + CONVERT(VARCHAR(10), output)
 from client_sp_prototypes
 where Client_sp_id = @id
Insert Into #cmd
 select 'UPDATE client_sp_prototypes set input = @Input, input_output = @Input_Output, output = @Output where sp_name = ' + '''' + LTrim(RTrim(SP_Name)) + ''''
 from client_sp_prototypes
 where Client_sp_id = @id
Insert Into #cmd
 select 'If @@Rowcount = 0'
Insert Into #cmd  
 select 'INSERT INTO Client_SP_Prototypes (SP_Name, Command_Text, Stored_Proc, Input, Input_Output, Output, Server_Cursor, CursorType_Id, LockType_Id, Prepare_SP, Timeout, MaxRetries, SP_Desc) VALUES('
Insert Into #cmd 
select 
 '  ''' + LTrim(RTrim(SP_Name)) + ''','''
+ LTrim(RTrim(Command_Text)) + ''','
+ CONVERT(VARCHAR(10), Stored_Proc) + ','
+ '@Input,@Input_Output,@Output,'
--+ CONVERT(VARCHAR(10), Input) + ','
--+ CONVERT(VARCHAR(10), Input_Output) + ',' 
--+ CONVERT(VARCHAR(10), Output)+ ',' 
+ CONVERT(VARCHAR(10), Server_Cursor) + ','
+ CONVERT(VARCHAR(10), CursorType_Id) + ',' + CONVERT(VARCHAR(10), LockType_Id) + ',' + CONVERT(VARCHAR(10), Prepare_SP) + ',' + CONVERT(VARCHAR(10), Timeout) + ',' + CONVERT(VARCHAR(10), MaxRetries)
 from client_sp_prototypes
  where Client_sp_id = @id
Insert Into #cmd 
  Select '   ,''' + COALESCE(SP_Desc, '')  + ''')'
   from client_sp_prototypes 
    where Client_sp_id = @id
Insert Into #cmd 
  Select 'GO'
      Goto MyLoop1
    End
Close MyCursor
Deallocate MyCursor
select cmd as '--cmd' from #cmd
drop table #cmd
drop table #Status
If @All = 0
  BEGIN
    print 'All update flags reset'
    Update Client_SP_Prototypes Set Updated = 0
  END
