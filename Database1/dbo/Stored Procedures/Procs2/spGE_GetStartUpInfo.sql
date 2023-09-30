Create Procedure dbo.spGE_GetStartUpInfo
  AS
Declare @TempUnit Int,
 	 @RollMap  nvarchar(25)
Select @TempUnit = Null,@RollMap = Null
Select @TempUnit = Case When value = '' Then Null
 	  	 else value
 	  	 End
 	 From Parameters sp
 	 Join Site_parameters p on p.parm_Id = sp.Parm_Id
        Where  Parm_Name = 'Temporary Unit'
Select @RollMap = value
 	 From Parameters sp
 	 Join Site_parameters p on p.parm_Id = sp.Parm_Id
        Where  Parm_Name = 'GenealogyRollMap'
If @RollMap is Null
  Select @RollMap = 'Bad'
/*
IF @RollMap <> 'MapEnabled'
  Select  RollMapEnabled = 0
Else
  Select  RollMapEnabled = 1
*/
If @TempUnit Is Not Null 
 	 Select PU_Id = @TempUnit,RollMapEnabled = case When @RollMap <> 'MapEnabled' then 0 else 1 End
Else
   Select pu_Id = 0,RollMapEnabled = case When @RollMap <> 'MapEnabled' then 0 else 1 End 
-- 	 From  Prod_Units  Where PU_Id = 1 and PU_Id = 2
 Select Distinct Icon_Id 
 	 from Production_status
Select Topic_Desc = 'Day to Date Unit Details ',Topic_id = 100  --obsolite (old clients)
Create Table #Topics(Topic_Desc nvarchar(50),Topic_Id Int)
Insert into #Topics(Topic_Desc,Topic_Id) Values (dbo.fnDBTranslate(N'0',24297,'Day To Date'),102)
Insert into #Topics(Topic_Desc,Topic_Id) Values (dbo.fnDBTranslate(N'0',24298,'Shift To Date'),122)
Insert into #Topics(Topic_Desc,Topic_Id) Values (dbo.fnDBTranslate(N'0',24299,'Rolling 24 Hour'),132)
Select * FROM #Topics
Declare @Tasks Table (KeyId Int,TaskId Int,TaskDesc nvarchar(50),IsChecked TinyInt,EventType Int)
Insert Into @Tasks (KeyId ,TaskId ,TaskDesc ,IsChecked,EventType) Values (1,5,'Fire Calculations for Parent Event [~]',1,1)
--Insert Into @Tasks (KeyId ,TaskId ,TaskDesc ,IsChecked,EventType) Values (2,13,'Fire Models for Parent Event [~]',1,1)
Insert Into @Tasks (KeyId ,TaskId ,TaskDesc ,IsChecked,EventType) Values (3,5,'Fire Calculations for Child Event [~]',0,2)
--Insert Into @Tasks (KeyId ,TaskId ,TaskDesc ,IsChecked,EventType) Values (4,13,'Fire Models for Child Event [~]',0,2)
--Insert Into @Tasks (KeyId ,TaskId ,TaskDesc ,IsChecked,EventType) Values (5,19,'Fire Models for Component Link',0,3)
--Insert Into @Tasks (KeyId ,TaskId ,TaskDesc ,IsChecked,EventType) Values (6,39,'Fire Calculations for Component Link',0,3)
Select * from @Tasks
