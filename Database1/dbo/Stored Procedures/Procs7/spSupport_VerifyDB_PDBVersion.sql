CREATE PROCEDURE dbo.spSupport_VerifyDB_PDBVersion
@MinVersion varchar(25), @DoIt bit OUTPUT
AS
Select @DoIt = 0
If exists (select * from sys.sysobjects where id = object_id(N'[dbo].[AppVersions]') and OBJECTPROPERTY(id, N'IsTable') = 1) 
  BEGIN
    If (Select App_Version from AppVersions Where App_Id = 34) = 'Unknown' 
      Select @DoIt = 1
 	  	 Else If (Select App_Version from AppVersions Where App_Id = 34) <= @MinVersion 
 	  	  	  	  	 Select @DoIt = 1
 	 If @DoIt = 0
 	  	 Begin
 	  	  	 If (Select count(*) from AppVersions Where  App_Id = 34) = 0 and (Select count(*) from AppVersions Where  App_Id = 2) = 1
 	  	  	  	 Select @DoIt = 1
 	  	 End
  END
return
