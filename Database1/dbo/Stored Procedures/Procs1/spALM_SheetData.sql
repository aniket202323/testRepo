CREATE Procedure dbo.spALM_SheetData
@Sheet_Desc nVarchar(50) = null, 
@InStarttime datetime = NULL,
@InEndtime datetime = NULL,
@Unit_Id int = NULL,
@Event_Id int = NULL
AS
Declare 
  @PU_Id int, 
  @Sheet_id int,
  @Var_id int,
  @Prod_Id int, 
  @Prod_Code varchar(25),
  @Prod_Desc varchar(50),
  @Alarm_Desc varchar(1000), 
  @Var_Desc varchar(50), 
  @ack tinyint, 
  @Ack_by varchar(25),
  @AlarmId int,
  @TotCounter int,
  @Counter int,
  @@Alarm_ID int, 
  @@Event_Num varchar(25),
  @@PU_Id int, 
  @InitialCount int,
  @Priority int
if @InEndtime < '1/1/1970'
 	 SELECT @InEndtime = Null
If @InStartTime is NULL and @Sheet_Desc is NOT NULL
  BEGIN
    Select @InitialCount = -1 * COALESCE(Initial_Count, 24) from Sheets Where Sheet_Desc = @Sheet_Desc
    Select @InStartTime = DATEADD(hour, @InitialCount, dbo.fnServer_CmnGetDate(getUTCdate()))
  END
If @InEndtime is NULL and @Sheet_Desc is NOT NULL
  BEGIN
    Select @InitialCount = COALESCE(Initial_Count, 24) from Sheets Where Sheet_Desc = @Sheet_Desc
    Select @InEndtime = DATEADD(hour, @InitialCount/8, dbo.fnServer_CmnGetDate(getUTCdate()))
  END
Create table #Alarms 
(Alarm_ID int, 
AT_Id int, 
Var_Id int, 
VarCommentId int NULL, 
ATD_id int,
Alarm_Type_Id int, 
AP_Id int, 
TemplateVarCommentId int null, 
Alarm_Desc varchar(1000),
Start_Result varchar(25),
Start_Time Datetime,
End_Time Datetime null, 
Duration int null, 
Ack bit, 
Ack_By varchar(50) NULL,
PU_Id int,
Cause1 int null DEFAULT (0), 
Cause2 int null DEFAULT (0), 
Cause3 int null DEFAULT (0), 
Cause4 int null DEFAULT (0), 
Action1 int null DEFAULT (0), 
Action2 int null DEFAULT (0), 
Action3 int null DEFAULT (0), 
Action4 int null DEFAULT (0), 
CauseCommentID int NULL, 
CauseComment varchar(255) NULL, 
ActionCommentID int NULL, 
ActionComment varchar(255) NULL, 
Prod_Code varchar(25) NULL, 
Prod_Desc varchar(50) NULL,
ProdCommentId int NULL, 
Event_Id int NULL,
Event_Desc varchar(50) NULL, 
EventCommentId int NULL, 
SortPriorityAck varchar(255) NULL, 
VarComment varchar(255) NULL, 
TemplateVarComment varchar(255) NULL,
ResearchCommentID int NULL,
ResearchComment varchar(255) NULL,
Cause1Text int NULL DEFAULT (0),
Cause2Text int NULL DEFAULT (0),
Cause3Text int NULL DEFAULT (0),
Cause4Text int NULL DEFAULT (0),
Action1Text int NULL DEFAULT (0),
Action2Text int NULL DEFAULT (0),
Action3Text int NULL DEFAULT (0),
Action4Text int NULL DEFAULT (0),
ESignature_Level int NULL
)
DECLARE @OpenOnly Int,@SheetId Int,@sOpenOnly VarChar(100),@IncludeProductionPlanAlarms Int
if @Sheet_Desc = ''
  select @Sheet_Desc = NULL
IF @Sheet_Desc is NOT NULL
BEGIN
 	 SELECT @SheetId = Sheet_Id From sheets WHERE Sheet_Desc = @Sheet_Desc
 	 SELECT @sOpenOnly = value
 	  	 FROM Sheet_Display_Options
 	  	 WHERE Sheet_Id = @SheetId and  Display_Option_Id = 13 
 	  	 SET @OpenOnly = 0
 	  	 IF @sOpenOnly = 'TRUE' 
 	  	  	 SET @OpenOnly = 1
 	 SELECT @IncludeProductionPlanAlarms = value
 	  	 FROM Sheet_Display_Options
 	  	 WHERE Sheet_Id = @SheetId and Display_Option_Id = 443
END
if @Unit_id = 0
  select @Unit_id = NULL
