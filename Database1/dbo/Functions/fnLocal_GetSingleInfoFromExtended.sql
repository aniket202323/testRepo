
-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetSingleInfoFromExtended] (@Key_Id int, @TableName varchar(50), @ParmName varchar(10))

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:	fnLocal_GetSingleInfoFromExtended
Author				: 	Normand Carbonneau (System Technologies for industry Inc)
Date created		: 	07-Jun-2007
Version				: 	1.0.0
Editor Tab spacing:	3
Proposed				:
SP Type				:	
Called by			:	SPs

Description:
=========
Extracts a parameter (SS, VT, RPT, VC...) from the Extended Info of a table.
Example :	We have a variable	Var_Id = 13759 Extended_Info = 'VT=PQM;R=;SS=2;RPT=Y;QSMT=Y;NORM=Y;TZ=N'
Example :	fnLocal_GetSingleInfoFromExtended(13759, 'Variables', 'SS') will return '2'
				fnLocal_GetSingleInfoFromExtended(13759, 'Variables', 'VT') will return 'PQM'
				fnLocal_GetSingleInfoFromExtended(13759, 'Variables', 'TZ') will return 'N'


Revision 	Date 				Who 							What
========		====				===							====
1.1.0			13-Mar-2006		Normand Carbonneau		Creation of function.
1.1.1			29-Jan-2008		Linda Hudon				Remove extended_info from comments and products tables
														because this field doesn't exist in Proficy 3



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
	
	-- Get the Extended_Info ffrom the table defined by @TableName parameter
	IF @TableName = 'Characteristics'
		BEGIN
			SET @ExtInfo = (SELECT Extended_Info FROM Characteristics WHERE Char_Id = @Key_Id)
		END
	ELSE IF @TableName = 'Events'
		BEGIN
			SET @ExtInfo = (SELECT Extended_Info FROM Events WHERE Event_Id = @Key_Id)
		END
	ELSE IF @TableName = 'Prod_Units'
		BEGIN
			SET @ExtInfo = (SELECT Extended_Info FROM Prod_Units WHERE PU_Id = @Key_Id)
		END
	ELSE IF @TableName = 'Prod_Lines'
		BEGIN
			SET @ExtInfo = (SELECT Extended_Info FROM Prod_Lines WHERE PL_Id = @Key_Id)
		END
	ELSE IF @TableName = 'Specifications'
		BEGIN
			SET @ExtInfo = (SELECT Extended_Info FROM Specifications WHERE Spec_Id = @Key_Id)
		END
	ELSE IF @TableName = 'Variables'
		BEGIN
			SET @ExtInfo = (SELECT Extended_Info FROM Variables WHERE Var_Id = @Key_Id)
		END
	
		
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

