













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Remove_Display_Variable]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 1.23
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-09-09
Version		:	1.2.0
Purpose		: 	SP is no more reseting variables' Interval and Offset fields to 0.

-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-04
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	15-Apr-2004
Version		: 	1.0.0
Purpose		: 	This sp remove all the variable of a display
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intSheetId	integer

AS
SET NOCOUNT ON

/*
--Reset sampling interval and offset for variable that are in no other display
UPDATE dbo.Variables
SET sampling_interval = 0,
    sampling_offset = 0
WHERE var_id IN (SELECT sv.var_id
                 FROM dbo.Sheets s
                      JOIN dbo.Sheet_Variables sv ON sv.sheet_id = s.sheet_id
                 WHERE s.sheet_id = @intSheetId AND s.sheet_type = 1 AND
                       sv.var_id IS NOT NULL AND
                       sv.var_id NOT IN (SELECT sv.var_id
                                         FROM dbo.Sheets s
                                              JOIN dbo.Sheet_Variables sv ON sv.sheet_id = s.sheet_id
                                         WHERE s.sheet_id <> @intSheetId AND 
                                               s.sheet_type = 1 AND sv.var_id IS NOT NULL))
*/

--Remove All Variable from the Display
DELETE 
FROM dbo.Sheet_Variables
WHERE sheet_id = @intSheetId

SET NOCOUNT OFF















