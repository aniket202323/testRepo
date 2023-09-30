   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-26  
Version  : 1.0.1  
Purpose  : Version number   
     Added [dbo] template when referencing objects.  
     Redesign of SP (Compliant with Proficy 3 and 4).  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_CleanDatabase  
Author:   Matthew Wells (MSI)  
Date Created:  11/16/01  
  
Description:  
=========  
This procedure cleans up the Proficy database and deletes old records.  
  
Change Date Who What  
=========== ==== =====  
11/16/01 MKW Created.  
02/01/02 MKW Modified Centerline limit to 60 days.  
*/  
CREATE PROCEDURE spLocal_CleanDatabase   
AS  
  
SET NOCOUNT ON  
  
Declare @PU_Id    int,  
 @TimeStamp    datetime,  
 @Events_Limit    int,  
 @Events_Limit_Default   int,  
 @Events_Range_Start   datetime,  
 @Timed_Events_Limit   int,  
 @Timed_Events_Limit_Default  int,  
 @Timed_Events_Range_Start  datetime,  
 @Product_Changes_Limit  int,  
 @Product_Changes_Limit_Default int,  
 @Product_Changes_Range_Start datetime,  
 @Product_Changes_Start  datetime,  
 @Alarms_Limit    int,  
 @Alarms_Range_Start   datetime,  
 @Clients_Log_Limit   int,  
 @Clients_Log_Range_Start  datetime,  
 @Timed_Value_Limit   int,  
 @Timed_Value_Range_Start  datetime,  
 @Specifications_Limit   int,  
 @Specifications_Range_Start  datetime,  
 @Centerline_Limit   int,  
 @Event_Id    int,  
 @Start_Id    int,  
 @Start_Time    datetime,  
 @AppVersion   varchar(30),  
 @StrSQL    varchar(8000)  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
Select  @Events_Limit_Default   = 365, --105  
 @Timed_Events_Limit_Default  = 365,  
 @Product_Changes_Limit_Default = 365,  
 @Alarms_Limit    = 365,  
 @Clients_Log_Limit   = 365,  
 @Timed_Value_Limit   = 365,  
 @Specifications_Limit   = 365,  
 @Centerline_Limit    = 60,  
 @Product_Changes_Start  = '1970-01-01 00:00:00.000'  
  
/* Initialize */  
Select @TimeStamp = getdate()  
  
Declare Units Cursor For  
Select pu.PU_Id, Events_Limit, Timed_Events_Limit, Product_Changes_Limit   
From [dbo].Prod_Units pu  
     Left Outer Join [dbo].Local_DataRetention r On pu.PU_Id = r.PU_Id  
Open Units  
  
