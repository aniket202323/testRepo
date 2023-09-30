-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_VariableNameSplit1] (@Var_Desc varchar(50))
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	This function returns the first half of a Variable Name
					if the Variable Name length is higher than 25.
					The split must be done between two words to avoid cutting a word in half.
-------------------------------------------------------------------------------------------------
*/

RETURNS varchar(25)

AS
BEGIN
	DECLARE
	@LeftPart		varchar(25),
	@LastSpacePos	int
	
	-- Removes extra spaces at the beginning and at the end
	SET @Var_Desc = ltrim(rtrim(@Var_Desc))
	
	-- Variable name fits directly into Result
	IF len(@Var_Desc) <= 25
		BEGIN
			SET @LeftPart = @Var_Desc
		END
	ELSE
		BEGIN
			-- Get the first 25 characters
			SET @LeftPart = left(@Var_Desc, 25)
			
			-- If the 26th character is not a space, then a word is splitted
			-- We have to cut at the preceding space character to avoid splitting a word in half
			IF substring(@Var_Desc, 26, 1) <> ' '
				BEGIN
					SET @LeftPart = reverse(@LeftPart)
					SET @LastSpacePos = charindex(' ', @LeftPart)
					SET @LeftPart = substring(@LeftPart, @LastSpacePos, len(@LeftPart) - @LastSpacePos + 1)
					SET @LeftPart = rtrim(reverse(@LeftPart))
				END
			ELSE
				BEGIN
					SET @LeftPart = rtrim(@LeftPart)
				END
			END

	RETURN @LeftPart

END

