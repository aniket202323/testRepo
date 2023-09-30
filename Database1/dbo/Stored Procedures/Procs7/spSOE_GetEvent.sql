﻿Create Procedure dbo.spSOE_GetEvent
  @Sheet_Desc [varchar_Desc],
  @NewEventTimeStamp datetime,
  @DecimalSep char(1) = '.'
  AS
  Select @DecimalSep = COALESCE(@DecimalSep,'.')
  DECLARE @MasterUnit int,
         @Sheet_Id int,
         @Initial_Count int,
         @ET nvarchar(20), 
         @Interval smallint,
         @PR Int,
         @IntervalLength int,
         @Start datetime,
         @End datetime,
         @WasteSOEKey nvarchar(50), 
         @WasteSOEDesc nvarchar(150), 
         @WastePUId int,
         @WasteEventSubTypeId int,
         @WasteDimensionX nvarchar(50),
         @EventName nvarchar(50),
         @Event_Id int, 
         @Timestamp datetime, 
         @PU_Id int,
         @Prev_Timestamp datetime,
         @Alarm_Id int,
         @Priority int
----------------------------------------------------------------
-- Get general sheet information.
----------------------------------------------------------------
  Select  @MasterUnit = Master_Unit,
    @Interval = Interval,
    @Initial_Count =  Initial_Count,
    @Sheet_Id = Sheet_Id
  From Sheets
  Where (Sheet_Desc = @Sheet_Desc)
---------------------------------------------------------------
-- Get Units that SOE should show data for this sheet
--------------------------------------------------------------
  Create Table #PUET
  ( 
  PUId int,
  PUDesc nvarchar(50) null,
  GroupId int null, 
  EventSubTypeId int,
  EventSubTypeDesc nvarchar(50) Null,
  ETId int,
  DurationRequired bit null,
  CauseRequired bit null,
  ActionRequired bit null,
  AckRequired bit null,
  Selected bit null,
  ATId int NULL
  )
  Insert into #PUET 
    EXEC dbo.spCmn_GetEventSubEventByUnit @Sheet_Id
---------------------------------------------------------------
-- Get Start and End Time interval
--------------------------------------------------------------
  Select @End =  @NewEventTimeStamp
  Select @Start = DateAdd(Hour,-1 * @Initial_Count, @End)
-------------------------------------------------------------
-- Create temporary tables
-------------------------------------------------------------
  CREATE TABLE #CurrEvents
  (
  SOE_Key nvarchar(50),
  Event_Id int,
  Type int,
  SOE_Desc1 nvarchar(150),
  SOE_Desc2 nvarchar(150) NULL, 
  Start_Time Datetime,
  End_Time Datetime NULL, 
  Duration Decimal(6,1) NULL, 
  Var_Id int NULL,
  Var_Desc  nvarchar(50) NULL,
  PU_Id int NULL,
  Cause nVarChar(255) NULL,
  Action nVarChar(255) NULL,
  PriorityId int NULL, 	 
  Event_SubType_Id int NULL,
  Event_SubType_Desc nvarchar(50) NULL,
  TipText nvarchar(50) NULL,
  Cause_Comment_Id int NULL,
  Status int NULL,
  GroupId Int NULL,
  AT_Id int NULL,
  Time_Stamp DateTime NULL,
  Sort_Time DateTime NULL,
  Icon_Id int NULL,
  Ack bit NULL
  )