Fetch Next From Units Into @PU_Id, @Events_Limit, @Timed_Events_Limit, @Product_Changes_Limit  
While @@FETCH_STATUS = 0  
Begin  
  
     /* Initialize */  
     If @Events_Limit Is Null  
        Select @Events_Limit = @Events_Limit_Default  
     If @Timed_Events_Limit Is Null  
        Select @Timed_Events_Limit = @Timed_Events_Limit_Default  
     If @Product_Changes_Limit Is Null  
        Select @Product_Changes_Limit = @Product_Changes_Limit_Default  
  
     /****************************************************************************************************  
     *                                  Cleanup Production Events                                        *  
     ****************************************************************************************************/  
     Select @Events_Range_Start = DateAdd(dd, -@Events_Limit, @TimeStamp)  
  
     Delete  
     From [dbo].Test_History  
     From [dbo].Test_History th  
          Inner Join [dbo].Tests t On t.Test_Id = th.Test_Id  
          Inner Join [dbo].Variables v On v.Var_Id = t.Var_Id  
     Where v.Event_Type = 1 And v.PU_Id = @PU_Id And t.Result_On < @Events_Range_Start  
  
     Delete  
     From [dbo].Tests  
     From [dbo].Tests t  
          Inner Join [dbo].Variables v On v.Var_Id = t.Var_Id  
     Where v.Event_Type = 1 And v.PU_Id = @PU_Id And Result_On < @Events_Range_Start  
  
     /* Delete all associated waste events and their comments - In this case join faster than #temp table */  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    Delete  
    From [dbo].Comments  
    From [dbo].Comments wtc  
    Inner Join [dbo].Waste_Event_Details wed On wed.Cause_Comment_Id = wtc.Comment_Id  
    Where wed.PU_Id = @PU_Id And wed.TimeStamp < @Events_Range_Start And Event_Id Is Not Null  
   END  
  ELSE  
      Delete  
      From [dbo].Waste_n_Timed_Comments  
      From [dbo].Waste_n_Timed_Comments wtc  
           Inner Join [dbo].Waste_Event_Details wed On wed.WED_Id = wtc.WTC_Source_Id And wtc.WTC_Type = 3  
      Where wed.PU_Id = @PU_Id And wed.TimeStamp < @Events_Range_Start And Event_Id Is Not Null  
     
  
     Delete  
     From [dbo].Waste_Event_Details  
     Where PU_Id = @PU_Id And TimeStamp < @Events_Range_Start And Event_Id Is Not Null  
  
     /* Delete all the Events */  
     Delete   
     From [dbo].Event_Components  
     From [dbo].Event_Components ec  
          Inner Join [dbo].Events e On e.Event_Id = ec.Event_Id  
     Where e.PU_Id = @PU_Id And e.TimeStamp < @Events_Range_Start  
  
     Delete     -- Faster to split these two  
     From [dbo].Event_Components  
     From [dbo].Event_Components ec  
          Inner Join [dbo].Events e On e.Event_Id = ec.Source_Event_Id  
     Where e.PU_Id = @PU_Id And e.TimeStamp < @Events_Range_Start  
  
     Delete  
     From [dbo].PrdExec_Input_Event_History  
     From [dbo].PrdExec_Input_Event_History pieh  
          Inner Join [dbo].Events e On e.Event_Id = pieh.Event_Id  
     Where e.PU_Id = @PU_Id And e.TimeStamp < @Events_Range_Start  
  
     Delete  
     From [dbo].Event_Details  
     From [dbo].Event_Details ed  
          Inner Join [dbo].Events e On e.Event_Id = ed.Event_Id  
     Where e.PU_Id = @PU_Id And e.TimeStamp < @Events_Range_Start  
  
     Delete  
     From [dbo].Event_History  
     From [dbo].Event_History eh  
          Inner Join [dbo].Events e On e.Event_Id = eh.Event_Id  
     Where e.PU_Id = @PU_Id And e.TimeStamp < @Events_Range_Start  
  
     /* This update query doubles the execution time */  
     Select @Event_Id = Null  
     Select TOP 1 @Event_Id = e1.Event_Id  
     From [dbo].Events e1  
          Inner Join [dbo].Events e2 On e1.Source_Event = e2.Event_Id  
     Where e2.PU_Id = @PU_Id And e2.TimeStamp < @Events_Range_Start  
  
     If @Event_Id Is Not Null  
          Begin  
          Alter Table [dbo].Events Disable Trigger All  
  
          Update [dbo].Events  
          Set Source_Event = Null  
          From [dbo].Events e2   
          Where Source_Event Is Not Null And Source_Event = e2.Event_Id And e2.PU_Id = @PU_Id And e2.TimeStamp < @Events_Range_Start  
  
          Alter Table [dbo].Events Enable Trigger All  
          End  
  
     Delete  
     From [dbo].Events  
     Where PU_Id = @PU_Id And TimeStamp < @Events_Range_Start  
  
     /****************************************************************************************************  
     *                                  Cleanup Product Changes                                                         *  
     ****************************************************************************************************/  
     Alter Table [dbo].Production_Starts Disable Trigger All  
  
     /* MUST keep original production start (ie. Prod_Id = 1)                                              */  
     Delete  
     From [dbo].Production_Starts  
     Where PU_Id = @PU_Id And End_Time < @Product_Changes_Range_Start And Start_Time > @Product_Changes_Start  
  
     /* The Production_Starts records must be contiguous.  This means that have to update the  */  
     /* End_Time of the original one to match the Start_Time  of the next one in time                    */  
  
     Declare Starts Cursor For   
     Select Start_Id, PU_Id  
     From [dbo].Production_Starts-- Or End_Time Is Null  
     Where Start_Time = @Product_Changes_Start And End_Time Is Not Null And End_Time < @Product_Changes_Range_Start And PU_Id > 0  
     Open Starts  
  
     Fetch Next From Starts Into @Start_Id, @PU_Id  
     While @@FETCH_STATUS = 0  
          Begin  
          /* Find the next Production_Start record */  
          Select TOP 1 @Start_Time = Start_Time  
          From [dbo].Production_Starts  
          Where PU_Id = @PU_Id And Start_Time > @Product_Changes_Start  
          Order By Start_Time Asc  
   
          Update [dbo].Production_Starts  
          Set End_Time = @Start_Time  
          Where Start_Id = @Start_Id  
  
          Fetch Next From Starts Into @Start_Id, @PU_Id  
          End  
  
     Close Starts  
     Deallocate Starts  
  
     Alter Table [dbo].Production_Starts Enable Trigger All  
                                
     /****************************************************************************************************  
     *                                  Cleanup Downtime Events                                                         *  
     ****************************************************************************************************/  
     Select @Timed_Events_Range_Start = DateAdd(dd, -@Timed_Events_Limit, @TimeStamp)  
  
     /* Delete all associated tests */  
     Delete  
     From [dbo].Test_History  
     From [dbo].Test_History th  
          Inner Join [dbo].Tests t On t.Test_Id = th.Test_Id  
          Inner Join [dbo].Variables v On v.Var_Id = t.Var_Id  
     Where v.PU_Id = @PU_Id And v.Event_Type = 2 And t.Result_On < @Timed_Events_Range_Start  
  
     Delete  
     From [dbo].Tests  
     From [dbo].Tests t  
          Inner Join [dbo].Variables v On v.Var_Id = t.Var_Id  
     Where v.PU_Id = @PU_Id And v.Event_Type = 2 And Result_On < @Timed_Events_Range_Start  
  
     /* Delete all associated waste events and their comments */  
  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    Delete  
    From [dbo].Comments  
    From [dbo].Comments wtc  
    Inner Join [dbo].Waste_Event_Details wed On wed.Cause_Comment_Id = wtc.Comment_Id  
    Where wed.PU_Id = @PU_Id And wed.TimeStamp < @Events_Range_Start And Event_Id Is Not Null  
   END  
  ELSE  
      Delete  
      From [dbo].Waste_n_Timed_Comments  
      From [dbo].Waste_n_Timed_Comments wtc  
           Inner Join [dbo].Waste_Event_Details wed On wed.WED_Id = wtc.WTC_Source_Id And wtc.WTC_Type = 3  
      Where wed.PU_Id = @PU_Id And wed.TimeStamp < @Timed_Events_Range_Start And Event_Id Is Null  
  
     Delete  
     From [dbo].Waste_Event_Details  
     Where PU_Id = @PU_Id And TimeStamp < @Timed_Events_Range_Start And Event_Id Is Not Null  
  
     /* Delete all timed event details and their comments */  
  
    
  IF @AppVersion LIKE '4%'  
   BEGIN  
    Delete  
    From [dbo].Comments  
    From [dbo].Comments wtc  
     Inner Join [dbo].Timed_Event_Details ted On ted.Cause_Comment_Id = wtc.Comment_Id  
    Where ted.PU_Id = @PU_Id And ted.End_Time < @Timed_Events_Range_Start  
   END  
  ELSE  
      Delete  
      From [dbo].Waste_n_Timed_Comments  
      From [dbo].Waste_n_Timed_Comments wtc  
           Inner Join [dbo].Timed_Event_Details ted On ted.TEDet_Id = wtc.WTC_Source_Id And wtc.WTC_Type = 2  
      Where ted.PU_Id = @PU_Id And ted.End_Time < @Timed_Events_Range_Start  
  
     Delete  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @PU_Id And End_Time < @Timed_Events_Range_Start  
  
     /* Delete all timed event details and their comments */  
     Delete  
     From [dbo].Waste_n_Timed_Comments  
     From [dbo].Waste_n_Timed_Comments wtc  
          Inner Join [dbo].Timed_Event_Details ted On ted.TEDet_Id = wtc.WTC_Source_Id And wtc.WTC_Type = 2  
     Where ted.PU_Id = @PU_Id And ted.End_Time < @Timed_Events_Range_Start  
  
     Delete  
     From [dbo].Timed_Event_Summarys  
     Where PU_Id = @PU_Id And End_Time < @Timed_Events_Range_Start  
  
     Fetch Next From Units Into @PU_Id, @Events_Limit, @Timed_Events_Limit, @Product_Changes_Limit  
