CREATE PROCEDURE dbo.spBF_AddUpdateDeleteUserCrew
        @CrewId integer,
        @userId integer,
        @startDate datetime,
        @endDate datetime,
 	  	 @ModifyUserId Int = 1,
 	  	 @TransType 	 Int
AS
SET NOCOUNT ON
IF @TransType = 1
BEGIN
 	 IF @ModifyUserId Is Null SET @ModifyUserId =1
 	 IF NOT EXISTS (SELECT TOP 1 * FROM Crew_Users_Mapping WHERE Crew_Id = @CrewId and User_Id = @userId)
 	 BEGIN
 	  	 insert into Crew_Users_Mapping (Crew_Id,User_Id,Start_Date,End_Date,Update_User_Id,Modified_On) 
 	  	  	 values (@CrewId,@userId, @startDate, @endDate,@ModifyUserId,GETUTCDATE())
 	 END
 	 ELSE 
 	 BEGIN
 	  	 UPDATE Crew_Users_Mapping set Start_Date=@startDate,End_Date= @endDate,Update_User_Id=@ModifyUserId,Modified_On=GETUTCDATE() 
 	  	  	 where Crew_Id = @CrewId and User_Id = @userId
 	 END
END
IF @TransType = 3
BEGIN
 	 delete from Crew_Users_Mapping where Crew_Id = @CrewId and User_Id = @userId
END
SELECT 'Success'
