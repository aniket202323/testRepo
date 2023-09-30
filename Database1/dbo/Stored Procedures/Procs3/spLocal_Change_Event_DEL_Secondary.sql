 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
--Written by Joe Nichols, 3/18/03  
--This stored procedure updates the Historian Tags specified in an event configuration in Proficy to DELETE  
--the IP Address (or any other text string) as the historian name.  This is useful when a secondary   
--Historian is added to a server.  
--The values passed in are:  
-- @DCString, which typically is the data collector name you are looking for.  
-- @PLID, which is the Line ID you wish to restrict your search to.  
-- @HistLength, which is the number of characters +3 in the name of the Historian you wish to remove, which is typically the IP Address.  
--  NOTE that you must add 3 extra characters to the name to accommodate the leading '\\' and trailing '\' in the name.  
--EXAMPLE CALL:  EXEC spLocal_Change_Event_DEL_Secondary 'MHMP', '152', '15'  
--Where MHMP is the data collector name, 152 is the line ID to focus on, and the historian string length to delete is 15, since  
--which is a count of the characters in '\\143.5.230.35\' thus 12+3=15.  
--Example:  
--EXEC spLocal_Change_Event_DEL_Secondary 'MHMP','152',15  
  
CREATE PROCEDURE dbo.spLocal_Change_Event_DEL_Secondary  
@DCString  Varchar(16),  
@PLID  Varchar(100),  
@HistLength Integer  
  
AS  
  
SET NOCOUNT ON  
  
--Select the records to verify your criteria are correct.  
Declare @StringCompare Varchar(16)  
Select @StringCompare = '%' + @DCString + '%'  
  
Select * FROM [dbo].Event_Configuration_Values ecv   
INNER JOIN [dbo].Event_Configuration_Data ecd ON ecv.ECV_Id = ecd.ECV_Id   
INNER JOIN [dbo].Prod_Units pu ON ecd.PU_Id = pu.PU_Id  
WHERE (ecv.Value LIKE @StringCompare) AND (ecv.Value LIKE '%PT:%')AND(pu.PL_Id IN (@PLID))  
  
--Update the text fields to modify the tagnames  
DECLARE @ptrval binary(16)  
DECLARE c_result CURSOR FOR  
SELECT TEXTPTR(value)  
 FROM [dbo].Event_Configuration_Values ecv   
  INNER JOIN [dbo].Event_Configuration_Data ecd ON ecv.ECV_Id = ecd.ECV_Id   
  INNER JOIN [dbo].Prod_Units pu ON ecd.PU_Id = pu.PU_Id  
  WHERE (ecv.Value LIKE @StringCompare) AND (ecv.Value LIKE '%PT:%')AND(pu.PL_Id IN (@PLID))  
  
OPEN c_result  
  
FETCH NEXT FROM c_result INTO  
   @ptrval  
WHILE @@FETCH_STATUS = 0  
  
BEGIN  
--syntax for UPDATETEXT is UPDATETEXT tabel.column pointervar insertoffset deletelength inserttext  
UPDATETEXT Event_Configuration_Values.Value @ptrval 3 @HistLength   
FETCH NEXT FROM c_result  
   INTO @ptrval  
END   
CLOSE c_result  
deallocate c_result  
  
SET NOCOUNT OFF  
  
