  
  
/*  
Stored Procedure: spLocal_CreateTurnoverEvent  
Author:   Matthew Wells (MSI)  
Date Created:  04/16/02  
  
Description:  
=========  
This procedure monitors a Turnover signal and creates Production events when the value transitions from a 0 to a 1.  
  
This procedure is written for Model 603 and creates Production events.  As such, a Model 603 must be defined for the Production Event on the   
associated Production Unit.  The event model configuration in the Administrator must be as follows:  
Local spName = spLocal_CreateTurnoverEvent (this procedure)  
PI Tag #1 = Turnover signal  
  
Change Date Who What  
=========== ==== =====  
04/16/02 MKW Created procedure.  
05/08/02 MKW Added EventMgr User_Id to CreateParentRollEvents call.  
05/21/02 MKW Added check for last 'complete' turnover so can fill out the start time and exclude false turnover's from the historian variable reads.  
06/27/02 MKW Added code to insert values for Teardown Weight directly so immediately available.  
*/  
  
CREATE procedure dbo.spLocal_CreateTurnoverEvent3  
@Success  int OUTPUT,  
@ErrorMsg  varchar(255) OUTPUT,  
@JumpToTime  varchar(30) OUTPUT,  
@ECId   int,  
@Reserved1  varchar(30),  
@Reserved2  varchar(30),  
@Reserved3  varchar(30),  
@ChangedTagNum int,  
@ChangedPrevValue varchar(30),  
@ChangedNewValue varchar(30),  
@ChangedPrevTime varchar(30),  
@ChangedNewTime varchar(30),  
@TurnoverPrevValue varchar(30),  
@TurnoverNewValue varchar(30),  
@TurnoverPrevTime varchar(30),  
@TurnoverNewTime varchar(30)  
As  
  
/*  
Select @ECId   = 12,  
 @ChangedPrevValue = 0,  
 @ChangedNewValue = 1,  
 @ChangedPrevTime = '2002-04-16 02:00:14',  
 @ChangedNewTime  = '2002-04-16 02:00:15'  
*/  
  
Declare @Turnover_PU_Id    int,  
 @Turnover_Event_Id   int,  
 @Roll_PU_Id    int,  
 @TID_Header    varchar(25),   
 @Prod_Start_Date   datetime,   
 @Julian_Date     varchar(25),  
 @Team_Desc    varchar(25),  
 @TID     varchar(25),  
 @Prod_Id    int,  
 @Event_Id     int,   
 @Event_Status    int,  
 @Event_Search_String   varchar(25),  
 @Event_Count     int,  
 @Loop_Count    int,  
 @Duplicate_Count   int,  
 @Turnover_TimeStamp    datetime,  
 @Turnover_TimeStamp_Str  varchar(30),  
 @Last_TimeStamp   datetime,  
 @Complete_Status_Id   int,  
 @Current_Value    int,  
 @Complete_Value   int,  
 @Running_Value   int,  
 @Default_Window   int,  
 @Range_Start_Time   datetime,  
 @Extended_Info   varchar(255),  
 @Schedule_PU_Str   varchar(25),  
 @Schedule_PU_Id   int,  
 @Flag_Start    int,  
 @Flag_Value    varchar(255),  
 @Roll_Var_Desc   varchar(25),  
 @Roll_Var_Id    int,  
 @Roll_Calculation_Id   int,  
 @ULID_Header    varchar(25),  
 @ULID_Reserved   varchar(25),  
 @PRID_Header    varchar(25),  
 @PRID_Var_Id    int,  
 @Downtime_PU_Id   int,  
 @Default_Status   varchar(25),  
 @Fire_Safety    varchar(25),  
 @False_Status    varchar(25),  
 @Member_Var_Id   int,  
 @Calc_Input_Id    int,  
 @Roll_Number    varchar(25),  
 @QCS_Weight    varchar(25),  
 @QCS_Weight_Flag   varchar(25),  
 @QCS_Weight_Var_Id   int,  
 @QCS_Weight_PU_Flag  varchar(25),  
 @QCS_Weight_PU_Id   int ,  
 @QCS_Weight_Event_Id  int,  
 @QCS_Weight_TimeStamp  datetime,  
 @QCS_Weight_TimeDelta  int,  
 @QCS_Weight_Window   int,  
 @QCS_Weight_Precision  int,  
 @QCS_Roll_Weight_Var_Id  int,  
 @Teardown_Weight   varchar(25),  
 @Teardown_Weight_Flag  varchar(25),  
 @Teardown_Weight_Var_Id  int,  
 @Teardown_Weight_Precision  int,  
 @AliasValues_Var_Id   int,  
 @AliasValuesByRatio_Var_Id  int,  
 @AliasValuesByPosition_Var_Id  int,  
 @Last_Turnover_TimeStamp  datetime,  
 @Schedule_PU_Flag   varchar(25),  
 @Closer_Events    int  
  
  
