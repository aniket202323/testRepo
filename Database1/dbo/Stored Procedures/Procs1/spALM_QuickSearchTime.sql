CREATE PROCEDURE dbo.spALM_QuickSearchTime
@ATD_ID integer,
@Sheet_ID int,
@StartTime nvarchar(30) = NULL,
@EndTime nvarchar(30) = NULL
AS
Declare 
  @PU_Id int, 
  @Start_Time nvarchar(30),
  @End_Time nvarchar(30), 
  @Var_id int,
  @Prod_Id int, 
  @Alarm_start_time nvarchar(30),
  @Alarm_end_time nvarchar(30), 
  @Prod_Code nvarchar(25),
  @Prod_Desc nvarchar(50),
  @Alarm_Desc nvarchar(1000), 
  @Var_Desc nvarchar(50), 
  @ack tinyint, 
  @Ack_by nvarchar(25),
  @AlarmId int,
  @TotCounter int,
  @Counter int,
  @RowCount int,
  @InitialCount int,
  @Priority int
If @StartTime is NULL 
  BEGIN
    Select @InitialCount = -1 * COALESCE(Initial_Count,8) from Sheets Where Sheet_Id = @Sheet_ID
    Select @StartTime = DATEADD(hour, @InitialCount, dbo.fnServer_CmnGetDate(getUTCdate()))
  END
If @EndTime is NULL 
  BEGIN
    Select @InitialCount = COALESCE(Initial_Count,4) from Sheets Where Sheet_Id = @Sheet_ID
    Select @EndTime = DATEADD(hour, @InitialCount, dbo.fnServer_CmnGetDate(getUTCdate()))
  END
Declare 
  @@Alarm_ID int,  
  @@Start_Time Datetime,
  @@Event_Num nvarchar(25),
  @@PU_Id int
Create table #Alarms 
(Alarm_ID int,  
AT_Id int, 
Var_Id int, 
VarCommentId int NULL, 
ATD_id int,
Alarm_Type_Id int, 
AP_Id int NULL, 
TemplateVarCommentId int null, 
Alarm_Desc nvarchar(1000),
Start_Result nvarchar(25),
Start_Time Datetime,
End_Time Datetime null, 
Duration int null, 
Ack bit, 
Ack_By nvarchar(50) NULL,
PU_Id int,
Cause1 int null, 
Cause2 int null, 
Cause3 int null, 
Cause4 int null, 
Action1 int null, 
Action2 int null, 
Action3 int null, 
Action4 int null, 
CauseCommentID int NULL, 
CauseComment nvarchar(255) NULL, 
ActionCommentID int NULL, 
ActionComment nvarchar(255) NULL, 
Prod_Code nvarchar(25) NULL, 
Prod_Desc nvarchar(50) NULL,
ProdCommentId int NULL, 
Event_Id int NULL,
Event_Desc nvarchar(50) NULL, 
EventCommentId int NULL, 
SortPriorityAck nvarchar(255) NULL, 
VarComment nvarchar(255) NULL, 
TemplateVarComment nvarchar(255) NULL,
ResearchCommentID int NULL,
ResearchComment nvarchar(255) NULL,
Cause1Text nvarchar(100) NULL,
Cause2Text nvarchar(100) NULL,
Cause3Text nvarchar(100) NULL,
Cause4Text nvarchar(100) NULL,
Action1Text nvarchar(100) NULL,
Action2Text nvarchar(100) NULL,
Action3Text nvarchar(100) NULL,
Action4Text nvarchar(100) NULL
)
Declare 
 @RC int
set @RC = convert(int, (select Value from Sheet_Display_Options where sheet_Id = 74 and Display_Option_Id = 4))
select @RC
if @RC = 1 
 	 set rowcount 1
if @RC = 2 
 	 set rowcount 2
if @RC = 3 
 	 set rowcount 3
if @RC = 4 
 	 set rowcount 4
if @RC = 5 
 	 set rowcount 5
if @RC = 6 
 	 set rowcount 6
if @RC = 7 
 	 set rowcount 7
if @RC = 8 
 	 set rowcount 8
if @RC = 9 
 	 set rowcount 9
