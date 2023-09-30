CREATE PROCEDURE dbo.spSupport_VerifyDB_DBVersion
@MinVersion varchar(25), @DoIt bit OUTPUT
AS
Select @DoIt = 0
If exists (select * from sys.sysobjects where id = object_id(N'[dbo].[AppVersions]') and OBJECTPROPERTY(id, N'IsTable') = 1) 
  BEGIN
    If (Select App_Version from AppVersions Where App_Id = 2) = 'Unknown' 
      Select @DoIt = 1
    Else If (Select CHARINDEX('/',App_Version,1) from AppVersions Where App_Id = 2) > 1 
      Select @DoIt = 1
    Else If (Select isnumeric(App_Version) from AppVersions Where App_Id = 2) = 0 
 	  	  	 Begin
 	  	  	  	 If (Select App_Version from AppVersions Where App_Id = 2) <= @MinVersion 
 	  	  	  	  	 Select @DoIt = 1
 	  	  	 End
    Else If  (Select isnumeric(@MinVersion))  = 0  
      Select @DoIt = 1
    Else If (Select CONVERT(real, App_Version) from AppVersions Where App_Id = 2) <= CONVERT(real,@MinVersion) 
      Select @DoIt = 1
  END
return