if @Event_Id = 0
  select @Event_Id = NULL
if @Event_Id is NOT NULL
  Begin
    select @Unit_Id = PU_Id, @InEndtime = TimeStamp, @InStarttime = Start_Time from events where event_Id = @event_Id
    if @InStarttime is NULL select @InStarttime = Coalesce(MAX(TimeStamp), '01/01/1970') from events where PU_Id = @Unit_Id and TimeStamp < @InEndtime and TimeStamp > '01/01/1970'
  End
if @Unit_Id is NOT NULL and @InEndtime is NULL
  select @InEndtime = dbo.fnServer_CmnGetDate(getUTCdate())
CREATE TABLE #Vars(ATD_Id int, AP_Id int, Key_Id int, PU_Id int, AT_Id int, VarComment int NULL, ATDComment int NULL, SPC_Group_Variable_Type_Id int NULL)
if @Sheet_Desc is NOT NULL and @Unit_Id is NOT NULL
  begin
    Insert Into #Vars
      Select d.ATD_Id, t.AP_Id, v.Var_Id, v.PU_Id, d.AT_Id, VarComment=v.Comment_Id, ATDComment = d.Comment_Id, v.SPC_Group_Variable_Type_Id
       From Variables v
       Join Sheet_Variables sv on sv.Var_Id = v.Var_Id
       Join Sheets s on s.Sheet_Id = sv.Sheet_Id and Sheet_Desc = @Sheet_Desc
       Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
       Join Alarm_Templates t on t.AT_Id = d.AT_Id
       Where v.PU_Id = @Unit_Id
  end
else if @Sheet_Desc is NOT NULL
  Begin
    Insert Into #Vars
      Select d.ATD_Id, t.AP_Id, v.Var_Id, COALESCE(pu.Master_Unit, pu.PU_Id), d.AT_Id, VarComment=v.Comment_Id, ATDComment = d.Comment_Id, v.SPC_Group_Variable_Type_Id
       From Variables v
       Join Sheet_Variables sv on sv.Var_Id = v.Var_Id
       Join Sheets s on s.Sheet_Id = sv.Sheet_Id and Sheet_Desc = @Sheet_Desc
       Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
       Join Alarm_Templates t on t.AT_Id = d.AT_Id
       Join Prod_Units pu on v.PU_Id = pu.PU_Id
    Insert Into #Vars
     Select distinct d.ATD_Id, t.AP_Id, v.Var_Id, COALESCE(pu.Master_Unit, pu.PU_Id), d.AT_Id, VarComment=v.Comment_Id, ATDComment = d.Comment_Id, v.SPC_Group_Variable_Type_Id
      From Sheets s 
      Join Sheet_Unit su on su.Sheet_Id = s.Sheet_Id
      Join Prod_Units pu on pu.PU_Id = su.PU_Id
      Join Variables v on v.PU_Id = pu.PU_Id
      Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
      Join Alarm_Templates t on t.AT_Id = d.AT_Id
 	  	  	  Where s.Sheet_Id = su.Sheet_Id and Sheet_Desc = @Sheet_Desc and v.System = 1
  End
else
  Begin
    Insert Into #Vars
      Select d.ATD_Id, t.AP_Id, v.Var_Id, COALESCE(pu.Master_Unit, pu.PU_Id), d.AT_Id, VarComment=v.Comment_Id, ATDComment = d.Comment_Id, v.SPC_Group_Variable_Type_Id
       From Variables v
       Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
       Join Alarm_Templates t on t.AT_Id = d.AT_Id
       Join Prod_Units pu on v.PU_Id = pu.PU_Id and pu.PU_Id = @Unit_Id
  End
