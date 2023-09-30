CREATE PROCEDURE uspGetManagerID8  
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
 select top 1 * from Local_PG_eCIL_Routes 
  select top 1 * from Local_PG_eCIL_TeamUsers 
 --select * from @tblAvailableBatchesUnit 
 --DROP table #tblAvailableBatches  
END

exec uspGetManagerID8  10581

select * from Variables_Base