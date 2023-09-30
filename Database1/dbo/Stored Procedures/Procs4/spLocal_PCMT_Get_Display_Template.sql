




-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Display_Template]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_Display_Template

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Updated By	:	Benoit Saenz de Ugarte (System Technologies for Industry Inc)
Date			:	2008-06-10
Version		:	2.0.1
Purpose		: 	Always sort by desc
-------------------------------------------------------------------------------------------------
Updated By	:	Eric Perron (System Technologies for Industry Inc)
Date		:	2006-06-27
Version		:	2.0.0
Purpose		: 	Now retrieve the right display for the event_type
			Add parameters for the event_type
			Correction on the last modification	
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date		:	2006-05-18
Version		:	1.2.0
Purpose		: 	Now retreives display using event subtype
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date		:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Modified by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On		:	6-May-2003
Version		: 	1.0.1
Purpose		: 	Change the count Var_id to a count var_order
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On		:	29-Nov-2002	
Version		: 	1.0.0
Purpose		: 	Type = 1: return the alarm template list
               Type = 2: return the alarm display list
					Type = 3: return the autolog display list
-------------------------------------------------------------------------------------------------
*/

@intDisplay  	INTEGER, 
@intSubtype 	INTEGER = NULL, --Subtype
@intEventType	INTEGER = NULL,
@intPLId			INTEGER = NULL,
@vcrPUDesc		VARCHAR(100) = NULL

AS

SET NOCOUNT ON

DECLARE

@Item				VARCHAR(50),
@intPUId			INTEGER,
@intSheetType	INTEGER

--Getting pu_id from event and user_defined autolog displays
IF @intPLId IS NOT NULL AND @vcrPUDesc IS NOT NULL BEGIN
	SET @intPUId = (SELECT CASE WHEN master_unit IS NOT NULL THEN master_unit ELSE pu_id END 
						 FROM dbo.prod_units 
						 WHERE pl_id = @intPLId AND pu_desc_global = @vcrPUDesc)
END

SET @Item = ''
----Find which item we are looking for
--IF @intDisplay = 1
--  SET @Item = 'RTT Alarm Template'
--ELSE
--  IF @intDisplay = 2
--    SET @Item = 'RTT Alarm Display'
--  ELSE  
--    IF @intDisplay = 3
--      SET @Item = 'RTT Autolog Display'

----Get the translate item value
--SELECT @Item = [Translation]
--FROM dbo.Local_PG_PCMT_Translations t
--     join dbo.Local_PG_PCMT_Languages l on (t.lang_id = l.lang_id)
--     join dbo.Local_PG_PCMT_Items i on (t.item_id = i.item_id)
--WHERE i.item = @Item and l.is_active = 1

IF @intDisplay = 1 BEGIN

	--Get the alarm template list
	SELECT [id] = at_id, [desc] = at_desc
	FROM dbo.Alarm_Templates
	WHERE at_desc LIKE '%' + @Item + '%' ORDER BY at_desc END

ELSE BEGIN

	IF @intDisplay = 2 BEGIN

   	--Get the alarm display list
   	SELECT [id] = sheet_id, [desc] = sheet_desc
   	FROM 
			dbo.Sheets s
      	JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
   	WHERE 
			st.sheet_type_desc = 'Alarm View' 
			AND sheet_desc LIKE '%' + @Item + '%'
		ORDER BY s.sheet_desc END

	ELSE BEGIN

   	--Get the autolog display list
		IF @intEventType = 0 BEGIN
			
			--TIME BASED
			SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
		   FROM 
				dbo.Sheets s
         	JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
         	LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
		   WHERE 
				st.sheet_type_id = 1  
				AND sheet_desc LIKE '%' + @Item + '%'
			GROUP BY 
				s.sheet_id, s.sheet_desc
			ORDER BY s.sheet_desc END

		ELSE BEGIN 

			SET @intSheetType = (CASE WHEN @intEventType = 1 THEN 2 ELSE 25 END)

			--EVENT BASED
			SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
			FROM 
				dbo.Sheets s
				JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
				LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
			WHERE 
				st.sheet_type_id = @intSheetType 
				AND sheet_desc LIKE '%' + @Item + '%'
				AND ((s.master_unit = @intPUId AND @intPUId IS NOT NULL) OR (@intPUId IS NULL))
			GROUP BY 
				s.sheet_id, s.sheet_desc
			ORDER BY s.sheet_desc

		END

	END

END


/*

      IF @intSubtype IS NOT NULL
        SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
        FROM dbo.Sheets s
             LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
        WHERE s.event_subtype_id = @intSubtype AND s.sheet_desc LIKE '%' + @Item + '%'
        GROUP BY s.sheet_id, s.sheet_desc
      ELSE
			IF @intEventType IS NULL 
				BEGIN
	
	        		SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
	        		FROM dbo.Sheets s
	            JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
	            LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
	        		WHERE st.sheet_type_id = 25  AND sheet_desc LIKE '%' + @Item + '%'
	        		GROUP BY s.sheet_id, s.sheet_desc  
				END
			ELSE
				BEGIN
						IF @intEventType = 0 -- TIME
							 SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
						      FROM dbo.Sheets s
						             JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
						             LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
						      WHERE st.sheet_type_id = 1  AND sheet_desc LIKE '%' + @Item + '%'
								GROUP BY s.sheet_id, s.sheet_desc
						ELSE
							BEGIN
								IF @intEventType = 1 --Production event
									SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
							      FROM dbo.Sheets s
							             JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
							             LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
							      WHERE st.sheet_type_id = 2  AND sheet_desc LIKE '%' + @Item + '%'
							      GROUP BY s.sheet_id, s.sheet_desc
								ELSE
									SELECT [id] = s.sheet_id, [desc] = s.sheet_desc, VarCount = COUNT(sv.var_order)
							      FROM dbo.Sheets s
							             JOIN dbo.Sheet_Type st ON (s.sheet_type = st.sheet_type_id)
							             LEFT JOIN dbo.Sheet_Variables sv ON (sv.sheet_id = s.sheet_id)
							      WHERE st.sheet_type_id = 25  AND sheet_desc LIKE '%' + @Item + '%'
							      GROUP BY s.sheet_id, s.sheet_desc 
							END

				
				END

*/


SET NOCOUNT OFF