---------------------------------------------------------------
-- Get turnup/batch events for the PU/Period
---------------------------------------------------------------
  Select @ET =1
  If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
    Begin
      Insert Into #CurrEvents
        Select Convert(nvarchar(25),EV.event_Id) + '/' + @ET, EV.Event_Id, @ET,
          Case When ES.Event_Subtype_Desc Is Not Null Then ES.Event_Subtype_Desc + ' ' + EV.Event_Num + ' (' + PS.ProdStatus_Desc + ')' Else EV.Event_Num + ' (' + PS.ProdStatus_Desc + ')' End,
          '', EV.Start_Time, EV.TimeStamp, 0, NULL, NULL, EV.PU_Id, NULL, NULL,NULL, EV.Event_SubType_Id, ES.Event_SubType_Desc,
          NULL, EV.Comment_Id, EV.Event_Status, NULL, NULL, NULL, EV.Timestamp, NULL, NULL
        From Events EV 
        Left Outer Join Event_SubTypes ES ON EV.Event_SubType_Id = ES.Event_SubType_Id
        Left Outer Join Production_Status PS on PS.ProdStatus_Id = EV.Event_Status
        Where EV.PU_Id In (Select PT.PUId From #PUET PT Where PT.ETId = @ET) And
        EV.Timestamp Between @Start and @End
      Declare STCursor INSENSITIVE CURSOR
      For (Select Event_Id, End_Time, PU_Id From #CurrEvents Where Start_Time is NULL and Type = @ET)
      For Read Only
      Open STCursor
      STLoop:
      Fetch Next From STCursor Into @Event_Id, @Timestamp, @PU_Id
      If (@@Fetch_Status = 0)
        Begin        
          Select @Prev_Timestamp = Max(End_Time) From #CurrEvents Where End_Time < @Timestamp and PU_Id = @PU_Id          
          Update #CurrEvents
          Set Start_Time = @Prev_Timestamp
          Where Event_Id = @Event_Id
          Goto STLoop
        End
      Close STCursor
      Deallocate STCursor
    End  
---------------------------------------------------------------
-- Get Product change for the PU/Period
---------------------------------------------------------------
  Select @ET = 4
  If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
    Begin
      Select @EventName =Coalesce(Et_Desc,'Product Change') From Event_Types Where Et_Id = @ET
      Insert Into #CurrEvents
        Select Convert(nvarchar(25),PS.Start_Id) + '/' + @ET, 
          PS.Start_Id, @ET, @EventName + ' to ' + PR.Prod_Code, 
          NULL, PS.Start_Time, PS.End_Time, Datediff(mi, PS.Start_Time, PS.End_Time), NULL, NULL , PS.PU_Id, NULL, NULL, NULL,
          0, @EventName, PR.Prod_Desc, PS.Comment_Id, NULL, NULL, NULL, NULL, Start_Time, NULL, NULL
        From Production_Starts PS Inner Join Products PR on PR.Prod_Id = PS.Prod_Id
        Where PS.PU_Id In (Select PT.PUId From #PUET PT Where PT.ETId = @ET)
        And PS.Start_Time Between @Start And @End 
    End
---------------------------------------------------------------
-- Get UDE events for the PU/Period
---------------------------------------------------------------
  Select @ET =14
  If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
    Begin
      Insert Into #CurrEvents
        Select Convert(nvarchar(25),UDE_Id) + '/' + @ET, 
          UDE_Id, @ET, Coalesce(ES.Event_SubType_Desc, '') + ': ' + UDE_Desc,
          NULL, Start_Time, End_Time, Datediff(mi, Start_Time , End_Time), NULL, NULL , PU_Id,
          Coalesce(RTrim(RE.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE2.Event_Reason_Name), '')  + ' ' +
          Coalesce(RTrim(RE3.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE4.Event_Reason_Name), '') As Cause,
          Coalesce(RTrim(RE5.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE6.Event_Reason_Name), '')  + ' ' +
          Coalesce(RTrim(RE7.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE8.Event_Reason_Name), '') As Action, 
          NULL, UD.Event_SubType_Id, ES.Event_SubType_Desc, NULL, UD.Cause_comment_Id, NULL, NULL, NULL, NULL, Start_Time, ES.Icon_Id, UD.Ack
        From User_Defined_Events UD Left Outer Join Event_Subtypes ES On UD.Event_SubType_Id = ES.Event_SubType_Id 
        Left Outer Join Event_Reasons RE  On UD.Cause1 = RE.Event_Reason_Id
        Left Outer Join Event_Reasons RE2 On UD.Cause2 = RE2.Event_Reason_Id
        Left Outer Join Event_Reasons RE3 On UD.Cause3 = RE3.Event_Reason_Id
        Left Outer Join Event_Reasons RE4 On UD.Cause4 = RE4.Event_Reason_Id
        Left Outer Join Event_Reasons RE5 On UD.Action1 = RE5.Event_Reason_Id
        Left Outer Join Event_Reasons RE6 On UD.Action2 = RE6.Event_Reason_Id
        Left Outer Join Event_Reasons RE7 On UD.Action3 = RE7.Event_Reason_Id
        Left Outer Join Event_Reasons RE8 On UD.Action4 = RE8.Event_Reason_Id
        Where UD.PU_Id In (Select PUId From #PUET Where ETId = @ET)
        And Start_Time >= @Start 
        And (End_Time <= @End Or End_Time IS NULL)
    End 
---------------------------------------------------------------
-- Get Downtime for the PU/Period
---------------------------------------------------------------
  Select @ET = 2
  If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
    Begin
      Select @EventName =Coalesce(Et_Desc,'Downtime') From Event_Types Where Et_Id = @ET
      Insert Into #CurrEvents
        Select Convert(nvarchar(25),DE.TEDet_Id) + '/' + @ET, 
          DE.TEDet_Id, @ET, 
          SOE_Desc1 = @EventName + Case When DE.End_Time is NOT NULL Then 
            ' ' + Replace(Convert(nvarchar(10),Convert(Decimal(6,1),Datediff(s, DE.Start_Time , DE.End_Time)/Convert(real, 60))), '.', @DecimalSep) + ' minutes' Else '' End 
            + ' at ' + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
          Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
          Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
          Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End,
          NULL, DE.Start_Time, DE.End_Time, Convert(Decimal(6,1),Datediff(s, DE.Start_Time , DE.End_Time)/Convert(real, 60)), NULL, RE.Event_Reason_Name, DE.PU_Id,
          Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
          Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
          Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
          Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End as Cause,
          Case When RTrim(RE5.Event_Reason_Name) Is Not Null Then RTrim(RE5.Event_Reason_Name) Else '' End +
          Case When RTrim(RE6.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE6.Event_Reason_Name) Else '' End +
          Case When RTrim(RE7.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE7.Event_Reason_Name) Else '' End +
          Case When RTrim(RE8.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE8.Event_Reason_Name) Else '' End as Action, NULL, 0,@EventName, 
          NULL, DE.Cause_Comment_Id, NULL, NULL, NULL, NULL, DE.Start_Time, NULL, NULL
        From Timed_Event_Details DE 
        Join Prod_Units P on P.PU_Id = DE.PU_Id
        Left Outer Join Event_Reasons RE  On DE.Reason_Level1 = RE.Event_Reason_Id
        Left Outer Join Event_Reasons RE2 On DE.Reason_Level2 = RE2.Event_Reason_Id
        Left Outer Join Event_Reasons RE3 On DE.Reason_Level3 = RE3.Event_Reason_Id
        Left Outer Join Event_Reasons RE4 On DE.Reason_Level4 = RE4.Event_Reason_Id
        Left Outer Join Event_Reasons RE5 On DE.Action_Level1 = RE5.Event_Reason_Id
        Left Outer Join Event_Reasons RE6 On DE.Action_Level2 = RE6.Event_Reason_Id
        Left Outer Join Event_Reasons RE7 On DE.Action_Level3 = RE7.Event_Reason_Id
        Left Outer Join Event_Reasons RE8 On DE.Action_Level4 = RE8.Event_Reason_Id
        Where DE.PU_Id In (Select PUId From #PUET Where ETId = @ET)
        And DE.Start_Time >= @Start 
        And (DE.End_Time <= @End Or DE.End_Time IS NULL)
    End
---------------------------------------------------------------
-- Get Waste events for the PU/Period
---------------------------------------------------------------
  Select @ET = 3
  If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
    Begin
      Select @EventName =Coalesce(Et_Desc,'Waste') From Event_Types Where Et_Id = @ET
      Insert Into #CurrEvents
        Select Convert(nvarchar(25),WD.WED_Id)+ '/' + @ET, 
          WD.WED_Id, @ET, 
          SOE_Desc1 = @EventName + ' ' + Replace(RTrim(Convert(nvarchar(25), Convert(decimal(10,1), WD.Amount))), '.', @DecimalSep) + ' ' + Coalesce(M.Wemt_Name,'') + 
            ' at ' + + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
          Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
          Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
          Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End,
          NULL, Coalesce(E.TimeStamp, WD.TimeStamp), NULL, 0, WD.Event_Id, NULL, WD.PU_Id,
          Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
          Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
          Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
          Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End as Cause,
          Case When RTrim(RE5.Event_Reason_Name) Is Not Null Then RTrim(RE5.Event_Reason_Name) Else '' End +
          Case When RTrim(RE6.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE6.Event_Reason_Name) Else '' End +
          Case When RTrim(RE7.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE7.Event_Reason_Name) Else '' End +
          Case When RTrim(RE8.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE8.Event_Reason_Name) Else '' End as Action, 
          NULL, 0, @EventName, NULL,WD.Cause_Comment_Id, NULL, NULL, NULL, WD.TimeStamp, Coalesce(E.TimeStamp, WD.TimeStamp), NULL, NULL
        From Waste_Event_Details WD 
        Join Prod_Units P on P.PU_Id = WD.PU_Id
        Left Outer Join Events E on E.Event_Id = WD.Event_Id
        Left Outer Join Waste_Event_Meas M On WD.WEMT_Id = M.WEMT_Id
        Left Outer Join Event_Reasons RE  On WD.Reason_Level1 = RE.Event_Reason_Id
        Left Outer Join Event_Reasons RE2 On WD.Reason_Level2 = RE2.Event_Reason_Id
        Left Outer Join Event_Reasons RE3 On WD.Reason_Level3 = RE3.Event_Reason_Id
        Left Outer Join Event_Reasons RE4 On WD.Reason_Level4 = RE4.Event_Reason_Id
        Left Outer Join Event_Reasons RE5 On WD.Action_Level1 = RE5.Event_Reason_Id
        Left Outer Join Event_Reasons RE6 On WD.Action_Level2 = RE6.Event_Reason_Id
        Left Outer Join Event_Reasons RE7 On WD.Action_Level3 = RE7.Event_Reason_Id
        Left Outer Join Event_Reasons RE8 On WD.Action_Level4 = RE8.Event_Reason_Id
        Where WD.PU_Id In (Select PT.PUId From #PUET PT Where PT.ETId = @ET)
        And WD.Timestamp Between @Start And @End
    End
---------------------------------------------------------------
-- Get Alarm for the PU/Period
------------------------------------------------------------- 
  Select @ET = 11
  If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
    Begin
      Select @EventName =Coalesce(Et_Desc,'Alarm') From Event_Types Where Et_Id = @ET
      Insert Into #CurrEvents
        Select Convert(nvarchar(25), Alarm_Id) + '/' + @ET, 
          Alarm_Id, @ET, RTrim(Alarm_Desc) , NULL, Start_Time, End_Time,
          Datediff(mi, Start_Time, End_Time), AD.Var_Id, NULL, Source_PU_Id, 
          Coalesce(RTrim(RE.Event_Reason_Name),'') + ' ' + Coalesce(RTrim(RE2.Event_Reason_Name),'')  + ' ' +
          Coalesce(RTrim(RE3.Event_Reason_Name),'') + ' ' + Coalesce(RTrim(RE4.Event_Reason_Name),'') As Cause,
          Coalesce(RTrim(RE5.Event_Reason_Name),'') + ' ' + Coalesce(RTrim(RE6.Event_Reason_Name),'')  + ' ' +
          Coalesce(RTrim(RE7.Event_Reason_Name),'') + ' ' + Coalesce(RTrim(RE8.Event_Reason_Name),'') As Action, 
          AT.AP_Id, 0, @EventName, NULL, AL.Cause_Comment_Id, NULL, V.Group_Id, AT.AT_Id, NULL, Start_Time, NULL, AL.Ack
        From Alarms AL Inner Join Alarm_Template_Var_Data AD On AL.ATD_Id = AD.ATD_Id
        Inner Join Alarm_Templates AT On AD.AT_Id = AT.AT_Id
        Left Outer Join Variables V on AD.Var_Id = V.Var_Id
        Left Outer Join Event_Reasons RE  On AL.Cause1 = RE.Event_Reason_Id
        Left Outer Join Event_Reasons RE2 On AL.Cause2 = RE2.Event_Reason_Id
        Left Outer Join Event_Reasons RE3 On AL.Cause3 = RE3.Event_Reason_Id
        Left Outer Join Event_Reasons RE4 On AL.Cause4 = RE4.Event_Reason_Id
        Left Outer Join Event_Reasons RE5 On AL.Action1 = RE5.Event_Reason_Id
        Left Outer Join Event_Reasons RE6 On AL.Action2 = RE6.Event_Reason_Id
        Left Outer Join Event_Reasons RE7 On AL.Action3 = RE7.Event_Reason_Id
        Left Outer Join Event_Reasons RE8 On AL.Action4 = RE8.Event_Reason_Id
        Where Source_PU_Id In (Select PUId From #PUET Where ETId = @ET)
        And  Start_Time >= @Start 
        And (End_Time <= @End Or End_Time IS NULL)  
    End
/*
 If you have a grade running for one day and the SOE time interval is ST: today -3d and ET: today -2d: the SP was returning the current grade since PS.StartTime > ST and ET=NULL. To avoid this
problem I am deleting these records on the next statement
*/
  Delete From #CurrEvents 
  Where (Start_Time < @Start)
  Or (Start_Time > @End)
--Update the Priority for the Alarm Event type
 	 Declare PriorityCursor INSENSITIVE CURSOR For   
 	   Select Event_Id --Actually it's the Alarm_Id
 	   From #CurrEvents Where Type = 11
 	   For Read Only
 	   Open PriorityCursor  
 	 MyPriorityLoop1:
 	   Fetch Next From PriorityCursor Into @Alarm_ID
 	 
 	   If (@@Fetch_Status = 0)
 	     Begin
 	       exec spServer_AMgrGetAlarmPriority @Alarm_ID, @Priority output
 	       Update #CurrEvents Set PriorityId = @Priority Where Event_Id = @Alarm_ID and Type = 11
 	       Goto MyPriorityLoop1
 	     End
 	 Close PriorityCursor
 	 Deallocate PriorityCursor
--------------------------------------------------------------
-- Return new StartTime/EndTime
--------------------------------------------------------------
  Select @Start as StartTime, @End as EndTime
---------------------------------------------------------------
-- Return all kinds of events (resultset 2/2)
---------------------------------------------------------------
  Select SOE_Key, Event_Id, Type, SOE_Desc1, SOE_Desc2, Start_Time, End_Time, Duration, 
  Var_Id, Var_Desc, PU_Id, Cause, Action, PriorityId, Event_SubType_Id,  Event_SubType_Desc, 
  TipText, Cause_Comment_Id, Status, GroupId, AT_Id, Time_Stamp, Sort_Time, Icon_Id, Ack
  From #CurrEvents
  Order By Sort_Time Desc, Type Asc, SOE_Desc1 Asc
---------------------------------------------------------------
-- Drop Temporary tables
---------------------------------------------------------------
  Drop Table #Currevents
  Drop Table #PUET
  Return(1)
