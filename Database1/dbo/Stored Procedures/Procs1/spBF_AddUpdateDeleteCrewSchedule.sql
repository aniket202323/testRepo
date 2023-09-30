CREATE PROCEDURE [dbo].[spBF_AddUpdateDeleteCrewSchedule]
 	  	 @CSId 	 int,
        @CrewId int,
        @crewName nvarchar(50),
        @shiftId int,
        @shiftName nvarchar(50),
        @machineId int,
        @startTime datetime,
        @commentText text,
        @ClientUTCOffset int = 0,
 	  	 @ModifyUserId Int = 1,
 	  	 @TransType 	 Int
AS
IF @TransType = 1
BEGIN
 	 EXECUTE dbo.spBF_calCreateScheduleFromShift 	 @CrewId,@crewName,@shiftId,@shiftName,@machineId,
 	  	  	  	  	  	  	  	  	  	  	  	 @startTime,@commentText,@ClientUTCOffset,@ModifyUserId
END
IF @TransType = 2
BEGIN
 	 EXECUTE dbo.spBF_calUpdateSchedule     @CSId,@machineId,@startTime ,null ,@shiftId , @shiftName ,
 	  	  	  	  	  	  	  	  	  	  	  	 @CrewId ,@crewName ,@commentText,@ClientUTCOffset
END
IF @TransType = 3
BEGIN
 	  DELETE Shifts_Crew_schedule_mapping WHERE Crew_Schedule_Id = @CSId
     DELETE CrewSchedule_Crew_Mapping WHERE Crew_Schedule_Id = @CSId
 	  DELETE Crew_Schedule WHERE cs_Id = @CSId
 	  SELECT 'Success'
END
