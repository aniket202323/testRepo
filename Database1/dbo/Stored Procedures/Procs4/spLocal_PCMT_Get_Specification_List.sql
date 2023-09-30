













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Specification_List]
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

@intPropId		integer,
@vcrMask			varchar(50),
@intDataTypeId	integer = NULL,
@intPrecision	integer = NULL

AS

SET NOCOUNT ON

IF @intPrecision IS NULL
  BEGIN
    IF @intDataTypeId IS NULL
      SELECT s.spec_id, s.spec_desc, pp.prop_desc
      FROM dbo.Specifications s
           JOIN dbo.Product_Properties pp ON pp.prop_id = s.prop_id
      WHERE (s.prop_id = @intPropId OR @intPropId IS NULL) AND s.spec_desc LIKE '%' + @vcrMask + '%' AND
            s.spec_desc NOT LIKE 'z_obs_%'
      ORDER BY s.spec_desc
    ELSE
      SELECT s.spec_id, s.spec_desc, pp.prop_desc
      FROM dbo.Specifications s
           JOIN dbo.Product_Properties pp ON pp.prop_id = s.prop_id
      WHERE s.data_type_id = @intDataTypeId AND
            (s.prop_id = @intPropId OR @intPropId IS NULL) AND s.spec_desc LIKE '%' + @vcrMask + '%' AND
            s.spec_desc NOT LIKE 'z_obs_%'
      ORDER BY s.spec_desc
  END
ELSE
 SELECT s.spec_id, s.spec_desc, pp.prop_desc
 FROM dbo.Specifications s
      JOIN dbo.Product_Properties pp ON pp.prop_id = s.prop_id
 WHERE s.data_type_id = @intDataTypeId AND 
       s.spec_precision = @intPrecision AND
       (s.prop_id = @intPropId OR @intPropId IS NULL) AND s.spec_desc LIKE '%' + @vcrMask + '%' AND
       s.spec_desc NOT LIKE 'z_obs_%'
 ORDER BY s.spec_desc

SET NOCOUNT OFF















