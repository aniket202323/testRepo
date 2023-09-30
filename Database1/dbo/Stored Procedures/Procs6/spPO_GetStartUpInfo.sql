Create Procedure dbo.spPO_GetStartUpInfo
 	 @UserId int = 1
  AS
Select @UserId = coalesce(@UserId,1)
Select Topic_Desc = 'Day to Date Unit Details ',Topic_id = 100  --obsolite (old clients)
Create Table #Topics(Topic_Desc nvarchar(50),Topic_Id Int)
Insert into #Topics(Topic_Desc,Topic_Id) Values (dbo.fnDBTranslate(N'0',24297,'Day To Date'),102)
Insert into #Topics(Topic_Desc,Topic_Id) Values (dbo.fnDBTranslate(N'0',24298,'Shift To Date'),122)
Insert into #Topics(Topic_Desc,Topic_Id) Values (dbo.fnDBTranslate(N'0',24299,'Rolling 24 Hour'),132)
Select * FROM #Topics
Drop table #Topics
Select Password from users where user_Id = @UserId
