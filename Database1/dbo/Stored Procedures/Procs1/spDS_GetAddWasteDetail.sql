Create Procedure dbo.spDS_GetAddWasteDetail
@WId int,
@RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @PUId int,
         @EventId int,
         @Amount real,
         @TimeStamp datetime,
         @EventSubTypeId int,
         @EventSubTypeDesc nVarChar(50),
         @EventTimeStamp datetime,
         @WasteSequence int,
         @WasteEventType int,
         @NoDimension nVarChar(50),
         @NoEventSubTypeDesc nVarChar(50),
         @PartialWasteAmount real,
         @EventNum nVarChar(25),
         @WEMTId int,
         @WetId int,
         @SourcePUId int,
         @SourcePUDesc nVarChar(50),
         @EventPUId int,
         @ReasonLevel1 int,
   	  @ReasonLevel2 int,
         @ReasonLevel3 int,
         @ReasonLevel4 int,
 	  @ActionLevel1 int,
   	  @ActionLevel2 int,
         @ActionLevel3 int,
         @ActionLevel4 int,
         @CauseCommentId int,
         @ActionCommentId int,
         @ResearchUserId int,
 	  	  @ResearchStatusId int,
 	  	  @ResearchOpenDate datetime,
         @ResearchCloseDate datetime,
         @ResearchCommentId int,
         @ESignatureLevel int,
         @FaultId int,
         @DetailsExist bit,
 	  	  @EventET      DateTime
 Select @PUId = NULL
 Select @EventId = NULL
 Select @EventNum = NULL
 Select @EventSubTypeId = NULL
 Select @EventSubTypeDesc = NULL
 Select @EventTimeStamp = NULL
 Select @Amount = NULL
 Select @TimeStamp = NULL
 Select @WasteSequence = NULL
 Select @WasteEventType = 3
 Select @NoDimension = ''
 Select @NoEventSubTypeDesc = ''
 Select @PartialWasteAmount= NULL
 Select @WEMTId = NULL
 Select @WetId = NULL
 Select @SourcePUId = NULL
 Select @SourcePUDesc = NULL
 Select @ReasonLevel1 = NULL
 Select @ReasonLevel2 = NULL
 Select @ReasonLevel3 = NULL
 Select @ReasonLevel4 = NULL
 Select @ActionLevel1 = NULL
 Select @ActionLevel2 = NULL
 Select @ActionLevel3 = NULL
 Select @ActionLevel4 = NULL
 Select @CauseCommentId = NULL
 Select @ActionCommentId = NULL
 Select @ResearchUserId = NULL
 Select 	 @ResearchStatusId = NULL
 Select 	 @ResearchOpenDate = NULL
 Select @ResearchCloseDate = NULL
 Select @ResearchCommentId = NULL
 Select @EventPUId = NULL
 Select @ESignatureLevel = NULL
 Select @FaultId = NULL
 Select @DetailsExist = 0
-----------------------------------------------------
-- Get waste detail info
-------------------------------------------------------
 Select @PUId = WD.PU_Id, @EventId = WD.Event_Id, @Amount = WD.Amount, @TimeStamp = WD.TimeStamp, 
        @EventSubTypeId = EV.Event_SubType_Id, @EventNum= EV.Event_Num, @WEMTId=WD.WEMT_Id, @WetId=WD.Wet_Id,
        @SourcePUId=WD.Source_PU_Id, @ReasonLevel1 = WD.Reason_Level1, @ReasonLevel2 = WD.Reason_Level2,
        @ReasonLevel3 = WD.Reason_Level3, @ReasonLevel4 = WD.Reason_Level4, 
        @ActionLevel1 = WD.Action_Level1, @ActionLevel2 = WD.Action_Level2,
        @ActionLevel3 = WD.Action_Level3, @ActionLevel4 = WD.Action_Level4,
 	  	 @CauseCommentId = WD.Cause_Comment_Id, @ActionCommentId = WD.Action_Comment_Id,
        @ResearchUserId = WD.Research_User_Id, @ResearchStatusId= WD.Research_Status_Id, 
        @ResearchOpenDate = WD.Research_Open_Date, @ResearchCloseDate = WD.Research_Close_Date,
        @ResearchCommentId = WD.Research_Comment_Id,
        @EventPUId = EV.PU_Id, @EventTimeStamp = EV.Start_Time, @ESignatureLevel = EC.ESignature_Level,
        @FaultId = WD.WEFault_Id,@EventET = EV.Timestamp
  From Waste_Event_Details WD 
    Left Outer Join Events EV On WD.Event_Id = EV.Event_Id
    Left Outer Join Event_Configuration EC on EC.EC_Id = WD.EC_Id
   Where WED_Id = @WID
