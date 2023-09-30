CREATE PROCEDURE dbo.spServer_FTPGetConfig
@FTP_Engine nvarchar(20)
AS
declare 
    @Email_Success nVarChar(255), 
    @Email_Warning nVarChar(255), 
    @Email_Failure nVarChar(255),
 	  	 @EGId int, @Id int
DECLARE @TempResults TABLE(Id int IDENTITY(1,1), FC_Desc nVarChar(255), Is_Active tinyint, 
    Local_Path nVarChar(255), 
    Mask nvarchar(20) null, 
    Host nVarChar(20),
    OS_Id int null,
    OS_Desc nVarChar(255),  
    FA_Id tinyint,
    Interval int, 
    Remote_Path nVarChar(255), 
    New_Name nvarchar(25) null, 
    User_Name nVarChar(50), 
    Password nvarchar(25) null, 
    FTT_Id tinyint , 
    FPA_Id tinyint, 
    FPA_Dest nvarchar(50) null, 
    Email_Success nVarChar(255) null, 
    Email_Warning nVarChar(255) null, 
    Email_Failure nVarChar(255) null,
    Email_Success_Id int null, 
    Email_Warning_Id int null, 
    Email_Failure_Id int null, 
    OnError_Rename tinyint null,
    OnError_Stop tinyint null
)
insert into @TempResults(FC_Desc, Is_Active,  Local_Path, Mask, Host, OS_Id, OS_Desc, FA_Id, Interval, Remote_Path, New_Name,User_Name,
 	  	  	  	  	  	  	  	  	  	     Password, FTT_Id, FPA_Id, FPA_Dest, Email_Success, Email_Warning, Email_Failure, OnError_Rename, OnError_Stop)
Select FC_Desc, 
    Is_Active,
    Local_Path, 
    Mask, 
    Host,
    o.OS_Id,
    OS_Desc,  
    FA_Id,
    Interval, 
    Remote_Path, 
    New_Name, 
    User_Name, 
    Password, 
    FTT_Id , 
    FPA_Id , 
    FPA_Dest, 
    Email_Success, 
    Email_Warning, 
    Email_Failure,
    OnError_Rename,
    OnError_Stop
  From FTP_Config f
  Join Operating_Systems o on o.OS_Id = f.OS_Id
  Where FTP_Engine = @FTP_Engine and is_active is not null and is_active <> 0
 	 Declare FTP_Cursor CURSOR LOCAL STATIC READ_ONLY For 
 	  	 Select Id, Email_Success, Email_Warning, Email_Failure from @TempResults 
 	 Open FTP_Cursor  
 	 Fetch_Loop:
 	   Fetch Next From FTP_Cursor Into @Id, @Email_Success, @Email_Warning,  @Email_Failure 
 	   If (@@Fetch_Status = 0)
 	  	  	 Begin
 	  	  	  	 select @egid = null
 	  	  	  	 select @egid = EG_ID from Email_Groups where eg_desc = @Email_Success
 	  	  	  	 update @TempResults set email_success_id = @EGId where id = @Id
 	  	  	  	 select @egid = null
 	  	  	  	 select @egid = EG_ID from Email_Groups where eg_desc = @Email_Warning
 	  	  	  	 update @TempResults set email_warning_id = @EGId where id = @Id
 	  	  	  	 select @egid = null
 	  	  	  	 select @egid = EG_ID from Email_Groups where eg_desc = @Email_Failure
 	  	  	  	 update @TempResults set email_failure_id = @EGId where id = @Id
 	  	  	   Goto Fetch_Loop
 	  	  	 End
 	 Close FTP_Cursor
 	 Deallocate FTP_Cursor
select FC_Desc, Is_Active,  Local_Path, Mask, Host, OS_Id, OS_Desc, FA_Id, Interval, Remote_Path, New_Name,User_Name,
 	  	  	  Password, FTT_Id, FPA_Id, FPA_Dest, Email_Success_Id, Email_Warning_Id, Email_Failure_Id, OnError_Rename, OnError_Stop from @TempResults
