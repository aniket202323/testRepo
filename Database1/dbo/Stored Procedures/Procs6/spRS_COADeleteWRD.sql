Create Procedure dbo.spRS_COADeleteWRD
@WRD_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COADeleteWRD', 
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Delete From Web_Report_Definition_Criteria
Where WRD_Id = @WRD_Id
Delete From Web_Report_Printers
Where WRD_Id = @WRD_Id
Delete From Web_Report_Definitions
Where WRD_Id = @WRD_Id
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
