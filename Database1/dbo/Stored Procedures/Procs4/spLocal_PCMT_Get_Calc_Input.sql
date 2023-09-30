













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Calc_Input]
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
On				: 	29-Nov-02	
Version		: 	1.0.0
Purpose		:	Gets calculation inputs variable, if no data default value are shown
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intCalculation_Id	INTEGER,
@intVar_id				INTEGER = null

AS
SET NOCOUNT ON

SELECT ci.calc_input_id, cid.member_var_id, 
       ISNULL(cid.input_name,ci.input_name) AS input_name, 
       cie.entity_name, 
       pl.pl_desc + '\' + pu.pu_desc + '\' + pug.pug_desc + '\' + v.var_desc AS var_desc,
       ISNULL(cid.default_value, ci.default_value) AS default_value
FROM dbo.calculation_inputs ci
     JOIN dbo.calculation_input_entities cie 
          ON (ci.calc_input_entity_id = cie.calc_input_entity_id)
     LEFT JOIN dbo.calculation_input_data cid  
          ON (ci.calc_input_id = cid.calc_input_id AND cid.result_var_id = @intVar_id)
     LEFT JOIN dbo.variables v 
          ON (v.var_id = cid.member_var_id) 
     LEFT JOIN dbo.Prod_Units pu ON (pu.pu_id = v.pu_id)
     LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
     LEFT JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)  
WHERE ci.calculation_id = @intCalculation_Id AND
      ci.calc_input_entity_id IN (1, 3)      
ORDER BY  ci.calc_input_order ASC

SET NOCOUNT OFF















