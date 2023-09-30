CREATE PROCEDURE [dbo].[spRS_CompareVersions] 
AS
Declare @Proficy varchar(25)
Declare @ReportServer varchar(10)
Declare @Message varchar(255)
Declare @MajorVersionServer int
Declare @MajorVersionReport Real
Select @Proficy = App_Version 
From   AppVersions
Where  App_Id = 34 --2
Select @ReportServer = App_Version 
From   AppVersions
Where  App_Id = 11
Select @MajorVersionServer = Convert(Int, SubString(@Proficy, 1, 5))
Select @MajorVersionReport = Convert(real, @ReportServer)
If @MajorVersionServer = 12
  Begin
    If (@ReportServer < 400600.0)
      Select @Message = 'Warning!! Installed Version Of Report Server Appears To Be Old.  Please Upgrade The Report Server As Soon As Possible'
  End 
Select @Proficy 'Proficy', @ReportServer 'ReportServer', @Message 'Message'
