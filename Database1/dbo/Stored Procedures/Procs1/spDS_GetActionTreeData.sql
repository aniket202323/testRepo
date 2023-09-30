Create Procedure dbo.spDS_GetActionTreeData
 @PUId int,
 @EventSubTypeId int
AS
 Declare @ETId int
 Select @ETID=14
 DECLARE @DefaultStatus int
 DECLARE @DefaultTestingStatus Int
SELECT @DefaultTestingStatus = value From Site_Parameters where Parm_Id = 96 
SELECT @DefaultTestingStatus = coalesce(@DefaultTestingStatus,1)
SELECT @DefaultStatus = coalesce(Default_Event_Status,0)
   From Event_SubTypes
    Where Event_SubType_Id = @EventSubTypeId 
  Select Cause_Tree_Id as CauseTreeId, Action_Tree_Id as ActionTreeId, ESignature_Level
   From Event_SubTypes
    Where Event_SubType_Id = @EventSubTypeId  	  	  	 
------------------------------------------------------------
-- Data for common tab
-------------------------------------------------------------
 Select @PUId as PUId, PU.PU_Desc as PUDesc, @EventSubTypeId as EventSubTypeID, ET.Event_SubType_Desc as EventSubTypeDesc, 
  ET.Duration_Required as DurationRequired, ET.Cause_Required as CauseRequired, 
  ET.Action_Required as ActionRequired,NULL as UDEDesc, ET.Ack_Required as AckRequired,
  ET.Default_Cause1 as DefaultCause1, ET.Default_Cause2 as DefaultCause2,
  ET.Default_Cause3 as DefaultCause3, ET.Default_Cause4 as DefaultCause4,EventStatus = @DefaultStatus,EventTestingStatus = @DefaultTestingStatus
  From Prod_Units PU  
  Left Outer Join Event_SubTypes ET on ET.Et_Id=@ETId And @EventSubTypeId = ET.Event_SubType_Id
   Where PU.PU_Id = @PUId
DECLARE @InvalidStatuses Table(InvalidStatus nVarChar(100))
INSERT INTO @InvalidStatuses(InvalidStatus)
 	 SELECT  a.ProdStatus_Desc 
 	  	 FROM Production_Status  a
 	  	 WHERE ProdStatus_Id NOT IN (SELECT Valid_Status  FROM PrdExec_Status WHERE PU_Id = @PUId and Valid_Status is not null )
 	  	 
INSERT INTO @InvalidStatuses(InvalidStatus) SELECT ProdStatus_Desc FROM Production_Status WHERE LockData = 1 	  	 
SELECT DISTINCT InvalidStatus FROM @InvalidStatuses
