/*
DECLARE @RC INT
  execute @RC =     spEM_SetDomainNames '','','na.pg.com2','na.pg.com'
    select @Rc
  select WindowsUserInfo  from users where WindowsUserInfo is not null
  update users set WindowsUserInfo = 'na\Comxclient' where username = 'Comxclient' 
  update users set WindowsUserInfo = 'pg.com.na\Testing12345' where username = 'Testing12345' 
  update users set WindowsUserInfo = 'na.pg.com\Testing12345' where username = 'Testing123' 
  SELECT * FROM users
--UPDATE Site_Parameters SET Value = '' WHERE Parm_Id = 69 
*/
Create Procedure dbo.spEM_SetDomainNames 
@OldDomParm nVarChar(100),
@NewDomParm nVarChar(100),
@OldDomUser nVarChar(100),
@NewDomUser nVarChar(100)
AS
DECLARE @RC Int
SET @RC = 0
IF @OldDomParm <> @NewDomParm 
BEGIN
 	 IF (CHARINDEX('.',@NewDomParm) >= 0) and (CHARINDEX('\',@NewDomParm) = 0)
 	 BEGIN
 	  	 IF Exists(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 69)
 	  	  	 UPDATE Site_Parameters SET Value = @NewDomParm WHERE Parm_Id = 69 and HostName = ''
 	  	 ELSE
 	  	  	 INSERT INTO Site_Parameters(Parm_Id,HostName,Parm_Required,Value) VALUES (69,'',0,@NewDomParm)
 	 END
 	 ELSE
 	 BEGIN
 	  	 SET @RC = @RC - 100
 	 END
END
IF @OldDomUser <> @NewDomUser 
BEGIN
 	 IF (CHARINDEX('.',@NewDomUser) > 0) and (CHARINDEX('\',@NewDomUser)) = 0
 	 BEGIN
 	  	 SET @OldDomUser = @OldDomUser + '\'
 	  	 SET @NewDomUser = @NewDomUser + '\'
 	  	 UPDATE Users SET  WindowsUserInfo = REPLACE( WindowsUserInfo,@OldDomUser,@NewDomUser) 
 	  	  	 WHERE LEFT(WindowsUserInfo,CHARINDEX('\',WindowsUserInfo)) = @OldDomUser
 	 END
 	 ELSE
 	 BEGIN
 	  	  	  	 SET @RC = @RC - 200
 	 END
END
RETURN (@RC)
