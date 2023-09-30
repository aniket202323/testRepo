
-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetLineType] (@PL_id int)

/*
SQL Function			:		fnLocal_GetLineType
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		04-May-2006
Function Type			:		Scalar
Editor Tab Spacing	:		3

Description:
===========
Retrieves the Line Type of a Line (Always, Diaper, Tampax, Wipe)

CALLED BY				:  Stored Procedures (Several)


Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.1				04-June-2012	Namrata Kumar			Appversions corrected
1.0.0				04-May-2006		Normand Carbonneau		Creation
																		Compliant with new coding standards.
																		
1.1.0				22-May-2006		Normand Carbonneau		Compliant with Proficy 3 and 4.

*/

RETURNS varchar(50)

AS
BEGIN
	DECLARE
	@AppVersion		varchar(30),	-- Used to retrieve the Proficy database Version
	@LineType		varchar(50)
	
	-- Get the Proficy Database Version
	SELECT @AppVersion = App_Version FROM AppVersions WHERE App_Name = 'Database'

	IF  @AppVersion LIKE '4%'
		BEGIN
			SET @LineType =	(
									SELECT	substring(Extended_info,charIndex('Linetype=',Extended_info) + 9, 
												(charIndex(';', Extended_info, charIndex('Linetype=', Extended_info))
												- (charIndex('Linetype=', Extended_info) + 9)))
									FROM		dbo.Prod_Lines
									WHERE		PL_Id = @PL_id
									)
		END
	ELSE
		BEGIN
			SET @LineType = (SELECT Equipment_Type FROM dbo.Prod_Units WHERE (PL_Id = @PL_Id) AND (PU_Desc LIKE '%Quality%'))
		END
		
	RETURN @LineType
END

