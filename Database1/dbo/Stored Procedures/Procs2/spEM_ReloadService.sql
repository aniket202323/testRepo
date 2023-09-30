CREATE PROCEDURE dbo.spEM_ReloadService
 	 @Service_Id int, 
 	 @Time_Stamp Datetime_ComX ,
 	 @ReloadFlag Int,
 	 @User_Id int,
 	 @ExtendedInfo 	 Int = Null
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ReloadService',
                Convert(nVarChar(10),@Service_Id) + ','  + 
                Convert(nVarChar(25),@Time_Stamp) + ','  + 
                Convert(nVarChar(10),@ReloadFlag) + ','  + 
 	    Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  If @ExtendedInfo = 1 -- alarm reload
 	 Begin
      UPDATE CXS_Service SET Reload_Flag = 3, Time_Stamp = Null WHERE Service_Id = @Service_Id
 	   Return
 	 End
  If @ReloadFlag = 2
    UPDATE CXS_Service SET Reload_Flag = @ReloadFlag, Time_Stamp = Null WHERE Service_Id = @Service_Id
  Else
    UPDATE CXS_Service SET Reload_Flag = 1, Time_Stamp = @Time_Stamp WHERE Service_Id = @Service_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
