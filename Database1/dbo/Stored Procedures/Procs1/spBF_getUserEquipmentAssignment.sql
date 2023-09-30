CREATE Procedure dbo.spBF_getUserEquipmentAssignment
@EqId int, @StartTime datetime, @EndTime datetime
AS
BEGIN
SET NOCOUNT ON
  IF not exists(SELECT 1 FROM Prod_Units_Base where PU_Id = @EqId)
  BEGIN
    SELECT Error = 'Error: Unit Not Found'
   	 Return
  END
 	 Select U.Username, UEA.EquipmentId, UEA.UserId, UEA.StartTime, UEA.EndTime
 	 From [dbo].[User_Equipment_Assignment] UEA
     	 Join Users U on U.User_Id = UEA.UserId
 	 Where UEA.EquipmentId = @EqId and -- in (select value from @mytable) and 
   	 ((@StartTime >= UEA.StartTime and (UEA.EndTime <= @EndTime OR UEA.EndTime IS NULL)) OR 
   	 (@StartTime < UEA.StartTime and @EndTime >= UEA.StartTime) OR
   	 (@StartTime >= UEA.StartTime And @EndTime <= UEA.EndTime))
 	 Order By UEA.StartTime desc
END
