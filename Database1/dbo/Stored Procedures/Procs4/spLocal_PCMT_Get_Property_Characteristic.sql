











-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Property_Characteristic]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-05
Version		:	2.2.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Modified by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	20-Nov-2003 
Version		:	2.1.0
Purpose		:	The SP is now returning all production lines description. 
					Search for 'Tim Rogers' to what has been changed.  
-------------------------------------------------------------------------------------------------
Modified by	: 	Clement Morin, Solutions et Technologies Industrielles inc.
On				:	7-JUL-03 
Version		:	2.0.0
Purpose		:	Possible to return the caracteristic for multiple lines or
					single line configuration
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	Return the list of properties for a given unit name
-------------------------------------------------------------------------------------------------
*/

@intProperty	INT,
@vcrLineList	varchar(100) = NULL

AS
SET NOCOUNT ON

DECLARE
@intBegPos		INT,				--2.0.0
@intEndPos		INT,				--2.0.0
@vcrLineDesc	varchar(100) 	--2.0.0

-- No Longer needed
---- 2.0.1 Start
--Create table #tblLine(
--	vcrName		varchar(100)		
--)
--
--insert into #tblLine (vcrName)
--	select PL_Desc from dbo.Prod_Lines

SELECT	Char_Id, Char_Desc
FROM		dbo.Characteristics
WHERE		Prop_Id = @intProperty
                --put in comments asked by Tim Rogers on November 10th 2003
		--and not Exists(select char_desc from #tblLine tbl where char_desc like '%' + tbl.vcrName + '%')
ORDER BY	Char_Desc 
-- 2.0.1 END
/*
-- Verify if is multiple lines
if @vcrLineList is not NULL
begin 
        select @intBegPos = 1
	-- Get the characteristic asociated to each lines selected
        while @intBegPos <= len(@vcrLineList) begin
               select @intEndPos = charindex('[REC]', @vcrLineList, @intBegPos)
               select @vcrLineDesc = substring(@vcrLineList, @intBegPos, @intEndPos - @intBegPos)
     	  		
               insert #tblCharac(intCharact,vcrName)
			select 0, left(char_desc,charindex(@vcrLineDesc, char_desc)-2)
				FROM Characteristics 
				WHERE prop_id = @intProperty
					and char_desc like '%' + @vcrLineDesc
				ORDER BY char_desc 
			
               select @intBegPos = @intEndPos + 1
        end
	select Distinct intCharact,vcrname
	from #tblCharac
	ORDER BY vcrname
	
end
else
begin

-- 2.0.0 End
	SELECT char_id, char_desc
	FROM Characteristics 
	WHERE prop_id = @intProperty
	ORDER BY char_desc 
end
*/
--drop table #tblLine

SET NOCOUNT OFF













