






-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Display_Template_Line]
/*
Stored Procedure		:		spLocal_PCMT_Get_Display_Template_Line
Author					:		Rick Perreault (System Technologies for Industry Inc)
Date Created			:		15-Apr-2004
SP Type					:		
Editor Tab Spacing	:		3

Description:
===========
This sp return the line that have the display or template name.
1=Alarm Template
2=Alarm Display	
3=Autolog Display

CALLED BY				:  PCMT

				
Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.1.0				31-Oct-2005		Normand Carbonneau		Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		PCMT Version 4.0.0
					
1.2.0				05-Sep-2006		Normand Carbonneau		Now retrieves the Line Description regardless of the
																		position of the Line Description in the Alarm Template
																		or Sheet.
																		Also allows Line Desc with space characters.
																		
1.3.0				2008-08-08		Stephane Turner			Replace join with old join because line desc were not returned
																		correctly (war-mesdatabc: RTT Shiftly Auto EA1 OLD_DITR104 
																		and RTT Shiftly Auto EA1 DITR104)
																		spLocal_PCMT_Get_Display_Template_Line 3,	'RTT Shiftly Auto EA1'		

*/

@ItemType			INT,
@ItemDesc			varchar(50),
@intLineSpecific	BIT=1

AS
SET NOCOUNT ON

DECLARE @Items TABLE
(
KeyId		INT,
ItemDesc	varchar(50),
PL_Id		INT,
PL_Desc	varchar(50)
)

IF @intLineSpecific = 0 BEGIN

	IF @ItemType = 1 BEGIN
		SELECT pl_id, at_id, pl_desc, at_desc 
		FROM alarm_templates, prod_lines 
		WHERE at_desc = @ItemDesc AND pl_id <> 0 END
	ELSE IF @ItemType = 2 BEGIN
		SELECT pl.pl_id, sheet_id, pl_desc, sheet_desc 
		FROM sheets s, prod_lines pl 
		WHERE sheet_desc = @ItemDesc AND pl.pl_id <> 0 AND sheet_type = 11 END
	ELSE IF @ItemType = 3 BEGIN
		SELECT pl.pl_id, sheet_id, pl_desc, sheet_desc 
		FROM sheets s, prod_lines pl 
		WHERE sheet_desc = @ItemDesc AND pl.pl_id <> 0 AND sheet_type IN (1, 2, 25, 11)
	END

	RETURN

END


--Find which item we are looking for
IF @ItemType = 1
	BEGIN
		--Get the alarm template line list
		INSERT @Items (KeyId, ItemDesc)
			SELECT	AT_Id, AT_Desc
			FROM		dbo.Alarm_Templates at,
						dbo.prod_lines pl
			WHERE
				CHARINDEX(pl.pl_desc, at.at_desc) > 0
				AND (RTRIM(LTRIM(REPLACE(REPLACE(at.at_desc, pl.pl_desc, ''), '  ', ' '))) = @ItemDesc) 

--			SELECT	DISTINCT AT_Id, AT_Desc
--			FROM		dbo.Alarm_Templates
--			WHERE		AT_Desc LIKE '%' + @ItemDesc + '%'
	END
ELSE IF @ItemType = 2
	BEGIN
		--Get the alarm display line list
		INSERT @Items (KeyId, ItemDesc)
			SELECT	Sheet_id, Sheet_Desc
			FROM		dbo.sheets s,
						dbo.prod_lines pl
			WHERE
				Sheet_Type = 11
				AND CHARINDEX(pl.pl_desc, s.sheet_desc) > 0
				AND RTRIM(LTRIM(REPLACE(REPLACE(s.sheet_desc, pl.pl_desc, ''), '  ', ' '))) = @ItemDesc

--			SELECT	DISTINCT Sheet_id, Sheet_Desc
--			FROM		dbo.Sheets
--			WHERE		Sheet_Type = 11
			AND		Sheet_Desc LIKE '%' + @ItemDesc + '%'
	END
ELSE IF @ItemType = 3
	BEGIN
		--Get the autolog display line list
		INSERT @Items (KeyId, ItemDesc)
			SELECT	Sheet_id, Sheet_Desc
			FROM		dbo.sheets s,
						dbo.prod_lines pl
			WHERE
				Sheet_Type IN (1, 2, 25)
				AND CHARINDEX(pl.pl_desc, s.sheet_desc) > 0
				AND RTRIM(LTRIM(REPLACE(REPLACE(s.sheet_desc, pl.pl_desc, ''), '  ', ' '))) = @ItemDesc

--			SELECT	DISTINCT Sheet_id, Sheet_Desc
--			FROM		dbo.Sheets
--			WHERE		Sheet_Type IN(1,2)
--			AND		Sheet_Desc LIKE '%' + @ItemDesc + '%'
	END

UPDATE	i
SET		PL_Id = pl.PL_Id,
			PL_Desc = pl.PL_Desc
FROM		@Items i
--JOIN		dbo.Prod_Lines pl ON pl.PL_Desc = SUBSTRING(i.ItemDesc, CHARINDEX(pl.pl_desc, i.ItemDesc), LEN(pl.pl_desc))
JOIN		dbo.Prod_Lines pl ON pl.PL_Desc = RTRIM(LTRIM(REPLACE(i.ItemDesc, @ItemDesc, '')))

IF @ItemType = 1
BEGIN
	SELECT PL_Id, KeyId AS AT_Id, PL_Desc, itemdesc FROM @Items WHERE pl_id IS NOT NULL ORDER BY pl_desc
END
ELSE
BEGIN
	SELECT PL_Id, KeyId AS Sheet_Id, PL_Desc, itemdesc FROM @Items WHERE pl_id IS NOT NULL ORDER BY pl_desc
END


SET NOCOUNT OFF




