If (@EventId Is Not Null) 
BEGIN
 	 If @EventTimeStamp Is null
 	 BEGIN
 	  	 SELECT @EventTimeStamp = Max(timestamp) from Events where PU_Id = @EventPUId and timestamp < @EventET
 	  	 Select @EventTimeStamp = Coalesce(@EventTimeStamp,@EventET)
 	 END
END
If (@ESignatureLevel is Null)
  Select @ESignatureLevel = ESignature_Level from Event_Configuration Where PU_Id = @PUId and ET_Id = 3
----------------------------------------------------------------------------------------
-- For event-based waste, try to locate the single event-subtype for ET=1 for the PUId
--------------------------------------------------------------------------------------
 If (@EventId Is Not Null) And (@EventSubTypeId Is Null)
  Begin
   Select @EventSubTypeId =Min(ES.Event_Subtype_Id) 
    From Event_Subtypes ES 
     Inner Join Event_Configuration EC on EC.Event_Subtype_Id = ES.Event_Subtype_id
      Where EC.PU_ID=@EventPUId
       And ES.ET_id =1
   End
-----------------------------------------------
-- get event subtype desc
-----------------------------------------------
   If (@EventSubTypeId Is Not Null)
    Select @EventSubTypeDesc = Event_SubType_Desc 
     From Event_SubTypes 
      Where Event_SubType_Id = @EventSubTypeId 
--------------------------------------------------------
-- Cause and Action Tree Ids
--------------------------------------------------------
 Select Name_Id as CauseTreeId, Action_Tree_Id As ActionTreeId, Research_Enabled as ResearchEnabled 
  From Prod_Events 
   Where PU_Id = Case When @SourcePUId is not NULL Then @SourcePUID Else @PUId End
    And Event_Type=@WasteEventType
------------------------------------------------------------------------------
-- avaliable Locations (Units) for the PUId (combo box)
-----------------------------------------------------------------------------
 Select pu_desc as PUDesc, PU_id as PUDesc_Id
  From Prod_units p
  Where ((Master_Unit = @PUId) or
         (p.Pu_Id = @PUId)) 
------------------------------------------------------------------
-- Waste measurement combo box
-------------------------------------------------------------------
 Select WEMT_Id as WemtId, WEMT_Name as WemtDesc, Conversion as Conversion
  From Waste_Event_Meas
   Where PU_Id = @PUId
    Order By WEMT_Name
--------------------------------------------------------------------
-- Dimension headers
--------------------------------------------------------------------
 If (@EventSubTypeId IS NULL)
  Select @NoDImension as DimensionXName,  @NoDImension as DimensionYName, @NoDImension as DimensionZName, @NoDimension as DimensionXEngUnits
 Else
  Select Dimension_X_Name as DimensionXName, Dimension_Y_Name as DimensionYName, Dimension_Z_Name as DimensionZName, Dimension_X_Eng_Units as DimensionXEngUnits
    From Event_SubTypes
     Where Event_Subtype_Id =  @EventSubTypeId
