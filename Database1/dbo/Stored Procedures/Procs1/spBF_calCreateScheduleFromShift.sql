CREATE PROCEDURE [dbo].[spBF_calCreateScheduleFromShift]
        @CrewId int,
        @crewName nvarchar(50),
        @shiftId int,
        @shiftName nvarchar(50),
        @machineId int,
        @startTime datetime,
        @commentText text,
        @ClientUTCOffset int = 0,
 	  	 @ModifyUserId Int = 1
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
  declare @newId int;
  declare @cid int = NULL;
  declare @duration integer;
  declare @startShift DATETIME;
  declare @ret int;
  declare @st DATETIME;
  declare @et DATETIME;
  DECLARE @sn nvarchar(10);
  declare @cn nvarchar(10);
  declare @Count int
 	  BEGIN TRY
     BEGIN TRANSACTION
 	 IF @ModifyUserId Is Null SET @ModifyUserId =1
     select  @startShift=DateAdd(minute, @ClientUTCOffset - UTCOffset, Start_Time), @duration = duration from Shifts where Id = @shiftId;
  if @commentText is not null and DATALENGTH( @commentText ) > 0
    BEGIN
      insert into Comments(comment,Modified_On,ShouldDelete,User_Id) values (@commentText,GETUTCDATE(),0,@ModifyUserId);
      set @cid = SCOPE_IDENTITY() ;
    END
  select @st=dbo.fnBF_calCalculateStartSchedule(@startTime, @startShift, @ClientUTCOffset),
 	  	 @et=dbo.fnBF_calCalculateEndSchedule(@startTime, @startShift,@duration, @ClientUTCOffset);
  select @cn=left(@crewName,10), @sn=left(@shiftName,10);
  exec @ret = dbo.spServer_DBMgrUpdCrewSchedule @CS_Id=@newId OUTPUT, @PU_Id=@machineId, 
    @StartTime=@st, @EndTime=@et, @CrewName=@cn, @ShiftName=@sn, 
    @UserId=@ModifyUserId, @CommentId=@cid, @TransType=1, @TransNum=0 ;
-- only create the mapping entries if they do not already exist
  select @Count = count (Crew_Schedule_Id) from shifts_Crew_schedule_mapping where Crew_Schedule_Id = @newId
  if @Count = 0
  Begin
 	 insert into Shifts_Crew_schedule_mapping (Crew_Schedule_Id, Shift_Id ) values ( @newId,@shiftId) ;
 	 insert into CrewSchedule_Crew_Mapping (Crew_Schedule_Id, Crew_Id ) values ( @newId,@CrewId) ;
  End
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
  where te.cs_Id =  @newId ;
        COMMIT
  	 END TRY
 	 BEGIN CATCH
 	  	 IF @@TRANCOUNT > 0
        BEGIN
 	  	   ROLLBACK;
-- 	  	 IF @newId is null
-- 	  	 BEGIN
 	  	  	 SELECT Error = 'Error: Service failed to create or update crew assignment'
 	  	  	 RETURN
-- 	  	 END
        END
 	 END CATCH
END