if @RC = 10
 	 set rowcount 10
if @RC = 11
 	 set rowcount 11
if @RC = 12
 	 set rowcount 12
if @RC = 13
 	 set rowcount 13
if @RC = 14
 	 set rowcount 14
if @RC = 15
 	 set rowcount 15
if @RC = 16
 	 set rowcount 16
if @RC = 17
 	 set rowcount 17
if @RC = 18
 	 set rowcount 18
if @RC = 19
 	 set rowcount 19
if @RC = 20
 	 set rowcount 20
select * from Data_Source
Insert Into #Alarms
(Alarm_ID, AT_Id,  Var_Id, VarCommentId, ATD_id, Alarm_Type_Id, AP_Id, TemplateVarCommentId, Alarm_Desc, Start_Result, Start_Time, End_Time, 
Duration, Ack, Ack_By, PU_Id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
CauseCommentID, CauseComment, ActionCommentID, ResearchCommentID)
 Select Alarm_Id, d.AT_Id, v.VAR_Id, v.Comment_Id, d.ATD_Id, a.Alarm_Type_Id, NULL, d.Comment_Id, Alarm_Desc, Start_Result, Start_Time, End_Time, 
  Duration, Ack, u.Username,  
  pu.PU_id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
         Cause_Comment_Id, c.Comment_Text, Action_Comment_Id, Research_Comment_Id
   From Alarms a
   Join Alarm_Template_Var_Data d on d.ATD_Id = a.ATD_Id
    Join Variables v on v.Var_Id = d.Var_Id
  Join Alarm_Templates t on t.AT_Id = d.AT_Id
   Join Prod_Units pu on v.PU_Id = pu.PU_Id
   left outer Join Users u on u.User_Id = a.Ack_By 
   left outer Join Comments c on c.Comment_Id = a.Cause_Comment_Id 
   Where  a.ATD_ID=@ATD_ID
   and Start_Time > CONVERT(DATETIME, @StartTime) and (End_Time < CONVERT(DATETIME, @EndTime) or End_Time is NULL)
   order by Start_Time desc
Update #Alarms
  Set ActionComment = Comment_Text
  From #Alarms a
  Join Comments c on a.ActionCommentId = Comment_Id
Update #Alarms
  Set VarComment = Comment_Text
  From #Alarms a
  Join Comments c on a.VarCommentId = Comment_Id
Update #Alarms
  Set TemplateVarComment = Comment_Text
  From #Alarms a
  Join Comments c on a.TemplateVarCommentId = Comment_Id
Update #Alarms
  Set ResearchComment = Comment_Text
  From #Alarms a
  Join Comments c on a.ResearchCommentId = Comment_Id
Update #Alarms
  Set Cause1Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Cause1 = Event_Reason_Id
Update #Alarms
  Set Cause2Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Cause2 = Event_Reason_Id
Update #Alarms
  Set Cause3Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Cause3 = Event_Reason_Id
Update #Alarms
  Set Cause4Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Cause4 = Event_Reason_Id
Update #Alarms
  Set Action1Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Action1 = Event_Reason_Id
Update #Alarms
  Set Action2Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Action2 = Event_Reason_Id
Update #Alarms
  Set Action3Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Action3 = Event_Reason_Id
Update #Alarms
  Set Action4Text = Event_Reason_Name
  From #Alarms a  
  Join Event_Reasons e on Action4 = Event_Reason_Id
Declare PriorityCursor INSENSITIVE CURSOR For   
  Select Alarm_Id
  From #Alarms
  For Read Only
  Open PriorityCursor  
MyPriorityLoop1:
  Fetch Next From PriorityCursor Into @@Alarm_ID
  If (@@Fetch_Status = 0)
    Begin
      exec spServer_AMgrGetAlarmPriority @@Alarm_ID, @Priority output
      Update #Alarms Set AP_Id = @Priority Where Alarm_Id = @@Alarm_ID  
      Goto MyPriorityLoop1
    End
Close PriorityCursor
Deallocate PriorityCursor
select * from #alarms order by start_time desc
Drop Table #Alarms
RETURN
DROP TABLE #Alarms
Return(1)
set rowcount 0
