













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Error]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreailt, Solutions et Technologies Industrielles Inc.
On				:	18-Dec-02	
Version		:	1.0.0
Purpose		:	This SP gets error from Local_PG_PCMT_errors
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@dtmStartTime	DATETIME = NULL,
@dtmEndTime		DATETIME = NULL

AS

SET NOCOUNT ON

SELECT CONVERT(VARCHAR,[timestamp],120) AS [Entry On], [Description], Module, Sub
FROM dbo.Local_PG_PCMT_Errors
WHERE [timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      [timestamp] < ISNULL(@dtmEndTime,GETDATE())
ORDER BY [timestamp]


SET NOCOUNT OFF















