CREATE PROCEDURE [dbo].[spBF_calUpdateSchedule]
        @Id integer,
        @machineId int,
        @startTime datetime,
        @endTime datetime,
        @shiftId int,
        @shiftName nvarchar(50),
        @CrewId int,
        @crewName nvarchar(50),
        @commentText text,
 	 @ClientUTCOffset int = 0
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	  BEGIN TRY
     BEGIN TRANSACTION
  declare @duration integer;
  declare @startShift DATETIME;
  declare @ret int;
  declare @uid int;
  declare @st DATETIME;
  declare @et DATETIME;
  DECLARE @sn nvarchar(10);
  declare @cn nvarchar(10);
  DECLARE @OldCommentId int
  select  @startShift=DateAdd(Minute, @ClientUTCOffset - UTCOffset, Start_Time), @duration = duration from Shifts where Id = @shiftId;
  Select @OldCommentId = Comment_Id from Crew_Schedule where cs_Id = @Id
  EXECUTE dbo.spBF_UpdateComment @OldCommentId Output,@CommentText
    update Crew_Schedule set Comment_Id=@OldCommentId, PU_Id=@machineId,Crew_Desc=left(@crewName,10),Shift_Desc=left(@shiftName,10),
      Start_Time=dbo.fnBF_calCalculateStartSchedule(@startTime, @startShift, @ClientUTCOffset),
      End_Time=dbo.fnBF_calCalculateEndSchedule(@startTime, @startShift,@duration, @ClientUTCOffset)
    where cs_Id = @Id ;
    update Shifts_Crew_schedule_mapping set Shift_Id = @shiftId where Crew_Schedule_Id = @Id ;
    update CrewSchedule_Crew_Mapping set Crew_Id = @CrewId  where Crew_Schedule_Id = @Id ;
    COMMIT
  	 END TRY
 	 BEGIN CATCH
 	  	 IF @@TRANCOUNT > 0
      BEGIN
 	  	  	   ROLLBACK;
      END
 	 END CATCH
 SELECT te.CS_Id,te.Comment_Id,te.Crew_Desc,te.End_Time,te.PU_Id,te.Shift_Desc,te.Start_Time,te.User_Id,
  	 u.PU_Desc as machineName, sc.Shift_Id as shiftId,sh.Name as shiftName,cs.Crew_Id as Crew_Id, 
  	 cr.Name as crewName, co.Comment as comments
    from Crew_Schedule te
      left join Shifts_Crew_schedule_mapping sc on te.CS_Id = sc.Crew_Schedule_Id
      left join Shifts sh on sc.Shift_Id = sh.Id
      left join CrewSchedule_Crew_Mapping cs on te.CS_Id = cs.Crew_Schedule_Id
      left join Crews cr on cs.Crew_Id = cr.Id
      left join Comments co on te.Comment_Id = co.Comment_Id
      join Prod_Units u on u.PU_Id = te.PU_Id
  where te.cs_Id =  @Id ;
END
