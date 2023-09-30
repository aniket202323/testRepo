  --Written by Joe Nichols, 3/18/03  
--This stored procedure updates the Historian Tags specified in an event configuration in Proficy to include  
--the IP Address (or any other text string) as the historian name.  This is useful when a secondary   
--Historian is added to a server.  
--The values passed in are:  
-- @DCString, which typically is the data collector name you are looking for.  
-- @PLID, which is the Line ID you wish to restrict your search to.  It can NOT be a list.  
-- @HistName, which is the name of the Historian you wish to insert, which is typically the IP Address.  
--Examples  
--EXEC spLocal_Change_Event_ADD_Secondary 'MHMP','152','143.5.230.35'  
  
CREATE PROCEDURE dbo.spLocal_Change_Event_ADD_Secondary  
@DCString  varchar(20),  
@PLID  Varchar(100),  
@HistName Varchar(20)  
  
AS  
  
SET NOCOUNT ON  
  
--Select the records to verify your criteria are correct.  
Declare @StringCompare Varchar(20)  
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
Declare @FullHistName varchar(20)  
Select @FullHistName = '\\' + @HistName + '\'  
UPDATETEXT [dbo].Event_Configuration_Values.Value @ptrval 3 0 @FullHistName  
FETCH NEXT FROM c_result  
   INTO @ptrval  
END   
CLOSE c_result  
deallocate c_result  
  
  
--Select the records to verify your update worked correctly.  
Select * FROM [dbo].Event_Configuration_Values ecv   
INNER JOIN [dbo].Event_Configuration_Data ecd ON ecv.ECV_Id = ecd.ECV_Id   
INNER JOIN [dbo].Prod_Units pu ON ecd.PU_Id = pu.PU_Id  
WHERE (ecv.Value LIKE @StringCompare) AND (ecv.Value LIKE '%PT:%')AND(pu.PL_Id IN (@PLID))  
  
SET NOCOUNT OFF  
  