End  
  
Close Units  
Deallocate Units  
  
/****************************************************************************************************  
*                                       Cleanup Alarms                                              *  
****************************************************************************************************/  
Select @Alarms_Range_Start = DateAdd(dd, -@Alarms_Limit, @TimeStamp)  
  
Delete  
From [dbo].Alarms  
Where End_Time < @Alarms_Range_Start  
  
/* Comments? */  
  
/****************************************************************************************************  
*                               Cleanup Specs and Transactions                                      *  
****************************************************************************************************/  
Select @Specifications_Range_Start = DateAdd(dd, -@Specifications_Limit, @TimeStamp)  
  
Delete  
From [dbo].Active_Specs  
Where Expiration_Date < @Specifications_Range_Start And Expiration_Date Is Not Null  
  
Delete  
From [dbo].Var_Specs  
Where Expiration_Date < @Specifications_Range_Start And Expiration_Date Is Not Null  
  
  
/****************************************************************************************************  
*                                 Cleanup Client Connections                                        *  
****************************************************************************************************/  
Select @Clients_Log_Range_Start = DateAdd(dd, -@Clients_Log_Limit, @TimeStamp)  
  
Delete  
From [dbo].Client_Connection_Module_Data  
From [dbo].Client_Connection_Module_Data ccmd  
     Inner Join [dbo].Client_Connections cc On ccmd.Client_Connection_Id = cc.Client_Connection_Id  
