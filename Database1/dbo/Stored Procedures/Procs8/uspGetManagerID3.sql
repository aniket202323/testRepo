﻿CREATE PROCEDURE uspGetManagerID3 
   @Id int  
   
AS  
BEGIN  
DECLARE @DSId as int 
DECLARE	 @tblAvailableBatches TABLE(
			Id				INT ,
			DSId			INT
			)

  -- SELECT  DS_id
   --FROM dbo.Variables_Base
   --WHERE Var_Id = @Id  
   SET @DSId = 0

   INSERT @tblAvailableBatches(Id,DSId)
   SELECT  DS_id,@DSId
   FROM dbo.Variables_Base
   WHERE Var_Id = @Id  
   
    --INSERT #tblAvailableBatches(DSId)
	--SELECT @DSId
	select Id,DSId from @tblAvailableBatches
	--DROP table #tblAvailableBatches
END