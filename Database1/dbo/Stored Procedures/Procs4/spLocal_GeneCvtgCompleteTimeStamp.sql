   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.3  
Purpose  : Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GeneCvtgCompleteTimeStamp  
Author:   Matthew Wells (MSI)  
Date Created:  02/13/02  
  
Description:  
=========  
The procedure gets the timestamp of when the parent roll was completed out of the running position.  
  
This procedure checks the genealogy for the same event being loaded on this unit in   
the future.  This way we can prevent a rejected roll from picking up the data from   
the same event being reloaded in the future.  We just use the timestamp b/c you can't  
load the same roll simultaneously and the timestamp represents the time it was loaed  
onto the input (Staged or Running).  
  
Change Date Who What  
=========== ==== =====  
02/04/04 MKW Added comment and check of event status before retrieving data  
   Added check for same event being reloaded in future  
04/30/04 MKW Changed to look at this event's history  
*/  
  
CREATE PROCEDURE spLocal_GeneCvtgCompleteTimeStamp  
@OutputValue varchar(25) OUTPUT,  
@EventId int  
AS  
  
/* Testing...   
SELECT @Event_Id = 41788  
*/  
SET NOCOUNT ON  
  
DECLARE @CompleteTimeStamp datetime,  
 @EntryOn  datetime,  
 @Date   varchar(25),  
 @Time   varchar(25),  
 @StatusId  int,  
 @LastStatusId  int,  
 @Rows   int,  
 @Row   int  
  
DECLARE @StatusChanges TABLE ( ChangeId int IDENTITY PRIMARY KEY,  
    StatusId int,  
    EntryOn  datetime)  
  
-- Initialization  
SELECT  @CompleteTimeStamp  = NULL,  
      @OutputValue  = ' '  
  
SELECT @StatusId = Event_Status,  
 @EntryOn = Entry_On  
FROM [dbo].Events  
WHERE Event_Id = @EventId  
  
IF @StatusId NOT IN (3, 4, 9)  
 BEGIN  
 INSERT INTO @StatusChanges ( StatusId,  
     EntryOn )  
 SELECT Event_Status,  
  Entry_On  
 FROM [dbo].Event_History  
 WHERE Event_Id = @EventId  
 ORDER BY Entry_On ASC  
   
 SELECT @Rows  = @@ROWCOUNT + 1,  
  @Row  = 0,  
  @LastStatusId = 0  
   
 INSERT INTO @StatusChanges ( StatusId,  
     EntryOn )  
 VALUES (@StatusId,  
  @EntryOn )  
  
 WHILE @Row < @Rows  
  BEGIN  
  SELECT @Row = @Row + 1  
  SELECT @StatusId = StatusId,  
   @EntryOn = EntryOn  
  FROM @StatusChanges  
  WHERE ChangeId = @Row  
   
  IF @LastStatusId <> @StatusId  
   AND @StatusId NOT IN (3,4,9)  
   BEGIN  
   SELECT @CompleteTimeStamp = @EntryOn  
   END  
   
  SELECT @LastStatusId = @StatusId  
  END  
 END  
  
-- Output results  
IF @CompleteTimeStamp IS NOT NULL  
 BEGIN  
 EXEC spLocal_ConvertDate @Date OUTPUT,  
     @CompleteTimeStamp,  
     NULL  
 EXEC spLocal_ConvertTime @Time OUTPUT,  
     @CompleteTimeStamp,  
     NULL  
 SELECT @OutputValue = convert(varchar(25), @Date+' '+@Time)  
 END  
  
SET NOCOUNT OFF  
  
