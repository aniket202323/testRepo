 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System Technologies for Industry  
Date   : 2006-01-31  
Version  : 1.0.3  
Purpose  : Correction on the scripting  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System Technologies for Industry  
Date   : 2006-01-31  
Version  : 1.0.2  
Purpose  : Add user_id  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-17  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_UpdateClothingEvent  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
The stored procedure requires that Site Parameter 142 (AllowEventMoveOutsideWindow) be set to TRUE.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
01/30/02 MKW Fixed pass of float string to integer status argument  
07/08/02 MKW Changed default status to be 'Inventory' instead of 'Next On'  
   Modified so that when set to Running will take the first 'Next On' found  
08/19/02 MKW Changed count(Event_Id) to count(*) to prevent the indexes from coming into play when SQL determines its execution plan  
08/20/02 MKW Changed count(*) to count(PU_Id) so use same field as in the Where statement b/c that index already used  
09/09/02 MKW Removed Group By clause for count query that was preventing update of times for running, next on and inventory  
*/  
  
CREATE procedure [dbo].[spLocal_UpdateClothingEvent]  
@OutputValue   varchar(25) OUTPUT,  
@Event_Id   int,  
@Last_Event_Status_Str varchar(30),  
@Unload_Date_Var_Id  int,  
@Unload_Time_Var_Id  int,  
@Complete_Status_Desc varchar(25),  
@Running_Status_Desc  varchar(25),  
@Removed_Status_Desc varchar(25),  
@Next_On_Status_Desc varchar(25),  
@Inventory_Status_Desc varchar(25)  
AS  
SET NOCOUNT ON  
  
/*  
Insert Into Local_ClothingChange(Event_Id,  TimeStamp)  
Values(@Event_Id, getdate())  
*/  
  
DECLARE  @EventUpdates Table(  
 Result_Set_Type int Default 1,  
 Id        int Identity,  
 Transaction_Type  int Default 2,   
 Event_Id   int Null,   
 Event_Num   varchar(25),   
 PU_Id    int,   
 TimeStamp   datetime,   
 Applied_Product  int Null,   
 Source_Event   int Null,   
 Event_Status   int Null,  
 Confirmed   int Default 1,  
 User_Id   int Null,  
 Post_Update  int Default 0)  
  
Declare @TimeStamp  datetime,  
 @Entry_On  datetime,  
 @PU_Id  int,  
 @Event_Num  varchar(25),  
 @Event_Status  int,  
 @Next_Event_Id int,  
 @Next_Event_Num varchar(30),  
 @Next_Event_Status int,  
 @Next_TimeStamp datetime,  
 @Last_TimeStamp  datetime,  
 @Complete_Status_Id tinyint,  
 @Running_Status_Id tinyint,  
 @Removed_Status_Id tinyint,  
 @Next_On_Status_Id tinyint,  
 @Inventory_Status_Id tinyint,  
 @Load_TimeStamp datetime,  
 @Unload_TimeStamp datetime,  
 @Unload_Date  varchar(30),  
 @Unload_Time  varchar(30),  
 @Count   int,  
 @Last_Event_Status int  
  
DECLARE @strSQL nvarchar(500),  
@param    nvarchar(500),  
@AppVersion   varchar(30),  
 @User_id    int  
   
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
/* Testing */  
/*  
Select @Event_Id = 44565,  
 @Event_Status  = 5,  
 @Complete_Status_Desc = 'Complete',  
 @Running_Status_Desc = 'Running',  
 @Removed_Status_Desc = 'Removed',  
 @Next_On_Status_Desc = 'Next On',  
 @Unload_Date_Var_Id = 3317,  
 @Unload_Time_Var_Id = 3318  
*/  
/* Initialization */  
Select  @Last_Event_Status = Null,  
 @Count   = 0  
  
/* Verify arguments */  
If IsNumeric(@Last_Event_Status_Str) = 1  
     Select @Last_Event_Status = convert(int, convert(float, @Last_Event_Status_Str))  
  
/* Get additional data */  
Select  @PU_Id = PU_Id,  
 @Event_Num = Event_Num,  
 @TimeStamp = TimeStamp,  
 @Event_Status = Event_Status,  
 @Entry_On = Entry_On  
From [dbo].Events  
Where Event_Id = @Event_Id  
  
Select @OutputValue = @Event_Status  
  