If convert(int, @ChangedPrevValue) = 0 And convert(int, @ChangedNewValue) = 1  
     Begin   
     /* Initialization */  
     Select @Complete_Status_Id  = 5,  
     @Complete_Value   = 1,  
     @Running_Value  = 0,   
     @Default_Window   = 365,  
     @Event_Count   = 0,  
     @Loop_Count   = 0,  
     @Duplicate_Count  = 1,  
     @Roll_Var_Desc  = 'Create Parent Roll Events',  
     @ULID_Header   = '004003709963',  
     @ULID_Reserved  = 0,  
     @PRID_Header   = 'XX',  
     @PRID_Var_Id   = 0,  
     @Downtime_PU_Id  = 0,  
     @Fire_Safety   = 48,  
     @False_Status   = 'False Turnover',  
     @Default_Status  = 'Good',  
     @QCS_Weight_Window  = 5,  
  @Flag_Value   = Null,  
  @Schedule_PU_Flag  = 'SCHEDULEUNIT=',  
  @Schedule_PU_Id  = Null,  
     @QCS_Weight_PU_Flag = 'QCSDATAUNIT=',  
  @QCS_Weight_PU_Id  = Null,  
  @QCS_Weight_Flag  = '/QCS_WEIGHT/',  
  @QCS_Weight_Var_Id  = Null,  
  @Teardown_Weight_Flag = '/TEARDOWN_WEIGHT/',  
  @Teardown_Weight_Var_Id = Null,  
  @Turnover_TimeStamp_Str = Null  
  
     /* Convert arguments */  
     Select @Turnover_TimeStamp = convert(datetime, rtrim(ltrim(@ChangedNewTime))),  
    @Range_Start_Time   = dateadd(dd, -@Default_Window, @Turnover_TimeStamp),  
    @Turnover_TimeStamp_Str = @ChangedNewTime   -- Need for spServer_CmnPutTestValue  
  
     /* Event PU Id - MKW 01/24/02 - Moved up from below */  
     Select @Turnover_PU_Id = PU_ID  
     From Event_Configuration  
     Where EC_Id = @ECID  
  
     /************************************************************************************************************************************************************************  
     *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
     ************************************************************************************************************************************************************************/  
     Select TOP 1 @Event_Id = Event_Id  
     From Events  
     Where PU_Id = @Turnover_PU_Id And TimeStamp >= @Turnover_TimeStamp  
     Order By TimeStamp Desc  
  
     If @Event_Id Is Null  
          Begin  
          /************************************************************************************************************************************************************************  
          *                                                                                                      Get the Flags                                                                                                    *  
          ************************************************************************************************************************************************************************/  
          /* Get Extended info field and parse out the schedule PU_Id */  
          Select @Extended_Info = upper(replace(Extended_Info, ' ', ''))+';'  
          From Prod_Units  
          Where PU_Id = @Turnover_PU_Id  
  
          Select @Flag_Start = charindex(@Schedule_PU_Flag, @Extended_Info)+len(@Schedule_PU_Flag)  
          Select @Flag_Value = substring(@Extended_Info, @Flag_Start, charindex(';', @Extended_Info, @Flag_Start) - @Flag_Start )  
  
          If isnumeric(@Flag_Value) = 1  
               Select @Schedule_PU_Id = convert(int, @Flag_Value)  
          Else  
               Select @Schedule_PU_Id = @Turnover_PU_Id  
            
          Select @Flag_Start = charindex(@QCS_Weight_PU_Flag, @Extended_Info)+len(@QCS_Weight_PU_Flag)  
          Select @Flag_Value = substring(@Extended_Info, @Flag_Start, charindex(';', @Extended_Info, @Flag_Start) - @Flag_Start )  
  
          If isnumeric(@Flag_Value) = 1  
               Select @QCS_Weight_PU_Id = convert(int, @Flag_Value)  
  
          /************************************************************************************************************************************************************************  
          *                                                                    Get Roll/Turnover Configuration Data (Need Machine for TID)                                                          *  
          ************************************************************************************************************************************************************************/  
          Select @Roll_Var_Id = Var_Id, @Roll_Calculation_Id = Calculation_Id  
          From Variables  
          Where PU_Id = @Turnover_PU_Id And Var_Desc = @Roll_Var_Desc  
  
          Select @Prod_Id = Prod_Id  
          From Production_Starts  
          Where PU_Id = @Turnover_PU_Id And Start_Time <= @Turnover_TimeStamp And (End_Time > @Turnover_TimeStamp Or End_Time Is Null)  
  
          /* Roll PU Id - Input 3 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 3  
  
          Select @Member_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id --Input_Name = 'Default Status'  
  
          Select @Roll_PU_Id = PU_Id  
          From Variables  
          Where Var_Id = @Member_Var_Id  
  
          /* Default Status - Input 4 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 4  
  
          Select @Default_Status = Default_Value  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id --Input_Name = 'Default Status'  
  
          /* ULID Header - Input 5 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 5  
  
          Select @Member_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id --Input_Name = 'ULID Header'  
  
          If @Member_Var_Id Is Not Null  
               Select @ULID_Header = Target  
               From Var_Specs  
               Where Var_Id = @Member_Var_Id And Prod_Id = @Prod_Id And Effective_Date < @Turnover_TimeStamp And (Expiration_Date > @Turnover_TimeStamp Or Expiration_Date Is Null)  
  
          /* ULID Reserved Count - Input 6 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 6  
  
          Select @Member_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'ULID S/N Reserved Count'  
  
          If @Member_Var_Id Is Not Null  
               Select @ULID_Reserved = Target  
               From Var_Specs  
               Where Var_Id = @Member_Var_Id And Prod_Id = @Prod_Id And Effective_Date < @Turnover_TimeStamp And (Expiration_Date > @Turnover_TimeStamp Or Expiration_Date Is Null)  
  
          /* PRID Header - Input 7 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 7  
  
          Select @Member_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'PRID Header'  
  
          If @Member_Var_Id Is Not Null  
               Select @PRID_Header = Target  
               From Var_Specs  
               Where Var_Id = @Member_Var_Id And Prod_Id = @Prod_Id And Effective_Date < @Turnover_TimeStamp And (Expiration_Date > @Turnover_TimeStamp Or Expiration_Date Is Null)  
  
          /* Fire Safety Limit - Input 8 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 8  
  
          Select @Fire_Safety = Default_Value  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'FIRE Roll Safety Limit (h)'  
  
          /* Downtime PU Id - Input 9 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 9  
  
          Select @Member_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'Downtime PU Id'  
  
          Select @Downtime_PU_Id = PU_Id  
          From Variables  
          Where Var_Id = @Member_Var_Id  
  
          /* PRID Var Id - Input 10 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 10  
  
          Select @PRID_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'PRID Var Id'  
  
          /* False Status - Input 11 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 11  
  
          Select @False_Status = Default_Value  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'PRID Var Id'  
  
          /* QCS Weight Var Id - Input 12 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 12   
          Select @QCS_Weight_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'QCS Weight PU Id'  
  
          Select @QCS_Weight_PU_Id = PU_Id  
          From Variables  
          Where Var_Id = @QCS_Weight_Var_Id  
  
          /* QCS Weight Var Id - Input 13 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 13  
  
          Select @QCS_Roll_Weight_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'QCS Roll Weight Var Id'  
  
          /* Calling User Id - Input 14 */  
          /* QCS Weight Var Id - Input 15 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 15  
  
          Select @AliasValues_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'QCS Roll Weight Var Id'  
  
          /* QCS Weight Var Id - Input 16 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 16  
  
          Select @AliasValuesByRatio_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'QCS Roll Weight Var Id'  
  
          /* QCS Weight Var Id - Input 17 */  
          Select @Calc_Input_Id = Calc_Input_Id  
          From Calculation_Inputs  
          Where Calculation_Id = @Roll_Calculation_Id And Calc_Input_Order = 17  
  
          Select @AliasValuesByPosition_Var_Id = Member_Var_Id  
          From Calculation_Input_Data  
          Where Result_Var_Id = @Roll_Var_Id And Calc_Input_Id = @Calc_Input_Id -- Input_Name = 'QCS Roll Weight Var Id'  
  
          /************************************************************************************************************************************************************************  
          *                                                                                                      Get the Crew                                                                                                    *  
          ************************************************************************************************************************************************************************/  
          /* Get Crew description */  
          Select @Team_Desc = Crew_Desc  
          From Crew_Schedule  
          Where Start_Time <= @Turnover_TimeStamp And End_Time > @Turnover_TimeStamp And PU_Id = @Schedule_PU_Id  
  
          /************************************************************************************************************************************************************************  
          *                                                                                           Generate Event Number                                                                                             *  
          ************************************************************************************************************************************************************************/  
          /* Get Julian date */  
          Select @Julian_Date = right(datename(yy, @Turnover_TimeStamp),1)+right('000'+datename(dy, @Turnover_TimeStamp), 3)  
  
          /* Get TimeStamp for the start of the current day and then calculate number of events in the current day*/  
          Select @Prod_Start_Date = convert(datetime, floor(convert(float, @Turnover_TimeStamp)))  
  
          /* Get last Turnover id */  
          Select @Event_Search_String = @PRID_Header + @Julian_Date + '%[0-9][0-9][0-9]'  
  
          Select @Event_Count = Coalesce(Max(substring(Event_Num, 8, 3)), 0)  
          From Events  
          Where PU_Id = @Turnover_PU_Id And Event_Num Like @Event_Search_String And TimeStamp > DateAdd(d, -1, @Prod_Start_Date)  
  
          /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
          While @Duplicate_Count > 0 And @Loop_Count < 1000   
               Begin  
               Select @TID = @PRID_Header + @Julian_Date + @Team_Desc + right(convert(varchar(25),@Event_Count+1001),3)  
  
               Select @Duplicate_Count = count(Event_Id)   
               From Events   
               Where PU_Id = @Turnover_PU_Id And Event_Num = @TID  
  
               Select @Event_Count = @Event_Count + 1  
               Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
               End  
  
          /************************************************************************************************************************************************************************  
          *                                                                                           Get Last Turnover Date/Time                                                                                      *  
          ************************************************************************************************************************************************************************/  
