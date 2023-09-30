
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetOpenedNotifications]
/*
Stored Procedure		:		spLocal_eCIL_GetOpenedNotifications
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		09-May-2008
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of all the opened defects.
CALLED BY				:  eCIL Web Service
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			09-May-2008		Normand Carbonneau		Creation of SP
1.0.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
1.2				20-Apr-2016	   	Nilesh Panpaliya		To filter defects with NULL notifications and with start time less than 183 days.
1.3				20-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
1.4				23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.5 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
1.6				27-Jul-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard															
Test Code:
EXEC spLocal_eCIL_GetOpenedNotifications
*/

AS
SET NOCOUNT ON;

/*-- The application NEEDS to receive those records ordered by Start_Date */
SELECT	ude.UDE_Id,
			dbo.fnLocal_eCIL_GetNotificationFromUDE(ude.UDE_Id) AS NotificationNbr,
			ude.Start_Time
FROM		dbo.User_Defined_Events ude WITH (NOLOCK)
JOIN		dbo.Event_Subtypes es WITH (NOLOCK) ON ude.Event_Subtype_Id = es.Event_Subtype_Id
WHERE		es.Extended_Info = 'DefectType'
	AND		DATEDIFF(day,ude.Start_Time,getdate()) < 183
	AND		ude.End_Time IS NULL 
	AND		dbo.fnLocal_eCIL_GetNotificationFromUDE(ude.UDE_Id) IS NOT NULL
ORDER BY	ude.Start_Time;

