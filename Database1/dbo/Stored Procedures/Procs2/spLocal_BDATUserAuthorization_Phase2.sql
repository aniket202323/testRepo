

/*Step B Creation Of SP*/
CREATE   PROCEDURE [dbo].[spLocal_BDATUserAuthorization_Phase2]


/*-------------------------------------------------------------------------------------------------
Stored Procedure			spLocal_BDATUserAuthorization_Phase2
Author						Pratik Patil
Date Created				09-01-2023
SP Type						BDAT
Editor Tab Spacing         3
	
Description
=========
To check whether the user is an active proficy user.
To execute the stored procedure please provide <full domain name>\<PG short name> as Username

CALLED BY  BDAT Tool

Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			01-SEP-2023	Pratik Patil		   Creation of SP
Test Code
Declare @UserName VARCHAR(100)= 'ap.pg.com\patil.p.21', @IsActiveUser VARCHAR(1),@AccessLevel VARCHAR(1) 
EXEC spLocal_BDATUserAuthorization_Phase2 @UserName, @IsActiveUser OUTPUT, @AccessLevel OUTPUT
print @IsActiveUser
print @AccessLevel
*/

@UserName       VARCHAR(30),
@IsActiveUser   VARCHAR(1) OUTPUT,
@AccessLevel	VARCHAR(1) OUTPUT

AS
SET NOCOUNT ON

SET @AccessLevel = 0;
IF EXISTS(SELECT WindowsUserInfo FROM dbo.Users_Base WHERE WindowsUserInfo = @UserName and Active = 1)
  BEGIN
	SET @IsActiveUser = '1';
	SELECT DISTINCT @AccessLevel = us.Access_Level FROM Users_Base ub JOIN User_Security us
	ON ub.User_Id = us.User_Id  WHERE WindowsUserInfo = @UserName;	
  END
ELSE
  BEGIN
	SET @IsActiveUser = '0';  
  END;
