CREATE PROCEDURE dbo.spSupport_ChangeDBOAccount 
@AccountName varchar(50) = NULL, 
  @Password varchar(50) = NULL
AS
--declare  @AccountName varchar(50), @Password varchar(50) 
Select @AccountName = COALESCE(@AccountName, 'ProficyDBO'), @Password    = COALESCE(@Password, 'proficydbo')
DECLARE @DbOwners Table(UserName VarChar(1000))
INSERT INTO @DbOwners (UserName) VALUES('Sa')
INSERT INTO @DbOwners (UserName) 
 	 SELECT USER_NAME(member_principal_id) 
 	  	 FROM sys.database_role_members
 	  	 WHERE USER_NAME(role_principal_id) = 'db_owner'
IF Not Exists (SELECT 1 FROM @DbOwners WHERE UserName =  SYSTEM_USER) 	  	  	   
BEGIN
 	 Print 'You must be logged in as db_owner to execute this stored procedure. No changes have been applied.'
 	 RETURN 
END
if NOT exists (select * from sys.sysobjects where id = object_id(N'[dbo].[Tests]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
 	 Print 'You must be in the Proficy database to execute this stored procedure. No changes have been applied.'
 	 RETURN 
END
Declare @O varchar(255), @DBName varchar(255), @LoginLang varchar(30)
Select @DBName = db_name(), @loginlang = @@language
--Cleanup PA specific accounts before provisioning them
--Drops sysuser logins under @DBName
EXECUTE('Use ' + @DBName)
if exists (select * from sysusers where name = 'ProficyConnect')
exec sp_revokedbaccess 'ProficyConnect'
if exists (select * from sysusers where name = 'ComXClient')
exec sp_revokedbaccess 'ComXClient'
if exists (select * from sysusers where name = 'ProficyDBO')
exec sp_revokedbaccess 'ProficyDBO'
if exists (select * from sysusers where name = @AccountName)
exec sp_revokedbaccess @AccountName
--Drops Logins under default SQL Folder
if exists (select * from sysusers where name = 'ProficyDBO')
DROP LOGIN [ProficyDBO]
if exists (select * from sysusers where name = 'ComXClient')
DROP LOGIN [ComXClient]
if exists (select * from sysusers where name = 'ProficyConnect')
DROP LOGIN [ProficyConnect]
if exists (select * from sysusers where name = @AccountName)
EXECUTE('DROP LOGIN [' + @AccountName + ']')
EXECUTE('Use ' + @DBName)
EXECUTE('ALTER AUTHORIZATION ON DATABASE::' + @DBName + ' TO SA')
Declare @Major Int,@SQL VarChar(1000)
Declare @MyPos Int
Select @MyPos = charindex('.',convert(varchar(15),SERVERPROPERTY('ProductVersion')))
Select @Major = CONVERT(int,left(convert(varchar(10),SERVERPROPERTY('ProductVersion')),@MyPos-1))
if not exists (select * from master..syslogins where name = 'ComXClient')
BEGIN
 	 If @Major > 8
 	 BEGIN
 	  	 Select @SQL = 'CREATE LOGIN ComXClient WITH PASSWORD = ''comxclient'''
 	  	 Select @SQL = @SQL + ',DEFAULT_DATABASE = [' + @DBName + '],DEFAULT_LANGUAGE = ' + @loginlang + ',CHECK_POLICY = OFF' + ',CHECK_EXPIRATION = OFF'
 	  	 EXECUTE (@SQL)
 	 END
 	 ELSE
 	 BEGIN
 	  	 exec sp_addlogin 'ComXClient', 'comxclient', @DBName, @loginlang
 	 END
END
if (select l.sid from master.dbo.syslogins l
     join sysusers u on l.sid = u.sid 
 	   where l.isntname = 0 and loginname = 'ComXClient') is NULL 
 	 EXEC sp_adduser 'ComXClient'
else
 	 BEGIN
 	  	 EXEC sp_revokedbaccess 'comxclient'
 	  	 EXEC sp_grantdbaccess 'comxclient'
 	  	 EXEC sp_defaultdb 'comxclient', @DBName
   END
if not exists (select * from master..syslogins where name = 'ProficyConnect')
BEGIN
 	 If @Major > 8
 	 BEGIN
      Select @SQL = 'CREATE LOGIN ProficyConnect WITH PASSWORD = ''proficy'''      
      Select @SQL = @SQL + ',DEFAULT_DATABASE = ' + @DBName + ',DEFAULT_LANGUAGE = ' + @loginlang + ',CHECK_POLICY = OFF' + ',CHECK_EXPIRATION = OFF'          
 	  	 EXECUTE (@SQL)
 	 END
 	 ELSE
 	 BEGIN
   	  	 exec sp_addlogin 'ProficyConnect', 'proficy', @DBName, @loginlang
 	 END
END
if (select l.sid from master.dbo.syslogins l
     join sysusers u on l.sid = u.sid 
 	   where l.isntname = 0 and loginname = 'ProficyConnect') is NULL 
 	 EXEC sp_adduser 'ProficyConnect'
ELSE
 	 BEGIN
 	  	 EXEC sp_revokedbaccess 'ProficyConnect'
 	  	 EXEC sp_grantdbaccess 'ProficyConnect'
 	  	 EXEC sp_defaultdb 'ProficyConnect', @DBName
   END
if not exists (select * from master..syslogins where name = @AccountName)
BEGIN
 	 If @Major > 8
 	 BEGIN
       	  	 Select @SQL = 'CREATE LOGIN ' + @AccountName + ' WITH PASSWORD = ''' + @Password  + ''''     
       	  	 Select @SQL = @SQL + ',DEFAULT_DATABASE = ' + @DBName + ',DEFAULT_LANGUAGE = ' + @loginlang + ',CHECK_POLICY = OFF' + ',CHECK_EXPIRATION = OFF'      
 	  	 EXECUTE (@SQL)
 	 END
 	 ELSE
 	 BEGIN
   	  	 exec sp_addlogin @AccountName , @Password , @DBName, @loginlang
 	 END
END
-----------------------REPLACE THIS WITH THE DBO PASSWORD (default = 'proficydbo')
Execute spCmn_Encryption @Password ,'EncrYptoR',20,1,@O output 
Update Site_Parameters set Value = @O where Parm_Id = 20 and Hostname = ''
-----------------------REPLACE THIS WITH THE DBO USERNAME (default = 'ProficyDBO')
Update Site_Parameters set Value = @AccountName where Parm_Id = 19 and Hostname = ''
EXEC sp_defaultdb @AccountName, @DBName
EXEC sp_grantdbaccess @AccountName, @AccountName
EXEC sp_addrolemember N'db_owner', @AccountName
/*
if (select uid from sysusers where name = 'comxclient'
            and (issqluser = 1 or isntname = 1)         
            and (name <> 'guest' or hasdbaccess = 1)) IS NULL 
 	 BEGIN
 	  	 EXEC sp_revokedbaccess 'comxclient'
 	  	 EXEC sp_grantdbaccess 'comxclient'
   END
if (select uid from sysusers where name = 'ProficyConnect'
            and (issqluser = 1 or isntname = 1)         
            and (name <> 'guest' or hasdbaccess = 1)) IS NULL 
 	 BEGIN
 	  	 EXEC sp_revokedbaccess 'ProficyConnect'
 	  	 EXEC sp_grantdbaccess 'ProficyConnect'
   END
*/
EXEC spSupport_GrantAll
EXEC sp_defaultdb 'comxclient' , @DBName
EXEC sp_defaultdb 'ProficyConnect' , @DBName
EXEC sp_addrolemember 'db_securityadmin', 'comxclient'
-- This runs in the Verifies.
EXEC spSupport_PopulateModuleCheckDigit
-- New stuff - from Brent
exec sp_change_users_login 'Auto_Fix', @AccountName,Null, @Password
exec sp_change_users_login 'Auto_Fix', 'comxclient',Null, 'comxclient'
exec sp_change_users_login 'Auto_Fix', 'ProficyConnect',Null, 'proficy'
