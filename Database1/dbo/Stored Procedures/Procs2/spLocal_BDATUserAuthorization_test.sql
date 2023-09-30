

/*Step B Creation Of SP*/
CREATE   PROCEDURE [dbo].[spLocal_BDATUserAuthorization_test]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDATUserAuthorization
Author				:		Pratik Patil
Date Created		:		07-27-2023
SP Type				:		BDAT
Editor Tab Spacing  :       3
	
Description:
=========
To check whether the user is an active proficy user 


CALLED BY:  BDAT Tool

Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			27-July-2023	Pratik Patil		   Creation of SP

Test Code:
Declare @UserName VARCHAR(100)= 'patil.p.21', @IsActiveUser VARCHAR(1)
EXEC spLocal_BDATUserAuthorization @UserName, @IsActiveUser OUTPUT
*/

@UserName       VARCHAR(30),
@IsActiveUser   VARCHAR(1) OUTPUT,
@IsDomainUser   VARCHAR(1) OUTPUT

AS
SET NOCOUNT ON

IF EXISTS(Select WindowsUserInfo from dbo.Users_Base where WindowsUserInfo = @UserName and Active = 1)
  BEGIN
	SET @IsActiveUser = '1';	
	SET @IsDomainUser = '1';
  END
ELSE
  BEGIN
	SET @IsActiveUser = '0';
	SET @IsDomainUser = '1';  
  END

