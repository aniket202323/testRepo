Create Procedure dbo.spSOE_SheetData
  @Sheet_Desc nvarchar(50),
  @Start Datetime = NULL,
  @End Datetime = NULL,
  @Direction int = NULL,
  @SourceEventType int = NULL,  
  @RetrieveSheetData int = NULL,
  @DecimalSep char(1) = '.'
  AS
  Select @DecimalSep = COALESCE(@DecimalSep,'.')
  DECLARE @Sheet_id int,
          @Sheet_Type int,
          @Sheet_Com_Id int,
          @SheetGroupId int,
          @SheetEventSubType int,
          @OrigSheetEventSubType int,
          @GroupId int,
          @Event_Type tinyint,
          @Interval smallint,
          @Offset smallint,
          @Initial_Count int,
          @Maximum_Count int,
          @RowsFound int,
          @MasterUnit int,
          @RCount int,
          @Expand int,
          @ET nvarchar(20), 
          @PR Int,
          @Reason nvarchar(50),
          @WasteSOEKey nvarchar(50), 
          @WasteSOEDesc nvarchar(150), 
          @WastePUId int,
       	   @WasteEventSubTypeId int,
       	   @WasteDimensionX nvarchar(50),
       	   @AlarmSubTypesApply int,
          @AlarmEventModels int,
          @EventName nvarchar(50),
          @RootCount int,
          @Event_Id int, 
          @Timestamp datetime, 
          @PU_Id int,
          @Prev_Timestamp datetime,
          @Alarm_Id int,
          @Priority int,
          @Filter nvarchar(100),
          @SQL nvarchar(2000)
----------------------------------------------------------------
-- Get general sheet information.
----------------------------------------------------------------
  Select @Sheet_Id = Sheet_Id,
         @Sheet_Type = Sheet_Type,
         @Event_Type = Event_Type,
         @Interval = Interval,
         @Offset = Offset,
         @Initial_Count =  Initial_Count,
         @Maximum_Count = Maximum_Count,
         @MasterUnit = Master_Unit,
         @Sheet_Com_Id = Comment_Id,
         @SheetGroupId  =  s.Sheet_Group_Id,
         @GroupId = Coalesce(s.Group_Id,sg.Group_Id),
         @Expand = 1 
  From Sheets s
  Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
  Where (Sheet_Desc = @Sheet_Desc)
