CREATE Procedure dbo.spEMSEC_PutFault
  @PUId           	 int,
  @SPUId    	  	  	 int,
  @TreeId 	  	  	 Int,
  @FaultName    	  	 nVarChar(100),
  @FaultValue   	  	 nVarChar(25),
  @ReasonLevel1   	 nVarChar(100),
  @ReasonLevel2   	 nVarChar(100),
  @ReasonLevel3   	 nVarChar(100),
  @ReasonLevel4   	 nVarChar(100),
  @EventType 	  	 Int,
  @UserId  	  	  	 int,
  @FaultId      	  	 int 	  	  	 OUTPUT
AS
IF @EventType = 3 --WASTE
BEGIN
 	 IF @FaultId Is Not Null and @FaultName IS Null AND @FaultValue IS NULL -- DELETE
 	 BEGIN
 	  	 UPDATE Waste_Event_Details SET WEFault_Id = NULL WHERE WEFault_Id = @FaultId
 	  	 DELETE Waste_Event_Fault WHERE WEFault_Id = @FaultId
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEMEC_PutWasteEventFault 
 	  	  	  	 @PUId, 
 	  	  	  	 @FaultId, 
 	  	  	  	 @SPUId, 
 	  	  	  	 @TreeId, 
 	  	  	  	 @FaultName, 
 	  	  	  	 @FaultValue, 
 	  	  	  	 @ReasonLevel1,
 	  	  	  	 @ReasonLevel2,
 	  	  	  	 @ReasonLevel3,
 	  	  	  	 @ReasonLevel4,
 	  	  	  	 @UserId
 	  	 IF @FaultId IS NULL AND @SPUId IS NOT NULL
 	  	 BEGIN
 	  	  	 SELECT @FaultId = WEFault_Id FROM Waste_Event_Fault WHERE Source_PU_Id = @SPUId AND  WEFault_Value = @FaultValue AND  WEFault_Name = @FaultName
 	  	 END
 	 END
END
ELSE  --DOWNTIME
BEGIN
 	 IF @FaultId Is Not Null and @FaultName IS Null AND @FaultValue IS NULL -- DELETE
 	 BEGIN
 	  	 UPDATE Timed_Event_Details SET TEFault_Id = NULL WHERE TEFault_Id = @FaultId
 	  	 DELETE Timed_Event_Fault WHERE TEFault_Id = @FaultId
 	 END
 	 ELSE
 	 BEGIN
 	  	 EXECUTE spEMEC_PutTimedEventFault
 	  	  	  	 @PUId,
 	  	  	  	 @FaultId,
 	  	  	  	 @SPUId,
 	  	  	  	 @TreeId,
 	  	  	  	 @FaultName,
 	  	  	  	 @FaultValue,
 	  	  	  	 @ReasonLevel1,
 	  	  	  	 @ReasonLevel2,
 	  	  	  	 @ReasonLevel3,
 	  	  	  	 @ReasonLevel4,
 	  	  	  	 @UserId
 	  	 IF @FaultId IS NULL AND @SPUId IS NOT NULL
 	  	 BEGIN
 	  	  	 SELECT @FaultId = TEFault_Id FROM Timed_Event_Fault WHERE Source_PU_Id = @SPUId AND  TEFault_Value = @FaultValue AND  TEFault_Name = @FaultName
 	  	 END
 	 END
END
