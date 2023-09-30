













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_Calc_DependencyAdd]
  
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-03
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	: 	Marc Charest, Solutions et Technologies Industrielles Inc.
On				:	27-Nov-02	
Version		: 	1.0.0
Purpose		: 	Inserts an additional dependency to a calculated variable
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intVar_Id					integer,
@intVar_Id_New_Depend	integer

AS
SET NOCOUNT ON

--inserts into calculation_instance_dependencies
INSERT INTO 
  dbo.calculation_instance_dependencies (result_var_id, var_id, calc_dependency_scope_id, calc_dependency_notactive)
VALUES 
  (@intVar_Id, @intVar_Id_New_Depend, 2, 0)

SET NOCOUNT OFF















