-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_IsOutOfLimits] (@ValueEntered varchar(25), @LowerLimit varchar(25) = NULL, @UpperLimit varchar(25) = NULL)
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	Compares the ValueEntered parameter with @LowerLimit and @UpperLimit.
					Returns -1 if @ValueEntered is lower than @LowerLimit.
					Returns 0 if @ValueEntered is within limits.
					Returns 1 if @ValueEntered is higher than @UpperLimit.
					Returns NULL if it is not possible to evaluate.
-------------------------------------------------------------------------------------------------
*/

RETURNS int

AS
BEGIN

DECLARE
@IsOut	int

-- If no ValueEntered or both limits are empty, then cannot evaluate
IF	(@ValueEntered IS NULL)
	OR
	((@LowerLimit IS NULL) OR (@LowerLimit = '')) AND ((@UpperLimit IS NULL) OR (@UpperLimit = ''))
	BEGIN
		RETURN NULL
	END

-- By default, we set the flag indicating that the value is in limits.
SET @IsOut = 0

-- First check for LowerLimit if one exists
IF (@LowerLimit IS NOT NULL) AND (@LowerLimit <> '')
	BEGIN
		IF convert(float, @ValueEntered) < convert(float, @LowerLimit)
			BEGIN
				SET @IsOut = -1
			END
	END

-- First check for UpperLimit if one exists, and only if LowerLimit was not exceeded
IF (@UpperLimit IS NOT NULL) AND (@UpperLimit <> '') AND (@IsOut = 0)
	BEGIN
		IF convert(float, @ValueEntered) > convert(float, @UpperLimit)
			BEGIN
				SET @IsOut = 1
			END
	END

RETURN @IsOut

END

