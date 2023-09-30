CREATE PROCEDURE dbo.spEM_IEImportTimedEventFault
@LineDesc 	  	  	 nVarchar (100),
@UnitDesc 	  	  	 nVarchar (100),
@FaultValue 	  	  	 nVarchar (100),
@FaultDesc 	  	  	 nVarchar (100),
@LocationDesc 	  	 nVarchar (100),
@RLevel1 	  	  	 nVarchar (100),
@RLevel2 	  	  	 nVarchar (100),
@RLevel3 	  	  	 nVarchar (100),
@RLevel4 	  	  	 nVarchar (100),
@AddReasons 	  	  	 nVarChar(10),
@User_Id 	  	  	 Int
As
Declare 	 @UnitId 	  	 Int,
 	 @Line_Id 	 Int,
 	 @LocationId 	 Int,
 	 @TreeId 	  	 Int,
 	 @R1Id 	  	 Int,
 	 @R2Id 	  	 Int,
 	 @R3Id 	  	 Int,
 	 @R4Id 	  	 Int,
 	 @FaultId 	 Int,
   	 @ReasonId1 	 Int,
   	 @ReasonId2 	 Int,
   	 @ReasonId3 	 Int,
 	 @iAddReason 	 int,
   	 @ReasonId4 	 Int,
 	 @TreeName 	 nVarChar(100)
/* Clean arguments */
SELECT  	 @LineDesc  	 = RTrim(LTrim(@LineDesc)),
 	 @UnitDesc  	 = RTrim(LTrim(@UnitDesc)),
 	 @FaultValue  	 = RTrim(LTrim(@FaultValue)),
 	 @FaultDesc  	 = RTrim(LTrim(@FaultDesc)),
 	 @LocationDesc  	 = RTrim(LTrim(@LocationDesc)),
 	 @RLevel1 	 = RTrim(LTrim(@RLevel1)),
 	 @RLevel2 	 = RTrim(LTrim(@RLevel2)),
 	 @RLevel3 	 = RTrim(LTrim(@RLevel3)),
 	 @RLevel4 	 = RTrim(LTrim(@RLevel4)),
 	 @AddReasons 	 = RTrim(LTrim(@AddReasons))
IF @LineDesc = ''  	 SELECT @LineDesc = NULL
IF @UnitDesc = ''  	 SELECT @UnitDesc = NULL
IF @FaultValue = ''  	 SELECT @FaultValue = NULL
IF @FaultDesc = ''  	 SELECT @FaultDesc = NULL
IF @LocationDesc = ''  	 SELECT @LocationDesc = NULL
IF @RLevel1 = ''  	 SELECT @RLevel1 = NULL
IF @RLevel2 = ''  	 SELECT @RLevel2 = NULL
IF @RLevel3 = ''  	 SELECT @RLevel3 = NULL
IF @RLevel4 = ''  	 SELECT @RLevel4 = NULL
IF @AddReasons = ''  	 SELECT @AddReasons = NULL
IF @LineDesc Is Null
  BEGIN
 	 SELECT 'Failed - Production Line must be defined'
 	 Return (-100)
  END
IF @UnitDesc Is Null
  BEGIN
 	 SELECT 'Failed - Production Unit must be defined'
 	 Return (-100)
  END
IF @FaultValue Is Null
  BEGIN
 	 SELECT 'Failed - Fault Value must be defined'
 	 Return (-100)
  END
 IF @LocationDesc Is Null
  BEGIN
 	 SELECT 'Failed - Location must be defined'
 	 Return (-100)
  END
IF @AddReasons = '1'
 	 SELECT @iAddReason = 1
Else
 	 SELECT @iAddReason = 0
/* Check For Fault on master unit */
SELECT @Line_Id = Null
SELECT @Line_Id = Pl_Id FROM Prod_Lines WHERE pl_Desc = @LineDesc
IF @Line_Id Is Null
  BEGIN
 	 SELECT 'Failed - Production Line not found'
 	 Return (-100)
  END
