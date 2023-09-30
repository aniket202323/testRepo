CREATE PROCEDURE dbo.spEM_GeteventMapAll
  AS
DECLARE   @MasterUnits Table(MU 	 Int, EventStr  	 nvarchar(2000) , EventSubtype ntext ,  EventSubtypeDimensions nvarchar(2000)) 
DECLARE   @AllUnits Table(Id Int Identity(1,1), MU 	 Int)
DECLARE @MU 	 Int,
  @EventStr  	 nvarchar(2000) ,
  @EventSubtype nvarchar(max) , 
  @EventSubtypeDimensions nvarchar(2000)
DECLARE @Start Int,@End Int
INSERT INTO @AllUnits(MU)
 	 SELECT PU_Id From Prod_Units_Base WHERE (Master_Unit is Null OR Master_Unit = pu_Id) 	 and PU_Id != 0
SELECT @End = @@ROWCOUNT 
SELECT @Start = 1
WHILE @Start <= @End
BEGIN
 	 SELECT @MU = mu FROM @AllUnits WHERE Id = @Start
 	 EXECUTE spEM_GetEventMapString
 	   @MU,
 	   @EventStr  	  Output,
 	   @EventSubtype  Output, 
 	   @EventSubtypeDimensions  Output
  INSERT INTO @MasterUnits(MU,EventStr,EventSubtype,EventSubtypeDimensions) 
 	 SELECT  @MU,@EventStr,@EventSubtype,@EventSubtypeDimensions 
  SELECT @Start = @Start + 1
END
---Check to see what The UseProficyClient flag is set to!
Declare @UseProficyClient int
Select @UseProficyClient = value from site_parameters where parm_id = 87
IF @UseProficyClient = 0
       Delete from @MasterUnits where MU = -100
SELECT MU, EventStr , EventSubtype ,  EventSubtypeDimensions FROM @MasterUnits
