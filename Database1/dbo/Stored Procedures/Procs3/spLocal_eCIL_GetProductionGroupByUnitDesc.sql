
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetProductionGroupByUnitDesc]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_GetProductionGroupByUnitDesc
Author				:		Linda Hudon, STI CORP
Date Created		:		22-Sept-2009
SP Type				:			
Editor Tab Spacing	:		3
Description:
=========
Get the list of Production Groups based on the Slave Unit and Line description we receive as parameters
CALLED BY:  eCIL Web Application
Revision 		Date			Who						What
========		=====			====					=====
1.0.0			22-Sep-2009		Linda Hudon				SP Creation
1.0.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			02-Aug-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard 
Test Call :
spLocal_eCIL_GetProductionGroupByUnitDesc  'ecIL001','TSK007'
*/
@LineDesc		VARCHAR(50),
@SlaveDesc		VARCHAR(50)

AS
SET NOCOUNT ON;

/*[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
--[]																	[]--
--[]							SECTION 1 - Variables Declaration		[]--
--[]																	[]--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]*/

DECLARE
@PuId		INT;

SET @PuId =	(
				SELECT	PU_Id 
				FROM		dbo.Prod_Units_Base WITH(NOLOCK)
				WHERE		Pu_Desc	=	@SlaveDesc
				AND		Pl_Id		=
					(
					SELECT	Pl_ID		
					FROM		dbo.Prod_Lines_Base as pl WITH(NOLOCK)
					WHERE		Pl_Desc = @LineDesc
					)
				);

IF @PuId IS NOT NULL
	
		SELECT	Pug_ID,
					Pug_Desc
		FROM		dbo.Pu_Groups pug WITH(NOLOCK)
		WHERE		Pu_Id		=	@PuId;
	
