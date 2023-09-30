Create Procedure dbo.spRS_COAGetGeneralCBOs 
@WRD_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAGetGeneralCBOs',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Select WAT_Id, WAT_Desc
From Web_App_Types
Order By WAT_Desc
Select Report_Type_Id, Description
From Report_Types
Order By Description
Select c.WARC_Id, c.WARC_Desc
From Web_App_Reject_Codes c
Join Web_Report_Definitions d on d.WAT_Id = c.WAT_Id
Where d.WRD_Id = @WRD_Id
Order By c.WARC_Desc
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
