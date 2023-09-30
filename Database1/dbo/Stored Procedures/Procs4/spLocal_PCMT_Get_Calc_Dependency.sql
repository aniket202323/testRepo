













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [DBO].[spLocal_PCMT_Get_Calc_Dependency]
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
Purpose		: 	Gets calculation's mandatory dependencies and dependencies' data if available.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intCalculation_Id	INTEGER,
@intVar_id				INTEGER=NULL

AS
SET NOCOUNT ON

SELECT 
  cd.calc_dependency_id, 
  cdd.var_id, 
  cd.name,
  cdd.var_desc
FROM 
  dbo.calculation_dependencies cd
  LEFT JOIN (SELECT	
               cdd.calc_dependency_id, 
               cdd.var_id, 
               pl.pl_desc + '\' + pu.pu_desc + '\' + pug.pug_desc + '\' + v.var_desc AS var_desc
             FROM 
               dbo.calculation_dependency_data cdd 
               LEFT JOIN dbo.variables v 
               ON (cdd.var_id = v.var_id)
               LEFT JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
               LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
               LEFT JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)  
             WHERE 
               cdd.calc_dependency_id IN (SELECT
                                            calc_dependency_id
                                          FROM 
                                            dbo.calculation_dependencies 
                                          WHERE 
                                            calculation_id = @intCalculation_Id
                                         ) AND 
               cdd.result_var_id = @intVar_id
            ) cdd
  ON (cd.calc_dependency_id = cdd.calc_dependency_id)
WHERE 
  cd.calculation_id = @intCalculation_Id
ORDER BY
  cd.name ASC

SET NOCOUNT OFF