SELECT @UnitId = Null
SELECT @UnitId = PU_Id FROM Prod_Units  WHERE pl_Id = @Line_Id and PU_Desc = @UnitDesc
IF @UnitId Is Null
  BEGIN
 	 SELECT 'Failed - Production Unit not found'
 	 Return (-100)
  END
/* Check for master unit with downtime model attached*/
IF (SELECT Count(*) FROM Event_Configuration WHERE ET_Id = 2 and PU_Id = @UnitId) = 0
  BEGIN
 	 SELECT 'Failed - Downtime model not found'
 	 Return (-100)
  END
IF (SELECT Count(*) FROM Prod_Units WHERE Timed_Event_Association = 1 and PU_Id = @UnitId) = 0
  BEGIN
 	 UPDATE Prod_Units SET Timed_Event_Association = 1 WHERE PU_Id = @UnitId
  END
IF  @LocationDesc is Not null
BEGIN
 	 SELECT @LocationId = PU_Id
 	 FROM Prod_Units
 	 WHERE PU_Desc = @LocationDesc and (pu_Id = @UnitId or Master_Unit = @UnitId)
 	 IF @LocationId Is null
 	 BEGIN
 	  	 SELECT 'Failed - Location not Found'
 	  	 Return (-100)
 	 END
 	 IF (SELECT Count(*) FROM Prod_Units WHERE Timed_Event_Association = 1 and PU_Id = @LocationId) = 0
 	 BEGIN
 	  	 Update Prod_Units set Timed_Event_Association = 1 WHERE PU_Id = @LocationId
 	 END
 	 SELECT @TreeId = Null
 	 SELECT @TreeId = Name_Id FROM Prod_Events WHERE Event_Type = 2 and PU_Id = @LocationId
 	 IF @TreeId is null
 	 BEGIN
 	  	 SELECT 'Failed - No Reason tree associated with location'
 	  	 Return (-100)
 	 END
 	 SELECT @TreeName = Tree_Name FROM Event_Reason_Tree WHERE Tree_Name_Id = @TreeId 
END
IF @RLevel1 is not null
BEGIN
 	 SELECT @R1Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel1
 	 IF @R1Id is null and @iAddReason = 0
 	 BEGIN
 	  	 SELECT 'Failed - Reason 1 not found'
 	  	 Return (-100)
 	 END
 	 IF @R1Id is null
 	 BEGIN
 	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	 SELECT @R1Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel1
 	  	 IF @R1Id is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Unable to create new reason 1'
 	  	  	 Return (-100)
 	  	 END
 	 END
END
IF @RLevel2 is not null
BEGIN
 	 SELECT @R2Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel2
 	 IF @R2Id is null and @iAddReason = 0
 	 BEGIN
 	  	 SELECT 'Failed - Reason 2 not found'
 	  	 Return (-100)
 	 END
 	 IF @R2Id is null
 	 BEGIN
 	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	 SELECT @R2Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel2
 	  	 IF @R2Id is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Unable to create new reason 2'
 	  	  	 Return (-100)
 	  	 END
 	 END
END
IF @RLevel3 is not null
BEGIN
 	 SELECT @R3Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel3
 	 IF @R3Id is null and @iAddReason = 0
 	 BEGIN
 	  	 SELECT 'Failed - Reason 3 not found'
 	  	 Return (-100)
 	 END
 	 IF @R3Id is null
 	 BEGIN
 	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	 SELECT @R3Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel3
 	  	 IF @R3Id is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Unable to create new reason 3'
 	  	  	 Return (-100)
 	  	 END
 	 END
END
IF @RLevel4 is not null
BEGIN
 	 SELECT @R4Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel4
 	 IF @R4Id is null and @iAddReason = 0
 	 BEGIN
 	  	 SELECT 'Failed - Reason 4 not found'
 	  	 Return (-100)
 	 END
 	 IF @R4Id is null
 	 BEGIN
 	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	 SELECT @R4Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel4
 	  	 IF @R4Id is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Unable to create new reason 4'
 	  	  	 Return (-100)
 	  	 END
 	 END
