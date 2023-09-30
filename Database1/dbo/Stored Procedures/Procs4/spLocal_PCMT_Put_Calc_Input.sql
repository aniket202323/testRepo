














-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_Calc_Input]
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
Purpose		: 	Attaches input's data to variable's input
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intVar_Id			integer,
@intCalc_Input_Id	integer,
@intMember_Var_Id	integer = NULL,
@vcrDefault_Value	varchar(50) = NULL

AS

SET NOCOUNT ON

--inserts into calculation_input_data
INSERT INTO
  dbo.calculation_input_data (calc_input_id, member_var_id, result_var_id, default_value)
VALUES
  (@intCalc_Input_Id, @intMember_Var_Id, @intVar_Id, @vcrDefault_Value)

SET NOCOUNT OFF
















