CREATE PROCEDURE dbo.spCSS_LoadUserSecurity 
@User_Id int
AS
DECLARE  @IsRole int
DECLARE @RoleGroups Table(UserId INT)
DECLARE @Access Table(Access_Level INT,Group_Id INT)
SELECT @IsRole = Role_Based_Security
FROM USERS Where User_Id = @User_Id
IF @IsRole = 0
 	 Select * 
    From User_Security
    Where User_Id = @User_Id
ELSE
BEGIN
  	  INSERT INTO @RoleGroups(UserId)
  	    	  SELECT Role_User_Id 
 	  	  	 FROM User_Role_Security 
 	  	  	 WHERE User_Id = @User_Id
 	 INSERT INTO @Access(Access_Level,Group_Id) 	  	  	 
 	  	 SELECT Access_Level,Group_Id
 	  	 From User_Security
 	  	 Where user_Id = @User_Id
 	 INSERT INTO @Access(Access_Level,Group_Id) 	  	  	 
  	   Select Access_Level,Group_Id
  	    	  From User_Security
  	    	  Where  user_Id In (select UserId From  @RoleGroups)
  	 SELECT Access_Level = Max(Access_Level),Group_Id
  	  	 FROM @Access
  	  	 GROUP BY Group_Id
END
