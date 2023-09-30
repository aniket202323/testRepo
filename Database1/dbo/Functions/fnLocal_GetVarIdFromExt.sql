-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetVarIdFromExt] (@Extended_Info varchar(255), @PU_Id int)
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	Finds the Var_Id of a variable by looking at the text in the Extended_Info
					and the PU_Id.
					Example : 'OOSUC' will return 12247 (The Out of Spec Upper Control variable
					on this unit.
-------------------------------------------------------------------------------------------------
*/

RETURNS int

AS
BEGIN
	DECLARE 
	@Var_Id	int

	SET @Var_Id = (SELECT Var_Id FROM dbo.Variables WHERE Extended_Info = @Extended_Info AND PU_Id = @PU_Id)
	RETURN @Var_Id
END

