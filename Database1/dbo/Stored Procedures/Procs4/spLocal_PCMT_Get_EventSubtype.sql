













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE 	PROCEDURE [dbo].[spLocal_PCMT_Get_EventSubtype]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_EventSubtype

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Alexandre Turgeon, Solutions et Technologies Industrielles inc.
Date created	:	2006-05-17
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp return the possible event subtype for PCMT.
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what

*/

AS
SET NOCOUNT ON

SELECT event_subtype_id, event_subtype_desc
FROM dbo.Event_SubTypes
WHERE event_subtype_desc LIKE '%%'

SET NOCOUNT OFF















