CREATE PROCEDURE dbo.spBF_calUpdateScheduleTime
        @Id integer,
        @startTime datetime,
        @endTime datetime,
        @commentText text,
 	  	 @UserId Int = 1
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	  BEGIN TRY
     BEGIN TRANSACTION
 	 IF @UserId IS NULL SET @UserId = 1
  declare @cid int = NULL;
  declare @nextcid int = ( select Comment_Id from Crew_Schedule where cs_Id = @Id );
  if @commentText is not null and DATALENGTH( @commentText ) > 0
    BEGIN
      insert into Comments(comment,Modified_On,ShouldDelete,User_Id,NextComment_Id) values (@commentText,GETUTCDATE(),0,@UserId,@nextcid);
      set @cid = SCOPE_IDENTITY() ;
    END
   ELSE
    BEGIN
       set @cid = @nextcid;
    END
  if @nextcid is not NULL and @cid is NOT NULL
    BEGIN
      update Comments set NextComment_Id=@cid  where Comment_Id = @nextcid ;
    END
  update Crew_Schedule set Comment_Id=@cid, Start_Time=@startTime,End_Time=@endTime where cs_Id = @id ;
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
  where te.cs_Id =  @id ;
END
