CREATE PROCEDURE uspGetManagerID5  
   @Id int    
     
AS    
BEGIN    
DECLARE @DSId as int   
DECLARE @FName as varchar(10)
DECLARE  @tblAvailableBatches TABLE(  
   Id    INT ,  
   DSId   INT  
   )  

   DECLARE  @tblAvailableBatchesUnit TABLE(  
   Id    INT ,  
   FName   varchar(10)  
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
 select * from @tblAvailableBatches  
 --DROP table #tblAvailableBatches  
END
