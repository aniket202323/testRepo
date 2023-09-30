CREATE PROCEDURE dbo.[spEM_AddScheduledTasks_Bak_177]
 	 @Ids VarChar(7000),
 	 @Tasks nvarchar(1000)
AS
Declare @ID 	 nVarChar(10)
Create Table #tasks (TaskId Int)
While (Datalength( LTRIM(RTRIM(@Tasks))) > 1) 
  Begin
    Select @ID = SubString(@Tasks,1,CharIndex(Char(1),@Tasks)-1)
 	 Insert Into #tasks(TaskId) Values(@ID)
    Select @Tasks = SubString(@Tasks,CharIndex(Char(1),@Tasks),LEN(@Tasks))
    Select @Tasks = Right(@Tasks,Datalength(@Tasks)-1)
  End
While (Datalength( LTRIM(RTRIM(@Ids))) > 1) 
  Begin
    Select @ID = SubString(@Ids,1,CharIndex(Char(1),@Ids)-1)
 	 Insert INto Pendingtasks (ActualId,TaskId) Select @ID,TaskId From #tasks
    Select @Ids = SubString(@Ids,CharIndex(Char(1),@Ids),Datalength(@Ids))
    Select @Ids = Right(@Ids,Datalength(@Ids)-1)
  End
Drop Table #tasks
