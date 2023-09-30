  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
 This stored procedure receives a Revision number and stored procedure name and updates the AppVersions table.  
 If the stored procedure entry already exists, it is updated.  If there is no entry, it is inserted.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
   
 2006-07-17 Vince King  Rev1.00  
 Original version.  
  
 2006-OCT-13 Langdon Davis Rev1.01  
 Added an update of the Modified_On field to the current date/time when a version is upgraded so we can track   
 when the update took place.  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE PROCEDURE [dbo].[spLocal_UpdateAppVersions]  
-- DECLARE  
   @AppVersion VARCHAR(20),  
   @SPName  VARCHAR(50)  
  
AS  
  
-- For testing  
-- SELECT @AppVersion  = '7.57',  
--    @SPName   = 'spLocal_RptCvtgELPVAL'  
  
DECLARE  @Next_AppId INTEGER  
  
if (select count(app_id) from appversions where app_name = @SPName) > 0   
 UPDATE appversions  
  SET App_Version = @AppVersion,  
     Modified_On = GETDATE()  
 WHERE App_Name = @SPName  
ELSE  
 BEGIN  
  SELECT @Next_AppId = MAX(App_Id) + 1  
  FROM AppVersions  
  
  INSERT AppVersions(Modified_On, App_Id, Module_Id, App_Version, App_Name)  
  SELECT GETDATE(), @Next_AppId, 0, @AppVersion, @SPName  
 END  
  
SET NOCOUNT OFF  
  
  
