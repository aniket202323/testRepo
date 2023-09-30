  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_CreateBladeEvent  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
This procedure monitors a blade status signal and creates/updates Production events when the value of the signal changes.  The blade signal   
has to be a constant value indicating whether the blade is loaded or unloaded (ie. a value of 1 if the blade is loaded and a value of 0 when the   
blade is unloaded).  The values indicating whether the value is loaded or not are specified below in the Initialization section (Load_Value and Unload_Value).  
  
When the blade is loaded (blade status signal = load value) the procedure  
 - Creates a new Production event with an event status of 'Running'  
  
When the blade is unloaded (blade status signal = unload value) the procedure  
 - Sets the status of the current 'Running' Production event to 'Complete  
 - Updates the Unload Date and Unload Time variable values with the time the blade status signal changed  
  
The procedure checks to see if the machine is currently down and only allows one blade change when the machine is down.  If more than one blade  
load or unload is encountered when the machine is down, the procedure will ignore the extra load/unload signals and do nothing.  This is to prevent  
false blade changes from being created when work is being done to the blade system when the machine is down.  
  
This procedure is written for Model 603 and creates Production events.  As such, a Model 603 must be defined for the Production Event on the   
associated Production Unit.  The event model configuration in the Administrator must be as follows:  
Local spName = spLocal_CreateBladeEvent (this procedure)  
PI Tag #1 = Blade status signal  
  
The values of the Reserved Parameters are retrieved from the configuration table.  The last and current values of the Blade status signal are respectively  
passed to the stored procedure in the ChangedPrevValue and ChangedNewValue arguments.  The respective timestamps for the ChangedPrevValue and  
ChangedNewValue are passed to ChangePrevTime and ChangedNewTime.  
  
Change Date Who What  
=========== ==== =====  
08/27/01 MKW Created procedure.  
01/24/02 MKW Moved call to PU_Id  
03/13/02 MKW Fixed Julian Date  
01/16/04 MKW Added wildcards to Extended_Info search for Blade Unload Date/Time variables  
01/19/04 MKW Fixed issue with multiple blade changes per downtime  
*/  
  
CREATE procedure dbo.spLocal_CreateBladeEvent  
@Success   int OUTPUT,  
@ErrorMsg   varchar(255) OUTPUT,  
@JumpToTime   varchar(30) OUTPUT,  
@ECId    int,  
@Reserved1   varchar(30),  
@Reserved2   varchar(30),  
@Reserved3   varchar(30),  
@ChangedTagNum   int,  
@ChangedPrevValue  varchar(30),  
@ChangedNewValue  varchar(30),  
@ChangedPrevTime  varchar(30),  
@ChangedNewTime  varchar(30),  
@BladePrevValue  varchar(30),  
@BladeNewValue   varchar(30),  
@BladePrevTime   varchar(30),  
@BladeNewTime   varchar(30)  
AS  
SET NOCOUNT ON  
/* TESTING  
INSERT INTO Local_Model_Inputs (EC_Id,  
    ChangedTagNum,  
    ChangedTagNewValue,  
    ChangedTagPrevValue,  
    ChangedTagNewTime,  
    ChangedTagPrevTime,  
    Entry_On,  
    A,  
    B,  
    C,  
    D)  
VALUES (@ECId,  
 @ChangedTagNum,  
 @ChangedNewValue,  
 @ChangedPrevValue,  
 @ChangedNewTime,  
 @ChangedPrevTime,  
 getdate(),  
 @BladePrevValue,  
 @BladeNewValue,  
 @BladePrevTime,  
 @BladeNewTime)  
*/  
  
Declare @Blade_Start_Date  datetime,  
 @PU_Id    int,  
 @PL_Id   int,   
 @Prod_Start_Date datetime,   
 @Julian_Date   varchar(25),  
 @Event_Num   varchar(25),  
 @Event_Id   int,   
 @Event_Status  int,  
 @Event_Count   int,  
 @Loop_Count  int,  
 @Duplicate_Count int,  
 @DT_PU_Id   int,  
 @DT_Start_Time   datetime,   
 @DT_End_Time   datetime,  
 @Unload_Date_Var_Id  int,   
 @Unload_Date_Flag varchar(25),  
 @Unload_Date_Name varchar(25),  
 @Unload_Date  varchar(25),  
 @Unload_Time_Var_Id  int,  
 @Unload_Time_Flag varchar(25),  
 @Unload_Time_Name varchar(25),  
 @Unload_Time  varchar(25),  
 @TEDet_Id  int,  
 @TimeStamp   datetime,  
 @Running_Status  int,  
 @Complete_Status int,  
 @Current_Value  int,  
 @Load_Value  int,  -- Holds the value of blade change signal when the blade is loaded  
 @Unload_Value  int,  -- Holds the value of blade change signal when the blade is unloaded  
 @Default_Window  int,  
 @Range_Start_Time datetime,  
 @Event_Header_Flag varchar(25),  
 @Event_Header  varchar(25),  
 @Delay_Type_Flag varchar(25),  
 @Delay_Type_Value varchar(25),  
 @User_id   int  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
  
