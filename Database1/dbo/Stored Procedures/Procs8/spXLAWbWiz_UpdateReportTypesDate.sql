-- spXLAWbWiz_UpdateReportTypesDate() update the date field specified
--
CREATE PROCEDURE dbo.spXLAWbWiz_UpdateReportTypesDate
 	   @Report_Type_Id     Int
 	 , @TheDate            DateTime
 	 , @Which_Date_Type    Int
AS
DECLARE @DateType_Date_Saved            TinyInt
DECLARE @DateType_Date_Tested_Locally   TinyInt
DECLARE @DateType_Date_Tested_Remotely  TinyInt
DECLARE @Return_Status                  Int
DECLARE @Return_Date                    DateTime
 	 --Define Date type to update
SELECT @DateType_Date_Saved            = 1
SELECT @DateType_Date_Tested_Locally   = 2
SELECT @DateType_Date_Tested_Remotely  = 3
SELECT @Return_Status = -1  	 --Initialize
If @Which_Date_Type = @DateType_Date_Saved
  BEGIN
    UPDATE Report_Types SET Date_Saved = @TheDate WHERE Report_Type_Id = @Report_Type_Id
    SELECT @Return_Status = @@Error
    SELECT @Return_Date = Date_Saved FROM Report_Types WHERE Report_Type_Id = @Report_Type_Id
  END
Else If @Which_Date_Type = @DateType_Date_Tested_Locally
  BEGIN
    UPDATE Report_Types SET Date_Tested_Locally = @TheDate WHERE Report_Type_Id = @Report_Type_Id
    SELECT @Return_Status = @@Error
    SELECT @Return_Date = Date_Tested_Locally FROM Report_Types WHERE Report_Type_Id = @Report_Type_Id
  END
Else
  BEGIN
    UPDATE Report_Types SET Date_Tested_Remotely = @TheDate WHERE Report_Type_Id = @Report_Type_Id
    SELECT @Return_Status = @@Error
    SELECT @Return_Date = Date_Tested_Remotely FROM Report_Types WHERE Report_Type_Id = @Report_Type_Id
  END
--EndIf:@Which_Date_Type
SELECT ReturnStatus = @Return_Status, Return_Date = @Return_Date
