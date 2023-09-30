-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_VariableNameSplit2] (@Var_Desc varchar(50), @LeftPart varchar(25))
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	This function returns the second half of a Variable Name
					If the Variable Name length is higher than 25.
					The split must be done between two words to avoid cutting a word in half.
-------------------------------------------------------------------------------------------------
*/

RETURNS varchar(25)

AS
BEGIN
	DECLARE
	@RightPart		varchar(25)
	
	-- Eliminate the first half of variable name
	SET @Var_Desc = replace(@Var_Desc, @LeftPart, '')
	
	SET @RightPart = left(ltrim(rtrim(@Var_Desc)),25)
	
	RETURN @RightPart

END

