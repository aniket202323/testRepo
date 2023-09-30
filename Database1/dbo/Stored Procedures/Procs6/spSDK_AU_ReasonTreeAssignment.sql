CREATE procedure [dbo].[spSDK_AU_ReasonTreeAssignment]
@AppUserId int,
@ActionEnabled bit ,
@ActionTree nvarchar(50) ,
@ActionTreeId int ,
@CauseTree nvarchar(50) ,
@CauseTreeId int ,
@Department varchar(200) ,
@DepartmentId int ,
@EventType nvarchar(50) ,
@EventTypeId tinyint ,
@MasterUnit nvarchar(50) ,
@MasterUnitId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@ResearchEnabled bit 
AS
DECLARE @Association Int
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
If (@ActionEnabled Is NULL)
 	 Select @ActionEnabled = 0
 	 
If (@ResearchEnabled Is NULL)
 	 Select @ResearchEnabled = 0
 	 
SET @Association = 1
IF @EventTypeId not in (2,3)
BEGIN
 	 Select 'Incorrect event type'
 	 RETURN(-100)
END
IF @EventTypeId = 3
BEGIN
 	 SELECT @Association = Coalesce(a.Waste_Event_Association ,@Association)
 	  	 FROM Prod_Units_Base a
 	  	 WHERE PU_Id = @ProductionUnitId
END
IF @EventTypeId = 2
BEGIN
 	 SELECT @Association = Coalesce(a.Timed_Event_Association ,@Association)
 	  	 FROM Prod_Units_Base a
 	  	 WHERE PU_Id = @ProductionUnitId
END
IF @Association = 0 SET @Association = 1
EXECUTE spEMSEC_PutEventConfigInfo  	 @ProductionUnitId,@EventTypeId,@CauseTreeId,@ActionTreeId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ResearchEnabled,@Association,@AppUserId
 	 
RETURN(1)
