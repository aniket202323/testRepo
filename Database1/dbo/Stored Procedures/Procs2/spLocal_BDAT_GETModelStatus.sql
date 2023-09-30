

/*Step B Creation Of SP*/
CREATE   PROCEDURE [dbo].[spLocal_BDAT_GETModelStatus]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDAT_GETModelStatus
Author				:		Pratik Patil
Date Created		:		07-27-2023
SP Type				:		BDAT
Editor Tab Spacing  :       3
	
Description:
=========
To check whether the user is an active proficy user.
To execute the stored procedure please provide <full domain name>\<PG short name> as Username


CALLED BY:  BDAT Tool

Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			27-July-2023	Pratik Patil		   Creation of SP

Test Code:
Declare @IsActive VARCHAR(1), @IsConfigured VARCHAR(1)
EXEC spLocal_BDAT_GETModelStatus @IsActive OUTPUT, @IsConfigured OUTPUT
print @IsActive
print @IsConfigured
*/


@IsActive   VARCHAR(1) OUTPUT,
@IsConfigured VARCHAR(1) OUTPUT
AS
SET NOCOUNT ON

SET @IsConfigured = '0';
IF EXISTS(Select Is_Active from Event_Configuration where ED_Model_Id = 49000)
	BEGIN
		SET @IsConfigured = '1';
	END
		
IF EXISTS(Select Is_Active from Event_Configuration where ED_Model_Id = 49000 and Is_Active = 1)
  BEGIN
	SET @IsActive = '1';
  END
ELSE
  BEGIN
	SET @IsActive = '0';  
  END

