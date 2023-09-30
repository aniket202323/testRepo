
















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Add_Display_Variable]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 1.16
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-09-17
Version		:	1.2.1
Purpose		: 	It fixes a bug introduced with the previous version (1.2.0).
					Version 1.1.0 was missing some BEGIN/END statements and had bad indentation. 
					Because of this non-standard coding, 1.2.0 led to a new bug. Thus 1.2.1 only fixes
					version 1.2.0. :)
Service Call:	22294708
-------------------------------------------------------------------------------------------------
											PCMT Version 1.15
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-09-09
Version		:	1.2.0
Purpose		: 	SP is no more setting variables' Interval and Offset to the sheet settings.
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
Purpose		: 	This sp add a variable to a display. If the display is time based
               set variable's sampling interval and offset to the display values
               If no line is pass, then it is a title
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intSheetId	integer,
@intPlId		integer = null,
@vcrVarDesc	varchar(50)

AS
SET NOCOUNT ON

DECLARE
@intOrder	integer,
@intVarId	integer

--Get the next var_order
SELECT @intOrder = count(*)+1
FROM dbo.Sheet_Variables
WHERE sheet_id = @intSheetId

--If it is a title
IF @intPlId IS NOT NULL BEGIN

	--Variable insertion


	SELECT @intVarId = v.var_id
	FROM 	dbo.Variables v
			JOIN dbo.Prod_Units pu on pu.pu_id = v.pu_id
	WHERE 
		v.var_desc = @vcrVarDesc 
		AND pu.pl_id = @intPlId

	IF @intVarId IS NOT NULL BEGIN
		
/*
		--If time-based
		IF (SELECT sheet_type FROM dbo.SheetsWHERE sheet_id = @intSheetId) = 1 BEGIN

			--Set variable's interval and offset
			UPDATE dbo.Variables
			SET 
				sampling_interval = s.interval,  
				sampling_offset = s.offset
			FROM 
				dbo.Sheets s
			WHERE 
				var_id = @intVarId 
				AND s.sheet_id = @intSheetId
			
		END
*/
		--Add variable to the display 
		INSERT dbo.Sheet_Variables(sheet_id,var_id,var_order) VALUES(@intSheetId,@intVarId,@intOrder)

	END END

ELSE BEGIN

  --Title insertion
  INSERT dbo.Sheet_Variables(sheet_id,title,var_order) VALUES(@intSheetId,@vcrVarDesc,@intOrder)

END

SET NOCOUNT OFF


















