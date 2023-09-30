CREATE PROCEDURE uspGetManagerID7  
   @Id int    
     
AS    
BEGIN    
DECLARE @DSId as int   
DECLARE @Var_Desc as varchar(100)


   DECLARE  @tblAvailableBatchesUnit TABLE(  
   Id    INT ,  
   Var_Desc   varchar(100)  
   )  

  DECLARE  @tblAvailableBatches TABLE(  
   Id    INT ,  
   DSId   INT  
   )  
  -- SELECT  DS_id  
   --FROM dbo.Variables_Base  
   --WHERE Var_Id = @Id    
   SET @DSId = 0  
  
   INSERT @tblAvailableBatches(Id,DSId)  
   SELECT  DS_id,@DSId  
   FROM dbo.Variables_Base  
   WHERE Var_Id = @Id    
     
	  INSERT @tblAvailableBatchesUnit(Id,Var_Desc)  
   SELECT  DS_id,@Var_Desc  
   FROM dbo.Variables_Base  
   WHERE Var_Id = @Id  
    --INSERT #tblAvailableBatches(DSId)  
 --SELECT @DSId  
 select * from @tblAvailableBatches 

 select * from @tblAvailableBatchesUnit 
 --DROP table #tblAvailableBatches  
END