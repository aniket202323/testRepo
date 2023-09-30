CREATE procedure [dbo].spSDK_ShouldRunScript
AS
Declare
  @ThisScriptGenerationDate varchar(100),
  @InstalledScriptsVersion varchar(100),
  @ShouldRunScripts int
  Select @ShouldRunScripts = 0
  Select @ThisScriptGenerationDate = 'Ver8.2(20210519101739)'
  select @InstalledScriptsVersion = NULL
  select @InstalledScriptsVersion = App_Version from AppVersions Where App_Id = 27
  If (@InstalledScriptsVersion Is NULL) Or (SUBSTRING(@InstalledScriptsVersion,1,3) <> 'Ver')
    Select @ShouldRunScripts = 1
  Else
    Begin
      If (@ThisScriptGenerationDate >= @InstalledScriptsVersion)
        Select @ShouldRunScripts = 1
    End
  If (@ShouldRunScripts = 1)
    Update AppVersions Set App_Version = @ThisScriptGenerationDate Where App_Id = 27
  Return(@ShouldRunScripts)
