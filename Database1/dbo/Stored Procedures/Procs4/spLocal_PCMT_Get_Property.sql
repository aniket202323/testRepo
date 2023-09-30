








-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Property]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-01
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		: 	1.0.0
Purpose		: 	This sp return the specification tree structure.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/
@intUserId		INTEGER,
@intDataTypeId	integer = NULL,
@intPrecision	integer = NULL

AS

SET NOCOUNT ON

--Security Utilization
CREATE TABLE #PCMTPPIDs(Item_Id INTEGER)
INSERT #PCMTPPIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'product_properties', 'prop_id', @intUserId

IF @intPrecision IS NULL
  BEGIN
    IF @intDataTypeId IS NULL
      SELECT pp.prop_id, ISNULL(pp.prop_desc_global, pp.prop_desc)
      FROM dbo.Product_Properties pp, #PCMTPPIDs pp2
		WHERE pp.prop_id = pp2.item_id 
      ORDER BY ISNULL(pp.prop_desc_global, pp.prop_desc)
    ELSE
      SELECT DISTINCT pp.prop_id, ISNULL(pp.prop_desc_global, pp.prop_desc)
      FROM dbo.Product_Properties pp
           JOIN dbo.Specifications s ON (s.prop_id = pp.prop_id), 
			  #PCMTPPIDs pp2
      WHERE s.data_type_id = @intDataTypeId
				AND pp.prop_id = pp2.item_id 
      ORDER BY ISNULL(pp.prop_desc_global, pp.prop_desc)
  END
ELSE
 SELECT DISTINCT pp.prop_id, ISNULL(pp.prop_desc_global, pp.prop_desc)
 FROM dbo.Product_Properties pp
      JOIN dbo.Specifications s ON (s.prop_id = pp.prop_id),
		#PCMTPPIDs pp2
 WHERE s.data_type_id = @intDataTypeId AND 
       s.spec_precision = @intPrecision
		 AND pp.prop_id = pp2.item_id 
 ORDER BY ISNULL(pp.prop_desc_global, pp.prop_desc)

DROP TABLE #PCMTPPIDs

SET NOCOUNT OFF


















