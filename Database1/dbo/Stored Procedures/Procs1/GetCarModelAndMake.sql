CREATE PROCEDURE GetCarModelAndMake
@Id INT,

@CarMake varchar(50) OUTPUT
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
   
   SET @DSId = 0    
    
   INSERT @tblAvailableBatches(Id,DSId)    
   SELECT  DS_id,@DSId    
   FROM dbo.Variables_Base    
   WHERE Var_Id = @Id      
       
   INSERT @tblAvailableBatchesUnit(Id,Var_Desc)    
   SELECT  DS_id,@Var_Desc    
   FROM dbo.Variables_Base    
   WHERE Var_Id = @Id    
     
SET @CarMake = 'test3455'
--select * from @tblAvailableBatches
--select * from @tblAvailableBatchesUnit 
--select top 10 * from Local_PG_eCIL_Routes 
END