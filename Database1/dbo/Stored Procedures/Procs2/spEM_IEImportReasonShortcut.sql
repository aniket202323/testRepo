CREATE PROCEDURE dbo.spEM_IEImportReasonShortcut
@LineDesc 	  	  	 nVarchar (100),
@UnitDesc 	  	  	 nVarchar (100),
@SCName 	  	  	  	 nVarchar (100),
@AmountTime 	  	  	 nVarchar (100),
@LocationDesc 	  	 nVarchar (100),
@RLevel1 	  	  	 nVarchar (100),
@RLevel2 	  	  	 nVarchar (100),
@RLevel3 	  	  	 nVarchar (100),
@RLevel4 	  	  	 nVarchar (100),
@Type 	  	  	  	 nvarchar(50),
@User_Id 	  	  	 Int
As
Declare 	 @UnitId 	  	 Int,
 	 @LineId 	 Int,
 	 @LocationId 	 Int,
 	 @TreeId 	  	 Int,
 	 @R1Id 	  	 Int,
 	 @R2Id 	  	 Int,
 	 @R3Id 	  	 Int,
 	 @R4Id 	  	 Int,
 	 @RSId 	  	 Int,
   	 @ReasonId1 	 Int,
   	 @ReasonId2 	 Int,
   	 @ReasonId3 	 Int,
   	 @ReasonId4 	 Int,
 	 @AppId 	  	 Int
/* Clean arguments */
SELECT  	 @LineDesc  	 = RTrim(LTrim(@LineDesc)),
 	 @UnitDesc  	 = RTrim(LTrim(@UnitDesc)),
 	 @SCName  	 = RTrim(LTrim(@SCName)),
 	 @AmountTime  	 = RTrim(LTrim(@AmountTime)),
 	 @LocationDesc  	 = RTrim(LTrim(@LocationDesc)),
 	 @RLevel1 	 = RTrim(LTrim(@RLevel1)),
 	 @RLevel2 	 = RTrim(LTrim(@RLevel2)),
 	 @RLevel3 	 = RTrim(LTrim(@RLevel3)),
 	 @RLevel4 	 = RTrim(LTrim(@RLevel4))
IF @LineDesc = ''  	 SELECT @LineDesc = NULL
IF @UnitDesc = ''  	 SELECT @UnitDesc = NULL
IF @SCName = ''  	 SELECT @SCName = NULL
IF @AmountTime = ''  	 SELECT @AmountTime = NULL
IF @LocationDesc = ''  	 SELECT @LocationDesc = NULL
IF @RLevel1 = ''  	 SELECT @RLevel1 = NULL
IF @RLevel2 = ''  	 SELECT @RLevel2 = NULL
IF @RLevel3 = ''  	 SELECT @RLevel3 = NULL
IF @RLevel4 = ''  	 SELECT @RLevel4 = NULL
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
IF @SCName Is Null
  BEGIN
 	 SELECT 'Failed - Shortcut Name must be defined'
 	 Return (-100)
  END
/* Check For Fault on master unit */
SELECT @LineId = Null
SELECT @LineId = Pl_Id FROM Prod_Lines WHERE pl_Desc = @LineDesc
IF @LineId Is Null
  BEGIN
 	 SELECT 'Failed - Production Line not found'
 	 Return (-100)
  END
SELECT @UnitId = Null
SELECT @UnitId = PU_Id FROM Prod_Units  WHERE pl_Id = @LineId and PU_Desc = @UnitDesc
IF @UnitId Is Null
  BEGIN
 	 SELECT 'Failed - Production Unit not found'
 	 Return (-100)
  END
IF @Type Not In ('Timed','Waste')
BEGIN
 	 SELECT 'Failed - Type must be Timed or Waste'
 	 Return (-100)
