-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetParameterFromExtended] (@Var_Id int, @ParmName varchar(10))
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-13
Version		:	1.1.0
Purpose		:	Now returns Varchar(50) instead of Varchar(10)
					Exit immediately if @StartPos = 0
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	Extracts a parameter (SS, VT, RPT, VC...) from the Extended Info of a variable.
					Example : We have a variable	Var_Id = 13759
															Extended_Info = 'VT=PQM;R=;SS=2;RPT=Y;QSMT=Y;NORM=Y;TZ=N'
					Example :	fnLocal_GetParameterFromExtended(13759,'SS') will return '2'
									fnLocal_GetParameterFromExtended(13759,'VT') will return 'PQM'
									fnLocal_GetParameterFromExtended(13759,'TZ') will return 'N'
-------------------------------------------------------------------------------------------------
*/

RETURNS varchar(50)

AS
BEGIN
	DECLARE
	@ExtInfo			varchar(255),
	@StartPos		int,
	@EndPos			int,
	@ParmLength		int,
	@Parameter		varchar(50)

	-- Get the Extended_Info for the variable defined by @Var_Id parameter
	SET @ExtInfo = (SELECT Extended_Info FROM dbo.Variables WHERE Var_Id = @Var_Id)
	
	SET @ParmName = @ParmName + '='
	SET @ParmLength = len(@ParmName)
	
	IF @ExtInfo IS NOT NULL
		BEGIN
			SET @StartPos = charindex(@ParmName, @ExtInfo)
			
			IF @StartPos > 0
				BEGIN
					SET @EndPos = charindex(';', @ExtInfo, @StartPos)
					
					-- If no ; found at the end, this is the last parameter in Extended_Info
					IF @EndPos = 0
						BEGIN
							SET @EndPos = len(@ExtInfo) + 1
						END
						
					SET @Parameter = substring(@ExtInfo, @StartPos + @ParmLength, @EndPos - @StartPos - @ParmLength)
				END	
		END

	RETURN @Parameter

END

