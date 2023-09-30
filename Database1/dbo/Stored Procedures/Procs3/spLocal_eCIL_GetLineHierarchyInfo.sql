
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetLineHierarchyInfo]
/*
Stored Procedure		:		spLocal_eCIL_GetLineHierarchyInfo
Author					:		Normand Carbonneau (STICorp)
Date Created			:		17-Sep-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the Hierarchy of Plant Model as well as FLs and versions for line received as parameter
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			17-Sep-2007		Normand Carbonneau		Creation of SP
1.0.1			04-Jan-2010		Normand Carbonneau		Excluded deleted groups
																		Added LineId information required for Master Unit assignment of new modules.
1.1.0			16-Jun-2010		Normand Carbonneau		Now returns all Master Units having the eCIL Event Subtype configured on it,
																		regardless if they have Slave Units or Groups.
																		This is required to map the Plant Model based on FLs in VM.
																		This is also used to validate the Plant Model Configuration in VM.
1.2.0			21-Jun-2010		Normand Carbonneau		Added Line Version information required by VM in v2.4.0
1.2.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script																	
1.2.2			20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized, Added no locks and base tables
1.2.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.2.4 			02-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.2.5			04-July-2023	Payal Gadhvi			Updated SP with version management and to meet coding standard																		
Test Code:
EXEC spLocal_eCIL_GetLineHierarchyInfo 125
*/
@PLId	INT
AS
SET NOCOUNT ON ;

DECLARE
@EventSubTypeId	INT ;

SET @EventSubTypeId =
	(
	SELECT	Event_SubType_Id
	FROM		dbo.Event_Subtypes WITH(NOLOCK)
	WHERE		Event_Subtype_Desc LIKE 'eCIL'
	);
								
SELECT			DepartmentDesc			=	d.Dept_Desc,
				LineDesc				=	pl.PL_Desc,
				LineId					=	pl.PL_Id,
				MasterUnitDesc			=	pum.PU_Desc,
				SlaveUnitDesc			=	pus.PU_Desc,
				ProductionGroupDesc		=	pug.PUG_Desc,
				FL1						=	dbo.fnLocal_STI_Cmn_GetUDP(pl.PL_Id, 'FL1', 'Prod_Lines'),
				FL2						=	dbo.fnLocal_STI_Cmn_GetUDP(pum.PU_Id, 'FL2', 'Prod_Units'),
				FL3						=	dbo.fnLocal_STI_Cmn_GetUDP(pus.PU_Id, 'FL3', 'Prod_Units'),
				FL4						=	dbo.fnLocal_STI_Cmn_GetUDP(pug.PUG_Id, 'FL4', 'PU_Groups'),
				ModuleFeatureVersion	=	dbo.fnLocal_STI_Cmn_GetUDP(pus.PU_Id, 'eCIL_ModuleFeatureVersion', 'Prod_Units'),
				LineVersion				=	dbo.fnLocal_STI_Cmn_GetUDP(pl.PL_Id, 'eCIL_LineVersion', 'Prod_Lines')
FROM			dbo.Prod_Lines_Base as pl	WITH (NOLOCK)
JOIN			dbo.Departments_Base as d	WITH (NOLOCK)	ON	pl.Dept_id = d.Dept_Id
JOIN			dbo.Prod_Units_Base as pum	WITH (NOLOCK)	ON	pl.PL_Id = pum.PL_Id
JOIN			dbo.Event_Configuration as ec	WITH(NOLOCK)	ON	pum.Pu_Id =	ec.Pu_Id	
LEFT JOIN	dbo.Prod_Units_Base as pus		WITH (NOLOCK)	ON	pum.PU_Id = pus.Master_Unit
LEFT JOIN	dbo.PU_Groups as pug			WITH (NOLOCK)	ON	pus.PU_Id = pug.PU_Id
WHERE			pl.PL_Id				=	@PLId
	AND			ec.Event_Subtype_Id			=	@EventSubTypeId
	AND			(
					(pug.PUG_Id IS NULL)
					OR
					(pug.PUG_Id > 0)
				)
ORDER BY	LineDesc ASC,
			MasterUnitDesc ASC,
			SlaveUnitDesc ASC,
			ProductionGroupDesc ASC,
			FL3 ASC,
			FL4 ASC;
