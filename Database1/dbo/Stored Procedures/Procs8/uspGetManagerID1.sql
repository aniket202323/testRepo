CREATE PROCEDURE uspGetManagerID1  
   @Id int  
   
AS  
BEGIN  
DECLARE @DSId as int 
CREATE	TABLE #tblAvailableBatches(
			Id				INT ,
			DSId			INT
			)

  -- SELECT  DS_id
   --FROM dbo.Variables_Base
   --WHERE Var_Id = @Id  
   SET @DSId = 0

   INSERT #tblAvailableBatches(Id,DSId)
   SELECT  DS_id,@DSId
   FROM dbo.Variables_Base
   WHERE Var_Id = @Id  
   
    --INSERT #tblAvailableBatches(DSId)
	--SELECT @DSId
	select * from #tblAvailableBatches
	DROP table #tblAvailableBatches
END