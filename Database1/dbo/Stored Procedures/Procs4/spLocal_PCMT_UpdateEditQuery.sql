


CREATE    PROCEDURE [dbo].[spLocal_PCMT_UpdateEditQuery]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_UpdateEditQuery
Author:					Marc Charest (STI)	
Date Created:			2009-10-15
SP Type:				Called by spLocal_PCMT_UnobsoleteVariable
Editor Tab Spacing:		3
Test Code				
						DECLARE @SQLString varchar(5000)
						SET @SQLString = 'spLocal_PCMT_Update_Variable 4,''[PU_Desc]'',672,''[PUG_Desc]'',11640,''FGTEST001'',0,2,NULL,NULL,NULL,2,2,0,0,0,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,''FGTEST001'',NULL,NULL,NULL,127'
						execute spLocal_PCMT_UpdateEditQuery @SQLString OUTPUT
						SELECT @SQLString

*****************************************************************************************************************
*/
@SQLString		varchar(5000) OUTPUT

AS

SET NOCOUNT ON

DECLARE
@CurrentPos		INT,
@StartPos		INT,
@LoopCounter	INT,
@SubString		varchar(8000)


SET @StartPos = 1
SET @CurrentPos = 0
SET @LoopCounter = 1

--Counting ","
WHILE @LoopCounter <= 40 BEGIN
	SET @CurrentPos = charindex(',', @SQLString, @CurrentPos + 1)
	IF @CurrentPos = 0 BEGIN
		SET @LoopCounter = @LoopCounter - 1
		BREAK
	END
	SET @LoopCounter = @LoopCounter + 1
END

--If we reach 40 count, it means the variable can be unobsoleted without any problem
IF @LoopCounter = 41 BEGIN
	SET NOCOUNT OFF
	RETURN END
ELSE BEGIN

	--If we reach 35 count, it means the variable can be unobsoleted but we need to alter the query string
	IF @LoopCounter = 35 BEGIN

		SET @StartPos = 1
		SET @CurrentPos = 0
		SET @LoopCounter = 1

		WHILE @LoopCounter <= 29 BEGIN
			SET @CurrentPos = charindex(',', @SQLString, @CurrentPos + 1)
			SET @LoopCounter = @LoopCounter + 1
		END

		SET @SubString = substring(@SQLString, 1, @CurrentPos) + 'NULL,NULL,NULL,NULL,' + substring(@SQLString, @CurrentPos + 1, 8000)
		SET @SubString = reverse(@SubString)

		SET @StartPos = 1
		SET @CurrentPos = 0

		SET @CurrentPos = charindex(',', @SubString, @CurrentPos + 1)

		SET @SubString = substring(@SubString, 1, @CurrentPos) + '0,' + substring(@SubString, @CurrentPos + 1, 8000)
		SET @SubString = reverse(@SubString)

		SET @SQLString = @SubString END

	--If not, then we set sting to ''. This will flag PCMT to not unobsolete variable.
	ELSE BEGIN

		SET @SQLString = ''

	END

END

SET NOCOUNT OFF


