Create Procedure dbo.spRS_COAGetTriggerCBOs 
@WRD_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAGetTriggerCBOs',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Select WRT_Id, WRT_Desc
From Web_Report_Triggers
Order By WRT_Desc
Select RRD_Id, Default_Prompt_Desc
From Report_Relative_Dates
Where Date_Type_Id = 3
Order By RRD_Id
Select c.WAC_Id, c.WAC_Desc
From Web_App_Criteria c
Join Web_Report_Definitions d on d.WAT_Id = c.WAT_Id
Where d.WRD_Id = @WRD_Id
Order By WAC_Desc
Select Comparison_Operator_Id, Comparison_Operator_Value
From Comparison_Operators
Where Comparison_Operator_Id = 1
Order By Comparison_Operator_Value
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
