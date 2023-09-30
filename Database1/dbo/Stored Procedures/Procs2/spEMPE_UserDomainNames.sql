Create Procedure dbo.spEMPE_UserDomainNames 
@Domain nVarChar(100)
AS
Declare @Users table (id Int Identity(1,1),UserId Int,username nVarChar(100),WindowsInfo nvarchar(255))
DECLARE @Start Int
DECLARE @End   Int
DECLARE @parseStart   Int
DECLARE @WindowsInfo nvarchar(255)
DECLARE @DomainName nvarchar(255)
SET @End = 0
SET @Start = 1
INSERT INTO @Users(UserId,UserName,WindowsInfo)
 	 SELECT User_Id,username, WindowsUserInfo from Users where WindowsUserInfo is not null and WindowsUserInfo <>''
SELECT @Start = MIN(ID),@End = MAX(id) from @Users
WHILE @Start <= @End
BEGIN
 	 SELECT @WindowsInfo = WindowsInfo FROM @Users WHERE ID = @Start
 	 SELECT @parseStart = CHARINDEX( '\',@WindowsInfo)
 	 IF @parseStart > 0
 	 BEGIN
 	  	 SELECT @DomainName = SUBSTRING(@WindowsInfo,1,@parseStart)
 	  	 SET @parseStart = 0
 	  	 SELECT @parseStart = CHARINDEX('.',@DomainName,CHARINDEX('.',@DomainName)+1)
 	  	 IF @parseStart > 0
 	  	  	 DELETE FROM @Users WHERE ID = @Start
 	 END
 	 SELECT @Start = @Start + 1
END
SET @DomainName = Null
SELECT @DomainName = coalesce(value,'') FROM Site_Parameters where Parm_Id = 69
IF (CHARINDEX('.',@DomainName,CHARINDEX('.',@DomainName)+1) = 0)
BEGIN
 	 INSERT INTO @Users(username,WindowsInfo)
 	  	 SELECT '***INVALID SITE PARAMETER (DefaultDomainName)***',@DomainName
END
SELECT 'User Name' = username,'Windows Information' = WindowsInfo From @Users order by ID desc
