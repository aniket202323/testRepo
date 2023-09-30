   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Removed data type Varchar_PI_Tag and replaced it by Varchar(100)  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
--Created by Joe Nichols, 3/18/03  
--This script updates Historian variables in Proficy to ADD the IP Address (or any other string)  
--from the tag name, thereby setting it to a non-primary Historian on the Proficy Server.  
-- @DCString, which typically is the data collector name you are looking for.  
-- @PLID, which is the Line ID you wish to restrict your search to.  It can be a comma separated list.  
-- @HistName, which is the name of the Historian you wish to insert, which is typically the IP Address.  It must include the leading '\\' and trailing '\' as shown below.  
--EXAMPLE:    
--EXEC spLocal_Change_HistVars_ADD_Secondary 'MHMP','152,153','143.5.230.35'  
*/  
  
CREATE PROCEDURE dbo.spLocal_Change_HistVars_ADD_Secondary  
@DCString  Varchar(100),  
@PLID    Integer,  
@HistName  Varchar(100)  
  
AS  
SET NOCOUNT ON  
  
Declare @DCStringCompare Varchar(100)  
Select @DCStringCompare = '%'+@DCString+'%'  
UPDATE [dbo].Variables SET Input_Tag = ('\\' + @HistName + '\' + Input_Tag),DQ_Tag = (@HistName + DQ_Tag)   
FROM [dbo].Variables v JOIN [dbo].Prod_Units pu ON v.PU_Id = pu.PU_Id   
WHERE (PL_Id IN (@PLID) AND ((Input_Tag Like @DCStringCompare) OR (DQ_Tag Like @DCStringCompare)) )  
  
SET NOCOUNT OFF  
  