If @ChangedPrevValue <> @ChangedNewValue  
     Begin  
  
     /* Initialization */  
     Select @Running_Status   = 4,  
  @Complete_Status   = 5,  
  @Load_Value    = 1,  -- Value of blade change signal when the blade is loaded  
  @Unload_Value   = 0,  -- Value of blade change signal when the blade is unloaded  
  @Default_Window   = 365,  -- Default search window in days (speeds up queries)  
  @TEDet_Id   = Null,  
  @Unload_Date_Flag  = '%/Equipment_Unload_Date/%',  
  @Unload_Time_Flag  = '%/Equipment_Unload_Time/%',  
  @Unload_Date_Name  = '%',  
  @Unload_Time_Name  = '%',  
  @Event_Count   = 0,  
  @Loop_Count   = 0,  
  @Duplicate_Count  = 1,  
  @Event_Header_Flag  = 'EVENTHEADER=',  
  @Delay_Type_Flag  = 'DELAYTYPE=',  
  @Delay_Type_Value  = 'DOWNTIME'  
  
     /* Convert arguments */  
     Select @TimeStamp = convert(datetime, rtrim(ltrim(@ChangedNewTime))),  
    @Range_Start_Time = dateadd(dd, -@Default_Window, @TimeStamp)  
  
     /* Equipment change PU Id - MKW 01/24/02 - Moved up from below */  
     Select @PU_Id = PU_ID  
     From [dbo].Event_Configuration  
     Where EC_Id = @ECID  
  
     /************************************************************************************************************************************************************************  
     *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
     ************************************************************************************************************************************************************************/  
     Select TOP 1 @Event_Id = Event_Id  
     From [dbo].Events  
     Where PU_Id = @PU_Id And TimeStamp >= @TimeStamp  
     Order By TimeStamp Desc  
  
     If @Event_Id Is Null  
          Begin  
          /*************************************************************************************************************  
          *                                                  Get the Flags                                             *  
          *************************************************************************************************************/  
          SELECT @Event_Header = GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @Event_Header_Flag)  
          FROM [dbo].Prod_Units pu  
          WHERE pu.PU_Id = @PU_Id  
  
          /*************************************************************************************************************  
          *                                                 Get Inputs                                                 *  
          *************************************************************************************************************/  
          /* Unload Date/Time Variables - NOTE: The @Unload_Date_Name = '%' speeds up the query */  
          SELECT @Unload_Date_Var_Id = Var_Id  
          FROM [dbo].Variables  
          WHERE PU_Id = @PU_Id  
    AND Var_Desc LIKE @Unload_Date_Name  
    AND Extended_Info LIKE @Unload_Date_Flag  
  
          SELECT @Unload_Time_Var_Id = Var_Id  
          FROM [dbo].Variables  
          WHERE PU_Id = @PU_Id  
    AND Var_Desc LIKE @Unload_Time_Name  
    AND Extended_Info LIKE @Unload_Time_Flag  
  
          /* Downtime PU_Id  */  
          SELECT @PL_Id = PL_Id  
          FROM [dbo].Prod_Units  
          WHERE PU_Id = @PU_Id  
  
          SELECT @DT_PU_Id = pu.PU_Id  
          FROM [dbo].Prod_Units pu  
          WHERE pu.PL_Id = @PL_Id  
     AND GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, 'DelayType=') = 'Downtime'  
  
          /************************************************************************************************************************************************************************  
          *                                                                           Get Last Equipment Change Event and Downtime                                                                      *  
          ************************************************************************************************************************************************************************/  
          /* Get the start time of the current blade record */  
          SELECT TOP 1 @Blade_Start_Date = TimeStamp,  
        @Event_Id  = Event_Id,  
        @Event_Status  = Event_Status,  
        @Event_Num  = Event_Num  
          FROM [dbo].Events  
          WHERE PU_Id = @PU_Id  
     AND TimeStamp < @TimeStamp  
     AND TimeStamp >= @Range_Start_Time  
          ORDER BY TimeStamp DESC  
  
          /* Check to see if we're in a downtime */  
          SELECT @TEDet_Id = TEDet_Id,  
   @DT_Start_Time = Start_Time  
   --, @DT_End_Time = End_Time  
          FROM [dbo].Timed_Event_Details  
          WHERE PU_ID = @DT_PU_ID  
  AND Start_Time < @TimeStamp  
  AND (End_Time > @TimeStamp OR End_Time Is Null)  
  
          /************************************************************************************************************************************************************************  
          *                                                                                            Process Blade Change Events                                                                                   *  
          ************************************************************************************************************************************************************************/  
          If (@TEDet_Id Is Not Null And (@Blade_Start_Date < @DT_Start_Time Or @Blade_Start_Date Is Null)) Or @TEDet_Id Is Null  
               Begin  
               Select @Current_Value = convert(int, @ChangedNewValue)  
  
               /* Blade inserted on Machine and last blade is not still running  */  
               If @Current_Value = @Load_Value And (@Event_Status <> @Running_Status Or @Event_Status Is Null)  
                    Begin  
                    /* Get Julian date */  
                    Select @Julian_Date = right(datename(yy, @TimeStamp),1)+right('000'+datename(dy, @TimeStamp), 3)  
  
                    /* Get TimeStamp for the start of the current day and then calculate number of events in the current day*/  
                    Select @Prod_Start_Date = convert(datetime, floor(convert(float, @TimeStamp)))  
                    --Select @Prod_Start_Date = dateadd(hh, -datepart(hh, @TimeStamp), @TimeStamp)  
                    --Select @Prod_Start_Date = dateadd(mi, -datepart(mi, @TimeStamp), @Prod_Start_Date)  
                    --Select @Prod_Start_Date = dateadd(ss, -datepart(ss, @TimeStamp), @Prod_Start_Date)  
                    --Select @Prod_Start_Date = dateadd(ms, -datepart(ms, @TimeStamp), @Prod_Start_Date)  
  
                    Select @Event_Count = count(Event_Id)  
                    From [dbo].Events   
                    Where PU_Id = @PU_Id And TimeStamp >= @Prod_Start_Date And TimeStamp < dateadd(dd, 1, @Prod_Start_Date)  
  
                    /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
                    While @Duplicate_Count > 0 And @Loop_Count < 1000  
                         Begin  
                         Select @Event_Num = @Event_Header + right(convert(varchar(25),@Event_Count+1001),3) + @Julian_Date  
  
                         Select @Duplicate_Count = count(Event_Id)   
                         From [dbo].Events   
                         Where PU_Id = @PU_Id And Event_Num = @Event_Num  
  
                         Select @Event_Count = @Event_Count + 1  
                         Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                         End  
  
                    /* Generate Blade Change Event */  
                    Select 1, 1, 1, Null, @Event_Num, @PU_ID, convert(varchar(30), @TimeStamp, 120), Null, Null, @Running_Status, 0, @User_id, 0  
                    End  
               /* Blade is unloaded  */  
               Else If @Current_Value = @Unload_Value  
                    Begin  
                    If @Blade_Start_Date Is Not Null  
                         Begin  
                         /* Update the Unload variables with the unload date/time */  
                         Exec [dbo].spLocal_ConvertDate @Unload_Date OUTPUT, @TimeStamp, Null  
                         Exec [dbo].spLocal_ConvertTime @Unload_Time OUTPUT, @TimeStamp, Null  
                         Select 2, @Unload_Date_Var_ID, @PU_ID, @User_id, 0, @Unload_Date, convert(varchar(30), @Blade_Start_Date, 120), 2, 0  
                         Select 2, @Unload_Time_Var_ID, @PU_ID, @User_id, 0, @Unload_Time, convert(varchar(30), @Blade_Start_Date, 120), 2, 0  
  
                         /* Update event status */  
                         Select 1, 1, 2, Event_ID, Event_Num, PU_ID, convert(varchar(30), TimeStamp, 120), Null, Null, @Complete_Status, 0, @User_id, 0  
                         From [dbo].Events  
                         Where Event_Id = @Event_Id  
                         End  
                    End  
               End  
          End  
     Else  
          Begin  
          Select @JumpToTime = convert(varchar(30), TimeStamp, 120)  
          From [dbo].Events  
          Where Event_Id = @Event_Id  
          End  
     End  
  
Select @Success = -1  
Select @ErrorMsg = Null  
  
SET NOCOUNT OFF  
  
