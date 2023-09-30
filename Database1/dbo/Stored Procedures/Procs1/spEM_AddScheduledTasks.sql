CREATE PROCEDURE dbo.spEM_AddScheduledTasks
 	 @Ids VarChar(7000),
 	 @Tasks nvarchar(1000)
AS
Declare @ID 	 nVarChar(10)
Create Table #tasks (TaskId Int)
Insert into #tasks
select Id from dbo.fnCMN_IdListToTable('xxx',@Tasks,CHAR(1))
Select * from #Tasks
Create Table #Ids (Id Int)
Insert into #Ids
Select Id from dbo.fnCMN_IdListToTable('xxx',@Ids,CHAR(1))
Insert into Pendingtasks
Select T.TaskId,I.Id from #tasks T cross join #Ids I 
 Drop table #Ids
Drop Table #tasks
