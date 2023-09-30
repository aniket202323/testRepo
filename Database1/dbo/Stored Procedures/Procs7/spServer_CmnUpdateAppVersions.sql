CREATE PROCEDURE dbo.spServer_CmnUpdateAppVersions
@AppId int,
@AppName nVarChar(100),
@Version nVarChar(100)
AS
Declare
  @OrigVersion nVarChar(10),
  @OrigModified datetime,
  @NewModified datetime
Delete From AppVersions Where (App_Id = 12) And (App_Name = 'WatchDog')
Delete From AppVersions Where App_Name in ('Server','Proficy Server')
If (@AppId Is NULL) Or (@AppId = 0)
  Begin
    Select @AppId = NULL
    Select @AppId = Service_Id From CXS_Service Where (Service_Desc = @AppName)
    If (@AppId Is NULL)
      Return
    Select @AppId = @AppId + 100
  End
Select @OrigVersion = NULL
Select @OrigModified = NULL
Select @OrigVersion = App_Version,
       @OrigModified = Modified_On
  From AppVersions Where (App_Id = @AppId)
If (@OrigVersion Is Not NULL)
  Begin
    Select @NewModified = dbo.fnServer_CmnGetDate(GetUTCDate())
    If (@Version = @OrigVersion)
      Select @NewModified = @OrigModified
    Update AppVersions 
 	 Set App_Name = @AppName,
            App_Version = @Version,
            Modified_On = @NewModified
      Where App_Id = @AppId
  End
Else
  Begin
    Insert Into AppVersions(App_Id,App_Name,App_Version,Modified_On) Values (@AppId,@AppName,@Version,dbo.fnServer_CmnGetDate(GetUTCDate()))
  End
