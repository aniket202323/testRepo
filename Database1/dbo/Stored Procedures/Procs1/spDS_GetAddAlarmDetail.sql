Create Procedure dbo.spDS_GetAddAlarmDetail
@AlarmId int,
@RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @PUId int,
         @ReasonTreeId int,
         @ActionTreeId int,
         @CauseRequired int,
         @ActionRequired int,
         @StartTime datetime,
         @EndTime datetime,
         @TimeStamp datetime,
         @TreeNameId int,
         @FirstEventNum nVarChar(25),
-- 	  @NoCause nVarChar(25),
--         @NoAction nVarChar(25),
 	  @AlarmEventType int 	 
-- Select @NoCause = '<None>'
-- Select @NoAction = '<None>'
 Select @PUId = NULL
 Select @ReasonTreeId = NULL
 Select @ActionTreeId = NULL
 Select @CauseRequired = NULL
 Select @ActionRequired = NULL
 Select @StartTime = NULL
 Select @EndTime = NULL
 Select @TimeStamp = NULL
 Select @AlarmEventType=11
----------------------------------------------------------------------------
-- Get Tree names for Reason and Action 
----------------------------------------------------------------------------
 Select @ReasonTreeId = Coalesce(AD.Override_Cause_Tree_Id, AT.Cause_Tree_Id),
        @ActionTreeId = Coalesce(AD.Override_Action_Tree_Id, AT.Action_Tree_Id),
        @CauseRequired = AT.Cause_Required,
        @ActionRequired = AT.Action_Required,
        @StartTime = AL.Start_Time,
        @EndTime = AL.End_Time, 
        @PUId = AL.Source_PU_Id
  From Alarm_Templates AT Inner Join Alarm_Template_Var_Data AD On AT.At_Id = AD.At_Id
                          Inner Join Alarms AL on AL.ATD_Id = AD.Atd_Id
   Where AL.Alarm_Id = @AlarmId
--------------------------------------------------------
-- Cause and Action Tree Ids
--------------------------------------------------------
 Select @ReasonTreeId as CauseTreeId, @ActionTreeId As ActionTreeId, 
        @ActionRequired as ActionRequired, @CauseRequired as CauseRequired 
------------------------------------------------------------------------------
-- detail info
-----------------------------------------------------------------------------
 Select AL.Alarm_Desc as Description, AL.Start_Time as StartTime, AL.End_Time as EndTime, AT.AT_Desc as AlarmRule,
        AL.ATD_Id as ATDid,AL.Source_PU_Id as PUId, AL.Start_Result as StartResult, AL.End_Result as EndResult, AD.Var_Id as VarId, AL.Key_Id as KeyId,
        AL.ACK as ACK, AL.ACK_by as ACKUserId, US2.UserName as ACKUser , AL.ACK_On as ACKDate, AT.AP_Id as APId, AP.AP_Desc as APDesc, 
        Duration as Duration, --      DateDiff(minute, AL.Start_Time , AL.End_Time) as Duration, 
        AL.Cause1 as CauseLevel1, RE.Event_Reason_Name as CauseName1, 
        AL.Cause2 as CauseLevel2, RE2.Event_Reason_Name as CauseName2, 
        AL.Cause3 as CauseLevel3, RE3.Event_Reason_Name as CauseName3, 
        AL.Cause4 as CauseLevel4, RE4.Event_Reason_Name as CauseName4, 
        AL.Action1 as ActionLevel1, RE5.Event_Reason_Name as ActionName1, 
        AL.Action2 as ActionLevel2, RE6.Event_Reason_Name as ActionName2, 
        AL.Action3 as ActionLevel3, RE7.Event_Reason_Name as ActionName3, 
        AL.Action4 as ActionLevel4, RE8.Event_Reason_Name as ActionName4, 
        AL.Research_User_Id as ResearchUserId, US.UserName as ResearchUserName,
        AL.Research_Status_Id as ResearchStatusId, RS.Research_Status_Desc as ResearchStatusDesc,
        AL.Research_Open_Date as ResearchOpenDate, AL.Research_Close_Date as ResearchCloseDate,
        AL.Research_Comment_Id as ResearchCommentId, -- CO3.Comment as ResearchComment,
        AL.Cause_Comment_Id as CauseCommentId, -- CO.Comment as CauseComment,
        AL.Action_Comment_Id as ActionCommentId,  -- CO2.Comment as ActionComment,
        AT.ESignature_Level
  From Alarms AL Inner Join Alarm_Template_Var_Data AD On AL.ATD_Id = AD.ATD_Id
                 Inner Join Alarm_Templates AT on AD.AT_Id = AT.AT_Id
                 Inner Join ALarm_Priorities AP on AT.AP_Id = AP.AP_Id
                 Left Outer Join Users US2 on AL.Ack_By = US2.User_Id
                 Left Outer Join Event_Reasons RE on AL.Cause1 = RE.Event_Reason_Id
                 Left Outer Join Event_Reasons RE2 on AL.Cause2 = RE2.Event_Reason_Id
                 Left Outer Join Event_Reasons RE3 on AL.Cause3 = RE3.Event_Reason_Id
                 Left Outer Join Event_Reasons RE4 on AL.Cause4 = RE4.Event_Reason_Id
                 Left Outer Join Event_Reasons RE5 on AL.Action1 = RE5.Event_Reason_Id
                 Left Outer Join Event_Reasons RE6 on AL.Action2 = RE6.Event_Reason_Id
                 Left Outer Join Event_Reasons RE7 on AL.Action3 = RE7.Event_Reason_Id
                 Left Outer Join Event_Reasons RE8 on AL.Action4 = RE8.Event_Reason_Id
