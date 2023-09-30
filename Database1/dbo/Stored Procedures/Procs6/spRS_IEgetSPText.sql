CREATE PROCEDURE dbo.spRS_IEgetSPText
 	 @SPName 	 varchar(256)
AS
/*  For use in Import/Export of report packages
    MSI/MT 8-10-2000
*/
Declare @RowCount int
Declare @SPId int
Declare @IsEncrypted int
/* 
MSI/DS 5-27-03
ANSI Padding must be turn on so that trailing spaces and line breaks are preserved 
*/
SET NOCOUNT ON
SET ANSI_PADDING ON
---------------------------------------
-- Get The Id of the stored procedure
---------------------------------------
Select @Spid = id from sysobjects where name = @SPName and xtype = 'P' 
------------------------------------------------------
-- If This Procedure Is Encrypted Then Return Nothing
------------------------------------------------------
Select @IsEncrypted = count(*) from syscomments where id = @Spid and encrypted = 0
if @IsEncrypted = 0
 	 return (0)
---------------------------------------
-- Create Table to stored the contents 
-- of the sp
---------------------------------------
Create Table #t
 	 (
 	 Id int NOT NULL IDENTITY (1, 1),
 	 MyText varchar(8000)
 	 )
Insert Into #t(MyText)
 	 Select 'if exists (select * from sysobjects where id = object_id(N' + '''' + '[dbo].[' + @SPName + ']' + '''' + ') and OBJECTPROPERTY(id, N' + '''' + 'IsProcedure' + '''' + ') = 1)'
Insert Into #t(MyText)  	 Select 'drop procedure [dbo].[' + @SPName + ']' + Char(13)
Insert Into #t(MyText) Select 'GO' + Char(13)
insert Into #t(MyText) Select 'SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON' + Char(13)
Insert Into #t(MyText) Select 'GO' + Char(13)
----------------------------------------------------
-- Added Delete and Insert for Client_SP_Prototypes
----------------------------------------------------
Select @RowCount = Count(*) from Client_SP_Prototypes where command_text = @SpName
If @RowCount > 0 
  Begin
  insert into #t(MyText)
  select char(13) + 'Delete from Client_SP_Prototypes where command_text = ' + '''' + @SPName + ''''
  insert into #t(MyText) Values('GO' + char(13))
  insert into #t(MyText)
  Select char(13) + 'Insert Into Client_SP_Prototypes(System, Stored_Proc, Server_Cursor, Prepare_SP, Updated, Output, ExecMinMS,Input, ExecMaxMS, Input_Output, ExecCount, ExecTotalMinutes, TimeoutCount, DeadlockCount, MaxRetries, CursorType_Id, LockType_Id, Timeout, Hostname, SP_Desc, SP_Name, Command_Text) ' +
  '
  Values(' +
 	 convert(varchar(20), System) + ',' +
 	 convert(varchar(20), Stored_Proc) + ',' +
 	 convert(varchar(20), Server_Cursor) + ',' +
 	 convert(varchar(20), Prepare_SP) + ',' +
 	 convert(varchar(20), Updated) + ',' +
 	 convert(varchar(20), Output) + ',' +
 	 convert(varchar(20), ExecMinMS) + ',' +
 	 convert(varchar(20), Input) + ',' + 
 	 convert(varchar(20), ExecMaxMS) + ',' +
 	 convert(varchar(20), Input_Output) + ',' +
 	 convert(varchar(20), ExecCount) + ',' + 
 	 convert(varchar(20), ExecTotalMinutes) + ',' + 
 	 convert(varchar(20), TimeoutCount) + ',' + 
 	 convert(varchar(20), DeadLockCount) + ',' +
 	 convert(varchar(20), MaxRetries) + ',' +
 	 convert(varchar(20), CursorType_Id) + ',' + 	 
 	 convert(varchar(20), LockType_Id) + ',' +
 	 convert(varchar(20), Timeout) + ',' + 
 	 Case When HostName Is Null Then 'NULL' Else '''' + convert(varchar(5), HostName) + '''' End + ',' + 
 	 Case When SP_Desc Is Null Then 'NULL' Else '''' + convert(varchar(5), SP_Desc) + '''' End + ',' + 
 	 '''' + convert(varchar(50), Command_Text) + '''' + ',' +
 	 '''' + convert(varchar(50), SP_Name) + '''' + ')' + Char(13)
  from client_sp_Prototypes
  where command_text = @SPName
  Insert into #t(MyText) Values('GO' + char(13))
End
-------------------------------------------
-- Extract the sp text from SysComments 
-- where it is not Encrypted
-------------------------------------------
 	 insert #t(MyText)
 	  	 select c.text 
 	  	 from dbo.syscomments c
 	  	 where c.id = @Spid
 	  	 order by c.number, c.colid
Insert Into #t(MyText) Select Char(13) + 'GO' + Char(13)
insert Into #t(MyText) Select 'SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON' + Char(13)
Insert Into #t(MyText) Select 'GO' + Char(13)
insert Into #t(MyText) Select 'GRANT EXECUTE ON [dbo].[' + @SPName + '] TO [ComXClient]' + Char(13)
Insert Into #t(MyText) Select 'GO' + Char(13)
select MyText 'Text' from #t Order By Id
drop Table #t