---------------------------------------------------------------
-- Get Units that SOE should show data for this sheet
--------------------------------------------------------------
  Select @Sheet_Id as Sheet_Id
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
---------------------------------------------------------------------------
-- Get Initial EventSubType based on the sheet master_unit and event_type
---------------------------------------------------------------------------
-- Find an eventtype if the one that was supplied on the sheet was null or is not 
-- configured for the units being displayed on the SOE
  Select @SheetEventSubType = CONVERT(INT, Value) 
    From Sheet_Display_Options
    Where Sheet_Id = @Sheet_Id and Display_Option_id = 44 
  If @SheetEventSubType is null 
    BEGIN   
      If (@Event_Type Is Null) Or (@Event_Type = 0) 
      Select @Event_Type = Min(ETId) From #PUET
      Else
      If ((Select Count(*) From #PUET Where ETId = @Event_Type)=0)
        Select @Event_Type = Min(ETId) From #PUET
      Select @SheetEventSubType =Min(es.event_subtype_id) 
        From event_subtypes es 
        Inner Join event_configuration ec on ec.event_subtype_id = es.event_subtype_id
        Where ec.pu_id=@MasterUnit
        And es.et_id =@Event_Type
    END
---------------------------------------------------------------
-- Get Start and End Time interval
--------------------------------------------------------------
  IF (@End is NULL)  
    Select @End = dbo.fnServer_CmnGetDate(getUTCdate())
  IF (@Start is NULL)
    Select @Start = DATEADD(hour, -1 * @Initial_Count, @End) 
-------------------------------------------------------------
-- Create temporary tables
-------------------------------------------------------------
  CREATE TABLE #CurrEvents
  (
  SOE_Key nvarchar(50),
  Event_Id int,
  Type int,
  SOE_Desc1 nvarchar(1000),
  SOE_Desc2 nvarchar(1000) NULL, 
  Start_Time Datetime,
  End_Time Datetime NULL, 
  Duration Decimal(6,1) NULL, 
  Var_Id int NULL,
  DisplayDesc  nvarchar(1000) NULL,
  PU_Id int NULL,
  Cause nvarchar(1000) NULL,
  Action nvarchar(1000) NULL,
  PriorityId int NULL,
  Event_SubType_Id int NULL,
  Event_SubType_Desc nvarchar(50) NULL,
  TipText nvarchar(50) NULL,
  Cause_Comment_Id int NULL,
  Status int NULL,
  GroupId int NULL,
  AT_Id int NULL,
  Time_Stamp DateTime NULL,
  Sort_Time DateTime NULL,
  Icon_Id int NULL,
  Ack bit NULL
  )
---------------------------------------------------------------
-- Get turnup/batch events for the PU/Period  (Production Events)
---------------------------------------------------------------
  Select @ET = 1 
  If (@SourceEventType IS NULL) Or (@SourceEventType = @ET) 
    Begin
      If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
      Begin
        Insert Into #CurrEvents (SOE_Key,Event_Id ,Type ,SOE_Desc1,SOE_Desc2, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Start_Time,End_Time, Duration, Var_Id,DisplayDesc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PU_Id,Cause,Action,PriorityId,Event_SubType_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Event_SubType_Desc,TipText,Cause_Comment_Id,Status,GroupId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AT_Id,Time_Stamp,Sort_Time,Icon_Id,Ack)
          Select Convert(nvarchar(25), EV.event_Id) + '/' + @ET,EV.Event_Id, @ET, 
            Case When ES.Event_Subtype_Desc Is Not Null Then ES.Event_Subtype_Desc + ' ' + EV.Event_Num + ' (' + PS.ProdStatus_Desc + ')'  Else EV.Event_Num + ' (' + PS.ProdStatus_Desc + ')' End,
            '',
             EV.Start_Time, EV.TimeStamp,  0, NULL, NULL, 
             EV.PU_Id, NULL, NULL, NULL, EV.Event_SubType_Id,
             ES.Event_SubType_Desc,NULL, EV.Comment_Id, EV.Event_Status, NULL,
             NULL, NULL, EV.TimeStamp, NULL, NULL
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
            If @Prev_Timestamp is NULL
              Select @Prev_Timestamp = Max(TimeStamp) From Events Where TimeStamp < @Timestamp and PU_Id = @PU_Id
            Update #CurrEvents
            Set Start_Time = @Prev_Timestamp
            Where Event_Id = @Event_Id
            Goto STLoop
          End
        Close STCursor
        Deallocate STCursor
      End
    End  
---------------------------------------------------------------
-- Get Product change for the PU/Period
---------------------------------------------------------------
  Select @ET = 4 
  If (@SourceEventType IS NULL) Or (@SourceEventType = @ET) 
  Begin
    If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
      Begin
        Select @EventName =Coalesce(Et_Desc,'Product Change') From Event_Types Where Et_Id = @ET
        Insert Into #CurrEvents (SOE_Key,Event_Id ,Type ,SOE_Desc1,SOE_Desc2, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Start_Time,End_Time, Duration, Var_Id,DisplayDesc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PU_Id,Cause,Action,PriorityId,Event_SubType_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Event_SubType_Desc,TipText,Cause_Comment_Id,Status,GroupId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AT_Id,Time_Stamp,Sort_Time,Icon_Id,Ack)
          Select Convert(nvarchar(25), PS.Start_Id) + '/' + @ET,PS.Start_Id, @ET, @EventName + ' to ' + PR.Prod_Code, NULL, 
 	  	  	  	  	  	  	  	  	 PS.Start_Time, PS.End_Time,Datediff(mi, PS.Start_Time , PS.End_Time), NULL, NULL,
 	  	  	  	  	  	  	  	  	 PS.PU_Id, NULL, NULL, NULL,0,
 	  	  	  	  	  	  	  	  	 @EventName, PR.Prod_Desc, PS.Comment_Id, NULL, NULL,
 	  	  	  	  	  	  	  	  	 NULL, NULL, PS.Start_Time, NULL, NULL
          From Production_Starts PS 
          Join Products PR on PR.Prod_Id = PS.Prod_Id
          Where PS.PU_Id In (Select PT.PUId From #PUET PT Where PT.ETId = @ET)
          And PS.Start_Time Between @Start And @End 
      End
  End 
---------------------------------------------------------------
-- Get UDE events for the PU/Period
---------------------------------------------------------------
  Select @ET = 14 
  If (@SourceEventType IS NULL) Or (@SourceEventType = @ET) 
    Begin
      If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
        Begin
          Insert Into #CurrEvents (SOE_Key,Event_Id ,Type ,SOE_Desc1,SOE_Desc2, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Start_Time,End_Time, Duration, Var_Id,DisplayDesc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PU_Id,Cause,Action,PriorityId,Event_SubType_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Event_SubType_Desc,TipText,Cause_Comment_Id,Status,GroupId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AT_Id,Time_Stamp,Sort_Time,Icon_Id,Ack)
            Select Convert(nvarchar(25),UDE_Id) + '/' + @ET,UDE_Id, @ET, Coalesce(ES.Event_SubType_Desc, '') + ': ' + UDE_Desc,NULL, 
              Start_Time, End_Time, Datediff(mi, Start_Time, End_Time), NULL, NULL,
              PU_Id,
              Coalesce(RTrim(RE.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE2.Event_Reason_Name), '')  + ' ' +
              Coalesce(RTrim(RE3.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE4.Event_Reason_Name), '') As Cause,
              Coalesce(RTrim(RE5.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE6.Event_Reason_Name), '')  + ' ' +
              Coalesce(RTrim(RE7.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE8.Event_Reason_Name), '') As Action, NULL, 
              UD.Event_SubType_Id,
              ES.Event_SubType_Desc, NULL, UD.Cause_comment_Id, NULL, NULL,
              NULL, NULL, Start_Time, ES.Icon_Id, UD.Ack
            From User_Defined_Events UD 
            Left Outer Join Event_Subtypes ES On UD.Event_SubType_Id = ES.Event_SubType_Id 
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
    End 
---------------------------------------------------------------
-- Get Downtime for the PU/Period
---------------------------------------------------------------
  Select @ET = 2 
  If (@SourceEventType IS NULL) Or (@SourceEventType = @ET) 
    Begin
      If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
        Begin
          Select @EventName =Coalesce(Et_Desc,'Downtime') From Event_Types Where Et_Id = @ET
          Insert Into #CurrEvents (SOE_Key,Event_Id ,Type ,SOE_Desc1,SOE_Desc2, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Start_Time,End_Time, Duration, Var_Id,DisplayDesc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PU_Id,Cause,Action,PriorityId,Event_SubType_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Event_SubType_Desc,TipText,Cause_Comment_Id,Status,GroupId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AT_Id,Time_Stamp,Sort_Time,Icon_Id,Ack)
            Select Convert(nvarchar(25),DE.TEDet_Id) + '/' + @ET,DE.TEDet_Id, @ET,
 	  	  	  	  	  	  	  	 SOE_Desc1 = @EventName + Case When DE.End_Time is NOT NULL 
 	  	  	  	  	  	  	  	  	  	  	  	  	 Then ' ' + Replace(Convert(nvarchar(10), Convert(Decimal(6,1), Datediff(s, DE.Start_Time, DE.End_Time)/Convert(real, 60))), '.', @DecimalSep) + ' minutes' 
 	  	  	  	  	  	  	  	  	  	  	  	  	 Else '' End 
 	  	  	  	  	  	  	  	  	  	  	  	  	 + ' at ' + P.PU_Desc + ' for ' + Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
              Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
              Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
              Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End,NULL,
              DE.Start_Time, DE.End_Time, Convert(Decimal(6,1), Datediff(s, DE.Start_Time, DE.End_Time)/Convert(real, 60)),NULL, RE.Event_Reason_Name, 
              DE.PU_Id,
              Case When RTrim(RE.Event_Reason_Name) Is Not Null Then RTrim(RE.Event_Reason_Name) Else '' End +
              Case When RTrim(RE2.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE2.Event_Reason_Name) Else '' End +
              Case When RTrim(RE3.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE3.Event_Reason_Name) Else '' End +
              Case When RTrim(RE4.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE4.Event_Reason_Name) Else '' End as Cause,
              Case When RTrim(RE5.Event_Reason_Name) Is Not Null Then RTrim(RE5.Event_Reason_Name) Else '' End +
              Case When RTrim(RE6.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE6.Event_Reason_Name) Else '' End +
              Case When RTrim(RE7.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE7.Event_Reason_Name) Else '' End +
              Case When RTrim(RE8.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE8.Event_Reason_Name) Else '' End as Action, NULL, 0, 
              @EventName,NULL, DE.Cause_Comment_Id, NULL, NULL, 
              NULL, NULL, DE.Start_Time, NULL, NULL
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
    End 
---------------------------------------------------------------
-- Get Waste events for the PU/Period
---------------------------------------------------------------
  Select @ET = 3 
  If (@SourceEventType IS NULL) Or (@SourceEventType = @ET) 
    Begin
      If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
        Begin
          Select @EventName =Coalesce(Et_Desc,'Waste') From Event_Types Where Et_Id = @ET
          Insert Into #CurrEvents (SOE_Key,Event_Id ,Type ,SOE_Desc1,SOE_Desc2, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Start_Time,End_Time, Duration, Var_Id,DisplayDesc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PU_Id,Cause,Action,PriorityId,Event_SubType_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Event_SubType_Desc,TipText,Cause_Comment_Id,Status,GroupId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AT_Id,Time_Stamp,Sort_Time,Icon_Id,Ack)
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
              Case When RTrim(RE8.Event_Reason_Name) Is Not Null Then ', ' + RTrim(RE8.Event_Reason_Name) Else '' End as Action, NULL,
              0, @EventName, NULL,WD.Cause_Comment_Id, NULL, NULL, NULL, WD.TimeStamp, Coalesce(E.TimeStamp, WD.TimeStamp), NULL, NULL
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
    End
---------------------------------------------------------------
-- Get Alarm the PU/Period
---------------------------------------------------------------
  Select @ET = 11 
    If (@SourceEventType IS NULL) Or (@SourceEventType = @ET) 
      Begin
        If (Select IncludeOnSoe From Event_Types Where ET_Id = @ET) = 1
          Begin
            Select @EventName =Coalesce(Et_Desc,'Alarm') From Event_Types Where Et_Id = @ET
            Insert Into #CurrEvents (SOE_Key,Event_Id ,Type ,SOE_Desc1,SOE_Desc2, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Start_Time,End_Time, Duration, Var_Id,DisplayDesc,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PU_Id,Cause,Action,PriorityId,Event_SubType_Id,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Event_SubType_Desc,TipText,Cause_Comment_Id,Status,GroupId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AT_Id,Time_Stamp,Sort_Time,Icon_Id,Ack)
              Select Convert(nvarchar(25), Alarm_Id) + '/' + @ET + '/' + convert(nvarchar(10),Coalesce(AT.ESignature_Level,0)),
                Alarm_Id, @ET, RTrim(Alarm_Desc), NULL, Start_Time, End_Time,
                Datediff(mi, Start_Time, End_Time), AD.Var_Id, NULL, Source_PU_Id, 
                Coalesce(RTrim(RE.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE2.Event_Reason_Name), '')  + ' ' +
                Coalesce(RTrim(RE3.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE4.Event_Reason_Name), '') As Cause,
                Coalesce(RTrim(RE5.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE6.Event_Reason_Name), '')  + ' ' +
                Coalesce(RTrim(RE7.Event_Reason_Name), '') + ' ' + Coalesce(RTrim(RE8.Event_Reason_Name), '') As Action, 
                AT.AP_Id, 0, @EventName, 
                NULL, AL.Cause_Comment_Id, NULL, V.Group_Id, AT.AT_Id, NULL, Start_Time, NULL, AL.Ack
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
      End
/*
 If you have a grade running for one day and the SOE time interval is ST: today -3d and ET: today -2d: the SP was returning the current grade since PS.StartTime > ST and ET=NULL. To avoid this
problem I am deleting these records on the next statement
*/
  Delete From #CurrEvents 
  Where (Start_Time < @Start and Type <> 1)
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
---------------------------------------------------------------
-- Return PUIds that SOE should show for this Sheet
--------------------------------------------------------------
  If @Direction is null 
    Begin 
--  Filter out selected event types from the Display Option
      Select @Filter = NULL
      Select @Filter = Value from Sheet_Display_Options
        Where Sheet_Id = @Sheet_id and Display_Option_id = 382
      If @Filter is not NULL
        Begin
          Select @SQL = 'Update #PUET Set Selected = 0 where ETId not in (' + @Filter + ')'
          Execute (@SQL)
        End
      Select distinct PUId, PUDesc, GroupId,  EventSubTypeId, EventSubTypeDesc, ETid, DurationRequired, 
        CauseRequired, ActionRequired, ACKRequired, Selected, ATId
      From #PUET
      Order By PUId, EventSubTypeId
    End
---------------------------------------------------------------
-- Return Event Types when direction is null (resultset 1/4)
---------------------------------------------------------------
  If @Direction is null 
    Begin  -- Join sheet to sheet_event_types table to get selected events 
      Create Table #ET
      (
      ET_Id int NULL,
      ET_Desc nvarchar(50) NULL,
      Selected int NULL,
      Alarm int NULL,
      SubTypesApply int NULL,
      EventModels int NULL
      )
/*
 Alarms are special case. Although there is only one record on event_type, you have to handle each different 
 alarm priory level (low, medium, high) as a different event_type
*/
      Declare @AlarmEventDescription nvarchar(100)
      Select @AlarmEventDescription = Et_Desc From Event_Types Where ET_ID = 11
      If (Select IncludeOnSoe From Event_Types where ET_Id = 11) = 1
        Begin
          Insert Into #ET Values (11, @AlarmEventDescription + ' Low',1,1,0,0)
          Insert Into #ET Values (12, @AlarmEventDescription + ' Medium',1,1,0,0)
          Insert Into #ET Values (13, @AlarmEventDescription + ' High',1,1,0,0)
          Select @AlarmSubTypesApply = SubTypes_Apply,
            @AlarmEventModels = Event_Models
          From Event_Types 
          Where Event_Types.ET_Id = 11
          Update #ET  
          Set SubTypesApply = @AlarmSubTypesApply,
            EventModels = @AlarmEventModels
          Where Alarm=1
        End
      Insert Into #ET
        Select ET_Id, ET_Desc, 1, Case When ET_ID Between 11 And 13 Then 1 Else 0 End, SubTypes_Apply,  Event_Models
        From Event_Types
        Where Et_id<>11
        And IncludeOnSOE=1
--  Filter out selected event types from the Display Option
      Select @Filter = NULL
      Select @Filter = Value from Sheet_Display_Options
        Where Sheet_Id = @Sheet_id and Display_Option_id = 382
      If @Filter is not NULL
        Begin
          Select @SQL = 'Update #ET Set Selected = 0 where ET_Id not in (' + @Filter + ')'
          Execute (@SQL)
        End
      Select ET_Id, ET_Desc, Selected, Alarm, SubTypesApply,  EventModels from #ET oRDER BY et_ID  
      Drop table #ET
---------------------------------------------------------------
-- Return summary columns when direction is null (resultset 2/4)
---------------------------------------------------------------
      Create Table #Cols
      (
      Id tinyint, 
      Selected tinyint
      )
      Insert Into #Cols Select 1, 1
      Insert Into #Cols Select 2, 1
      Insert Into #Cols Select 3, 1
      Insert Into #Cols Select 4, 1
      Insert Into #Cols Select 5, 1
      Insert Into #Cols Select 6, 1
      Insert Into #Cols Select 7, 0
      Insert Into #Cols Select 8, 0
      Insert Into #Cols Select 9, 1 
      Insert Into #Cols Select 10, 1 -- cause 
      Insert Into #Cols Select 11, 1 -- action
      Insert Into #Cols Select 12, 1 -- cause comment
      Select * from #Cols
      Drop Table #Cols
---------------------------------------------------------------
-- Return Tree columns when direction is null (resultset 2/4)
---------------------------------------------------------------
-- SOE is using the tool.enable to determine if the tree column is visible 
-- instead the visible field on this temporary table
-- SOE only uses the width from this temp table if nothing was passed using the tool
      Create Table #TreeCols
      (
      VisibleToolName nvarchar(50), 	 
      WidthToolName nvarchar(50),
      HeaderName nvarchar(50),
      Visible  tinyint,
      Width int,
      IsUnit bit
      )
      Insert Into #TreeCols Select "TREEEVENTSVISIBLE", "TREEEVENTSWIDTH","Events",1, 170,0
      Insert Into #TreeCols Select "TREEUNITVISIBLE","TREEUNITWIDTH", "Unit",1, 90,1
      Insert Into #TreeCols Select "TREETIMESTAMPVISIBLE","TREETIMESTAMPWIDTH","TimeStamp" , 1,120,0
      Insert Into #TreeCols Select "TREESTARTTIMEVISIBLE", "TREESTARTTIMEWIDTH","Start Time",0, 120,0
      Insert Into #TreeCols Select "TREEENDTIMEVISIBLE", "TREEENDTIMEWIDTH","End Time",0, 120,0    
      Insert Into #TreeCols Select "TREEDURATIONVISIBLE", "TREEDURATIONWIDTH","Duration",1, 90,0
      Insert Into #TreeCols Select "TREECOMMENTVISIBLE","TREECOMMENTWIDTH","Comment" , 1,120,0
      Select * from #TreeCols
      Drop Table #TreeCols
-------------------------------------------------------------------
-- Return Icon info for Production Event
------------------------------------------------------------------
      Select ProdStatus_id, ProdStatus_Desc, Icon_Id, Color_Id
      From Production_Status
      Order by ProdStatus_Id
    End
---------------------------------------------------------------
-- ReturnSheet Data when direction is null Or RetrieveSheetData=1  (resultset 3/4)
---------------------------------------------------------------
  If @Direction is null  Or  @RetrieveSheetData=1
    Begin 
      -- If there are no root events, the tree won't show any events at all so 
      -- pick the lowest event type as the root 
      Select @RootCount = Count(*) 
      From #CurrEvents 
      Where Type = @SheetEventSubType
      If @RootCount = 0 
        BEGIN
          Select @OrigSheetEventSubType = @SheetEventSubType
          Select @SheetEventSubType = MIN(Type) 
          From #CurrEvents
        END
      Select RootEventType = @Event_Type, 
        RootEventSubType = @SheetEventSubType,
        OrigRootEventSubType = @OrigSheetEventSubType,
        StartTime = @Start,
        MasterUnit = @MasterUnit,
        EndTime =  @End,
        InitialCount = @Initial_Count,
        Interval = @Interval,
        MaxCount = @Maximum_Count, 
        RCount = COUNT(*),
        Comment_Id = @Sheet_Com_Id,
        SheetGroupId = @SheetGroupId,
        GroupId = @GroupId,
        Expand = @Expand
      From #CurrEvents
    End
---------------------------------------------------------------
-- Return all kinds of events (resultset 4/4)
---------------------------------------------------------------
  If @Direction = 0  Or (@Direction Is Null)
    Select SOE_Key, Event_Id, Type, SOE_Desc1, SOE_Desc2, Start_Time, End_Time, Duration, Var_Id, Var_Desc = DisplayDesc, 
      PU_Id, Cause, Action, PriorityId, Event_SubType_Id,  Event_SubType_Desc, TipText, Cause_Comment_Id,
      Status, GroupId, AT_Id, Time_Stamp, Sort_Time, Icon_Id, Ack
    From #CurrEvents
    Order By Sort_Time Desc, Type Asc, SOE_Desc1 Asc
  Else
    Select SOE_Key, Event_Id, Type, SOE_Desc1, SOE_Desc2, Start_Time, End_Time, Duration, Var_Id, Var_Desc = DisplayDesc,
      PU_Id, Cause, Action, PriorityId, Event_SubType_Id,  Event_SubType_Desc, TipText, Cause_Comment_Id,
      Status, GroupId, AT_Id, Time_Stamp, Sort_Time, Icon_Id, Ack
    From #CurrEvents
    Order By Sort_Time Asc, Type Desc, SOE_Desc1 Desc
  If @Direction is null  Or  @RetrieveSheetData=1
    Begin 
 	  	   Create Table #Display_Options (
 	  	     Display_Option_Id int, 
 	  	     Display_Option_Desc nvarchar(100),
 	  	     Value nvarchar(100)
 	  	     )
 	  	 
 	  	   Insert into #Display_Options (Display_Option_Id, Display_Option_Desc, Value)
      Select do.Display_Option_Id, do.Display_Option_Desc, sdo.Value
      From Sheet_Display_Options sdo
      Join Display_Options do on do.Display_Option_Id = sdo.Display_Option_Id
      Where sdo.Sheet_Id = @Sheet_id and COALESCE(sdo.Value, '') <> ''
 	  	 
 	  	   Insert into #Display_Options (Display_Option_Id, Display_Option_Desc, Value)
 	  	   Select stdo.Display_Option_Id, do.Display_Option_Desc, stdo.Display_Option_Default
 	  	     From Sheet_Type_Display_Options stdo
 	  	     Join Display_Options do on do.Display_Option_Id = stdo.Display_Option_Id
 	  	     Where stdo.Display_Option_Id not in (Select Display_Option_Id from #Display_Options)
 	  	       and stdo.Sheet_Type_Id = @Sheet_Type
 	  	       and stdo.Display_Option_Default is not NULL
 	  	 
 	  	   Select Display_Option_Desc, Value from #Display_Options order by Display_Option_Desc
   	  	 Drop Table #Display_Options
    End
---------------------------------------------------------------
-- Drop Temporary tables
---------------------------------------------------------------
  Drop Table #Currevents
  Drop Table #PUET
  Return(1)
