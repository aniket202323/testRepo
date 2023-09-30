  
  
CREATE   PROCEDURE  dbo.spLocal_WSGetInterPlantingULIDWebServiceURLPairs  
 @ULID VARCHAR(50)  
AS  
  
BEGIN  
  
SET @ULID  = REPLACE(REPLACE(COALESCE(@ULID, '%'), '*', '%'), '?', '_')  
 SELECT  ULID_Prefix,  
  WebService_URL  
  FROM dbo.Local_InterPlanting_ULID_WebService_Pairs  
   WHERE ULID_Prefix LIKE @ULID  
END  
RETURN  
  
