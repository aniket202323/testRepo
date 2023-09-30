  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_CleanProductChanges  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
This procedure runs every time a product change event is created on the associated unit.  It goes back in time   
and then checks between that time and the current time for any 'orphaned' product changes  
(ie. product changes cascaded from the 'Parent' unit but which were subsequently deleted on the 'Parent' unit).  
  
Change Date  Who      Vserion  What  
============ ================== ========= ==================================================  
2006-11-03  Marc Charest (STI) 2.0.0   Add code for debug matter.  
                Adjust Resultset #3 for PA4   
2005-11-22  Eric Perron (STI)  1.0.1   Redesign of SP (Compliant with Proficy 3 and 4).  
                Added [dbo] template when referencing objects.  
                Replace temp table for table variable.  
11/05/01   MKW      na    Added comment.  
*/  
  
CREATE procedure dbo.spLocal_CleanProductChanges  
@OutputValue varchar(25) OUTPUT,  
@Child_PU_Id int,  
@Parent_PU_Id int,  
@Reference_End_Time datetime,  
@bitDebug  BIT=0  
  
AS  
  
SET NOCOUNT ON  
/* TESTING  
Select @Child_PU_Id = 2169  
Select @Parent_PU_Id = 2  
*/  
  
Declare @Child_Start_Id  int,  
 @Child_Prod_Id  int,  
 @Child_Start_Time  datetime,  
 @Parent_Start_Id  int,  
 @Parent_Prod_Id  int,  
 @Parent_Start_Time  datetime,    
 @Last_Start_Id  int,  
 @Reference_Time datetime,  
 @Child_Fetch_Status int,  
 @Parent_Fetch_Status int,  
 @intUserId    INTEGER,  
 @vcrDebugMessage  VARCHAR(4000),  
 @vcrDebugSPName  VARCHAR(100),  
 @vcrDebugUser   VARCHAR(100)  
  
DECLARE @FalseProductChanges TABLE(  
 Start_Id   int,  
 Prod_Id   int,  
 Start_Time   datetime,  
 Prev_Prod_Id  int,  
 SecondUserId int default null,  
 TransType  int default null  
)  
  
-- user id for the resulset  
SELECT @intUserId = User_id   
FROM [dbo].Users  
WHERE username = 'GradeChangeClean'  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugUser = 'GradeChangeClean'  
 SET @vcrDebugSPName = 'spLocal_CleanProductChanges'   
 SET @vcrDebugMessage = '@Child_PU_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Child_PU_Id, 20), 'NULL') + ' | ' + '@Parent_PU_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Parent_PU_Id, 20), 'NULL') + ' | ' + '@Reference_End_Time = ' + ISNULL(CONVERT(VARCHAR(255), @Reference_End_Time, 20), 'NULL')  
 INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
END  
  
--Initialization  
Select @Reference_Time = dateadd(dd, -5, @Reference_End_Time)  
  
--************************************************************************************************************************************************************************  
--                                                       Loop Through Product Changes And Check For Mismatched/Orphaned Events                                           *  
--************************************************************************************************************************************************************************  
Declare ChildProductChanges Cursor For  
Select Start_Id, Prod_Id, Start_Time  
From [dbo].Production_Starts  
Where PU_Id = @Child_PU_Id and Start_Time > @Reference_Time   
Order By Start_Id Desc  
Open ChildProductChanges  
  
Declare ParentProductChanges Cursor For  
Select Start_Id, Prod_Id, Start_Time  
From [dbo].Production_Starts  
Where PU_Id = @Parent_PU_Id and Start_Time > @Reference_Time   
Order By Start_Id Desc  
Open ParentProductChanges  
  
Fetch Next From ChildProductChanges Into @Child_Start_Id, @Child_Prod_Id, @Child_Start_Time  
Select @Child_Fetch_Status = @@FETCH_STATUS  
Fetch Next From ParentProductChanges Into @Parent_Start_Id, @Parent_Prod_Id, @Parent_Start_Time  
Select @Parent_Fetch_Status = @@FETCH_STATUS  
  
While @Child_Fetch_Status = 0 And @Parent_Fetch_Status = 0  
Begin  
     If @Child_Start_Id < @Parent_Start_Id  
     Begin  
          --Create missing product changes  
          --Increment  
          Fetch Next From ParentProductChanges Into @Parent_Start_Id, @Parent_Prod_Id, @Parent_Start_Time  
          Select @Parent_Fetch_Status = @@FETCH_STATUS  
     End  
     Else  
     Begin  
          If @Child_Prod_Id <> @Parent_Prod_Id or @Child_Start_Time <> @Parent_Start_Time  
          Begin  
               --Delete bad product changes  
               Insert into @FalseProductChanges (Start_Id, Prod_Id, Start_Time)  
               Values (@Child_Start_Id, @Child_Prod_Id, @Child_Start_Time)  
               Select @Last_Start_Id = @Child_Start_Id  
               --Increment  
               Fetch Next From ChildProductChanges Into @Child_Start_Id, @Child_Prod_Id, @Child_Start_Time  
               Select @Child_Fetch_Status = @@FETCH_STATUS  
               --Update previous product id  
               Update @FalseProductChanges  
               Set Prev_Prod_Id = @Child_Prod_Id  
               Where Start_Id = @Last_Start_Id  
          End  
          Else  
          Begin  
               Fetch Next From ChildProductChanges Into @Child_Start_Id, @Child_Prod_Id, @Child_Start_Time  
               Select @Child_Fetch_Status = @@FETCH_STATUS  
               Fetch Next From ParentProductChanges Into @Parent_Start_Id, @Parent_Prod_Id, @Parent_Start_Time  
               Select @Parent_Fetch_Status = @@FETCH_STATUS  
          End  
     End  
End  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'Issue Product Change deletions...' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
END  
--Issue Product Change deletions  
Select 3, Start_Id, @Child_PU_Id, Prod_Id, Start_Time, 0, @intUserId, SecondUserId, TransType From @FalseProductChanges  
  
--Return number of records modified  
Select @OutputValue = convert(varchar(25), Count(Start_Id)) From @FalseProductChanges  
If @OutputValue Is Null  
     Select @OutputValue = '0'  
  
--Cleanup  
Close ChildProductChanges  
Close ParentProductChanges  
Deallocate ChildProductChanges  
Deallocate ParentProductChanges  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'END' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
END  
  
  
SET NOCOUNT OFF  
  
  
