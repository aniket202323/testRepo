CREATE PROCEDURE [dbo].[spLocal_eCIL_GetTaskOpenedDefects]
/*
Stored Procedure		:		spLocal_eCIL_GetTaskOpenedDefects
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		16-Jun-2008
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get all the opened defects on a Task, regardless of the instance.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			16-Jun-2008		Normand Carbonneau		Creation of SP
1.0.1			03-Aug-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			02-Aug-2023		Payal Gadhvi			Updated SP to add version management and to meet SP standard
Test Code:
EXEC spLocal_eCIL_GetTaskOpenedDefects 79307
EXEC spLocal_eCIL_GetTaskOpenedDefects 79298
*/
@VarId		INT

AS
SET NOCOUNT ON;

DECLARE
@VarIdStr	VARCHAR(15);

SET @VarIdStr = CONVERT(VARCHAR, @VarId);

SELECT			DefectStart		=	CONVERT(VARCHAR(19), ude.Start_Time, 120),
				FL				=	dbo.fnLocal_eCIL_GetFL3(dbo.fnLocal_eCIL_GetVarIdFromUDE(ude.UDE_Id)),
				DefectType		=	es.Event_Subtype_Desc,
				ReportedBy		=	u.Username,
				Notification	=	dbo.fnLocal_eCIL_GetNotificationFromUDE(ude.UDE_Id),
				Description		=	c.Comment_Text
FROM			dbo.User_Defined_Events as ude WITH (NOLOCK)
JOIN			dbo.Event_Subtypes as es WITH (NOLOCK) ON (ude.Event_Subtype_Id = es.Event_Subtype_Id) AND (es.Extended_Info = 'DefectType')
/* This is supposed to be a JOIN on Users table, but due to a bug in spServer_DBMgrUpdUserEvent that does not write the
-- User_Id in User_Defined_Events table, a left join is provided temporarily. */
LEFT JOIN	dbo.Users_Base as u WITH (NOLOCK) ON ude.[User_Id] = u.[User_Id]
JOIN		dbo.Prod_Units_Base as pu WITH (NOLOCK) ON ude.PU_Id = pu.PU_Id
LEFT JOIN	dbo.Comments as c WITH (NOLOCK) ON ude.Comment_Id = c.Comment_Id
WHERE		ude.UDE_Desc LIKE @VarIdStr + '-%-%'
AND			ude.End_Time IS NULL
ORDER BY	ude.Start_Time ASC;

