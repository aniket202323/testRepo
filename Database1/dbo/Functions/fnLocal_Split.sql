
-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION dbo.fnLocal_Split(@String VARCHAR(8000), @Delimiter CHAR(1))
RETURNS @Strings TABLE([id] INT IDENTITY, String VARCHAR(8000))


/*
SQL Function			:		fnLocal_Split
Author					:		Stephane Turner (System Technologies for Industry Inc)
Date Created			:		07-May-2007
Function Type			:		Table-Valued
Editor Tab Spacing	:		3

Description:
===========
Returns a Table variable from a string containing a list of values separated by a delimiter.

CALLED BY				:  SP


Revision 			Date				Who							What
========			===========		==================		=================================================================================
1.1				04-June-2012	Namrata Kumar			Appversions corrected
1.0.0				07-May-2007		Stephane Turner			Creation


TEST CODE :
SELECT * FROM dbo.fnLocal_Split ('One, Two, Three, Four, Five', ',')

*/

AS
BEGIN
  
 WHILE(CHARINDEX(@Delimiter, @String) > 0)
	 BEGIN
		  INSERT INTO @Strings(String)
		  SELECT LTRIM(RTRIM(SUBSTRING(@String, 1, CHARINDEX(@Delimiter, @String) - 1)))
		 
		  SET @String = SUBSTRING(@String, CHARINDEX(@Delimiter, @String) + 1, LEN(@String))
	 END
 
 IF LEN(@String) > 0
	 BEGIN
		INSERT INTO @Strings(String) SELECT @String
	 END
 
 RETURN
END
 
