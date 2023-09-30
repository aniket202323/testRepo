CREATE PROCEDURE [dbo].[spBF_calShiftAddUpdateDelete]
 	  	 @TransType 	  	 Int,
 	  	 @TransNum 	  	 Int = 0,
        @ShiftId 	  	 Int = Null,
        @ShiftName 	  	 nvarchar(50)= Null,
        @ShiftDesc 	  	 nvarchar(50)= Null,
        @shiftDuration 	 float= Null,
        @startDate 	  	 datetime= Null,
        @endDate 	  	 datetime= Null,
        @UTCOffset 	  	 Int = 0,
 	  	 @UpdateUserId 	 Int = 1
AS
SET NOCOUNT ON
IF @UpdateUserId Is Null SET @UpdateUserId = 1
IF @TransType = 1
BEGIN
 	 SELECT @ShiftId = NULL
 	 select @ShiftId=Id from Shifts where Name = @shiftName and IsDeleted = 1
 	 if @ShiftId is null
 	 begin
 	  	 insert into Shifts (Name,Description,duration,start_time, end_time,Update_User_Id, Modified_On, IsDeleted, UTCOffset) 
 	  	  	 values (@shiftName, @shiftDesc, @shiftDuration, @startDate,@endDate, @UpdateUserId, GETUTCDATE(),0,@UTCOffset)
 	  	  	  	 SELECT @ShiftId = Id FROM Shifts WHERE Name = @shiftName
 	 end
 	 else 
 	 begin
 	  	 update Shifts set IsDeleted=0, Name=@shiftName,Description=@shiftDesc,duration=@shiftDuration,start_time=@startDate, end_time=@endDate,Update_User_Id=@UpdateUserId, Modified_On=GETUTCDATE(), UTCOffset = @UTCOffset 
 	  	  	 where Id = @ShiftId 	   
 	 end 
END
IF @TransType = 2
BEGIN
  update Shifts set Name=@ShiftName,
 	  	  	  	 Description=@ShiftDesc,
 	  	  	  	 duration=@shiftDuration,
 	  	  	  	 start_time=@startDate, 
 	  	  	  	 end_time=@endDate,
 	  	  	  	 Update_User_Id=@UpdateUserId, 
 	  	  	  	 Modified_On=GETUTCDATE(), 
 	  	  	  	 UTCOffset = @UTCOffset 
 	 WHERE Id = @ShiftId
END
IF @TransType = 3
BEGIN
 	 IF @TransNum = 0
 	  	 update Shifts set IsDeleted=1,Update_User_Id=@UpdateUserId, Modified_On=GETUTCDATE() where Id = @ShiftId 
 	 ELSE
 	  	 DELETE FROM Shifts where Id = @ShiftId
 	 SELECT 'Success'
END
IF @TransType In (1,2)
BEGIN
 	 select Id,Description,Name,Start_Time,End_Time,Duration,Update_User_Id,Modified_On,IsDeleted 
 	  	 from Shifts 
 	  	 where Id = @ShiftId
END
