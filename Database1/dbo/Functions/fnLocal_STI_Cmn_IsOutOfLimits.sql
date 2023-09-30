
-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_STI_Cmn_IsOutOfLimits] (@LLimit Float, @ULimit Float, @Value Float)
/*
-------------------------------------------------------------------------------------------------
Created by	:	David Lemire (System Technologies for Industry Inc)
Date			:	2009-05-25
Version		:	1.0.0
Purpose		:	Determines if a test value is out of limits.
					Returns 1 if @Value is out of reject limits.
					Returns 0 if @Value is within reject limits.
					Returns NULL if it is not possible to evaluate.
-------------------------------------------------------------------------------------------------
*/
RETURNS int

AS
BEGIN
DECLARE
@IsOut	Int

-- If no ValueEntered or both limits are empty, then cannot evaluate
IF	(@Value IS NULL) OR
	((@LLimit IS NULL) OR (@LLimit = '') OR (ISNUMERIC(@LLimit) = 0)) AND ((@ULimit IS NULL) OR (@ULimit = '') OR (ISNUMERIC(@ULimit) = 0))
	BEGIN
		RETURN NULL
	END

-- By default, we set the flag indicating that the value is in limits.
SET @IsOut = 0

-- First check for LowerLimit if one exists
IF (@LLimit IS NOT NULL) AND (@LLimit <> '')
	BEGIN
		IF @Value < CONVERT(float, @LLimit)
			BEGIN
				SET @IsOut = 1
			END
	END

-- First check for UpperLimit if one exists, and only if LowerLimit was not exceeded
IF (@ULimit IS NOT NULL) AND (@ULimit <> '') AND (@IsOut = 0)
	BEGIN
		IF @Value > CONVERT(float, @ULimit)
			BEGIN
				SET @IsOut = 1
			END
	END

RETURN @IsOut

END

