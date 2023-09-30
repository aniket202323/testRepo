Create Procedure dbo.spDS_GetAddDowntimeDetail
@DowntimeId int,
@RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @DetailStartTime datetime,
         @DetailPUId int,
         @DetailSequence int,
         @DetailPartialDuration real,
         @SummaryPUDesc nVarChar(30),
         @SummaryFaultName nVarChar(30),
         @SummaryStartTime datetime,
         @SummaryEndTime datetime,
         @SourcePUID int,
         @SourcePUDesc nVarChar(30),
         @MaxStartTime datetime,
         @TreeNameId int,
         @DowntimeEventType int,
       	  @CompareEndTime datetime,
        	  @CursorStartTime datetime,
       	  @CursorDuration real,
       	  @CursorTeDetid int,
       	  @CursorCounter int,
       	  @CursorTotalDuration real,
         @SQLCommand nVarChar(1024),
         @MinEndTime datetime
 Select @DetailPUId = NULL
 Select @DetailStartTime = NULL
 Select @DetailSequence = NULL
 Select @DetailPartialDuration = 0
 Select @SummaryPUDesc = NULL
 Select @SourcePUID = NULL
 Select @SourcePUDesc = NULL
 Select @SummaryStartTime = NULL
 Select @SUmmaryEndTime = NULL
 Select @SummaryFaultName = NULL
 Select @MaxStartTime = NULL
 Select @DowntimeEventType = 2
 Select @CursorCounter=0
 Select @CursorTotalDuration=0
 Select @MinEndTime = NULL
--------------------------------------------------------
-- Get basic downtime detail info
-------------------------------------------------------
 Select @DetailStartTime = Start_Time, @DetailPUID = PU_Id, @SourcePUID = Source_PU_Id
  From Timed_Event_Details
   Where TeDet_Id = @DowntimeID
--------------------------------------------------------
-- Get location of source Id
-------------------------------------------------------
 Select @SourcePUDesc = PU_Desc
  From Prod_Units 
   Where PU_Id = @SourcePUID
-------------------------------------------------------
-- Get downtime summary info
-------------------------------------------------------
 Select @MaxStartTime = Max(Start_Time)
   From Timed_Event_Details
   Where PU_Id = @DetailPUId and
         Start_Time <= @DetailStartTime and (End_Time >= @DetailStartTime or End_Time is NULL) and
         Start_Time NOT IN (select End_Time From Timed_Event_Details Where PU_Id = @DetailPUId and Start_Time <= @DetailStartTime and End_Time is NOT NULL)
 If @MaxStartTime is NULL
   Select @MaxStartTime = Min(Start_Time)
   From Timed_Event_Details
   Where PU_Id = @DetailPUId
 Select @SummaryPUDesc = PU.PU_Desc,@SummaryFaultName = FA.TEFault_Name, @SummaryStartTime=Start_Time
  From Timed_Event_Details D Left Outer Join Prod_Units PU on D.PU_Id = PU.PU_Id
                               Left Outer Join Timed_Event_Fault FA on D.TEFault_Id = FA.TEFault_Id
   Where D.PU_Id = @DetailPUId
    And D.Start_Time = @MaxStartTime
 Select @MinEndTime = Min(Start_Time)
   From Timed_Event_Details
   Where PU_Id = @DetailPUId and
         Start_Time >= @DetailStartTime and (End_Time >= @DetailStartTime or End_Time is NULL) and
         End_Time NOT IN (select Start_Time From Timed_Event_Details Where PU_Id = @DetailPUId and Start_Time >= @DetailStartTime and End_Time is NOT NULL)
 Select @SummaryEndTime=End_Time
  From Timed_Event_Details D
   Where D.PU_Id = @DetailPUId
    And D.Start_Time = @MinEndTime
 Select @DetailPUId as DetailPUId, @SummaryPUDesc as SummaryPUDesc, @SummaryFaultName as SummaryFaultName, 
        @SummaryStartTime as SummaryStartTime, @SummaryEndTime as SummaryEndTime, @SourcePUDesc as SourcePUDesc
