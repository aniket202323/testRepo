













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_VariableId]
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
Created By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	30-Desc-02	
Version		:	1.0.0
Purpose		:	This sp get the var_id for all line where the var_desc is 
               the same as the var_desc of the given var_id.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intVar_Id   			integer

AS

SET NOCOUNT ON

SELECT pl.pl_desc, v.var_id, v.var_desc, 
       pl.pl_desc + '\' + pu.pu_desc + '\' + pug.pug_desc + '\' + v.var_desc AS long_var_desc
FROM dbo.Variables v
     JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
     JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
     JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
WHERE var_desc = (SELECT var_desc
                  FROM variables
                  WHERE var_id = @intVar_Id)

SET NOCOUNT OFF















