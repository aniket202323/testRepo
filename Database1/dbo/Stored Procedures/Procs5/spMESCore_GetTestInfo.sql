﻿Create Procedure [dbo].[spMESCore_GetTestInfo] (
  @eventId int,
  @varId int,
  @eventTime DATETIME)  --@eventTime is input as UTC
AS
set @eventTime = dbo.fnServer_CmnConvertToDBTime(@eventTime,'UTC')

----------------------------------------------------------------------------
-- Get the info for the event
----------------------------------------------------------------------------
Declare @EventInfo table (eventType int, varId int, eventId int, EventTime datetime)
insert into @EventInfo (eventType, varId, eventId, EventTime)
  SELECT et.ET_Id as eventType, v.var_id as varId,
  COALESCE(evt.event_id,ted.TEDet_Id, wed.wed_id,segInfo.event_id, workRespInfo.event_id,ps.Start_id,ude.UDE_Id,pps.PP_Start_Id) as eventId,
  COALESCE(evt.TimeStamp,ted.End_Time,wed.TimeStamp,
   dbo.fnServer_CmnConvertToDBTime(segInfo.EndTime,'UTC'),   --UTC already
   dbo.fnServer_CmnConvertToDBTime(workRespInfo.EndTime,'UTC'), --UTC already
   DATEADD(second,-1,ps.End_Time),ude.End_Time,pps.End_Time,@eventTime) as eventTime
  from  Variables_Base v 
 JOIN Event_Types et on v.Event_Type=et.ET_Id
 LEFT JOIN Events evt on v.Event_Type=1 and evt.Event_Id=@eventId
 LEFT JOIN Timed_Event_Details ted on v.Event_Type=2 and ted.TEDet_Id=@eventId
 LEFT JOIN Waste_Event_Details wed  on v.Event_Type=3 and wed.WED_Id=@eventId
 LEFT JOIN Production_Starts ps on v.Event_Type=4 and ps.Start_Id=@eventId
 LEFT JOIN User_Defined_Events ude on v.Event_Type=14 and ude.UDE_Id=@eventId
 LEFT JOIN Production_Plan_Starts pps on v.Event_Type=19 and pps.PP_Start_Id=@eventId
 LEFT JOIN
   (select s95e.Event_Id, sr.EndTime from S95_Event s95e 
 	 JOIN SegmentResponse sr on sr.SegmentResponseId=s95e.S95_Guid and s95e.Event_Id=@eventId) segInfo on v.Event_Type=31
 LEFT JOIN
   (select s95e.Event_Id, wr.EndTime from S95_Event s95e 
 	 JOIN WorkResponse wr on wr.WorkResponseId=s95e.S95_Guid and s95e.Event_Id=@eventId) workRespInfo on v.Event_Type=32
 	 where v.Var_Id=@varId
--select * from @EventInfo

----------------------------------------------------------------------------
-- Get the comment counts for the tests on these vars and this event
----------------------------------------------------------------------------
Declare @CommentInfo table (TestId bigint, NComments int)
insert into @CommentInfo (TestId, NComments)
 	 Select t.Test_Id, COUNT(*) N_Comments
 	   from variables v
 	   JOIN @EventInfo EI on  EI.varId=v.Var_Id and (EI.eventId=@eventId or ei.EventTime=@eventTime )
 	   JOIN Tests t on t.Var_Id = v.Var_Id and (t.Event_Id = EI.eventId or t.Result_On = EI.EventTime)
 	   JOIN Comments c on c.Comment_Id = t.Comment_Id
 	   JOIN Comments c2 on c2.TopOfChain_Id = c.TopOfChain_Id
 	   where v.Var_Id=@varId
 	   group by t.Test_Id

--select * from @CommentInfo