if @Sheet_Desc is NOT NULL
  Begin
  IF @OpenOnly = 0
    Insert Into #Alarms
    (Alarm_ID, AT_Id,  Var_Id, VarCommentId, ATD_id, Alarm_Type_Id, AP_Id, TemplateVarCommentId, Alarm_Desc, Start_Result, Start_Time, End_Time, 
    Duration, Ack, Ack_By, PU_Id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
    Cause1Text, Cause2Text, Cause3Text, Cause4Text, Action1Text, Action2Text, Action3Text, Action4Text,
    CauseCommentID, CauseComment, ActionCommentID, ResearchCommentID, ESignature_Level)
     Select Alarm_Id, at.AT_Id, v.Key_Id, VarComment, v.ATD_Id, a.Alarm_Type_Id, at.AP_Id, ATDComment, Alarm_Desc, Start_Result, Start_Time, End_Time, 
      Duration, Ack, u.UserName, 
      PU_id,  COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
      COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
             Cause_Comment_Id, Coalesce(SubString(c.Comment_Text, 1, 255), ''), Action_Comment_Id, Research_Comment_Id, COALESCE(at.ESignature_Level,0)
       From Alarms a
       Join Alarm_Template_Var_Data atv on atv.ATD_Id = a.ATD_Id
       Join Alarm_Templates at on at.AT_Id = atv.AT_Id
       Join #Vars v on v.Key_Id = a.Key_id and v.ATD_Id = a.ATD_Id
       left outer Join Users u on u.User_Id = a.Ack_By 
       left outer Join Comments c on c.Comment_Id = a.Cause_Comment_Id 
       Where (Start_Time  <=  @InEndtime) and   (End_Time >= @InStartTime or End_Time is NULL)
 	 ELSE
 	     Insert Into #Alarms
    (Alarm_ID, AT_Id,  Var_Id, VarCommentId, ATD_id, Alarm_Type_Id, AP_Id, TemplateVarCommentId, Alarm_Desc, Start_Result, Start_Time, End_Time, 
    Duration, Ack, Ack_By, PU_Id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
    Cause1Text, Cause2Text, Cause3Text, Cause4Text, Action1Text, Action2Text, Action3Text, Action4Text,
    CauseCommentID, CauseComment, ActionCommentID, ResearchCommentID, ESignature_Level)
     Select Alarm_Id, at.AT_Id, v.Key_Id, VarComment, v.ATD_Id, a.Alarm_Type_Id, at.AP_Id, ATDComment, Alarm_Desc, Start_Result, Start_Time, End_Time, 
      Duration, Ack, u.UserName, 
      PU_id,  COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
      COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
             Cause_Comment_Id, Coalesce(SubString(c.Comment_Text, 1, 255), ''), Action_Comment_Id, Research_Comment_Id, COALESCE(at.ESignature_Level,0)
       From Alarms a
       Join Alarm_Template_Var_Data atv on atv.ATD_Id = a.ATD_Id
       Join Alarm_Templates at on at.AT_Id = atv.AT_Id
       Join #Vars v on v.Key_Id = a.Key_id and v.ATD_Id = a.ATD_Id
       left outer Join Users u on u.User_Id = a.Ack_By 
       left outer Join Comments c on c.Comment_Id = a.Cause_Comment_Id 
       Where (Start_Time  <=  @InEndtime) And End_Time is NULL
  End
else
  Begin
    Insert Into #Alarms
    (Alarm_ID, AT_Id,  Var_Id, VarCommentId, ATD_id, Alarm_Type_Id, AP_Id, TemplateVarCommentId, Alarm_Desc, Start_Result, Start_Time, End_Time, 
    Duration, Ack, Ack_By, PU_Id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
    Cause1Text, Cause2Text, Cause3Text, Cause4Text, Action1Text, Action2Text, Action3Text, Action4Text,
    CauseCommentID, CauseComment, ActionCommentID, ResearchCommentID, ESignature_Level)
     Select Alarm_Id, at.AT_Id, v.Key_Id, VarComment, v.ATD_Id, a.Alarm_Type_Id, at.AP_Id, ATDComment, Alarm_Desc, Start_Result, Start_Time, End_Time, 
      Duration, Ack, u.UserName, 
      PU_id,  COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
      COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
             Cause_Comment_Id, Coalesce(SubString(c.Comment_Text, 1, 255), ''), Action_Comment_Id, Research_Comment_Id, COALESCE(at.ESignature_Level,0)
       From Alarms a
       Join Alarm_Template_Var_Data atv on atv.ATD_Id = a.ATD_Id
       Join Alarm_Templates at on at.AT_Id = atv.AT_Id
       Join #Vars v on v.Key_Id = a.Key_id and v.ATD_Id = a.ATD_Id
       left outer Join Users u on u.User_Id = a.Ack_By 
       left outer Join Comments c on c.Comment_Id = a.Cause_Comment_Id
       Where (Start_Time  <=  @InEndtime) and   (End_Time >= @InStartTime or End_Time is NULL)
  End
