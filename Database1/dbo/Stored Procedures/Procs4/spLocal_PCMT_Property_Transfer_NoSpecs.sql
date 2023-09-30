













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Transfer_NoSpecs]
/*
---------------------------------------------------------------------------------------------------------------
											      PCMT Version 5.0.0 (P3 and P4)
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_Property_Transfer_NoSpecs
Author:					Rick Perreault(STI)
Date Created:			05-Feb-04
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
Return the product list that do not have the corresponding char in the new property.
PCMT Version 2.1.0 and 3.0.0

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who								What
========	===========	==========================	===============================================================
1.2.0		23-May-06	Marc Charest (STI)			RTT groups are now split across multiple units.
																We revisited the SP to take care of these changes.
1.1.0		03-Nov-05	Normand Carbonneau (STI)	Compliant with Proficy 3 and 4.
																Added [dbo] template when referencing objects.
																Added registration of SP Version into AppVersions table.
																PCMT Version 5.0.3
*/
@intPropId	integer,
@intPugId	integer

AS
SET NOCOUNT ON

SELECT pl.pl_desc, pu.pu_desc, pug.pug_desc, v.var_desc
FROM dbo.Variables v
     JOIN dbo.PU_Groups pug ON pug.pug_id = v.pug_id
     JOIN dbo.Prod_Units pu ON pu.pu_id = v.pu_id
	  JOIN dbo.Prod_lines pl ON pl.pl_id = pu.pl_id
WHERE v.pug_id = @intPugId AND
      v.spec_id IS NOT NULL AND
      v.var_id NOT IN (SELECT v.var_id
                       FROM dbo.Variables v
                            JOIN dbo.Specifications s1 ON s1.spec_id = v.spec_id
                            JOIN dbo.Specifications s2 ON s2.spec_desc = s1.spec_desc
                       WHERE v.pug_id = @intPugId AND 
                             v.spec_id IS NOT NULL AND 
                             s2.prop_id = @intPropId)


SET NOCOUNT OFF