--                Left Outer Join Comments CO on AL.Cause_Comment_Id = CO.Comment_Id  
--                Left Outer Join Comments CO2 on AL.Action_Comment_Id = CO2.Comment_Id  
                 Left Outer Join Users US on AL.Research_User_Id = US.User_Id
--                Left Outer Join Comments CO3 on AL.Research_Comment_Id = CO3.Comment_Id  
                 Left Outer Join Research_Status RS on AL.Research_Status_Id = RS.Research_Status_Id
    Where AL.ALarm_Id = @AlarmID
------------------------------------------------------------------------------
-- Last event happened before the alarm begun
------------------------------------------------------------------------------
 Select top 1 @TimeStamp = TimeStamp 
  From Events
   Where PU_Id= @PUId
   And @StartTime > Start_Time and @StartTime <= TimeStamp order by Timestamp DESC
-- Select EV.Event_Num as FirstEventNum, ES.Event_SubType_Desc as SubTypeDescription
--  From Events EV Left Outer Join Event_SubTypes ES on EV.Event_SubType_Id = ES.Event_SubType_Id
--   Where EV.PU_Id = @PUId
--    And TimeStamp = @TimeStamp
 Select @FirstEventNum = Null
 Select @FirstEventNum = EV.Event_Num 
  From Events EV
   Where EV.PU_Id = @PUId
    And TimeStamp = @TimeStamp
 Select @FirstEventNum as FirstEventNum
------------------------------------------------------------------------------
-- Last Event happened during the alarm
------------------------------------------------------------------------------
 Select @TimeStamp = NULL
 If (@EndTime IS NULL)
  Select NULL as LastEventNum 
 Else
  Begin
   Select top 1 @TimeStamp = TimeStamp 
    From Events
     Where PU_Id= @PUId
 	  And @EndTime > Start_Time and @EndTime <= TimeStamp order by Timestamp DESC
   Select EV.Event_Num as LastEventNum
    From Events EV  
     Where EV.PU_Id = @PUId
      And TimeStamp = @TimeStamp
  End 
--------------------------------------------------------------------------------
-- Event Subype for the last production event before the alarm began
---------------------------------------------------------------------------------
 If (@FirstEventNum Is Null)
  Select Null as SubTypeDescription
 Else
  Select Min(ES.Event_SubType_Desc) As SubTypeDescription
   From Event_SubTypes ES Inner Join Event_Configuration EC
    On ES.Event_SubType_Id = EC.Event_SubType_Id
     Where ES.ET_Id = 1
      And EC.PU_Id = @PUId
------------------------------------------------------------------------------
-- Total of Events happened durint the alarm
------------------------------------------------------------------------------
 If (@EndTime Is Null)
  Select Count(*) as EventCounter
   From Events
    Where PU_Id = @PUId
     And TimeStamp >=@StartTime 
 Else 
  Select Count(*) as EventCounter
   From Events
    Where PU_Id = @PUId
     And TimeStamp >=@StartTime 
      And TimeStamp <=@EndTime
------------------------------------------------------------------------------
-- History
------------------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (16026,1)
 	 Insert into @CHT(HeaderTag,Idx) Values (16481,2)
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,3)
 	 Insert into @CHT(HeaderTag,Idx) Values (16333,4)
 	 Insert into @CHT(HeaderTag,Idx) Values (16345,5)
 	 Insert into @CHT(HeaderTag,Idx) Values (16408,6)
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	  Select [Acknowledged]= case when a.Ack = 1 THEN 'Yes'
 	  	  	  	  	 ELSE 'No'
 	  	  	  	  	 END,
 	  	  [Ack By] = u2.Username,
 	  	  [Start Time] = a.Start_Time,
 	  	  [End Time] = a.End_Time,
 	  	  [User] = u.Username, 
 	  	  [Approver] = u3.UserName
 	    From Alarm_History a
 	  	  Join Users u on u.User_id = a.User_Id
 	  	  Left outer Join Users u2 on u2.User_Id = a.Ack_By
 	  	  Left outer Join ESignature ES on ES.Signature_Id = a.Signature_Id
 	  	  Left outer Join Users u3 on u3.User_Id = ES.Verify_User_Id
 	  	  Where Alarm_Id = @AlarmId
 	  	  Order by Modified_On desc
END
ELSE
BEGIN
 Select a.Ack, u2.Username as Username2, a.Start_Time, a.End_Time, u.Username, u3.UserName as 'ApproverName'
   From Alarm_History a
     Join Users u on u.User_id = a.User_Id
     Left outer Join Users u2 on u2.User_Id = a.Ack_By
     Left outer Join ESignature ES on ES.Signature_Id = a.Signature_Id
     Left outer Join Users u3 on u3.User_Id = ES.Verify_User_Id
     Where Alarm_Id = @AlarmId
     Order by Modified_On desc
END
