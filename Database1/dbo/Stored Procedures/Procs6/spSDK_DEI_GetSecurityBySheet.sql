CREATE Procedure  dbo.spSDK_DEI_GetSecurityBySheet(
@ProductionUnitId Int,
@ProductionLineId Int,
@SDKUserId Int,
@sheetId Int Output,
@MyAccessLevel Int Output)
AS
BEGIN
DECLARE @SecurityGroupId Int
IF @ProductionUnitId Is Not Null or @ProductionLineId Is Not Null 
BEGIN
 	 SELECT @sheetId = a.Sheet_Id,@SecurityGroupId = a.Group_Id
 	  	 FROM sheets a
 	  	 Join Prod_Units_Base c on c.PL_Id = a.PL_Id
 	  	 WHERE  a.PL_Id  = @ProductionLineId and a.Sheet_Type = 30
 	 IF @sheetId Is Null and @ProductionUnitId Is Not Null
 	  	 SELECT @sheetId = a.Sheet_Id,@SecurityGroupId = a.Group_Id
 	  	  	 FROM sheets a
 	  	  	 Join Sheet_Unit c on c.Sheet_Id  = a.sheet_id
 	  	  	 WHERE  c.PU_Id = @ProductionUnitId  and a.Sheet_Type = 30
 	 IF  	 @SecurityGroupId Is Null
 	 BEGIN
 	  	 IF @ProductionUnitId is Null
 	  	  	 SELECT @SecurityGroupId = pl.Group_Id
 	  	  	  	 FROM Prod_Lines_Base pl
 	  	  	  	 WHERE pl.PL_Id = @ProductionLineId
 	  	 ELSE
 	  	  	 SELECT @SecurityGroupId = coalesce(pu.Group_Id,pl.Group_Id)
 	  	  	  	 FROM Prod_Units_Base pu
 	  	  	     Join Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id
 	  	  	     WHERE pu.PU_Id = @ProductionUnitId
 	 END
 	 
END
IF @SecurityGroupId Is Not Null
BEGIN
 	 SELECT @MyAccessLevel = MAX(Access_Level)
 	  	 FROM User_Security us
 	  	 Where us.Group_Id = @SecurityGroupId and us.User_Id = @SDKUserId
END
ELSE
BEGIN
 	 SET @MyAccessLevel = 4 ---- Default to manager if no group
END
IF EXISTS( SELECT 1 from user_security where user_id=@SDKUserId and access_Level=4 and group_id=1)
 	 SET @MyAccessLevel = 4 --SuperUser (admin to admin)
END
SELECT @MyAccessLevel = coalesce(@MyAccessLevel,0)
