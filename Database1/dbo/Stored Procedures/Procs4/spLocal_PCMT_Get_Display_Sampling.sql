













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Display_Sampling]
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
Created by	:	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	17-Sep-2003	
Version		: 	1.0.0
Purpose		: 	Type = 1: return the sampling interval of a display
            	Type = 2: return the sampling offset of a display
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intType			integer,
@intDisplay  	integer

AS
SET NOCOUNT ON

IF @intType = 1
  SELECT interval
  FROM dbo.sheets
  WHERE sheet_id = @intDisplay
ELSE
  SELECT offset
  FROM dbo.sheets
  WHERE sheet_id = @intDisplay

SET NOCOUNT OFF















