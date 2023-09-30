CREATE PROCEDURE dbo.spBF_calUpdateScheduleComments
        @Id integer,
        @commentText text
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	  BEGIN TRY
     BEGIN TRANSACTION
 	 DECLARE @OldCommentId 	 Int
 	 DECLARE @SaveCommentId 	 Int
 	 SELECT  @OldCommentId = Comment_Id from Crew_Schedule where cs_Id = @Id;
 	 SELECT @SaveCommentId = @OldCommentId
 	 EXECUTE dbo.spBF_UpdateComment  @OldCommentId  Output,@commentText
 	 IF @SaveCommentId Is Null and @OldCommentId Is Not Null
 	 BEGIN
 	  	 update Crew_Schedule set Comment_Id=@OldCommentId where cs_Id = @id ;
 	 END
 	 IF @SaveCommentId Is Not Null and @OldCommentId Is  Null
 	 BEGIN
 	  	 update Crew_Schedule set Comment_Id=Null where cs_Id = @id 
 	 END
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