If @Event_Status <> @Last_Event_Status Or @Last_Event_Status Is Null  
     Begin  
     /* Initialization */  
  
 IF @AppVersion LIKE '4%'  
 BEGIN  
  SET @strSQL = 'SELECT @PSID = ProdStatus_Id FROM [dbo].Production_Status '  
  SET @strSQL = @strSQL + 'WHERE COALESCE(ProdStatus_desc_global, ProdStatus_desc_local) = ''' + @Complete_Status_Desc + ''''  
  SET @Param = '@PSID int OUTPUT'  
  EXECUTE sp_executesql  
  @strSQL,  
  @Param,  
  @PSID=@Complete_Status_Id OUTPUT  
  
  SET @strSQL = 'SELECT @PSID = ProdStatus_Id FROM [dbo].Production_Status '  
  SET @strSQL = @strSQL + 'WHERE COALESCE(ProdStatus_desc_global, ProdStatus_desc_local) = ''' + @Next_On_Status_Desc + ''''  
  SET @Param = '@PSID int OUTPUT'  
  EXECUTE sp_executesql  
  @strSQL,  
  @Param,  
  @PSID=@Next_On_Status_Id OUTPUT  
  
  SET @strSQL = 'SELECT @PSID = ProdStatus_Id FROM [dbo].Production_Status '  
  SET @strSQL = @strSQL + 'WHERE COALESCE(ProdStatus_desc_global, ProdStatus_desc_local) = ''' + @Running_Status_Desc + ''''  
  SET @Param = '@PSID int OUTPUT'  
  EXECUTE sp_executesql  
  @strSQL,  
  @Param,  
  @PSID=@Running_Status_Id OUTPUT  
  
  SET @strSQL = 'SELECT @PSID = ProdStatus_Id FROM [dbo].Production_Status '  
  SET @strSQL = @strSQL + 'WHERE COALESCE(ProdStatus_desc_global, ProdStatus_desc_local) = ''' + @Removed_Status_Desc + ''''  
  SET @Param = '@PSID int OUTPUT'  
  EXECUTE sp_executesql  
  @strSQL,  
  @Param,  
  @PSID=@Removed_Status_Id OUTPUT  
  
  SET @strSQL = 'SELECT @PSID = ProdStatus_Id FROM [dbo].Production_Status '  
  SET @strSQL = @strSQL + 'WHERE COALESCE(ProdStatus_desc_global, ProdStatus_desc_local) = ''' + @Inventory_Status_Desc + ''''  
  SET @Param = '@PSID int OUTPUT'  
  EXECUTE sp_executesql  
  @strSQL,  
  @Param,  
  @PSID=@Inventory_Status_Id OUTPUT  
 END  
 ELSE  
 BEGIN  
     Select @Complete_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = @Complete_Status_Desc  
     Select @Next_On_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = @Next_On_Status_Desc  
     Select @Running_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = @Running_Status_Desc  
     Select @Removed_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = @Removed_Status_Desc  
     Select @Inventory_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = @Inventory_Status_Desc  
 END  
  
-- INSERT INTO Local_Sti_test (SP_NAME, Parm_name,Value) VALUES ('spLocal_UpdateClothingEvent','@Complete_Status_Id',Convert(varchar(50),isnull(@Complete_Status_Id,0)))  
-- INSERT INTO Local_Sti_test (SP_NAME, Parm_name,Value) VALUES ('spLocal_UpdateClothingEvent','@Next_On_Status_Id',Convert(varchar(50),isnull(@Next_On_Status_Id,0)))  
-- INSERT INTO Local_Sti_test (SP_NAME, Parm_name,Value) VALUES ('spLocal_UpdateClothingEvent','@Running_Status_Id',Convert(varchar(50),isnull(@Running_Status_Id,0)))  
-- INSERT INTO Local_Sti_test (SP_NAME, Parm_name,Value) VALUES ('spLocal_UpdateClothingEvent','@Removed_Status_Id',Convert(varchar(50),isnull(@Removed_Status_Id,0)))  
-- INSERT INTO Local_Sti_test (SP_NAME, Parm_name,Value) VALUES ('spLocal_UpdateClothingEvent','@Inventory_Status_Id',Convert(varchar(50),isnull(@Inventory_Status_Id,0)))  
-- INSERT INTO Local_Sti_test (SP_NAME, Parm_name,Value) VALUES ('spLocal_UpdateClothingEvent','@Event_Status',Convert(varchar(50),isnull(@Event_Status,0)))  
  
  
     If @Event_Status = @Complete_Status_Id  /* Complete */  
          Begin  
          Insert Into @EventUpdates (Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,user_id)  
          Select Event_Id, Event_Num, PU_Id, TimeStamp, @Inventory_Status_Id,@User_id  
          From [dbo].Events  
          Where Event_Id = @Event_Id  
  
          /* Return current status for next iteration */  
          Select @OutputValue = @Inventory_Status_Id  
          End  
     Else If @Event_Status = @Running_Status_Id /* Running */  
          Begin  
          /* Make sure there's only 1 running */  
          If (Select count(PU_Id) From Events Where PU_Id = @PU_Id and Event_Status = @Running_Status_Id) > 1  
               Begin  
               /* If more than 1 running then reset to 'Next On' */  
               Insert Into @EventUpdates (Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,user_id)  
               Select Event_Id, Event_Num, PU_Id, TimeStamp, @Next_On_Status_Id,@User_id  
               From [dbo].Events  
               Where Event_Id = @Event_Id  
  
               /* Return current status for next iteration */  
               Select @OutputValue = @Next_On_Status_Id  
               End  
          Else  
               Begin  
               /* Check the Event_History for duplicates */  
               Select @Count = count(Event_Id)  
               From [dbo].Event_History  
               Where Event_id = @Event_Id And Event_Status = @Running_Status_Id  
  
               If @Count < 2  
                    Begin  
                    /* Generate the new date */           
--                    Select @Load_TimeStamp = getdate()  
                    Select @Load_TimeStamp = @Entry_On  
  
                    /* Make sure future TimeStamps are updated and are at least 1 sec after the current one */  
                    Select @Last_TimeStamp = @Load_TimeStamp  
  
                    Declare ClothingChanges Cursor For  
                    Select Event_Id, Event_Num, TimeStamp, Event_Status  
                    From [dbo].Events  
                    Where PU_Id = @PU_Id And (Event_Status = @Next_On_Status_Id Or Event_Status = @Inventory_Status_Id)  
                    Order By TimeStamp Asc  
                    Open ClothingChanges  
  
                    Fetch Next From ClothingChanges Into @Next_Event_Id, @Next_Event_Num, @Next_TimeStamp, @Next_Event_Status  
                    While @@FETCH_STATUS = 0  
                         Begin  
                         If @Next_TimeStamp <= @Last_TimeStamp  
                              Begin  
                              Select @Last_TimeStamp = dateadd(s, 1, @Last_TimeStamp)  
  
                              Insert Into @EventUpdates (Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,user_id)  
                              Values(@Next_Event_Id, @Next_Event_Num, @PU_Id, @Last_TimeStamp, @Next_Event_Status,@User_id)  
                              End  
                         Fetch Next From ClothingChanges Into @Next_Event_Id, @Next_Event_Num, @Next_TimeStamp, @Next_Event_Status  
                         End  
  
                    /* Insert updates for the current event - Set the TimeStamp to be equal to the Start_Time */  
                    Insert Into @EventUpdates (Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,user_id)  
                    Values (@Event_Id, @Event_Num, @PU_Id, @Load_TimeStamp, @Event_Status,@User_id)  
  
                    /* Return current status for next iteration */  
                    Select @OutputValue = @Running_Status_Id  
  
                    /* Clean-up */  
                    Close ClothingChanges  
                    Deallocate ClothingChanges  
                    End  
               End  
          End  
     Else If @Event_Status = @Removed_Status_Id /* Removed */  
          Begin  
          /* Check to see if variables have values and, if not, set it to the current time */  
          Select @Unload_Date = Result  
          From [dbo].tests  
          Where Var_Id = @Unload_Date_Var_Id And Result_On = @TimeStamp  
  
          Select @Unload_Time = Result  
          From [dbo].tests  
          Where Var_Id = @Unload_Time_Var_Id And Result_On = @TimeStamp  
  
          If @Unload_Date Is Null And @Unload_Time Is Null  
               Begin  
               Select @Unload_TimeStamp = @Entry_On --getdate()  
               Exec [dbo].spLocal_ConvertDate @Unload_Date OUTPUT, @Unload_TimeStamp, Null  
               Exec [dbo].spLocal_ConvertTime @Unload_Time OUTPUT, @Unload_TimeStamp, Null  
               Select 2, @Unload_Date_Var_ID, @PU_ID, 1, 0, @Unload_Date, @TimeStamp, 2, 0  
               Select 2, @Unload_Time_Var_ID, @PU_ID, 1, 0, @Unload_Time, @TimeStamp, 2, 0  
               End  
  
          /* Return current status for next iteration */  
          Select @OutputValue = @Removed_Status_Id  
  
          /* Set the next 'Next On' clothing to Running */  
          Select @Next_TimeStamp = min(TimeStamp)  
          From [dbo].Events  
          Where PU_Id = @PU_Id And Event_Status = @Next_On_Status_Id And Entry_On <= @Entry_On  
  
          Insert Into @EventUpdates (Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,user_id)  
          Select Event_Id, Event_Num, PU_Id, TimeStamp, @Running_Status_Id,@User_id  
          From [dbo].Events  
          Where PU_Id = @PU_Id And TimeStamp = @Next_TimeStamp  
          End  
     End  
  
/* Return results */  
Select Result_Set_Type, Id, Transaction_Type, Event_Id, Event_Num, PU_Id,   
TimeStamp, Applied_Product, Source_Event, Event_Status, Confirmed, User_Id, Post_Update   
From @EventUpdates  
  
Order By TimeStamp Desc  
  
  
SET NOCOUNT OFF  
  
  
  
  
  
