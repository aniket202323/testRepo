CREATE procedure [dbo].[spSDK_AU_DowntimeStatus]
@AppUserId int,
@Id int OUTPUT,
@Department varchar(200) ,
@DepartmentId int ,
@DowntimeStatus varchar(100) ,
@DowntimeStatusValue varchar(100) ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int 
AS
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
IF @ProductionUnitId Is Null
BEGIN
 	 SELECT 'Production unit required'
 	 Return (-100)
END
IF @Id Is Null
BEGIN
 	 IF Exists(SELECT 1 FROM Timed_Event_Status a WHERE PU_Id = @ProductionUnitId and a.TEStatus_Value = @DowntimeStatusValue )
 	 BEGIN
 	  	 SELECT 'Timed event Status already exists add not allowed'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF Not Exists(SELECT 1 FROM Timed_Event_Status a WHERE a.TEStatus_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Timed event Status not found for update'
 	  	 RETURN(-100)
 	 END
 	 IF (SELECT PU_Id from Timed_Event_Status WHERE TEStatus_Id = @Id) <> @ProductionUnitId
 	 BEGIN
 	  	 SELECT 'Changing of production unit not allowed'
 	  	 RETURN(-100)
 	 END
 	 
END
EXECUTE  spEM_PutTimedEventStatus   @ProductionUnitId,@Id,@DowntimeStatus,@DowntimeStatusValue,@AppUserId
SELECT @Id = TEStatus_Id FROM Timed_Event_Status WHERE TEStatus_Value = @DowntimeStatusValue and PU_Id = @ProductionUnitId
Return(1)
