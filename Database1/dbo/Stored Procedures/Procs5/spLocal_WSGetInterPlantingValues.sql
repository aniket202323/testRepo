  
  
CREATE     PROCEDURE  dbo.spLocal_WSGetInterPlantingValues  
 @VARIABLE VARCHAR(50), --the variable name is the GlblDesc string from the Extended Information  
 @PUId  INT,  
 @Timestamp DATETIME  
AS  
  
BEGIN  
  
-- NEED TO FIND A UNIQUE    
--   
DECLARE @GLBLDESC NVARCHAR(100),@Result NVARCHAR(255)  
SET @GLBLDESC = '%GlblDesc=' + @VARIABLE +'%'  
  
SET @Result = NULL  
SELECT @Result = Result  
 FROM  Variables  va  
 LEFT JOIN Tests te   ON va.Var_Id = te.Var_Id  
 WHERE  va.Extended_Info LIKE @GLBLDESC  
 AND te.Result_On = @Timestamp  
 AND va.PU_Id = @PUId  
  
SELECT 'Value' = @Result  
  
END  
  
RETURN  
  
