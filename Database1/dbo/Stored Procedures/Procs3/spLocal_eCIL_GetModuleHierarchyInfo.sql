
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetModuleHierarchyInfo]
/*
Stored Procedure		:		spLocal_eCIL_GetModuleHierarchyInfo
Author					:		Normand Carbonneau (STICorp)
Date Created			:		17-Sep-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the Hierarchy of Plant Model as well as FLs and versions for module received as parameter
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			17-Sep-2007		Normand Carbonneau		Creation of SP
1.0.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard															
Test Code:
EXEC spLocal_eCIL_GetModuleHierarchyInfo 3541
*/
@SlaveUnitId	INT

AS
SET NOCOUNT ON;

DECLARE
@EventSubTypeId	int;

SET @EventSubTypeId =
	(
		SELECT	Event_SubType_Id
		FROM	dbo.Event_Subtypes WITH(NOLOCK)
		WHERE	Event_Subtype_Desc LIKE 'eCIL'
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
FROM			dbo.Prod_Lines_Base as pl			WITH (NOLOCK)
JOIN			dbo.Departments_Base as d			WITH (NOLOCK)	ON pl.Dept_id = d.Dept_Id
JOIN			dbo.Prod_Units_Base as pum			WITH (NOLOCK)	ON pl.PL_Id = pum.PL_Id
JOIN			dbo.Event_Configuration as  ec	WITH(NOLOCK)	ON	pum.Pu_Id =	ec.Pu_Id	
LEFT JOIN	dbo.Prod_Units_Base as pus				WITH (NOLOCK)	ON pum.PU_Id = pus.Master_Unit
LEFT JOIN	dbo.PU_Groups pug				WITH (NOLOCK)	ON pus.PU_Id = pug.PU_Id
WHERE			pus.PU_Id = @SlaveUnitId
	AND			ec.Event_Subtype_Id		= @EventSubTypeId
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
