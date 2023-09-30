-- Returns -1 if the equipment is assigned and the override bit is not 1
-- Returns -2 if the start time is prior to the previous end time
CREATE Procedure dbo.spBF_closeUserEquipmentAssignment
@EqId int, @EndTime datetime, @UserId int
AS
BEGIN
SET NOCOUNT ON
--Declare @mytable table (id int identity(1,1),value nVarChar(100))
--Declare @Start int = 1
--Declare @end Int
--Declare @eId nvarchar(36)
Declare @time datetime2
IF not exists(SELECT 1 FROM Prod_Units_Base where PU_Id = @EqId)
BEGIN
  SELECT Error = 'Error: Unit Not Found'
 	 Return
END
/**** Validate User ******/
IF not exists(SELECT 1 FROM Users where User_Id  = @UserId)
BEGIN
 	 SELECT Error = 'Error: User Not Found'
 	 Return
END
--While @start<=@End
BEGIN
 	 --SELECT @eId = Value from @mytable where id = @start
 	 Declare @eId int = @EqId
 	 select @time = StartTime from [dbo].[User_Equipment_Assignment] UEA
 	  	  	 where @eId = UEA.EquipmentId and @UserId = UEA.UserId and EndTime IS NULL
 	 If (@time < @EndTime) 	  	  	  	 
 	 Begin
 	  	 Update [dbo].[User_Equipment_Assignment]
 	  	 SET EndTime = @EndTime
 	  	 Where @eId = EquipmentId and EndTime IS NULL 	  	 
 	 End 	  	  	  	  	  	  	 
 	 Else if (@time is NULL)
 	 Begin
    SELECT Error = 'Error: Not found'
 	  	 return -- -2 --not found
 	 End
 	 Else
 	 Begin
    SELECT Error = 'Error: End time is less than Start time'
 	  	 return --  -1 -- end time is < start time
 	 End
--SELECT @Start = @Start + 1
END
 	 SELECT 'Success'
 	 Return
END