--------------------------------------------------------------------------------
-- Get downtime detail sequence and total number of details for the summary info
--------------------------------------------------------------------------------
 Select @SQLCommand = "Declare Cursor1 INSENSITIVE CURSOR For "+
        "(Select Start_Time , datediff(minute, Start_Time, End_Time), TeDet_Id From Timed_Event_Details "  +
        "Where PU_Id = " + Convert(nVarChar(05),@DetailPUID) + " And Start_Time >= '" + 
        Convert(nVarChar(25),@SummaryStartTime,113) + "'"
 If (@SummaryEndTime Is Not Null)
  Select @SQLCommand = @SQLCommand +
        " And End_Time <= '" + Convert(nVarChar(25),@SummaryEndTime,113) + "'"
  Select @SQLCommand = @SQLCommand + ") For Read Only"
 -- select @sqlcommand
  Exec (@SQLCommand)
  Open Cursor1
 Loop1:
   Fetch Next From Cursor1 Into  @CursorStartTime, @CursorDuration, @CursorTeDetId
   If (@@Fetch_Status = 0)
   Begin
    If @CursorDuration Is Null Select @CursorDuration =0     
--    Select @cursortedetid
--    select @cursorduration
    Select @CursorCounter = @CursorCounter+1 
    Select @CursorTotalDuration = @CursorTotalDuration + @CursorDuration
    If @CursorStartTime = @DetailStartTime Select @DetailSequence = @CursorCounter 
    If @CursorStartTime <=@DetailStartTime 
     begin
 --     Select @cursortedetid
 --     select @cursorduration  	 
      Select @DetailPartialDuration =  @DetailPartialDuration + @CursorDuration
     end
    Goto Loop1
   End
  Close Cursor1
  Deallocate Cursor1
 Select @DetailSequence as DetailSequence, @CursorCounter as TotalDetailCounter, 
        @CursorTotalDuration as TotalDetailDuration,  @DetailPartialDuration as PartialDetailDuration
--------------------------------------------------------
-- Cause and Action Tree Ids
--------------------------------------------------------
 Select Name_Id as CauseTreeId, Action_Tree_Id As ActionTreeId , Research_Enabled as ResearchEnabled 
  From Prod_Events 
   Where PU_Id = Case When @SourcePUId is not NULL Then @SourcePUID Else @DetailPUId End
    And Event_Type=@DowntimeEventType
------------------------------------------------------------------------------
-- avaliable Locations (Units) for the PUId (combo box)
-----------------------------------------------------------------------------
 Select pu_desc as DetailLocation, PU_id as DetailId
  From Prod_units p
--  Join Prod_events e on e.pu_id = p.pu_id and Event_Type = 2
  Where ((Master_Unit = @DetailPUId) or
         (p.Pu_Id = @DetailPUId)) -- and
--         Timed_Event_Association > 0 and
--         Timed_Event_Association is not null
------------------------------------------------------------------------------
-- avaliable Status for the PUId (combo box)
-----------------------------------------------------------------------------
 Select TEStatus_Id as StatusId, TEStatus_Name as StatusName
  From Timed_Event_Status
   Where PU_Id = @DetailPUId
    Order by TeStatus_Name
------------------------------------------------------------------------------
-- avaiable Faults for the PUId (combo box)
-----------------------------------------------------------------------------
 Select TEFault_Id as FaultId, TEFault_Name as FaultName
  From Timed_Event_Fault
   Where PU_Id = @DetailPUId
    Order by TeFault_Name
