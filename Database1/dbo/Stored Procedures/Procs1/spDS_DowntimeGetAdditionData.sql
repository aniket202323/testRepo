Create Procedure dbo.spDS_DowntimeGetAdditionData
@DetailPUId int,
@DetailId int
AS
 Declare @DetailStartTime datetime,
--         @DetailPUId int,
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
         @MinEndTime datetime -- ,
--         @NoCause nVarChar(25),
--         @NoAction nVarChar(25) 
-- Select @DetailPUId = NULL
 Select @DetailStartTime = NULL
 Select @DetailSequence = NULL
 Select @DetailPartialDuration = NULL
 Select @SummaryPUDesc = NULL
 Select @SummaryStartTime = NULL
 Select @SUmmaryEndTime = NULL
 Select @SummaryFaultName = NULL
 Select @SourcePUDesc = NULL
 Select @MaxStartTime = NULL
-- Select @NoCause = '<None>'
-- Select @NoAction = '<None>'
 Select @DowntimeEventType = 2
 Select @MinEndTime = NULL
--------------------------------------------------------
-- Get basic downtime detail info
-------------------------------------------------------
 Select @DetailStartTime = Start_Time, @DetailPUID = PU_Id, @SourcePUID = Source_PU_Id
  From Timed_Event_Details
   Where TeDet_Id = @DetailId
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
 Create table #Detail (
  Counter int IDENTITY (1, 1) NOT NULL ,
  StartTime datetime ,
  Duration real ,
  TeDet_Id int 
 )
 If (@SummaryEndTime Is NOT NULL)
  Begin
   Insert Into #Detail 
     Select  Start_Time , datediff(minute, Start_Time, End_Time), TeDet_Id
      From Timed_Event_Details
       Where PU_Id = @DetailPUID
        And Start_Time >= @SummaryStartTime
         And End_Time <= @SummaryEndTime
  End
 Else
  Begin
   Insert Into #Detail
    Select  Start_Time , datediff(minute, Start_Time, End_Time) , TeDet_Id
     From Timed_Event_Details
      Where PU_Id = @DetailPUID
       And Start_Time >= @SummaryStartTime  
  End
  update #detail set duration = 0 where duration is null
  Select @DetailSequence = Count(Counter)+1
   From #Detail
  Select @DetailPartialDuration = Sum(Duration) From #Detail 
  Select @DetailSequence as DetailSequence, Count(Counter)+1 as TotalDetailCounter, Sum(Duration) as TotalDetailDuration,  0 as PartialDetailDuration
    From #Detail
--------------------------------------------------------
-- Cause and Action Tree Ids
--------------------------------------------------------
 Select Name_Id as CauseTreeId, Action_Tree_Id As ActionTreeId , Research_Enabled as ResearchEnabled 
  From Prod_Events 
   Where PU_Id = @DetailPUId 
    And Event_Type=@DowntimeEventType
/*
--------------------------------------------------------------------------------
-- Reason/Cause Tree
--------------------------------------------------------------------------------
 Select @TreeNameId=Name_Id From Prod_Events Where PU_Id = @DetailPUId and Event_Type=@DowntimeEventType
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
 Select @TreeNameId=Action_Tree_Id From Prod_Events Where PU_Id = @DetailPUId and Event_Type=@DowntimeEventType
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
 Select pu_desc as DetailLocation, pu_id as DetailId
  From Prod_units p
  Where (Master_Unit = @DetailPUId) or
         (p.Pu_Id = @DetailPUId)
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
/*
--------------------------------------------------------
-- Get basic downtime detail info
-------------------------------------------------------
 Select @DetailStartTime = Start_Time, @DetailPUID = PU_Id
  From Timed_Event_Details
   Where TeDet_Id = @DowntimeID
*/
-------------------------------------------------------------------------------
-- Drop temporary tables
-------------------------------------------------------------------------------
 Drop table #Detail
