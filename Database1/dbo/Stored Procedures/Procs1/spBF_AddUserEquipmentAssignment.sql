-- Returns -1 if the equipment is assigned and the override bit is not 1
-- Returns -2 if the start time is prior to the previous end time
CREATE Procedure dbo.spBF_AddUserEquipmentAssignment
@EqId int, @StartTime datetime, @UserId int, @Override bit
AS
BEGIN
  SET NOCOUNT ON
-- Declare @mytable table (id int identity(1,1),value nVarChar(100))
-- Declare @Start int = 1
-- Declare @end Int
-- Declare @eId nvarchar(36)
-- insert into @mytable(value)
-- select value from [dbo].[fnLocal_CmnParseList](@EqId,',')
--Select @end = @@ROWCOUNT 
--
--IF @end = 0 --NO DATA
-- 	 RETURN -100
/***** Validate guids *******/
-- BEGIN TRY
-- IF EXISTS(SELECT  1 FROM @mytable  where VALUE not in (SELECT EquipmentId FROM EQUIPMENT ))
-- 	 RETURN -200
--END TRY
--BEGIN CATCH
-- 	 RETURN -200
--END CATCH
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
-- While @start<=@End
BEGIN
 	 -- SELECT @eId = Value from @mytable where id = @start
   Declare @eId int = @EqId
 	 IF @Override = 1
 	 Begin
 	  	 --Need the check that the start time is not prior to the end time of the last entry
 	  	 If Exists (select EndTime from [dbo].[User_Equipment_Assignment]
 	  	  	  	  	 where @eId = EquipmentId and EndTime > @StartTime)
 	  	 Begin
 	  	  	 SELECT Error = 'Error: Start time is prior to End time of last entry'
      return -- -2;
 	  	 End 	  	 
 	  	  	  	 
 	  	 Update [dbo].[User_Equipment_Assignment]
 	  	 SET EndTime = @StartTime
 	  	 Where @eId = EquipmentId and EndTime IS NULL 	  	 
 	  	 
 	  	 Insert into [dbo].User_Equipment_Assignment (EquipmentId, UserId, StartTime)
 	  	 VALUES (@eId, @UserId, 	 @StartTime); 	 
 	 End
 	 Else
 	 Begin
 	  	 If Exists (select EquipmentId from [dbo].[User_Equipment_Assignment]
 	  	  	  	 where @eId = EquipmentId and EndTime IS NULL)
 	  	  	 Begin
 	  	  	  	 SELECT Error = 'Error: Unit is already assigned'
        return --return -1
 	  	  	 End
 	  	 Else If Exists (select EndTime from [dbo].[User_Equipment_Assignment]
 	  	  	  	  	 where @eId = EquipmentId and EndTime > @StartTime)
 	  	 Begin
 	  	  	 SELECT Error = 'Error: Start time is prior to End time of last entry'
      return -- -2;return -2;
 	  	 End 	 
 	  	 Else
 	  	  	 Begin
 	  	  	  	 Insert into [dbo].User_Equipment_Assignment (EquipmentId, UserId, StartTime)
 	  	  	  	 VALUES (@eId, @UserId, 	 @StartTime);
 	  	  	 End 	 
 	 End
-- SELECT @Start = @Start + 1
END
SELECT 'Success'
Return
END