END
IF @Type = 'Timed'
BEGIN
 	 SELECT @AppId = 2
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
END
IF @Type = 'Waste'
BEGIN
 	 SELECT @AppId = 3
 	 IF (SELECT Count(*) FROM Event_Configuration WHERE ET_Id = 3 and PU_Id = @UnitId) = 0
 	 BEGIN
 	  	 SELECT 'Failed - Waste model not found'
 	  	 Return (-100)
 	 END
 	 If (SELECT Count(*) FROM Prod_Units WHERE Waste_Event_Association is not null and PU_Id = @UnitId) = 0
 	 BEGIN
 	  	 SELECT 'Failed - Waste not associated to Unit'
 	  	 Return (-100)
 	 END
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
 	 IF @Type = 'Timed'
 	 BEGIN
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
 	 END
 	 IF @Type = 'Waste'
 	 BEGIN
 	  	 IF (SELECT Count(*) FROM Prod_Units WHERE Waste_Event_Association is not null and PU_Id = @LocationId) = 0
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Waste not associated to Location'
 	  	  	 Return (-100)
 	  	 END
 	  	 SELECT @TreeId = Null
 	  	 SELECT @TreeId = Name_Id FROM Prod_Events WHERE Event_Type = 3 and PU_Id = @LocationId
 	  	 IF @TreeId is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - No Reason tree associated with location'
 	  	  	 Return (-100)
 	  	 END
 	 END
END
IF @RLevel1 is not null
BEGIN
 	 SELECT @R1Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel1
 	 IF @R1Id is null
 	 BEGIN
 	  	 SELECT 'Failed - Reason 1 not found'
 	  	 Return (-100)
 	 END
END
IF @RLevel2 is not null
BEGIN
 	 SELECT @R2Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel2
 	 IF @R2Id is null
 	 BEGIN
 	  	 SELECT 'Failed - Reason 2 not found'
 	  	 Return (-100)
 	 END
END
IF @RLevel3 is not null
BEGIN
 	 SELECT @R3Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel3
 	 IF @R3Id is null
 	 BEGIN
 	  	 SELECT 'Failed - Reason 3 not found'
 	  	 Return (-100)
 	 END
END
IF @RLevel4 is not null
BEGIN
 	 SELECT @R4Id = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @RLevel4
 	 IF @R4Id is null
 	 BEGIN
 	  	 SELECT 'Failed - Reason 4 not found'
 	  	 Return (-100)
 	 END
END
IF @R1Id is not Null
BEGIN
 	 SELECT @ReasonId1 = Null
 	 SELECT @ReasonId1 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R1Id and Event_Reason_Level = 1
 	 IF @ReasonId1 is null
 	 BEGIN
 	  	 SELECT 'Failed - Reason 1 not found on associated tree'
 	  	 Return (-100)
 	 END
 	 IF @R2Id is not Null
 	 BEGIN
 	  	 SELECT @ReasonId2 = Null
 	  	 SELECT @ReasonId2 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R2Id  and Parent_Event_R_Tree_Data_Id = @ReasonId1
 	  	 IF @ReasonId2 is null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - Reason 2 not found on  associated tree'
 	  	  	 Return (-100)
 	  	 END
 	  	 IF @R3Id is not Null
 	  	 BEGIN
 	  	  	 SELECT @ReasonId3 = Null
 	  	  	 SELECT @ReasonId3 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R3Id  and Parent_Event_R_Tree_Data_Id = @ReasonId2
 	  	  	 IF @ReasonId3 is null
 	  	  	 BEGIN
 	  	  	  	 SELECT 'Failed - Reason 3 not found on  associated tree'
 	  	  	  	 Return (-100)
 	  	  	 END
 	  	  	 IF @R4Id is not Null
 	  	  	 BEGIN
 	  	  	  	 SELECT @ReasonId4 = Null
 	  	  	  	 SELECT @ReasonId4 = Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE  Tree_Name_Id = @TreeId and Event_Reason_Id = @R4Id  and Parent_Event_R_Tree_Data_Id = @ReasonId3
 	  	  	  	 IF @ReasonId4 is null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 'Failed - Reason 4 not found on  associated tree'
 	  	  	  	  	 Return (-100)
 	  	  	  	 END
 	  	  	 END
 	  	 END
 	 END
END
/* Data Correct */
SELECT @RSId = Null
SELECT @RSId = RS_Id FROM Reason_Shortcuts WHERE PU_Id = @UnitId and Shortcut_Name = @SCName and App_Id = @AppId
Execute spEM_PutReasonShortcut @UnitId,@RSId,@AppId,@LocationId,@SCName,@AmountTime,@RLevel1,@RLevel2,@RLevel3,@RLevel4,@User_Id
RETURN(0)
