Create Procedure dbo.spRS_COACreateNewWRD
@User_Id int,
@NewWRDDesc varchar(50) OUTPUT
AS
Declare @x int,
@ID int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COACreateNewWRD', 
             Convert(varchar(10),@User_Id), getdate())
SELECT @Insert_Id = Scope_Identity()
Select @x = 0
NextAvailDesc:
Select @x = @x + 1
Select @ID = Null
Select @ID = WRD_Id From Web_Report_Definitions
Where WRD_Desc = 'Web Report Definition ' + Convert(varchar(10), @x)
If @ID is Null
  Begin
    Select @NewWRDDesc = 'Web Report Definition ' + Convert(varchar(10), @x)
  End
Else
  Begin
    GoTo NextAvailDesc
  End
Insert Into Web_Report_Definitions(WRD_Desc, WRT_Id) Values (@NewWRDDesc, 1)
Select @NewWRDDesc
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
