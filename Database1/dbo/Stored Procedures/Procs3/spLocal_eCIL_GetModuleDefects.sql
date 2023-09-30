
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetModuleDefects]
/*
Stored Procedure		:		spLocal_eCIL_GetModuleDefects
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		19-Jun-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get all the opened defects on a module (Slave Unit)
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			19-Jun-2007		Normand Carbonneau		Creation of SP
1.1.0			15-Apr-2008		Normand Carbonneau		The SP now retrieves the defects differently due to the changes allowing
																		a task to have more than one open defect.
1.2.0			01-May-2008		Normand Carbonneau		Now retrieves the defects differently. Uses new functions:
																		fnLocal_eCIL_GetVarIdFromUDE, fnLocal_eCIL_GetNotificationFromUDE
																		No longer need to access the Tests table.
																		Now retrieves FL3 from fnLocal_eCIL_GetFL3
																		UDE_Desc is now : VarId-TestId-NotificationNumber.
1.0.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.0.2			20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.0.5			27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard																	
Test Code:
EXEC spLocal_eCIL_GetModuleDefects 1010
EXEC spLocal_eCIL_GetModuleDefects 1012
EXEC spLocal_eCIL_GetModuleDefects 1087
EXEC spLocal_eCIL_GetModuleDefects 1296
*/
@SlaveUnitId		INT

AS
SET NOCOUNT ON;

SELECT			DefectStart		=	CONVERT(VARCHAR(19), ude.Start_Time, 120),
				FL				=	dbo.fnLocal_eCIL_GetFL3(dbo.fnLocal_eCIL_GetVarIdFromUDE(ude.UDE_Id)),
				DefectType		=	es.Event_Subtype_Desc,
				ReportedBy		=	u.Username,
				Notification	=	dbo.fnLocal_eCIL_GetNotificationFromUDE(ude.UDE_Id),
				Description		=	c.Comment_Text
FROM			dbo.User_Defined_Events as ude WITH (NOLOCK)
JOIN			dbo.Event_Subtypes as es WITH (NOLOCK) ON (ude.Event_Subtype_Id = es.Event_Subtype_Id) AND (es.Extended_Info = 'DefectType')
JOIN			dbo.Users_Base as u WITH (NOLOCK) ON ude.[User_Id] = u.[User_Id]
LEFT JOIN	dbo.Comments as c WITH (NOLOCK) ON ude.Comment_Id = c.Comment_Id
WHERE			ude.PU_Id		= @SlaveUnitId
	AND			ude.End_Time IS NULL
ORDER BY		ude.Start_Time ASC ;