--          Select TOP 1 @Last_TimeStamp = TimeStamp  
--          From Events  
--          Where PU_Id = @Turnover_PU_Id And TimeStamp < @Turnover_TimeStamp And Event_Status = @Complete_Status_Id  
--          Order By TimeStamp Desc  
  
          /************************************************************************************************************************************************************************  
          *                                                                                                Create Turnover Event                                                                                           *  
          ************************************************************************************************************************************************************************/  
          /* Hot insert event into Events */  
          Execute spServer_DBMgrUpdEvent  @Turnover_Event_Id OUTPUT,   --1 @Event_Id  
      @TID,      --2 @Event_Num  
      @Turnover_PU_Id,    --3 @PU_Id  
      @Turnover_TimeStamp,     --4 @Turnover_TimeStamp  
      Null,      --5 @Applied_Product  
      Null,      --6 @Source_Event  
      @Complete_Status_Id,    --7 @Event_Status  
      1,      --8 @Transaction_Type  
      0,     --9 @Transaction_Number  
      6,      --10 @User_Id  
      Null,      --11 @Comment_Id  
      Null,      --12 @Event_Subtype_Id  
      Null,      --13 @Testing_Status  
      Null,      --14 @Prop_Start_Time  
      Null,      --15 @Prop_Entry_On  
      1     --16 @Return_Result_Set  
  
          If @Turnover_Event_Id Is Not Null  
               Begin  
               /* Issue Turnover Event */   
               Select  1,       -- @Result_Set_Type  
  1,       -- @Id  
  1,       -- @Transaction_Type  
  @Turnover_Event_Id,     -- @Event_Id  
  @TID,       -- @Event_Num  
  @Turnover_PU_Id,     -- @PU_Id  
  convert(varchar(30), @Turnover_TimeStamp, 120), -- @TimeStamp  
  Null,       -- @Applied_Product  
  Null,       -- @Source_Event  
  @Complete_Status_Id,     -- @Event_Status  
  0,       -- @Confirmed  
  6,       -- @User_Id  
  1       -- @Post_Update  
  
               /************************************************************************************************************************************************************************  
               *                                                                                              Get the Weight Variables                                                                                          *  
               ************************************************************************************************************************************************************************/  
               Select @QCS_Weight_Var_Id   = Var_Id,  
  @QCS_Weight_Precision = Var_Precision  
               From Variables  
               Where PU_Id = @Turnover_PU_Id And Extended_Info = @QCS_Weight_Flag  
  
               Select @Teardown_Weight_Var_Id  = Var_Id,  
  @Teardown_Weight_Precision = Var_Precision  
               From Variables  
               Where PU_Id = @Turnover_PU_Id And Extended_Info = @Teardown_Weight_Flag  
  
               /************************************************************************************************************************************************************************  
               *                                                                                           Get the QCS Turnover Weight                                                                                    *  
               ************************************************************************************************************************************************************************/  
               /* Get closest QCS Turnover weight */  
               Select TOP 1 @QCS_Weight_Event_Id = Event_Id,  
    @QCS_Weight_TimeStamp = TimeStamp  
               From Events  
               Where PU_Id = @QCS_Weight_PU_Id And   
                           TimeStamp < Dateadd(mi, @QCS_Weight_Window, @Turnover_TimeStamp) And TimeStamp > Dateadd(mi, -1*@QCS_Weight_Window, @Turnover_TimeStamp)  
               Order By Abs(Datediff(s, @Turnover_TimeStamp, TimeStamp))  
  
               If @QCS_Weight_TimeStamp Is Not Null  
                    Begin  
                    /* Get new time delta so that can see if there is a closer Turnover record to the QCS weight and then  
                        find the closest Turnover to that Weight's timestamp to verify that it is actually this one */  
                    Select @Closer_Events = 0  
                    Select @QCS_Weight_TimeDelta = Abs(Datediff(s, @QCS_Weight_TimeStamp, @Turnover_TimeStamp))  
  
                    If @QCS_Weight_TimeDelta > 0  
                         Select @Closer_Events  = count(Event_Id)  
                         From Events  
                         Where PU_Id = @Turnover_PU_Id  And   
                                    TimeStamp > Dateadd(s, -1*@QCS_Weight_TimeDelta, @QCS_Weight_TimeStamp) And TimeStamp < Dateadd(s, @QCS_Weight_TimeDelta, @QCS_Weight_TimeStamp)  
  
                    /* Get the roll weight from Event_Details */  
                    If @Closer_Events = 0  
                         Begin  
                         Select @QCS_Weight = ltrim(str(Final_Dimension_X, 15, @QCS_Weight_Precision))  
                         From Event_Details  
                         Where Event_Id = @QCS_Weight_Event_Id  
  
                         /* Insert weight value record */  
                         Exec spServer_CmnPutTestValue @QCS_Weight_Var_Id,   -- @Var_Id  
      @Turnover_TimeStamp_Str,  -- @TimeStamp  
      @QCS_Weight,    -- @Result  
      6,     -- @User_Id  
      Null,     -- @Array_Id  
      Null,     -- @Test_Id  
      Null,      -- @Entry_Year  
      Null,      -- @Entry_Month  
      Null,      -- @Entry_Day  
      Null,      -- @Entry_Hour  
      Null,      -- @Entry_Minute  
      Null     -- @Entry_Second  
  
                         /* Return test results for any other rolls associated with this turnover */  
                         Select 2,       -- Result_Set_Type  
   @QCS_Weight_Var_Id,     -- Var_Id  
   @Turnover_PU_Id,     -- PU_Id  
   6,       -- User_Id  
   0,       -- Canceled  
   @QCS_Weight,      -- Result  
   @Turnover_TimeStamp_Str,    -- Result_On              
   1,       -- Transaction_Type  
   1       -- Post_Update  
  
                         End  
                    End  
  
               /************************************************************************************************************************************************************************  
               *                                                                                           Get the Teardown Weight                                                                                           *  
               ************************************************************************************************************************************************************************/  
               Select @Prod_Id = Prod_Id  
               From Production_Starts  
               Where PU_Id = @Turnover_PU_Id And Start_Time <= @Turnover_TimeStamp And (End_Time > @Turnover_TimeStamp Or End_Time Is Null)  
  
               Select @Teardown_Weight = Target  
               From Var_Specs  
               Where Var_Id = @Teardown_Weight_Var_Id And Prod_Id = @Prod_Id And Effective_Date <= @Turnover_TimeStamp And (Expiration_Date > @Turnover_TimeStamp Or Expiration_Date Is Null)  
  
               If @Teardown_Weight Is Not Null  
                    Begin  
                    Exec spServer_CmnPutTestValue @Teardown_Weight_Var_Id,  -- @Var_Id  
      @Turnover_TimeStamp_Str,  -- @TimeStamp  
      @Teardown_Weight,   -- @Result  
      6,     -- @User_Id  
      Null,     -- @Array_Id  
      Null,     -- @Test_Id  
      Null,      -- @Entry_Year  
      Null,      -- @Entry_Month  
      Null,      -- @Entry_Day  
      Null,      -- @Entry_Hour  
      Null,      -- @Entry_Minute  
      Null     -- @Entry_Second  
  
                    /* Return test results for any other rolls associated with this turnover */  
                    Select 2,       -- Result_Set_Type  
   @Teardown_Weight_Var_Id,    -- Var_Id  
   @Turnover_PU_Id,     -- PU_Id  
   6,       -- User_Id  
   0,       -- Canceled  
   @Teardown_Weight,     -- Result  
   @Turnover_TimeStamp_Str,    -- Result_On              
   1,       -- Transaction_Type  
   1       -- Post_Update  
                    End  
  
               /************************************************************************************************************************************************************************  
               *                                                                                                Create Roll Event                                                                                                   *  
               ************************************************************************************************************************************************************************/    
               Exec spLocal_CreateParentRollEvents3 @Roll_Number OUTPUT,  
      @Turnover_Event_Id,  
      @Roll_Var_Id,  
      @Roll_PU_Id,  
      @Default_Status,  
      @ULID_Header,  
      @ULID_Reserved,  
      @PRID_Header,  
      @Fire_Safety,  
      @Downtime_PU_Id,  
      @PRID_Var_Id,  
      @False_Status,  
      @QCS_Weight_PU_Id,  
      @QCS_Roll_Weight_Var_Id,  
      6,    -- EventMgr User_Id  
      @AliasValues_Var_Id,  
      @AliasValuesByRatio_Var_Id,  
      @AliasValuesByPosition_Var_Id  
  
               End  
          End  
     Else  
          Select @JumpToTime = convert(varchar(30), TimeStamp, 120)  
          From Events  
          Where Event_Id = @Event_Id  
     End  
  
Select @Success = -1  
Select @ErrorMsg = Null  
  
  
  
  
