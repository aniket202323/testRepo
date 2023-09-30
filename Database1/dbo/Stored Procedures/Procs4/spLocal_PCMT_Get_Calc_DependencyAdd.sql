













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Calc_DependencyAdd]
/*
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
Created By	: 	Marc Charest, Solutions et Technologies Industrielles Inc.
On				: 	27-Nov-02	
Version		: 	1.0.0
Purpose		: 	Gets calculation's additional dependencies
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intVar_id	integer

AS
SET NOCOUNT ON

SELECT 
  v.var_id, 
  pl.pl_desc + '\' + pu.pu_desc + '\' + pug.pug_desc + '\' + v.var_desc AS var_desc
FROM 
  dbo.calculation_instance_dependencies cid, 
  dbo.variables v
  LEFT JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
  LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
  LEFT JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)  
WHERE 
  cid.Result_Var_Id = @intVar_id AND
  cid.Var_Id = v.var_id

SET NOCOUNT OFF