----------------------------------------------------------------------------
-- Get the history counts for the tests on these vars and this event
----------------------------------------------------------------------------
Declare @HistInfo table (TestId bigint, NHist int)
insert into @HistInfo (TestId, NHist)
 	 Select t.Test_Id, COUNT(*) N_Hist
 	   from variables v
 	   JOIN @EventInfo EI on  EI.varId=v.Var_Id and (EI.eventId=@eventId or ei.EventTime=@eventTime )
 	   JOIN Tests t on t.Var_Id = v.Var_Id and (t.Event_Id = EI.eventId or t.Result_On = EI.EventTime)
 	   JOIN Test_History h on h.Test_Id = t.Test_Id
 	   where v.Var_Id=@varId
 	   group by t.Test_Id

--select * from @HistInfo

----------------------------------------------------------------------------
-- Get the SpecSetting Site Parameter
----------------------------------------------------------------------------
Declare @SpecSetting int
select @SpecSetting = convert(int, dbo.fnServer_CmnGetParameter(13, null, null, null, null))
if ((@SpecSetting is null) or (@SpecSetting < 1) or (@SpecSetting > 2)) select @SpecSetting = 2
----------------------------------------------------------------------------
-- Return the final results
----------------------------------------------------------------------------
select v.event_type EventTypeId,
 	    EI.eventId EventId,
 	    EI.varId VarID,
       DATEADD(millisecond,-DATEPART(millisecond,EI.EventTime),dbo.fnServer_CmnConvertFromDBTime(EI.EventTime,'UTC')) ResultOn,
 	    Prod_Lines.PL_Id ProductionLineId,
 	    Prod_Units.PU_Id ProductionUnitId,
 	    Products.Prod_Id ProductId,
 	    Production_Plan_Starts.PP_Id ProductionPlanId,
 	    Production_Plan_Starts.PP_Start_Id ProductionPlanStartId,
 	    Prod_Lines.PL_Desc ProductionLine,
 	    Prod_Units.PU_Desc ProductionUnit,
 	    v.Var_Desc Variable,
 	    Events.Event_Num  EventName,
 	    v.Test_Name TestName,
 	    Production_Plan.Process_Order ProcessOrder,
 	    Products.Prod_Code ProductCode,
 	    COALESCE(Active_Specs.L_Entry,Var_Specs.L_Entry) LEL,
 	    COALESCE(Active_Specs.L_Reject,Var_Specs.L_Reject) LRL,
 	    COALESCE(Active_Specs.L_User,Var_Specs.L_User) LUL,
 	    COALESCE(Active_Specs.L_Warning,Var_Specs.L_Warning) LWL,
 	    COALESCE(Active_Specs.U_Entry,Var_Specs.U_Entry) UEL,
 	    COALESCE(Active_Specs.U_Reject,Var_Specs.U_Reject) URL,
 	    COALESCE(Active_Specs.U_User,Var_Specs.U_User) UUL,
 	    COALESCE(Active_Specs.U_Warning,Var_Specs.U_Warning) UWL,
 	    COALESCE(Active_Specs.Target,Var_Specs.Target) TGT,
       COALESCE(ltrim(str(tsd.Mean - 3 * tsd.sigma,25,v.Var_Precision)),Active_Specs.L_Control,Var_Specs.L_Control) LCL,
       COALESCE(ltrim(str(tsd.Mean,25,v.Var_Precision)),                Active_Specs.T_Control,Var_Specs.T_Control) TCL,
       COALESCE(ltrim(str(tsd.Mean + 3 * tsd.sigma,25,v.Var_Precision)),Active_Specs.U_Control,Var_Specs.U_Control) UCL,
 	    v.ShouldArchive ShouldArchive,
 	    COALESCE(Active_Specs.Test_Freq,Var_Specs.Test_Freq) TestFrequency,
 	    event_types.et_desc EventType,
 	    ds.DS_Desc DataSourceDesc,
 	    ds.DS_Id DataSourceID,
 	    dt.Data_Type_Id DataTypeID,
 	    v.Eng_Units EngUnits,
 	    v.Var_Precision Precision,
 	    t.Result Result,
       v.PUG_Id VarGroupId,
       g.PUG_Desc VarGroup,
       g.PUG_Order GroupOrder,
       v.PUG_Order VarOrder,
       COALESCE(ci.NComments, 0) NComments,
       COALESCE(hi.NHist, 0) NHist,
       t.Signature_Id ESignatureId,
       v.Comment_Id CommentId,
       cm.Comment_Text Comment,
       case when v.String_Specification_Setting is null then 0 else v.String_Specification_Setting end StringSpecSetting,
       @SpecSetting SpecSetting,
       t.Locked Locked
  from Variables_Base v
  JOIN PU_Groups g on g.PUG_Id = v.PUG_Id
  JOIN Event_Types ON Event_Types.ET_Id = v.Event_Type
  JOIN @EventInfo EI on  EI.varId=v.Var_Id and (EI.eventId=@eventId or ei.EventTime=@eventTime )
  JOIN Data_Source ds on ds.DS_Id=v.DS_Id
  JOIN Data_Type DT on DT.Data_Type_Id= v.Data_Type_Id
  LEFT JOIN Tests t on t.Var_Id = v.Var_Id and (t.Event_Id = EI.eventId or t.Result_On = EI.EventTime)
  LEFT JOIN @CommentInfo ci on ci.TestId = t.Test_Id
  LEFT JOIN Comments cm on cm.Comment_Id = v.Comment_Id
  LEFT JOIN @HistInfo hi on hi.TestId = t.Test_Id
  LEFT JOIN Events ON v.Event_Type = 1 and Events.Event_Id = EI.eventId and Event_Types.ValidateTestData = 1
  LEFT JOIN S95_Event SegRespS95 ON SegRespS95.Event_Type = 31 and SegRespS95.Event_Id = EI.eventId and Event_Types.ValidateTestData = 1 and v.Event_Type = 31
  LEFT JOIN S95_Event WorkRespS95 ON WorkRespS95.Event_Type = 32 and WorkRespS95.Event_Id = EI.eventId  and Event_Types.ValidateTestData = 1 and v.Event_Type = 32
  JOIN Prod_Units ON prod_units.PU_Id = COALESCE(Events.PU_Id,dbo.fnServer_CmnGetSegRespUnit(SegRespS95.S95_Guid),dbo.fnServer_CmnGetWorkRespUnit(WorkRespS95.S95_Guid),v.PU_Id) AND prod_units.PU_Id <> 0
  LEFT JOIN Production_Starts ON Production_Starts.PU_Id = COALESCE(prod_units.Master_Unit,prod_units.PU_Id) 
 	 AND Production_Starts.Start_Time < EI.EventTime 
 	 AND (Production_Starts.End_Time >= EI.EventTime OR Production_Starts.End_Time IS NULL)
  LEFT JOIN Products ON Products.Prod_id = COALESCE(events.Applied_Product, Production_Starts.Prod_id)
  LEFT JOIN Var_Specs ON Var_Specs.Var_id = @VarId AND Var_Specs.Prod_id = Products.Prod_id 
 	 AND Var_Specs.Effective_Date <= EI.EventTime 
 	 AND (Var_Specs.Expiration_date > EI.EventTime OR Var_Specs.Expiration_date IS NULL)
  LEFT JOIN Active_Specs ON Active_Specs.Spec_id = v.Spec_Id AND Active_Specs.Char_id = COALESCE(SegRespS95.Char_Id,WorkRespS95.Char_Id) AND Active_Specs.Effective_Date <= EI.EventTime  AND (Active_Specs.Expiration_date > EI.EventTime OR Active_Specs.Expiration_date IS NULL)
  LEFT JOIN Test_Sigma_Data tsd on tsd.Test_Id = t.Test_Id 
  JOIN Prod_Lines ON prod_lines.PL_Id = prod_units.PL_Id AND prod_lines.PL_Id <> 0
  LEFT JOIN Production_Plan_Starts ON Production_Plan_Starts.PU_Id = COALESCE(prod_units.Master_Unit,prod_units.PU_Id) AND Production_Plan_Starts.Start_Time < EI.EventTime AND (Production_Plan_Starts.End_Time >= EI.EventTime OR Production_Plan_Starts.End_Time IS NULL)
  LEFT JOIN Production_Plan ON Production_Plan_Starts.PP_Id = Production_Plan.PP_Id
  where v.Var_Id=@varId