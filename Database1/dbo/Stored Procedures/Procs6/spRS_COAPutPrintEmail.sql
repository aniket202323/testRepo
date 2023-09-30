Create Procedure dbo.spRS_COAPutPrintEmail
@WRD_Id int,
@Destination_EG_Id int = NULL,
@Reject_EG_Id int = NULL,
@Report_Addressee_Id int = NULL,
@Printer_Id int = NULL,
@Action tinyint,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAPutPrintEmail',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@Destination_EG_Id) + ','  + 
             Convert(varchar(10),@Reject_EG_Id) + ','  + 
             Convert(varchar(10),@Report_Addressee_Id) + ','  + 
             Convert(varchar(10),@Printer_Id) + ','  + 
             Convert(varchar(10),@Action) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
if @Action = 0
  Update Web_Report_Definitions 
  Set Destination_EG_Id = @Destination_EG_Id, Reject_EG_Id = @Reject_EG_Id, Report_Addressee_Id = @Report_Addressee_Id
  Where WRD_Id = @WRD_Id
else if @Action = 1
  Insert Into Web_Report_Printers (WRD_Id, Printer_Id) Values (@WRD_Id, @Printer_Id)
else if @Action = 2
  Delete From Web_Report_Printers Where WRD_Id = @WRD_Id and Printer_Id = @Printer_Id
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
