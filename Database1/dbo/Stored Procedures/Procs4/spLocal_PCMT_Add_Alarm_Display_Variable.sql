















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Add_Alarm_Display_Variable]
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
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	15-Apr-2004
Version		: 	1.0.0
Purpose		: 	This sp add a variable to an alarm display.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intSheetId	integer,
@intPlId		integer,
@vcrVarDesc	varchar(50)

AS
SET NOCOUNT ON

DECLARE
@intOrder	integer,
@intVarId	integer

--Get the next var_order
SELECT @intOrder = MAX(var_order)+ 1
FROM dbo.Sheet_Variables
WHERE sheet_id = @intSheetId

SELECT @intVarId = v.var_id
FROM dbo.Variables v
     JOIN dbo.Prod_Units pu on pu.pu_id = v.pu_id
WHERE v.var_desc = @vcrVarDesc AND pu.pl_id = @intPlId

IF @intVarId IS NOT NULL
  INSERT dbo.Sheet_Variables(sheet_id,var_id,var_order) VALUES(@intSheetId,@intVarId,ISNULL(@intOrder,1))

SET NOCOUNT OFF















