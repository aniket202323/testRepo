













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Remove_Template_Variable]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-04
Version		:	3.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced #Sheet temp table by @Sheets TABLE variable.
					Created new @Sheets_Variables TABLE variable.
					Eliminated c_Sheet and c_SheetVariable cursors no longer required.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Modified by	: 	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	15-Apr-2004	
Version		:	3.0.0
Purpose		: 	The var_desc and pl_id are passed instead of the var_id
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
Modified by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	13-May-2003	
Version		:	2.0.0
Purpose		:	This SP removes one variables from a template. It also remove 
               the variable from all alarm display if it is in no other template
-------------------------------------------------------------------------------------------------
Created by	:	Marc Charest, Solutions et Technologies Industrielles Inc.
On				:	13-Dec-02	
Version		:	1.0.0
Purpose		:	This SP removes all variables from a template. Deletion takes care of constraints between
					alarm_history, alarms and alarm_template_var_data.
-------------------------------------------------------------------------------------------------
*/

@intAtId				integer,	--Template ID
@intPlId				integer,
@vcrVarDesc			varchar(50)

AS
SET NOCOUNT ON

DECLARE 
@intVarId			integer,
@vcrNew_Var_Desc	varchar(50),
@vcrExt_Info		varchar(255),
@intPU_Id			integer,
@intCount			integer,
@vcrPUG_desc		varchar(50),
@intSheetId			integer,
@intCTR				integer,
@intVarOrder		integer,
@NbrRows				INT,
@SheetsRowNum		INT,
@VarRowNum			INT

DECLARE @Sheets TABLE
(
PKey			INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
Sheet_Id		INT
)

DECLARE @Sheet_Variables TABLE
(
PKey			INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
Var_Order		INT
)

SELECT @intVarId = v.var_id 
FROM dbo.Variables v
     JOIN dbo.Prod_Units pu ON pu.pu_id = v.pu_id
WHERE v.var_desc = @vcrVarDesc AND pu.pl_id = @intPlId
     

--Remove alarms for this variable
DELETE
FROM dbo.Alarm_history
WHERE alarm_id IN (SELECT alarm_id
		   FROM dbo.Alarms
		   WHERE atd_id IN (	SELECT atd_id
              	 	     	  	FROM dbo.Alarm_Template_Var_Data
                 		    	WHERE var_id = @intVarId AND at_id = @intAtId))
DELETE
FROM dbo.Alarms
WHERE atd_id IN (SELECT atd_id
                 FROM dbo.Alarm_Template_Var_Data
                 WHERE var_id = @intVarId AND at_id = @intAtId)

--Remove the variable from the alarm template
DELETE 
FROM dbo.Alarm_Template_Var_Data
WHERE var_id = @intVarId AND at_id = @intAtId


IF NOT EXISTS(SELECT var_id
              FROM dbo.Alarm_Template_Var_Data
              WHERE var_id = @intVarId)
	BEGIN
		--Get sheet id where the variable is in.	
		INSERT @Sheets (Sheet_Id)
		SELECT s.Sheet_Id
		FROM dbo.Sheet_Variables sv
		JOIN dbo.Sheets s ON s.sheet_id = sv.sheet_id
		WHERE sv.var_id = @intVarId AND s.sheet_type = 11
		
		--Remove the variable from any display
		DELETE 
		FROM dbo.Sheet_Variables
		WHERE var_id = @intVarId AND sheet_id IN (SELECT Sheet_Id 
		FROM @Sheets)
		
		-- Initialize Sheets loop variables
		SET @NbrRows = (SELECT MAX(PKey) FROM @Sheets)
		SET @SheetsRowNum = 1
		
		--Reset display order
		WHILE @SheetsRowNum <= @NbrRows
			BEGIN
				SET @intSheetId = (SELECT Sheet_Id FROM @Sheets WHERE PKey = @SheetsRowNum)
								
				-- Delete variables from previous sheet
				DELETE @Sheet_Variables
				
				-- Fills variables for current sheet
				INSERT @Sheet_Variables (Var_Order)
				SELECT Var_Order FROM dbo.Sheet_Variables WHERE Sheet_Id = @intSheetId ORDER BY Var_Order
				
				-- Initialize variables loop variable
				SET @VarRowNum = 1
				
				WHILE @VarRowNum <= @NbrRows
					BEGIN
						SET @intVarOrder = (SELECT Var_Order FROM @Sheet_Variables WHERE PKey = @VarRowNum)
						
						UPDATE dbo.Sheet_Variables
						SET Var_Order = @VarRowNum
						WHERE (Sheet_Id = @intSheetId) AND (Var_Order = @intVarOrder)
						
						SET @VarRowNum = @VarRowNum + 1
					END -- Variables loop

				SET @SheetsRowNum = @SheetsRowNum + 1
			END -- Sheets Loop
	END -- IF

SET NOCOUNT OFF















