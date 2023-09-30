Create Procedure dbo.spEMFC_UpdateFTP_Config
@mode tinyint,
@FC_Id int,
@engine nvarchar(20),
@Direction tinyint,
@mask nvarchar(20),
@desc nvarchar(50),
@localPath nvarchar(255),
@RemotePath nvarchar(255),
@host nvarchar(20),
@transType tinyint = null,
@PostAction tinyint = null,
@interval Int = null,
@username nvarchar(50) = null,
@Password nVarChar(25) = null,
@OSID int = null,
@EmailSuccess nvarchar(255) = null,
@EmailWarning nvarchar(255) = null,
@EmailFailure nvarchar(255) = null,
@NewName nVarChar(25) = null,
@FPADest nvarchar(50) = null,
@User_Id int,
@NewFCId int OUTPUT
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, 'spEMFC_UpdateFTP_Config' ,
                Substring(Convert(nVarChar(10), @mode) +',' + convert(nVarChar(10), @FC_Id)  +',' +  @engine  +',' +  Convert(nVarChar(10),@Direction)  +',' +  @mask  +',' +  @desc  +',' +  @LocalPath  +',' +  @remotePath  +',' +  @Host  +',' +  
 	    convert(nVarChar(10), @transType)  +',' +  convert(nVarChar(10), @PostAction)  +',' +  convert(nVarChar(10), @interval)  +',' +   @username   +',' +  @Password  +',' + convert(nVarChar(10), @OSID)  +  ',' + 
 	     @EmailSuccess +  ',' +  @EmailWarning +  ',' +  @EmailFailure +  ',' + @NewName +  ',' +  @FPADest +  ',' + Convert(nVarChar(10),@User_Id),1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
select @NewFCId = @FC_Id
if @mode = 0
   begin
      update FTP_Config
      set FTP_Engine = @engine, FA_Id = @Direction, Mask = @mask, FC_Desc = @desc, Local_Path = @localPath, Remote_Path = @RemotePath, User_Name =@Username, 
           Password = @Password, Interval = @interval, Host = @host, FTT_Id = @transType, FPA_Id = @PostAction, OS_Id = @OSID, Email_Success = @EmailSuccess, Email_Warning = @EmailWarning, 
           Email_Failure = @EmailFailure, New_Name = @NewName, FPA_Dest = @FPADest
      where FC_Id = @FC_Id
   end
if @mode = 1
 	 begin
 	 insert into FTP_Config (Is_Active,FTP_Engine,FC_Desc,
                                FA_Id,Interval,Host,Remote_Path,
                                Local_Path,Mask,User_Name,Password,
 	  	  	  	 New_Name,FPA_Id,FTT_Id,FPA_Dest,OnError_Rename,
 	  	  	  	 OnError_Stop,Email_Success,Email_Warning,Email_Failure,OS_Id) 
 	  	  	 Values (1, @engine, @desc, 
 	  	  	  	 @Direction, @interval, @host, @RemotePath,
 	  	  	  	 @localPath, @Mask, @username, @Password,
 	  	  	  	 @NewName, @PostAction,@transType, @FPADest, null,
 	  	  	  	 null, @EmailSuccess, @EmailWarning, @EmailFailure, @OSID)
        SELECT @NewFCId = Scope_Identity()
 	 end
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
