-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_FindModelInterval] (@EC_Id int)
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-02-06
Version		:	1.0.0
Purpose		:	Find the interval of a Model.
					Example : 'TINT:5' will return 5
-------------------------------------------------------------------------------------------------
*/

RETURNS int

AS
BEGIN

DECLARE
@vcrInterval		varchar(10),
@Interval			int

SET @vcrInterval =	(
							SELECT	replace(convert(varchar,Value),'TINT:','')
							FROM		dbo.Event_Configuration ec
							JOIN		dbo.Event_Configuration_Data ecd ON ec.ec_id = ecd.ec_id
							JOIN		dbo.Event_Configuration_Values ecv ON ecd.ecv_id = ecv.ecv_id
							WHERE		ec.EC_Id = @EC_Id
							AND		Value LIKE '%TINT:%'
							)

IF isnumeric(@vcrInterval) = 1
	BEGIN
		SET @Interval = convert(int, @vcrInterval)
	END
	
	RETURN @Interval
END

