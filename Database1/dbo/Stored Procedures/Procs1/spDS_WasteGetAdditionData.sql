Create Procedure dbo.spDS_WasteGetAdditionData
@PuId int,
@EventId int= NULL,
@WEDId int=NULL
AS
 Declare @Amount real,
         @TimeStamp datetime,
         @EventSubTypeId int,
         @WasteSequence int,
         @WasteEventType int,
         @NoDimension nVarChar(50),
         @NoEventSubTypeDesc nVarChar(50),
         @EventSubTypeDesc nVarChar(50),
         @EventNum nVarChar(50),
         @EventTimeStamp datetime,
         @SourcePUDesc nVarChar(50),
         @FaultId int,
         @PartialWasteAmount real,
         @DetailsExist bit,
 	  	  @EventPu 	  	 Int,
 	  	  @EventET 	  	 DateTime
 Select @EventSubTypeId = NULL
 Select @Amount = NULL
 Select @TimeStamp = NULL
 Select @WasteSequence = NULL
 Select @WasteEventType = 3
 Select @NoDimension = ''
 Select @NoEventSubTypeDesc = ''
 Select @EVentSubTypeId = NULL
 Select @EventSubTypeDesc = NULL
 Select @EventTimeStamp = NULL
 Select @SourcePUDesc = NULL
 Select @PartialWasteAmount= NULL
 Select @EventNum = NULL
 Select @DetailsExist = 0
-----------------------------------------------------
-- Get basic info
-------------------------------------------------------
If (@EventId Is Not Null) 
BEGIN
 	  Select @EventSubTypeId = EV.Event_SubType_Id, @EventSubTypeDesc = ES.Event_SubType_Desc, 
 	  	  	 @EventNum = EV.Event_Num, @EventTimeStamp = EV.start_time,@EventPu = Pu_Id,@EventET = ev.timestamp
 	   From Events EV Left Outer Join Event_SubTypes ES On EV.Event_SubType_Id = ES.Event_SubType_Id
 	  	 Where EV.Event_Id = @EventId
 	 If @EventTimeStamp Is null
 	 BEGIN
 	  	 SELECT @EventTimeStamp = Max(timestamp) from Events where PU_Id = @EventPu and timestamp < @EventET
 	  	 Select @EventTimeStamp = Coalesce(@EventTimeStamp,@EventET)
 	 END
END
--------------------------------------------------------
-- Cause and Action Tree Ids
--------------------------------------------------------
 Select Name_Id as CauseTreeId, Action_Tree_Id As ActionTreeId, Research_Enabled as ResearchEnabled  
  From Prod_Events 
   Where PU_Id = @PUId 
    And Event_Type=@WasteEventType
/*
--------------------------------------------------------------------------------
-- Reason/Cause Tree
--------------------------------------------------------------------------------
 Select @TreeNameId=Name_Id From Prod_Events Where PU_Id = @PUId and Event_Type=@WasteEventType
 Select 1 as Event_Reason_Level, 0 as Event_Reason_Id, NULL as Parent_Event_Reason_Id, @NoCause as Event_Reason_Name, 0 as Comment_Required, 0 as Event_Reason_Tree_Data_Id, 0 as Parent_Event_R_Tree_Data_Id
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id,DT.Parent_Event_Reason_Id,  ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id 
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId 
    And DT.Event_Reason_Level=1
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id, DT.Parent_Event_Reason_Id, ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id  
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId
    And DT.Event_Reason_Level=2
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id, DT.Parent_Event_Reason_Id, ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id  
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId
    And DT.Event_Reason_Level=3
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id, DT.Parent_Event_Reason_Id, ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id 
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId
    And DT.Event_Reason_Level=4
    Order by DT.Event_Reason_Level, ER.Event_Reason_Id
--------------------------------------------------------------------------------
-- Action Tree
--------------------------------------------------------------------------------
 Select @TreeNameId=Action_Tree_Id From Prod_Events Where PU_Id = @PUId and Event_Type=@WasteEventType
 Select 1 as Event_Reason_Level, 0 as Event_Reason_Id, NULL as Parent_Event_Reason_Id, @NoAction as Event_Reason_Name, 0 as Comment_Required, 0 as Event_Reason_Tree_Data_Id, 0 as Parent_Event_R_Tree_Data_Id
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id,DT.Parent_Event_Reason_Id,  ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id 
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId 
    And DT.Event_Reason_Level=1
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id, DT.Parent_Event_Reason_Id, ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id  
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId
    And DT.Event_Reason_Level=2
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id, DT.Parent_Event_Reason_Id, ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id  
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId
    And DT.Event_Reason_Level=3
  Union
 Select DT.Event_Reason_Level, ER.Event_Reason_Id, DT.Parent_Event_Reason_Id, ER.Event_Reason_Name, ER.Comment_Required, DT.Event_Reason_Tree_Data_Id, DT.Parent_Event_R_Tree_Data_Id 
  From Event_Reasons ER   Inner Join Event_Reason_Tree_Data DT On ER.Event_Reason_Id = DT.Event_Reason_Id
   Where DT.Tree_Name_Id= @TreeNameId
    And DT.Event_Reason_Level=4
     Order by DT.Event_Reason_Level, ER.Event_Reason_Id 
*/
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
     Where wed.wed_Id = @WEDId
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
       Where wed.wed_Id = @WEDId
If (@EventId Is Not NULL)
  Select @DetailsExist = Count(*) from Event_Details where Event_Id = @EventId
----------------------------------------------------------------------------
-- ProdCode
-----------------------------------------------------------------------------
 Select PR.Prod_Code as ProdCode
  From Events EV Inner Join Production_Starts PS On EV.PU_Id = PS.Pu_Id
                   And  EV.TimeStamp >= PS.Start_Time And (EV.TimeStamp <= PS.End_Time Or PS.End_Time IS NULL)
                 Inner Join Products PR on PS.Prod_Id = PR.Prod_Id 
   Where EV.Event_Id = @EventId
------------------------------------------------------------------------------
-- detail info
-----------------------------------------------------------------------------
 Select @FaultId = WEFault_Id
  From Waste_Event_Details wed
   Where wed.Event_Id = @EventId   
 Select @PUId as PUId, PU.PU_Desc as PUDesc, @EventSubTypeId as EventSubTypeId, @EventId as EventId,
        @EventSubTypeDesc as EventSubTypeDesc,@EventNum as EventNum, @EventTimeStamp as EventTimeStamp,
        @SourcePUDesc as SourcePUDesc, @FaultId as FaultId, @DetailsExist as DetailsExist
  From Prod_Units PU 
   Where PU.PU_Id = @PUId
--------------------------------------------------------------------
--  1 Of 2 totalizing xxxx pounds
---------------------------------------------------------------------
 If @EventId Is NULL
  Select  @NoEventSubTypeDesc , 1 as WasteSequence ,1 as  TotalWasteCounter , @Amount as PartialWasteAmount
 Else
  Begin
   Select Count(*)+1 as WasteSequence, COunt(*)+1 as TotalWasteCounter,  Sum(Amount) as PartialWasteAmount
    From Waste_Event_Details
     Where Event_Id = @EventID
  End
