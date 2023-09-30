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
--This script updates Historian variables in Proficy to REMOVE the IP Address (or any other string)  
--from the tag name, thereby setting it to the primary Historian on the Proficy Server.  
--Parameters:  
--  @HistName This is the Historian name to be deleted.  Note that this MUST include the leading '\\' and trailing '\'  
--  @PLID This is the Line ID you wish to restrict your search to.    
--Example:  EXEC spLocal_Change_HistVars_DEL_Secondary '152','\\143.5.230.35\'  
*/  
  
CREATE PROCEDURE dbo.spLocal_Change_HistVars_DEL_Secondary  
@PLID    Varchar(100),  
@HistName  Varchar(100)  
  
AS  
SET NOCOUNT ON  
Declare   
 @HistCompare Varchar(100)  
  
Select @HistCompare = '%' + @HistName + '%'  
UPDATE [dbo].Variables SET Input_Tag = REPLACE(Input_Tag,@HistName,''),DQ_Tag = REPLACE(DQ_Tag,@HistName,'')   
FROM [dbo].Variables v JOIN [dbo].Prod_Units pu ON v.PU_Id = pu.PU_Id   
WHERE (PL_Id IN (@PLID))AND ((Input_Tag Like @HistCompare OR DQ_Tag Like @HistCompare))  
  
SET NOCOUNT OFF  
