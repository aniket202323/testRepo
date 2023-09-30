













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_Calc_Dependency]
  
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
Purpose		:	Attaches dependency's data to variable's dependency
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intVar_Id					integer,
@intCalc_Dependency_Id	integer,
@intVar_Id_Depend			integer

AS

SET NOCOUNT ON

--inserts into calculation_dependency_data
INSERT INTO
  dbo.calculation_dependency_data (calc_dependency_id, var_id, result_var_id)
VALUES
  (@intCalc_Dependency_Id, @intVar_Id_Depend, @intVar_Id)

SET NOCOUNT OFF















