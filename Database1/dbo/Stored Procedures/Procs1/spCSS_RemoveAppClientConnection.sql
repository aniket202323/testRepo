CREATE PROCEDURE dbo.spCSS_RemoveAppClientConnection
@ConnectionID int,
@AppId int,
@Counter int Output
AS
DECLARE 
  @ModuleId tinyint
SELECT @ModuleId = Module_Id
 FROM AppVersions 
 WHERE App_Id = @AppId 
UPDATE Client_Connection_Module_Data Set Counter = Counter - 1 Where Client_Connection_Id = @ConnectionID and Module_Id = @ModuleId
If @@ROWCOUNT = 0 and @AppId = 30
  --Time/Product_Time may be licensed under the Efficiency Module if no Quality licenses
  Begin
    Select @ModuleId = 2
    UPDATE Client_Connection_Module_Data Set Counter = Counter - 1 Where Client_Connection_Id = @ConnectionID and Module_Id = @ModuleId
  End
DELETE Client_Connection_Module_Data Where Client_Connection_Id = @ConnectionID and Module_Id = @ModuleId and Counter = 0 
UPDATE Client_Connection_App_Data Set Counter = Counter - 1 Where Client_Connection_Id = @ConnectionID and App_Id = @AppId
Select @Counter = Counter From Client_Connection_App_Data Where Client_Connection_Id = @ConnectionID and App_Id = @AppId
--Added this attempt to speed up the proc 9/22/03-Joe
if @Counter = 0 
  DELETE Client_Connection_App_Data Where Client_Connection_Id = @ConnectionID and App_Id = @AppId
