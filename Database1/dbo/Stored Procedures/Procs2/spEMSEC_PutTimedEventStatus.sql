Create Procedure dbo.spEMSEC_PutTimedEventStatus
  @PUId 	  	  	  	 int,
  @TEStatusName 	  	 nVarChar(100),
  @TEStatusValue 	 nVarChar(25),
  @UserId 	  	  	 int,
  @TEStatusId 	  	 int 	  	 OUTPUT
AS
IF @PUId Is NULL AND @TEStatusId IS NOT NULL
BEGIN
 	 DELETE Timed_Event_Status WHERE TEStatus_Id = @TEStatusId
END
ELSE
BEGIN
 	 EXECUTE spEM_PutTimedEventStatus   
 	  	  	 @PUId,
 	  	  	 @TEStatusId,
 	  	  	 @TEStatusName,
 	  	  	 @TEStatusValue,
 	  	  	 @UserId
 	 SELECT @TEStatusId = TEStatus_Id FROM Timed_Event_Status WHERE TEStatus_Name = @TEStatusName and PU_Id = @PUId
END