------------------------------------------------------------------------------
-- Downtime detail info
-----------------------------------------------------------------------------
 Select DE.Start_Time as DetailStartTime, DE.End_Time as DetailEndTime, datediff(minute, de.start_time , de.end_time) as DetailDuration, 
        ST.TEStatus_Id as DetailStatusId, ST.TEStatus_Name as DetailStatusName,
        FA.TEFault_Id as DetailFaultId, FA.TEFault_Name as DetailFaultName, DE.Source_PU_Id as DetailSourcePUId,
        DE.Reason_Level1 as ReasonLevel1, DE.Reason_Level2 as ReasonLevel2, 
        DE.Reason_Level3 as ReasonLevel3, DE.Reason_Level4 as ReasonLevel4,
        DE.Cause_Comment_Id as ReasonCommentId,  
        DE.Action_Level1 as ActionLevel1, DE.Action_Level2 as ActionLevel2, 
        DE.Action_Level3 as ActionLevel3, DE.Action_Level4 as ActionLevel4,
        DE.Action_Comment_Id as ActionCommentId,  
        DE.Research_User_Id as ResearchUserId, US.UserName as ResearchUserName,
        DE.Research_Status_Id as ResearchStatusId, RS.Research_Status_Desc as ResearchStatusDesc,
        DE.Research_Open_Date as ResearchOpenDate, DE.Research_Close_Date as ResearchCloseDate,
        DE.Research_Comment_Id as ResearchCommentId, PU.PU_Desc as DetailSourceDesc, EC.ESignature_Level
   From Timed_Event_Details DE Left Outer Join Timed_Event_Status ST on DE.TEStatus_Id = ST.TEStatus_Id
                               Left Outer Join Timed_Event_Fault FA on DE.TEFault_Id = FA.TEFault_Id
                               Left Outer Join Users US on DE.Research_User_Id = US.User_Id
                               Left Outer Join Research_Status RS on DE.Research_Status_Id = RS.Research_Status_Id
                               Left Outer Join Prod_Units PU on DE.Source_PU_Id = PU.PU_Id
                               Left Outer Join Event_Configuration EC on EC.PU_Id = DE.PU_Id and EC.ET_Id = 2 and EC.Is_Active = 1
    Where DE.TEDet_Id = @DowntimeId
