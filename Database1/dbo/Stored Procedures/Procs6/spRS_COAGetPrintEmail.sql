Create Procedure dbo.spRS_COAGetPrintEmail
@WRD_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAGetPrintEmail',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Select EG_Id, EG_Desc
From Email_Groups
Where EG_Id <> 50
Order By EG_Desc
--E-mail Groups
Select Destination_EG_Id, Reject_EG_Id
From Web_Report_Definitions
Where WRD_Id = @WRD_Id
Select Customer_Id, Customer_Name
From Customer
Order By Customer_Name
--Report Addressee
Select Report_Addressee_Id
From Web_Report_Definitions
Where WRD_Id = @WRD_Id
--Available Printers
Select Printer_Id, Printer_Name
From Report_Printers
Where Printer_Id Not In (Select Printer_Id From Web_Report_Printers Where WRD_Id = @WRD_Id)
Order By Printer_Name
--Selected Printers
Select r.Printer_Id, r.Printer_Name
From Report_Printers r
Join Web_Report_Printers w on w.Printer_Id = r.Printer_Id
Where w.WRD_Id = @WRD_Id
Order By r.Printer_Name
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