-----------------------------------------------------------------------------
-- Initial_Dimension_X, FInal_Dimension_X, Y and Z and Prod_Code
-----------------------------------------------------------------------------
 If (@EventId Is NULL)
   Select wed.Dimension_X as DimensionX, wed.Dimension_Y as DimensionY, wed.Dimension_Z as DimensionZ, wed.Dimension_A as DimensionA, 
         wed.Start_Coordinate_X as StartCoordinateX, wed.Start_Coordinate_Y as StartCoordinateY, 
         wed.Start_Coordinate_Z as StartCoordinateZ, wed.Start_Coordinate_A as StartCoordinateA,
         Null as EventInitialDimensionX, Null as EventInitialDimensionY,
         Null as EventInitialDimensionZ, Null as EventInitialDimensionA,
         Null as EventFinalDimensionX, Null as EventFinalDimensionY,
         Null as EventFinalDimensionZ, Null as EventFinalDimensionA
    From Waste_Event_Details wed
     Where wed.wed_Id = @WId
 Else
   Select wed.Dimension_X as DimensionX, wed.Dimension_Y as DimensionY, wed.Dimension_Z as DimensionZ, wed.Dimension_A as DimensionA, 
           wed.Start_Coordinate_X as StartCoordinateX, wed.Start_Coordinate_Y as StartCoordinateY, 
           wed.Start_Coordinate_Z as StartCoordinateZ, wed.Start_Coordinate_A as StartCoordinateA,
           ed.Initial_Dimension_X as InitialDimensionX, ed.Final_Dimension_X as FinalDimensionX, 
           ed.Initial_Dimension_Y as InitialDimensionY, ed.Final_Dimension_Y as FinalDimensionY, 
           ed.Initial_Dimension_Z as InitialDimensionZ, ed.Final_Dimension_Z as FinalDimensionZ,
           ed.Initial_Dimension_A as InitialDimensionA, ed.Final_Dimension_A as FinalDimensionA
      From Waste_Event_Details wed
       Join Event_Details ed on ed.Event_Id = @EventId
       Where wed.wed_Id = @WId
----------------------------------------------------------------------------
-- ProdCode
-----------------------------------------------------------------------------
 If (@EventId Is Null)
  Select Null as ProdCode
 Else
  Select PR.Prod_Code as ProdCode
   From Events EV Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
                    And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp <= PS.End_Time Or PS.End_Time IS NULL)
                  Inner Join Products PR on PS.Prod_Id = PR.Prod_Id 
    Where EV.Event_Id = @EventId
If (@EventId Is Not NULL)
  Select @DetailsExist = Count(*) from Event_Details where Event_Id = @EventId
-----------------------------------------------------------------------------
-- source PU_Id Desc
------------------------------------------------------------------------------      
 Select @SourcePUDesc = PU_Desc
  From Prod_Units
    Where PU_id = Case When @SourcePUId is not NULL Then @SourcePUID Else @PUId End
------------------------------------------------------------------------------
-- detail info
-----------------------------------------------------------------------------
 Select @PUId as PUId, PU.PU_Desc as PUDesc, @TimeStamp as TimeStamp, 
        @EventSubTypeDesc as EventSubTypeDesc, @EventNum as EventNum, 
        @Amount as WasteAmount, @WEMTId as WasteMeasurementId, 
        WM.WEMT_Name as WasteMeasurementDesc, @WetId as WasteTypeId, 
        WT.Wet_Name as WasteTypeDesc, @EventId as EventId, @SourcePUId as SourcePUId,
        @ReasonLevel1 as CauseLevel1, @ReasonLevel2 as CauseLevel2,
        @ReasonLevel3 as CauseLevel3, @ReasonLevel4 as CauseLevel4,
        @CauseCommentId as CauseCommentId,  
        @ActionLevel1 as ActionLevel1, @ActionLevel2 as ActionLevel2,
        @ActionLevel3 as ActionLevel3, @ActionLevel4 as ActionLevel4,  
        @ActionCommentId as ActionCommentId, 
        @ResearchUserId as ResearchUserId, US.UserName as ResearchUserName,
        @ResearchStatusId as ResearchStatusId, RS.Research_Status_Desc as ResearchStatusDesc,
        @ResearchOpenDate as ResearchOpenDate, @ResearchCloseDate as ResearchCloseDate,
        @ResearchCommentId as ResearchCommentId, @EventTimeStamp as EventTimeStamp, @SourcePUDesc as SourcePUDesc,
        @ESignatureLevel as ESignature_Level, @FaultId as FaultId, @DetailsExist as DetailsExist
  From Prod_Units PU 
   Left Outer Join Waste_Event_Meas WM on WM.WEMT_Id=@WEMTId
   Left Outer Join Waste_Event_Type WT on WT.WET_Id = @WETId
   Left Outer Join Users US on @ResearchUserId = US.User_Id
   Left Outer Join Research_Status RS on @ResearchStatusId = RS.Research_Status_Id
    Where PU.PU_Id = @PUID
