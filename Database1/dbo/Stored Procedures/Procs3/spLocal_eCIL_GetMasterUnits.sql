
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetMasterUnits]

/*
Stored Procedure		:		spLocal_eCIL_GetMasterUnits
Author					:		Normand Carbonneau (STICorp)
Date Created			:		24-Sep-2009
SP Type					:		Generic
Editor Tab Spacing		:		3
Description:
===========
Get the list of Master Units for a production line.
CALLED BY				:  eCIL Configuration
Revision 		Date			Who					What
========		===========		==================		=================================================================================
1.0.0			24-Sep-2009		Normand Carbonneau		Creation of SP
2.0.0			29-Sep-2009		Normand Carbonneau		Removed @UserId and @MinimumAccessLevel parameters.
																		The @PLId parameter we receive already have filtered security for line.
2.0.1			30-Apr-2010		Normand Carbonneau		Correction of the ORDER BY Clause to avoid an error on SQL 2005.
																		The error was : The multi-part identifier "pu.PU_Desc" could not be bound.
2.1.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
2.1.2			20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
2.1.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
2.1.4 			02-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
2.1.5			27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard
TEST CODE :
EXEC spLocal_eCIL_GetMasterUnits 125, 1
*/
@PLId					INT,
@FirstItemBlank			BIT = 0

AS
SET NOCOUNT ON;

DECLARE
@EventSubTypeId			INT;


SET @EventSubTypeId =	(
								SELECT	Event_SubType_Id
								FROM		dbo.Event_Subtypes WITH(NOLOCK)
								WHERE		Event_Subtype_Desc LIKE 'eCIL'
								);

SELECT	CASE @FirstItemBlank
				WHEN 1 THEN -1
			END AS PU_Id,
			CASE @FirstItemBlank
				WHEN  1 THEN ''
			END AS PU_Desc
WHERE		@FirstItemBlank = 1
UNION
SELECT		pu.PU_Id, 
			pu.PU_Desc
FROM		dbo.Prod_Units_Base as pu WITH(NOLOCK)
JOIN		dbo.Event_Configuration as ec	WITH(NOLOCK)ON	pu.Pu_Id =	ec.Pu_Id	
WHERE		pu.PU_Id > 0
AND			pu.PL_Id = @PLId
AND			pu.Master_Unit IS NULL
AND			ec.Event_Subtype_Id	= @EventSubTypeId
ORDER BY	PU_Desc ASC;

