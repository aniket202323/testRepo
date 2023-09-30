













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_DisplaySubtype]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_DisplaySubtype

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Alexandre Turgeon, Solutions et Technologies Industrielles inc.
Date created	:	2006-06-07
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp returns a display's event subtype
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what

*/
@vcrDisplayDesc 	varchar(50)

AS
SET NOCOUNT ON

SELECT event_subtype_id
FROM dbo.sheets
WHERE sheet_desc = @vcrDisplayDesc

SET NOCOUNT OFF















