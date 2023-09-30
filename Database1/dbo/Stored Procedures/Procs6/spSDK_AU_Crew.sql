CREATE procedure [dbo].[spSDK_AU_Crew]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@CrewDescription varchar(10) ,
@Department varchar(200) ,
@DepartmentId int ,
@EndTime datetime ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@ShiftDescription varchar(10) ,
@StartTime datetime 
AS
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT
DECLARE @sComment VarChar(255),@sStartTime VarChar(14),@sEndTime VarChar(14)
DECLARE @CurrentComment 	  	 Int
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
SET @sComment = substring(@CommentText,1,255)
 	 
EXECUTE spSDK_ConvertDate @StartTime OUTPUT,@sStartTime OUTPUT
EXECUTE spSDK_ConvertDate @EndTime OUTPUT,@sEndTime OUTPUT
IF @Id Is Null
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportCrewSchedule 	  	 @ProductionLine,@ProductionUnit,@CrewDescription,@ShiftDescription,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @sStartTime,@sEndTime,@sComment,@AppUserId,'X'
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @CurrentComment = Comment_Id,@Id = CS_Id 
 	  	 FROM Crew_Schedule a
 	  	 WHERE a.PU_Id = @ProductionUnitId and a.Start_Time = @StartTime
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Crew failed'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 SELECT @CurrentComment = Comment_Id FROM Crew_Schedule a where a.CS_Id = @Id
 	 EXECUTE spEMCSC_PutCrewSched 0,@AppUserId,@ProductionUnitId,@StartTime,
 	  	  	  	  	  	  	 @EndTime,@CrewDescription,@ShiftDescription,@CurrentComment,@Id
END
SET @CommentId = COALESCE(@CurrentComment,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
  UPDATE Crew_Schedule SET Comment_Id = null WHERE CS_Id = @Id
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Crew_Schedule SET Comment_Id = @CommentId WHERE CS_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
  Return(1)
