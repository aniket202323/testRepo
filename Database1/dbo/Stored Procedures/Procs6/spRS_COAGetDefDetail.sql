Create Procedure dbo.spRS_COAGetDefDetail 
@WRD_Id int,
@Update int = 0,
@User_Id int,
@WRD_Desc varchar(50) OUTPUT, 
@WAT_Id int OUTPUT, 
@Report_Type_Id int OUTPUT,
@WARC_Id int OUTPUT, 
@Trigger_Delay int OUTPUT, 
@Is_Active int OUTPUT, 
@Hold_For_Review int OUTPUT, 
@Last_Time_Trigger datetime OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spRS_COAGetDefDetail',
             Convert(varchar(10),@WRD_Id) + ','  + 
             Convert(varchar(10),@Update) + ','  + 
             Convert(varchar(10),@User_Id) + ','  + 
             @WRD_Desc + ','  + 
             Convert(varchar(10),@WAT_Id) + ','  + 
             Convert(varchar(10),@Report_Type_Id) + ','  + 
             Convert(varchar(10),@WARC_Id) + ','  + 
             Convert(varchar(10),@Trigger_Delay) + ','  + 
             Convert(varchar(10),@Is_Active) + ','  + 
             Convert(varchar(10),@Hold_For_Review) + ','  + 
             Convert(varchar(10),@Last_Time_Trigger), getdate())
SELECT @Insert_Id = Scope_Identity()
Declare @Current_WAT_Id int
Select @Current_WAT_Id = WAT_Id
From Web_Report_Definitions
Where WRD_Id = @WRD_Id
If @Update = 0
  Select @WRD_Desc = WRD_Desc, @WAT_Id = WAT_Id, @Report_Type_Id = Report_Type_Id, 
  @WARC_Id = WARC_Id, @Trigger_Delay = Trigger_Delay, @Is_Active = Is_Active, 
  @Hold_For_Review = Hold_For_Review, @Last_Time_Trigger = Last_Time_Trigger
  From Web_Report_Definitions
  Where WRD_Id = @WRD_Id
Else If @Update = 1
  Begin
    if @Current_WAT_Id <> @WAT_Id
      Delete From Web_Report_Definition_Criteria Where WRD_Id = @WRD_Id
    If @WARC_Id = 0 Select @WARC_Id = NULL
    Update Web_Report_Definitions Set 
    WRD_Desc = @WRD_Desc, WAT_Id = @WAT_Id, Report_Type_Id = @Report_Type_Id, 
    WARC_Id = @WARC_Id, Trigger_Delay = @Trigger_Delay, Is_Active = @Is_Active, 
    Hold_For_Review = @Hold_For_Review, Last_Time_Trigger = @Last_Time_Trigger
    Where WRD_Id = @WRD_Id
    if @Current_WAT_Id <> @WAT_Id
    Update Web_Report_Definitions Set WARC_Id = NULL Where WRD_Id = @WRD_Id
  End
Else If @Update = 2
  Begin
    if @Current_WAT_Id <> @WAT_Id
      Select @WARC_Id = Count(*) From Web_Report_Definition_Criteria Where WRD_Id = @WRD_Id
    else
      Select @WARC_Id = 0
  End
UPDATE  Audit_Trail SET EndTime = getdate(),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
