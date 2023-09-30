













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Display_Variable]
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
Modified By	: 	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				: 	10-Sept-03	
Version		: 	1.0.1
Purpose		: 	Order by variable for alarm display, else by var_order
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		: 	1.0.0
Purpose		: 	This sp return the variable and title of a display.
-------------------------------------------------------------------------------------------------
*/

@intDisplayId 	integer

AS
SET NOCOUNT ON

IF EXISTS (SELECT sheet_id
           FROM dbo.Sheets
           WHERE sheet_id = @intDisplayId AND sheet_type = 11)
  SELECT sv.var_id, title = CASE 
                              WHEN sv.var_id IS NULL THEN sv.Title
                              ELSE v.var_desc
                            END
  FROM dbo.Sheet_Variables sv
       left join dbo.Variables v ON (v.var_id = sv.var_id)
  WHERE sheet_id = @intDisplayId
  ORDER BY title
ELSE
  SELECT sv.var_id, title = CASE 
                              WHEN sv.var_id IS NULL THEN sv.Title
                              ELSE v.var_desc
                            END
  FROM dbo.Sheet_Variables sv
       left join dbo.Variables v ON (v.var_id = sv.var_id)
  WHERE sheet_id = @intDisplayId
  ORDER BY var_order

SET NOCOUNT OFF















