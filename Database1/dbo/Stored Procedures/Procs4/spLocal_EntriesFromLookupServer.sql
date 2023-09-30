  
  
CREATE PROCEDURE [dbo].[spLocal_EntriesFromLookupServer]  
 @ServerName nvarchar(50)  
  
AS  
  
  
  
DECLARE  
 @Cont int  
  
  
SET @Cont = ( SELECT  COUNT(*)  FROM Local_InterPlanting_ULID_WebService_Pairs WHERE ULID_Prefix = '000000000000')  
  
  
  
if @Cont = 0   
BEGIN  
 INSERT INTO Local_InterPlanting_ULID_WebService_Pairs VALUES(  
 '000000000000','http://'+@ServerName+'/pgInterPlantingWebServ/pgInterPlantingWebServ.asmx' )  
END   
  
if @Cont = 1   
BEGIN  
 UPDATE Local_InterPlanting_ULID_WebService_Pairs  
 SET WebService_URL = 'http://'+@ServerName+'/pgInterPlantingWebServ/pgInterPlantingWebServ.asmx'  
 WHERE ULID_Prefix = '000000000000'  
  
END  
  
if @Cont > 1   
BEGIN  
 DELETE FROM Local_InterPlanting_ULID_WebService_Pairs  
 WHERE ULID_Prefix = '000000000000'  
  
 INSERT INTO Local_InterPlanting_ULID_WebService_Pairs VALUES(  
 '000000000000','http://'+@ServerName+'/pgInterPlantingWebServ/pgInterPlantingWebServ.asmx' )   
END   
