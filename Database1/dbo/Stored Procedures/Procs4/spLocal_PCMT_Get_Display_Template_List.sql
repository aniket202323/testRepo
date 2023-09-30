




-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Display_Template_List]
/*
Stored Procedure		:		spLocal_PCMT_Get_Display_Template_List
Author					:		Rick Perreault (System Technologies for Industry Inc)
Date Created			:		15-Apr-2004
SP Type					:		
Editor Tab Spacing	:		3

Description:
===========
Return distinct template or display name and without line name in and type
Type = 1: return the alarm template list
Type = 2: return the alarm display list
Type = 3: return the autolog display list

CALLED BY				:  PCMT

				
Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.1.0				31-Oct-2005		Normand Carbonneau		Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		PCMT Version 4.0.0

2.0.0				29-May-2006		Alexandre Turgeon			Compliant with PCMT 5.0.0
																		Added option to return all templates
																		Type = 4: Return all alarm templates
																		Type = 5: Return all alarm displays
																		Type = 6: Return all autolog displays
																		
2.1.0				05-Sep-2006		Normand Carbonneau		Now retrieves the Display/Template name regardless of the
																		position of the Line Description.
																		Also allows Line Desc with space characters.

2.2.0				08-May-08		Marc Charest				Added ORDER BY clauses to have more readable outputs.


*/

@ItemType			INT,
@vcrFilter			VARCHAR(50)=NULL,
@intLineSpecific	BIT=1

AS
SET NOCOUNT ON

DECLARE
@Item				varchar(50),
@NbrRows			INT,
@RowNum			INT,
@PL_Desc			varchar(50)

DECLARE @Lines TABLE
(
PKey		INT IDENTITY(1,1),
PL_Desc	varchar(50)
)

DECLARE @Items TABLE
(
PKey		INT IDENTITY(1,1),
Type		INT,
ItemDesc	varchar(50),
PL_Desc	varchar(255)
)

/*
--Find which item we are looking for
IF @ItemType = 1
	BEGIN
		SET @Item = 'RTT Alarm Template'
	END
ELSE IF @ItemType = 2
	BEGIN
		SET @Item = 'RTT Alarm Display'
	END
ELSE IF @ItemType = 3
	BEGIN
		SET @Item = 'RTT Autolog Display'
	END
ELSE IF (@ItemType = 4) OR (@ItemType = 5) OR (@ItemType = 6)
	BEGIN
		SET @Item = NULL
	END

--Get the translate item value
SET @Item =	(
				SELECT	[Translation]
				FROM		dbo.Local_PG_PCMT_Translations t
				JOIN		dbo.Local_PG_PCMT_Languages l ON t.Lang_Id = l.Lang_Id
				JOIN		dbo.Local_PG_PCMT_Items i ON (t.Item_Id = i.Item_Id)
				WHERE		i.Item = @Item
				AND		l.Is_Active = 1
				)
*/
SET @Item = ''

-- Get the name of all lines
-- The ORDER BY is important to remove QACR016A before QACR016
INSERT @Lines (PL_Desc)
	SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id > 0	ORDER BY PL_Desc DESC
	
IF (@ItemType = 1) OR (@ItemType = 4)
	BEGIN
		--Get the alarm template list
		INSERT @Items (Type, ItemDesc, PL_Desc)
			SELECT	DISTINCT Type = 0, AT_Desc, pl_desc
			FROM		dbo.Alarm_Templates at, dbo.prod_lines pl
			WHERE		
						AT_Desc LIKE '%' + isnull(@Item,'') + '%' 
						AND ((CHARINDEX(pl.pl_desc, AT_Desc) > 0 AND @intLineSpecific = 1) OR @intLineSpecific = 0)
						AND AT_Desc LIKE '%' + ISNULL(@vcrFilter,'') + '%'
			ORDER BY pl.pl_desc, at.at_desc
	END
ELSE IF @ItemType = 2 OR (@ItemType = 5)
	BEGIN
		--Get the alarm display list
		INSERT @Items (Type, ItemDesc, PL_Desc)
			SELECT	DISTINCT Type = Sheet_Type, Sheet_Desc, pl_desc
			FROM		dbo.Sheets s, dbo.prod_lines pl
			WHERE		Sheet_Type = 11
			AND		Sheet_Desc LIKE '%' + isnull(@Item,'') + '%'
			AND	 	((CHARINDEX(pl.pl_desc, sheet_Desc) > 0 AND @intLineSpecific = 1) OR @intLineSpecific = 0)
			AND 		Sheet_Desc LIKE '%' + ISNULL(@vcrFilter,'') + '%'
			ORDER BY pl.pl_desc, s.sheet_desc

	END   
ELSE IF @ItemType = 3 OR (@ItemType = 6)
	BEGIN
		--Get the autolog display list
		INSERT @Items (Type, ItemDesc, PL_Desc)
			SELECT	DISTINCT Type = Sheet_Type, Sheet_Desc, pl_desc

			FROM		dbo.Sheets s, dbo.prod_lines pl
			WHERE		Sheet_Type IN(1, 2, 25)
			AND		Sheet_Desc LIKE '%' + isnull(@Item,'') + '%'
			AND	 	((CHARINDEX(pl.pl_desc, sheet_Desc) > 0 AND @intLineSpecific = 1) OR @intLineSpecific = 0)
			AND 		Sheet_Desc LIKE '%' + ISNULL(@vcrFilter,'') + '%'
			ORDER BY pl.pl_desc, s.sheet_desc
	END

IF @intLineSpecific = 1 BEGIN

	-- Initialize variables for Lines loop
	SET @NbrRows = (SELECT count(*) FROM @Lines)
	SET @RowNum = 1
	
	WHILE @RowNum <= @NbrRows
		BEGIN
			SET @PL_Desc = (SELECT PL_Desc FROM @Lines WHERE PKey = @RowNum)
			
			-- This is in case the Line Desc is in the middle of the Display/Template name
			UPDATE @Items SET ItemDesc = replace(ItemDesc, ' ' + @PL_Desc + ' ', ' ')
			
			UPDATE @Items SET ItemDesc = replace(ItemDesc, @PL_Desc, '')
			
			SET @RowNum = @RowNum + 1
		END
	
	-- Remove leading and trailing spaces
	UPDATE @Items SET ItemDesc = ltrim(rtrim(ItemDesc))

END

SELECT DISTINCT Type, ItemDesc AS [Desc] FROM @Items ORDER BY ItemDesc ASC

SET NOCOUNT OFF
























