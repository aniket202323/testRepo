CREATE Procedure dbo.spEMEPC_GetExecPaths
@PL_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetExecPaths',
             Convert(nVarChar(10),@PL_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select PL_Desc
From Prod_Lines
Where PL_Id = @PL_Id
Select pep.Path_Desc, pep.Path_Code, pep.Path_Id, pep.Is_Schedule_Controlled, pep.Schedule_Control_Type, pep.Is_Line_Production, pep.Create_Children, pep.Comment_Id, (Select Count(*) From Production_Plan Where Path_Id = pep.Path_Id) as 'Process Orders'
From Prdexec_Paths pep
Where pep.PL_Id = @PL_Id
Order By Path_Desc ASC
Create Table #ScheduleControlType (SCT_Id int, SCT_Desc nvarchar(50))
Insert Into #ScheduleControlType(SCT_Id,SCT_Desc) Values(0,'All Units Run Same Schedule Simultaneously')
Insert Into #ScheduleControlType(SCT_Id,SCT_Desc) Values(1,'Schedule Flows By Event')
Insert Into #ScheduleControlType(SCT_Id,SCT_Desc) Values(2,'Schedule Flows Independently')
Select SCT_Id, SCT_Desc
From #ScheduleControlType
Order By SCT_Desc ASC
Drop Table #ScheduleControlType
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