--include Production Plan alarms
if @IncludeProductionPlanAlarms = 1
Begin
  IF @OpenOnly = 0
    Insert Into #Alarms
    (Alarm_ID, AT_Id,  Var_Id, VarCommentId, ATD_id, Alarm_Type_Id, AP_Id, TemplateVarCommentId, Alarm_Desc, Start_Result, Start_Time, End_Time, 
    Duration, Ack, Ack_By, PU_Id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
    Cause1Text, Cause2Text, Cause3Text, Cause4Text, Action1Text, Action2Text, Action3Text, Action4Text,
    CauseCommentID, CauseComment, ActionCommentID, ResearchCommentID, ESignature_Level)
     Select Alarm_Id, 0, a.Key_Id, 0, 0, a.Alarm_Type_Id, pepa.AP_Id, 0, Alarm_Desc, 0, Start_Time, End_Time, 
      Duration, Ack, u.UserName, 
      null,  COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
      COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
             Cause_Comment_Id, Coalesce(SubString(c.Comment_Text, 1, 255), ''), Action_Comment_Id, Research_Comment_Id, 0
       From Alarms a
 	    Join PrdExec_Paths pep on pep.Path_Id = a.Path_Id
 	    Join PrdExec_Path_Alarms pepa on pepa.Path_Id = a.Path_Id and pepa.PEPAT_Id = a.SubType
       Join Sheet_Unit su on su.Sheet_Id = @SheetId
       Join Prod_Units pu on pu.PU_Id = su.PU_Id 	    
 	    Join PrdExec_Path_Units pepu on pepu.PU_Id = pu.PU_Id
       left outer Join Users u on u.User_Id = a.Ack_By 
       left outer Join Comments c on c.Comment_Id = a.Cause_Comment_Id 
       Where (Start_Time  <=  @InEndtime) and   (End_Time >= @InStartTime or End_Time is NULL)
 	      and a.Alarm_Type_Id = 3
 	 ELSE
 	     Insert Into #Alarms
    (Alarm_ID, AT_Id,  Var_Id, VarCommentId, ATD_id, Alarm_Type_Id, AP_Id, TemplateVarCommentId, Alarm_Desc, Start_Result, Start_Time, End_Time, 
    Duration, Ack, Ack_By, PU_Id, Cause1, Cause2, Cause3, Cause4, Action1, Action2, Action3, Action4, 
    Cause1Text, Cause2Text, Cause3Text, Cause4Text, Action1Text, Action2Text, Action3Text, Action4Text,
    CauseCommentID, CauseComment, ActionCommentID, ResearchCommentID, ESignature_Level)
     Select Alarm_Id, 0, a.Key_Id, 0, 0, a.Alarm_Type_Id, pepa.AP_Id, 0, Alarm_Desc, 0, Start_Time, End_Time, 
      Duration, Ack, u.UserName, 
      null,  COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
      COALESCE(Cause1,0), COALESCE(Cause2,0), COALESCE(Cause3,0), COALESCE(Cause4,0), COALESCE(Action1,0), COALESCE(Action2,0), COALESCE(Action3,0), COALESCE(Action4,0), 
             Cause_Comment_Id, Coalesce(SubString(c.Comment_Text, 1, 255), ''), Action_Comment_Id, Research_Comment_Id, 0
       From Alarms a
 	    Join PrdExec_Paths pep on pep.Path_Id = a.Path_Id
 	    Join PrdExec_Path_Alarms pepa on pepa.Path_Id = a.Path_Id and pepa.PEPAT_Id = a.SubType
       Join Sheet_Unit su on su.Sheet_Id = @SheetId
       Join Prod_Units pu on pu.PU_Id = su.PU_Id 	    
 	    Join PrdExec_Path_Units pepu on pepu.PU_Id = pu.PU_Id
       left outer Join Users u on u.User_Id = a.Ack_By 
       left outer Join Comments c on c.Comment_Id = a.Cause_Comment_Id 
       Where (Start_Time  <=  @InEndtime) And End_Time is NULL and a.Alarm_Type_Id = 3
  End
Update #Alarms
  Set ActionComment = Coalesce(SubString(Comment_Text, 1, 255), '')
  From #Alarms a
  Join Comments c on a.ActionCommentId = Comment_Id
Update #Alarms
  Set VarComment = Coalesce(SubString(Comment_Text, 1, 255), '')
  From #Alarms a
  Join Comments c on a.VarCommentId = Comment_Id
Update #Alarms
  Set TemplateVarComment = Coalesce(SubString(Comment_Text, 1, 255), '')
  From #Alarms a
  Join Comments c on a.TemplateVarCommentId = Comment_Id
Update #Alarms
  Set ResearchComment = Coalesce(SubString(Comment_Text, 1, 255), '')
  From #Alarms a
  Join Comments c on a.ResearchCommentId = Comment_Id
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
 	  	  	 If @Priority is not NULL
 	  	  	  	 Begin
 	        	 Update #Alarms Set AP_Id = @Priority Where Alarm_Id = @@Alarm_ID  
 	  	  	  	 End
      Goto MyPriorityLoop1
    End
Close PriorityCursor
Deallocate PriorityCursor
select * from #alarms order by start_time
drop table #vars 
DROP TABLE #Alarms