END
IF @R1Id is not Null
BEGIN
 	 SELECT @ReasonId1 = Null
 	 SELECT @ReasonId1 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R1Id and Event_Reason_Level = 1
 	 IF @ReasonId1 is null and @iAddReason = 0
 	 BEGIN
 	  	 SELECT 'Failed - Reason 1 not found on associated tree'
 	  	 Return (-100)
 	 END
 	 IF @ReasonId1 is null
 	 BEGIN
 	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	 SELECT @ReasonId1 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE Tree_Name_Id = @TreeId and Event_Reason_Id = @R1Id and Event_Reason_Level = 1
 	  	 IF @ReasonId1 is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Reason 1 not found on associated tree'
 	  	  	 Return (-100)
 	  	 END
 	 END
 	 IF @R2Id is not Null
 	 BEGIN
 	  	 SELECT @ReasonId2 = Null
 	  	 SELECT @ReasonId2 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R2Id  and Parent_Event_R_Tree_Data_Id = @ReasonId1
 	  	 IF @ReasonId2 is null and @iAddReason = 0
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Reason 2 not found on  associated tree'
 	  	  	 Return (-100)
 	  	 END
 	  	 IF @ReasonId2 is null
 	  	 BEGIN
 	  	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	  	 SELECT @ReasonId2 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R2Id  and Parent_Event_R_Tree_Data_Id = @ReasonId1
 	  	  	 IF @ReasonId2 is null
 	  	  	 BEGIN
 	  	  	  	 SELECT 'Failed - Reason 2 not found on associated tree'
 	  	  	  	 Return (-100)
 	  	  	 END
 	  	 END
 	  	 IF @R3Id is not Null
 	  	 BEGIN
 	  	  	 SELECT @ReasonId3 = Null
 	  	  	 SELECT @ReasonId3 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R3Id  and Parent_Event_R_Tree_Data_Id = @ReasonId2
 	  	  	 IF @ReasonId3 is null and @iAddReason = 0
 	  	  	 BEGIN
 	  	  	  	 SELECT 'Failed - Reason 3 not found on  associated tree'
 	  	  	  	 Return (-100)
 	  	  	 END
 	  	  	 IF @ReasonId3 is null
 	  	  	 BEGIN
 	  	  	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	  	  	 SELECT @ReasonId3 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R3Id  and Parent_Event_R_Tree_Data_Id = @ReasonId2
 	  	  	  	 IF @ReasonId3 is null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 'Failed - Reason 3 not found on associated tree'
 	  	  	  	  	 Return (-100)
 	  	  	  	 END
 	  	  	 END
 	  	  	 IF @R4Id is not Null
 	  	  	 BEGIN
 	  	  	  	 SELECT @ReasonId4 = Null
 	  	  	  	 SELECT @ReasonId4 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R4Id  and Parent_Event_R_Tree_Data_Id = @ReasonId3
 	  	  	  	 IF @ReasonId4 is null and @iAddReason = 0
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 'Failed - Reason 4 not found on  associated tree'
 	  	  	  	  	 Return (-100)
 	  	  	  	 END
 	  	  	  	 IF @ReasonId4 is null
 	  	  	  	 BEGIN
 	  	  	  	  	 EXECUTE spEM_IEImportEventReasonTree @TreeName,@RLevel1,@RLevel2,@RLevel3,@RLevel4,1,@User_Id
 	  	  	  	  	 SELECT @ReasonId4 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R4Id  and Parent_Event_R_Tree_Data_Id = @ReasonId3
 	  	  	  	  	 IF @ReasonId4 is null
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 'Failed - Reason 4 not found on associated tree'
 	  	  	  	  	  	 Return (-100)
 	  	  	  	  	 END
 	  	  	  	 END
 	  	  	 END
 	  	 END
 	 END
END
/* Data Correct */
SELECT @FaultId = Null
SELECT @FaultId = TEFault_Id FROM Timed_Event_Fault WHERE PU_Id = @UnitId and TEFault_Value = @FaultValue
Execute spEM_PutTimedEventFault @UnitId,@FaultId,@LocationId,@FaultDesc,@FaultValue,@ReasonId1,@ReasonId2,@ReasonId3,@ReasonId4,@User_Id
RETURN(0)