-------------------------------------------------------------------------------
-- History
-------------------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (16373,1)
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,2)
 	 Insert into @CHT(HeaderTag,Idx) Values (16333,3)
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,4)
 	 Insert into @CHT(HeaderTag,Idx) Values (16305,5)
 	 Insert into @CHT(HeaderTag,Idx) Values (16345,6)
 	 Insert into @CHT(HeaderTag,Idx) Values (16284,7)
 	 Insert into @CHT(HeaderTag,Idx) Values (16285,8)
 	 Insert into @CHT(HeaderTag,Idx) Values (16408,9)
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 SELECT 	 [Location] = pu.PU_Desc,
 	  	  	 [Start Time] = te.Start_Time, 
 	  	  	 [End Time] = te.End_Time, 
 	  	  	 [Status] = ts.TEStatus_Name,
 	  	  	 [Fault] =  tf.TEFault_Name, 
 	  	  	 [User] = u.Username,
 	  	  	 [Cause] = Case When te.Reason_Level4 is not null THEN
 	  	  	  	  	  	  	  	 er1.Event_Reason_Name + ',' + er2.Event_Reason_Name + ',' + er3.Event_Reason_Name + ',' + er4.Event_Reason_Name 
 	  	  	  	  	  	  	   When te.Reason_Level3 is not null THEN
 	  	  	  	  	  	  	  	 er1.Event_Reason_Name + ',' + er2.Event_Reason_Name + ',' + er3.Event_Reason_Name 
 	  	  	  	  	  	  	   When te.Reason_Level2 is not null THEN
 	  	  	  	  	  	  	  	 er1.Event_Reason_Name + ',' + er2.Event_Reason_Name 
 	  	  	  	  	  	  	   When te.Reason_Level1 is not null THEN
 	  	  	  	  	  	  	  	 er1.Event_Reason_Name 
 	  	  	  	  	  	  	   ELSE ''
 	  	  	  	  	  	  	   END,
 	  	  	 [Action] = Case When te.Action_Level4 is not null THEN
 	  	  	  	  	  	  	  	 er5.Event_Reason_Name + ',' + er6.Event_Reason_Name + ',' + er7.Event_Reason_Name + ',' + er8.Event_Reason_Name 
 	  	  	  	  	  	  	   When te.Action_Level3 is not null THEN
 	  	  	  	  	  	  	  	 er5.Event_Reason_Name + ',' + er6.Event_Reason_Name + ',' + er7.Event_Reason_Name 
 	  	  	  	  	  	  	   When te.Action_Level2 is not null THEN
 	  	  	  	  	  	  	  	 er5.Event_Reason_Name + ',' + er6.Event_Reason_Name 
 	  	  	  	  	  	  	   When te.Action_Level1 is not null THEN
 	  	  	  	  	  	  	  	 er6.Event_Reason_Name 
 	  	  	  	  	  	  	   ELSE ''
 	  	  	  	  	  	  	   END,
 	  	  	  [Approver] = u2.UserName
 	  	 From Timed_Event_Detail_History te
 	  	   Left Join Prod_Units pu on pu.PU_id = te.Source_PU_Id
 	  	   Left Join Timed_Event_Status ts on ts.TEStatus_Id = te.TEStatus_Id
 	  	   Left Join Timed_Event_Fault tf on tf.TEFault_Id = te.TEFault_Id
 	  	   Left Join ESignature es on es.Signature_Id = te.Signature_Id
 	  	   Left Join Users u2 on es.Verify_User_Id = u2.User_Id
 	  	   Join Users u on u.User_Id = te.User_Id
 	  	   Left Join Event_Reasons er1 on er1.Event_Reason_Id = te.Reason_Level1 
 	  	   Left Join Event_Reasons er2 on er2.Event_Reason_Id = te.Reason_Level2
 	  	   Left Join Event_Reasons er3 on er3.Event_Reason_Id = te.Reason_Level3
 	  	   Left Join Event_Reasons er4 on er4.Event_Reason_Id = te.Reason_Level4 
 	  	   Left Join Event_Reasons er5 on er5.Event_Reason_Id = te.Action_Level1 
 	  	   Left Join Event_Reasons er6 on er5.Event_Reason_Id = te.Action_Level2 
 	  	   Left Join Event_Reasons er7 on er5.Event_Reason_Id = te.Action_Level3 
 	  	   Left Join Event_Reasons er8 on er5.Event_Reason_Id = te.Action_Level4 
 	  	   Where TEDet_Id = @DowntimeId
 	  	  	 order by Modified_On Desc
END
ELSE
BEGIN
  Select pu.PU_Desc as Location, te.Start_Time, te.End_Time, ts.TEStatus_Name as Status, 
 	  	 tf.TEFault_Name as Fault, u.Username,
        te.Reason_Level1 as ReasonLevel1, te.Reason_Level2 as ReasonLevel2, 
        te.Reason_Level3 as ReasonLevel3, te.Reason_Level4 as ReasonLevel4,
        te.Action_Level1 as ActionLevel1, te.Action_Level2 as ActionLevel2, 
        te.Action_Level3 as ActionLevel3, te.Action_Level4 as ActionLevel4,
        erd.Tree_Name_Id, u2.UserName as ApproverName, pe.Action_Tree_Id as ActionTreeId
    From Timed_Event_Detail_History te
      Left outer Join Prod_Units pu on pu.PU_id = te.Source_PU_Id
      Left outer Join Timed_Event_Status ts on ts.TEStatus_Id = te.TEStatus_Id
      Left outer Join Timed_Event_Fault tf on tf.TEFault_Id = te.TEFault_Id
      Left outer Join Event_Reason_Tree_Data erd on erd.Event_Reason_Tree_Data_Id = te.Event_Reason_Tree_Data_Id
      Left outer Join ESignature es on es.Signature_Id = te.Signature_Id
      Left outer Join Users u2 on es.Verify_User_Id = u2.User_Id
      Join Users u on u.User_Id = te.User_Id
      Join Prod_Events pe on pe.PU_Id = pu.pu_Id and pe.event_type = 2
      Where TEDet_Id = @DowntimeId
        order by Modified_On Desc
END
