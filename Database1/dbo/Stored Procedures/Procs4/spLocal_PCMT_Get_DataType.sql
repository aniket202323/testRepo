














-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_DataType]
/*
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
Updated By	:	Tim Rogers (PG)
Date			:	2008-2-15
Version		:	1.2.0
Purpose		: 	Removed constraints, now it loads all data types
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced temp table #ProcessDataType by TABLE variable @ProcessDataType.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		:	1.0.0
Purpose		:	1: Return all data type
            	2: Return all the system data type and all the 
               	user defined data type that exist on the Process Audit unit.
            	3: Return the user defined data type 
               	that don't exist in the Process Audit unit.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intType 			INTEGER

AS
SET NOCOUNT ON

DECLARE
@Item					VARCHAR(50)

-- Table variable to hold Data_Type_Id's list
Declare @ProcessDataType TABLE(
	Data_Type_Id	INTEGER
)

--Get the translate item value
SELECT @Item = [Translation]
FROM dbo.Local_PG_PCMT_Translations t
     JOIN dbo.Local_PG_PCMT_Languages l ON (t.lang_id = l.lang_id)
     JOIN dbo.Local_PG_PCMT_Items i ON (t.item_id = i.item_id)
WHERE i.item = 'RTT Unit' AND l.is_active = 1

SET @Item = ''

IF @intType = 1 --Only User Defined Data Type
  SELECT DISTINCT data_type_id, data_type_desc, user_defined
  FROM dbo.Data_Type WHERE user_defined = 1 ORDER BY data_type_desc ASC
ELSE 
--This limitation did not need to be here, so we removed it, Tim Rogers
--  IF @intType = 2 --System + Process Data Type
--     (SELECT DISTINCT data_type_id, data_type_desc, user_defined
--      FROM dbo.Data_Type 
--      WHERE user_defined = 0)
--    UNION
--     (SELECT DISTINCT v.data_type_id, dt.data_type_desc, dt.user_defined
--      FROM dbo.Data_Type dt
--           JOIN dbo.Variables v ON (dt.data_type_id = v.data_type_id)
--           JOIN dbo.Prod_Units pu ON (v.pu_id = pu.pu_id)
--      WHERE pu.pu_desc LIKE '%' + @Item + '%' AND dt.user_defined = 1)
--    	ORDER BY user_defined, data_type_desc
--  ELSE --Non-Process Data Type
    BEGIN

		SELECT DISTINCT data_type_id, data_type_desc, user_defined
  		FROM dbo.Data_Type 
		ORDER BY user_defined ASC, data_type_desc ASC
/*
		INSERT INTO @ProcessDataType (Data_Type_Id)
      SELECT DISTINCT Data_Type_Id 
      FROM dbo.Variables v 
           join dbo.Prod_Units pu on (v.pu_id = pu.pu_id)
      WHERE pu.pu_desc like '%' + @Item + '%'

      SELECT DISTINCT dt.data_type_id, dt.data_type_desc
      FROM dbo.Data_Type dt
      WHERE dt.user_defined = 1 AND
            dt.data_type_id not in (SELECT Data_Type_Id FROM @ProcessDataType)
      ORDER BY dt.data_type_desc
*/
    END

SET NOCOUNT OFF
