--------------------------------------------------------------------
--  1 Of 2 totalizing xxxx pounds
---------------------------------------------------------------------
 If @EventId Is NULL
  Select  @NoEventSubTypeDesc , 1 as WasteSequence ,1 as  TotalWasteCounter , @Amount as PartialWasteAmount
 Else
  Begin
   Create table #Waste (
    Counter int IDENTITY (1, 1) NOT NULL ,
    TimeStamp datetime ,
    Amount real )
   Insert Into #Waste
    Select TimeStamp, Amount
     From Waste_Event_Details 
      Where Event_Id = @EventId
   Select @WasteSequence = Counter 
   From #Waste
    Where TimeStamp = @TimeStamp
   Select @PartialWasteAmount = Sum(Amount) From #Waste Where Counter <=@WasteSequence
   Select @WasteSequence as WasteSequence, Count(Counter) as  TotalWasteCounter,  @PartialWasteAmount as  PartialWasteAmount --  Sum(Amount) as TotalWasteAmount
    From #Waste
   Drop Table #Waste
  End
--------------------------------------------------------------------
--  History
---------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Timestamp')
 	 Insert into @CHT(HeaderTag,Idx) Values (16334,1) -- Event Number
 	 Insert into @CHT(HeaderTag,Idx) Values (16373,2) -- Location
 	 Insert into @CHT(HeaderTag,Idx) Values (16335,3) -- TimeStamp
 	 Insert into @CHT(HeaderTag,Idx) Values (16478,4) -- Amount
 	 Insert into @CHT(HeaderTag,Idx) Values (16479,5) -- Measurement
 	 Insert into @CHT(HeaderTag,Idx) Values (16480,6) -- Waste Type
 	 Insert into @CHT(HeaderTag,Idx) Values (16345,7) -- User
 	 Insert into @CHT(HeaderTag,Idx) Values (16284,8) -- Cause
 	 Insert into @CHT(HeaderTag,Idx) Values (16285,9) -- Action
 	 Insert into @CHT(HeaderTag,Idx) Values (16408,10) --Approver
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Event Number] = e.Event_Num,
 	  	  	 [Location] = pu.PU_Desc,
 	  	  	 [TimeStamp] = wh.Timestamp,
 	  	  	 [Amount] = wh.Amount,
 	  	  	 [Measurement] = wm.wemt_name,
 	  	  	 [Waste Type] = we.WET_Name,
 	  	  	 [User] = u.Username,
 	  	  	 [Cause] = Case When wh.Reason_Level4 is not null THEN
 	  	  	  	  	  	  	 er1.Event_Reason_Name + ',' + er2.Event_Reason_Name + ',' + er3.Event_Reason_Name + ',' + er4.Event_Reason_Name 
 	  	  	  	  	  	   When wh.Reason_Level3 is not null THEN
 	  	  	  	  	  	  	 er1.Event_Reason_Name + ',' + er2.Event_Reason_Name + ',' + er3.Event_Reason_Name 
 	  	  	  	  	  	   When wh.Reason_Level2 is not null THEN
 	  	  	  	  	  	  	 er1.Event_Reason_Name + ',' + er2.Event_Reason_Name 
 	  	  	  	  	  	   When wh.Reason_Level1 is not null THEN
 	  	  	  	  	  	  	 er1.Event_Reason_Name 
 	  	  	  	  	  	   ELSE 'N/A'
 	  	  	  	  	  	   END,
 	  	  	 [Action] = Case When wh.Action_Level4 is not null THEN
 	  	  	  	  	  	  	 er5.Event_Reason_Name + ',' + er6.Event_Reason_Name + ',' + er7.Event_Reason_Name + ',' + er8.Event_Reason_Name 
 	  	  	  	  	  	   When wh.Action_Level3 is not null THEN
 	  	  	  	  	  	  	 er5.Event_Reason_Name + ',' + er6.Event_Reason_Name + ',' + er7.Event_Reason_Name 
 	  	  	  	  	  	   When wh.Action_Level2 is not null THEN
 	  	  	  	  	  	  	 er5.Event_Reason_Name + ',' + er6.Event_Reason_Name 
 	  	  	  	  	  	   When wh.Action_Level1 is not null THEN
 	  	  	  	  	  	  	 er6.Event_Reason_Name 
 	  	  	  	  	  	   ELSE 'N/A'
 	  	  	  	  	  	   END,
 	  	  	 [Approver] =  u2.UserName
    From Waste_Event_Detail_History wh
      Left outer Join Events e on e.Event_id = wh.Event_Id
      Left outer Join Waste_Event_Meas wm on wm.wemt_id = wh.wemt_Id
      Left outer Join Waste_Event_Type we on we.wet_id = wh.wet_id
      Join Prod_Units pu on pu.pu_id = wh.source_pu_id
      Join Users u on u.user_id = wh.user_id
      Left outer Join Event_Reason_Tree_Data erd on erd.Event_Reason_Tree_Data_Id = wh.Event_Reason_Tree_Data_Id
      Left outer Join ESignature es on es.Signature_Id = wh.Signature_Id
      Left outer Join Users u2 on es.Verify_User_Id = u2.User_Id
 	   Left Join Event_Reasons er1 on er1.Event_Reason_Id = wh.Reason_Level1 
 	   Left Join Event_Reasons er2 on er2.Event_Reason_Id = wh.Reason_Level2
 	   Left Join Event_Reasons er3 on er3.Event_Reason_Id = wh.Reason_Level3
 	   Left Join Event_Reasons er4 on er4.Event_Reason_Id = wh.Reason_Level4 
 	   Left Join Event_Reasons er5 on er5.Event_Reason_Id = wh.Action_Level1 
 	   Left Join Event_Reasons er6 on er5.Event_Reason_Id = wh.Action_Level2 
 	   Left Join Event_Reasons er7 on er5.Event_Reason_Id = wh.Action_Level3 
 	   Left Join Event_Reasons er8 on er5.Event_Reason_Id = wh.Action_Level4 
     where wed_id = @WId
       order by Modified_on desc
