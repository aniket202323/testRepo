CREATE PROCEDURE dbo.spCSS_CreateDomainUser 
  @ntDomain  nvarchar(50),
  @ntUserName nvarchar(50),
  @roleIdList nvarchar(512),
  @userName nvarchar(50) output,
  @password nvarchar(50) output
AS
DECLARE @UTCNow Datetime,@DbNow Datetime
DECLARE @count int
DECLARE @userId int
DECLARE @sql nvarchar(680)
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
SET @userName = @ntUserName
IF Exists(Select 1 From Users where Username = @userName and (WindowsUserInfo is Null or WindowsUserInfo = ''))
BEGIN
 	 UPDATE Users SET WindowsUserInfo = @ntDomain + '\' + @ntUserName,Mixed_Mode_Login = 0,Role_Based_Security = 1 WHERE Username = @userName
END
ELSE
BEGIN
 	 IF Exists(Select 1 From Users where Username = @userName)
 	 BEGIN
 	  	 select @count = count(Username) from Users where Username = @userName
 	  	 while @count > 0
 	  	   begin
 	  	  	 set @userName = @userName + '|'
 	  	  	 select @count = count(Username) from Users where Username = @userName
 	  	   end
 	 END
 	 --Create a site user
 	 set @password = cast(@DbNow as nvarchar(50))
 	 insert into Users(Mixed_Mode_Login, Password, Role_Based_Security, User_Desc, Username, View_Id, WindowsUserInfo)
  	  	 values(0, @password, 1, '', @userName, 0, @ntDomain + '\' + @ntUserName)
END
SELECT @userId = User_Id From Users WHERE Username = @userName
IF @userId Is Not Null
BEGIN
--Build user security roles
 	 set @sql = 'insert into User_Security(Access_Level, Group_Id, User_Id)
 	   select Access_Level, Group_Id, ' + convert(nvarchar(50), @userId) + ' from User_Security
 	   where User_Id in (' + @roleIdList + ')'
 	 exec(@sql)
END
RETURN(0)
