Create Procedure dbo.spRS_COAGetCriteria
@WRD_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAGetCriteria',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
--WRDC_Id Column # (Total Columns - 1) for ListView
Select 3 as Column_Number
Select c.WAC_Desc as 'Criteria', o.Comparison_Operator_Value as 'Operator', NULL as 'Value', r.WRDC_Id, c.WAC_Id, o.Comparison_Operator_Id, r.Value as 'Value_Id'
From Web_Report_Definitions d
Join Web_Report_Definition_Criteria r on r.WRD_Id = d.WRD_Id
Left Outer Join Web_App_Criteria c on c.WAC_Id = r.WAC_Id
Left Outer Join Comparison_Operators o on o.Comparison_Operator_Id = r.Comparison_Operator_Id
Where d.WRD_Id = @WRD_Id
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