END
ELSE
BEGIN
 	 Select e.Event_Num, pu.PU_Desc as Location, wh.Timestamp, wh.Amount, wm.wemt_name as Measurement,
 	  	  we.WET_Name as Waste_Event_Desc, u.Username,
 	  	  wh.Reason_Level1 as ReasonLevel1, wh.Reason_Level2 as ReasonLevel2, 
 	  	  wh.Reason_Level3 as ReasonLevel3, wh.Reason_Level4 as ReasonLevel4,
 	  	  wh.Action_Level1 as ActionLevel1, wh.Action_Level2 as ActionLevel2, 
 	  	  wh.Action_Level3 as ActionLevel3, wh.Action_Level4 as ActionLevel4,
 	  	  erd.Tree_Name_Id, pe.Action_Tree_Id as ActionTreeId, u2.UserName as ApproverName
 	 From Waste_Event_Detail_History wh
 	 Left outer Join Events e on e.Event_id = wh.Event_Id
 	 Left outer Join Waste_Event_Meas wm on wm.wemt_id = wh.wemt_Id
 	 Left outer Join Waste_Event_Type we on we.wet_id = wh.wet_id
 	 Join Prod_Units pu on pu.pu_id = wh.source_pu_id
 	 Join Users u on u.user_id = wh.user_id
 	 Left outer Join Event_Reason_Tree_Data erd on erd.Event_Reason_Tree_Data_Id = wh.Event_Reason_Tree_Data_Id
 	 Left outer Join ESignature es on es.Signature_Id = wh.Signature_Id
 	 Left outer Join Users u2 on es.Verify_User_Id = u2.User_Id
 	 Join Prod_Events pe on pe.PU_Id = pu.pu_Id and pe.event_type = 3
 	 where wed_id = @WId
 	 order by Modified_on desc
END