Where End_Time < @Clients_Log_Range_Start Or (Last_Heartbeat < @Clients_Log_Range_Start And End_Time Is Null)  
  
Delete  
From [dbo].Client_Connection_App_Data  
From [dbo].Client_Connection_App_Data ccad  
     Inner Join [dbo].Client_Connections cc On ccad.Client_Connection_Id = cc.Client_Connection_Id  
Where End_Time < @Clients_Log_Range_Start Or (Last_Heartbeat < @Clients_Log_Range_Start And End_Time Is Null)  
  
Delete  
From [dbo].Client_Connections  
Where End_Time < @Clients_Log_Range_Start Or (Last_Heartbeat < @Clients_Log_Range_Start And End_Time Is Null)  
  
/****************************************************************************************************  
*                          Time-Based Entries (tests and sheet columns)                             *  
****************************************************************************************************/  
Select @Timed_Value_Range_Start = DateAdd(dd, -@Timed_Value_Limit, @TimeStamp)  
  
/* Delete all associated tests */  
Delete  
From [dbo].Test_History  
From [dbo].Test_History th  
     Inner Join [dbo].Tests t On t.Test_Id = th.Test_Id  
     Inner Join [dbo].Variables v On v.Var_Id = t.Var_Id  
Where v.Event_Type <> 1 And v.Event_Type <> 2 And t.Result_On < @Timed_Value_Range_Start  
  
Delete  
From [dbo].Tests  
From [dbo].Tests t  
     Inner Join [dbo].Variables v On v.Var_Id = t.Var_Id  
Where v.Event_Type <> 1 And v.Event_Type <> 2 And Result_On < @Timed_Value_Range_Start  
  
/* Delete data from sheet columns */  
Delete  
From [dbo].Sheet_Columns  
Where Result_On < @Timed_Value_Range_Start  
  
/****************************************************************************************************  
*                                              Comments                                             *  
****************************************************************************************************/  
Delete  
From [dbo].Comments  
Where ShouldDelete = 1  
  
/* Cleanup */  
SET NOCOUNT OFF  
  
  
  
  
  
  
  
  
  
  
  
  
  
