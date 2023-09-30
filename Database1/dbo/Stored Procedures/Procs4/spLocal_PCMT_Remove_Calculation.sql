













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Remove_Calculation]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-04
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	: 	Marc Charest, Solutions et Technologies Industrielles Inc.
On				:	27-Nov-02	
Version		: 	1.0.0
Purpose		: 	Detach calculation from a variable.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intVar_Id			integer

AS
SET NOCOUNT ON

DELETE FROM dbo.Calculation_Input_Data WHERE Result_Var_Id = @intVar_Id
DELETE FROM dbo.Calculation_Dependency_Data WHERE Result_Var_Id = @intVar_Id
DELETE FROM dbo.Calculation_Instance_Dependencies WHERE Result_Var_Id = @intVar_Id

SET NOCOUNT OFF















