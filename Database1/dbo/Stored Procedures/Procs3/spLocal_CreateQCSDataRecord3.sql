﻿  
  
  
/*  
Stored Procedure: spLocal_CreateQCSDataRecord2  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
This procedure monitors an accumulated QCS Weight value and when the value peaks (ie. the new data point is less than the previous  
data point) it creates a production event on the attached production unit and returns the maximum weight value to a defined variable.  The  
variable to which the weight it returned to is defined by putting the switch '\QCS Weight\' in the Extended Info field in the variable sheet.  The  
QCS weight variable must be under the same production unit as the event.  
  
This procedure is written for Model 603 and creates Production events.  As such, a Model 603 must be defined for the Production Event on the   
associated Production Unit.  The event model configuration in the Administrator must be as follows:  
Local spName = spLocal_CreateQCSDataRecord (this procedure)  
PI Tag #1 = QCS weight signal  
  
Change Date Who What  
=========== ==== =====  
08/27/01 MKW Created procedure.  
09/18/01 MKW Fixed date/string conversion problem.  
02/21/02 MKW Changed comparison type and WeightPrev->WeightNew to account for step model  
03/13/02 MKW Added check for profile type in the extended info field of the unit (must be either DATA_PROFILE=STEP or DATA_PROFILE=SAWTOOTH).  
   Fixed Julian date in the Event number.  
04/17/02 MKW Add push of QCS Turnover Weight to rolls.  
05/08/02 MKW Moved weight from Event record to Event_Details record.  
05/23/02 MKW Added weight conversion parameter.  
05/24/02 MKW Modified Event_Num format.  
   Modified Flag format  
06/27/02 MKW Added code to modify the transfer the QCS weight (use the alias variable link to the turnover QCS weight).  
*/  
  
CREATE procedure dbo.spLocal_CreateQCSDataRecord3  
@Success int OUTPUT,  
@ErrorMsg varchar(255) OUTPUT,  
@JumpToTime varchar(30) OUTPUT,  
@ECId int,  
@Reserved1 varchar(30),  
@Reserved2 varchar(30),  
@Reserved3 varchar(30),  
@ChangedTagNum int,  
@WeightPrevValue varchar(30),  
@WeightNewValue varchar(30),  
@WeightPrevTime varchar(30),  
@WeightNewTime varchar(30),  
@BatchTrgPrevValue varchar(30),  
@BatchTrgNewValue varchar(30),  
@BatchTrgPrevTime varchar(30),  
@BatchTrgNewTime varchar(30)  
AS  
  
Declare @WeightPrev    float,  
 @WeightNew    float,  
 @Weight   real,  
 @WeightTime   varchar(30),  
 @Weight_TimeStamp  datetime,  
 @Weight_Window  int,  
 @Weight_PU_Id  int,  
 @Weight_Event_Id  int,  
 @Weight_Conversion  real,  
 @Weight_Conversion_Str varchar(255),  
 @Start_Date   datetime,  
 @Julian_Date   varchar(25),  
 @Event_Num   varchar(25),  
 @Profile_Type   int,  -- 0 = Sawtooth / 1 = Step ; Default is Sawtooth so don't get blasted with data if specify the wrong type  
 @Turnover_TimeStamp  datetime,  
 @Turnover_TimeDelta  int,  
 @Turnover_Weight_Var_Id int,  
 @Turnover_PU_Id  int,  
 @Turnover_PU_Str  varchar(255),  
 @Turnover_Event_Id  int,  
 @Roll_PU_Id   int,  
 @Roll_TimeStamp  datetime,  
 @Roll_Weight_Var_Id  int,  
 @Closer_Events   int,  
 @Extended_Info  varchar(255),  
 @Flag_Start   int,  
 @Flag_Value   varchar(255),  
 @Roll_Var_Id   int,  
 @Roll_Weight_Precision  int,  
 @Roll_Event_Id   int,  
 @Roll_Var_Desc  varchar(25),  
 @Roll_Calculation_Id  int,  
 @Member_Var_Id  int,  
 @Calc_Input_Id   int,  
 @Event_Status   int,  
 @User_Id   int,  
 @Event_Count   int,  
 @Loop_Count   int,  
 @Duplicate_Count  int,  
 @Weight_Conversion_Flag varchar(25),  
 @Profile_Type_Flag  varchar(25),  
 @Turnover_PU_Flag  varchar(25),  
 @QCS_Weight_Flag  varchar(25),  
 @QCS_Weight_Var_Id  int,  
 @QCS_Weight_Precision int,  
 @Production_Event_Type_Id int  
  
If @WeightNewValue <> @WeightPrevValue And IsNumeric(@WeightNewValue) = 1 And IsNumeric(@WeightPrevValue) = 1  
     Begin  
     /* Convert Arguments */  
     Select @WeightPrev = convert(float, @WeightPrevValue)  
     Select @WeightNew = convert(float, @WeightNewValue)  
       
     /* Get PU Id */  
     Select @Weight_PU_Id = PU_Id  
     From Event_Configuration  
     Where EC_Id = @ECId  
  
     /* Initialization */  
     Select  @Profile_Type   = 0,  
  @Profile_Type_Flag  = 'DATAPROFILE=STEP',  
  @Weight_Conversion  = 1000.0,  
  @Weight_Conversion_Flag = 'WEIGHTCONVERSION=',  
  @Turnover_PU_Id  = Null,  
  @Turnover_PU_Flag  = 'TURNOVERUNIT=',  
  @QCS_Weight_Flag  = '/QCS_WEIGHT/',  
  @QCS_Weight_Var_Id  = Null,  
  @QCS_Weight_Precision = 0,  
  @Production_Event_Type_Id = 1  
  
     /************************************************************************************************************************************************************************  
     *                                                                                              Get Configuration Settings                                                                                        *  
     ************************************************************************************************************************************************************************/  
     /* Get Extended info field and parse out the schedule PU_Id */  
     Select @Extended_Info = upper(replace(Extended_Info, ' ', ''))+';'  
     From Prod_Units  
     Where PU_Id = @Weight_PU_Id  
  
     /* Get the profile type */  
     Select @Profile_Type = IsNull(CharIndex(@Profile_Type_Flag, upper(@Extended_Info)), 0)  
  
     /* Get the Weight Conversion */  
     Select @Flag_Start = charindex(@Weight_Conversion_Flag, @Extended_Info)+len(@Weight_Conversion_Flag)  
     Select @Flag_Value = substring(@Extended_Info, @Flag_Start, charindex(';', @Extended_Info, @Flag_Start) - @Flag_Start )  
  
     If isnumeric(@Flag_Value) = 1  
          Select @Weight_Conversion = convert(real, @Flag_Value)  
  
     /* Get the Turnover Unit */  
     Select @Flag_Start = charindex(@Turnover_PU_Flag, @Extended_Info)+len(@Turnover_PU_Flag)  
     Select @Flag_Value = substring(@Extended_Info, @Flag_Start, charindex(';', @Extended_Info, @Flag_Start) - @Flag_Start )  
  
     If isnumeric(@Flag_Value) = 1  
          Select @Turnover_PU_Id = convert(int, @Flag_Value)  
  
     Select @QCS_Weight_Var_Id  = Var_Id,  
 @QCS_Weight_Precision = Var_Precision  
     From Variables  
     Where PU_Id = @Turnover_PU_Id And upper(Extended_Info) = @QCS_Weight_Flag  
  
     /************************************************************************************************************************************************************************  
     *                                                                                                Evaluate Weight Change                                                                                       *  
     ************************************************************************************************************************************************************************/  
     If (@WeightNew <> @WeightPrev And @Profile_Type > 0) Or  
        (@WeightNew < @WeightPrev And @Profile_Type = 0)  
          Begin   
          /************************************************************************************************************************************************************************  
          *                                                                                          Initialize and Get Additional Data                                                                                  *  
          ************************************************************************************************************************************************************************/  
          /* Initialization */  
          Select  @Weight_Event_Id  = Null,  
  @Closer_Events   = 0,  
  @Weight_Window   = 5,  
  @Event_Status   = 5,    -- Complete  
  @User_Id   = 6,    -- EventMgr  
  @Event_Count   = 0,  
  @Loop_Count   = 0,  
  @Duplicate_Count  = 1  
  
  
          /* Get data by profile type */           
          If @Profile_Type = 0  
               Select @Weight = @WeightPrev/@Weight_Conversion,  
  @WeightTime = @WeightPrevTime  
          Else  
               Select  @Weight = @WeightNew/@Weight_Conversion,  
                @WeightTime  = @WeightNewTime  
  
          /* Convert More Arguments */  
          Select @Weight_TimeStamp  = convert(datetime, @WeightTime)  
  
          /************************************************************************************************************************************************************************  
          *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
          ************************************************************************************************************************************************************************/  
          Select TOP 1 @Weight_Event_Id = Event_Id  
          From Events  
          Where PU_Id = @Weight_PU_Id And TimeStamp >= @Weight_TimeStamp  
          Order By TimeStamp Desc  
  
          /* If no other events in the future (ie. this is the most recent event) then continue */  
          If @Weight_Event_Id Is Null  
               Begin  
               /************************************************************************************************************************************************************************  
               *                                                                                              Generate Event Num                                                                                                *  
               ************************************************************************************************************************************************************************/  
               /* Get Julian date and starting event increment*/  
               Select @Julian_Date = right(datename(yy, @Weight_TimeStamp),1)+right('000'+datename(dy, @Weight_TimeStamp), 3)  
  
               Select @Event_Count = round((convert(float, @Weight_TimeStamp)-floor(convert(float, @Weight_TimeStamp)))*86400, 0)  
  
               /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
               While @Duplicate_Count > 0 And @Loop_Count < 1000  
                    Begin  
                    Select @Event_Num =  @Julian_Date + right(convert(varchar(25),@Event_Count+1000000),5)  
  
                    Select @Duplicate_Count = count(Event_Id)   
                    From Events   
                    Where PU_Id = @Weight_PU_Id And Event_Num = @Event_Num  
  
                    Select @Event_Count = @Event_Count + 1  
                    Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                    End  
  
              /************************************************************************************************************************************************************************  
               *                                                                                     Create the QCS Data Record event                                                                                 *  
               ************************************************************************************************************************************************************************/  
               /* Hot insert event into Events */  
               Execute spServer_DBMgrUpdEvent  @Weight_Event_Id OUTPUT,   --1 @Event_Id  
      @Event_Num,     --2 @Event_Num  
      @Weight_PU_Id,    --3 @PU_Id  
      @WeightTime,     --4 @TimeStamp  
      Null,      --5 @Applied_Product  
      Null,      --6 @Source_Event  
      @Event_Status,    --7 @Event_Status  
      1,      --8 @Transaction_Type  
      0,      --9 @Transaction_Number  
      @User_Id,     --10 @User_Id  
      Null,      --11 @Comment_Id  
      Null,      --12 @Event_Subtype_Id  
      Null,      --13 @Testing_Status  
      Null,      --14 @Prop_Start_Time  
      Null,      --15 @Prop_Entry_On  
      1     --16 @Return_Result_Set  
  
               /* Update Dimension X field with the event with the QCS weight */  
--               Update Events  
--               Set Final_Dimension_X = @Weight  
--               Where Event_Id = @Weight_Event_Id  
  
               Exec spServer_DBMgrUpdEventDet @User_Id,    --1 @User_Id  
      @Weight_Event_Id,   --2 @Event_Id  
      @Weight_PU_Id,   --3 @PU_Id  
      @Event_Num,    --4 @Event_Num  
      1,     --5  @TransType,  
      0,     --6  @TransNum,  
      Null,     --7  @Alternate_Event_Num,  
      @Event_Status,    --8 @Event_Status  
      Null,     --9   @InitialDimX,  
      Null,     --10 @InitialDimY,  
      Null,     --11   @InitialDimZ,  
      Null,     --12  @InitialDimA,  
      @Weight,    --13  @FinalDimX,  
      Null,     --14  @FinalDimY,  
      Null,     --15  @FinalDimZ,  
      Null,     --16  @FinalDimA,  
      Null,     --17  @OrientationX,  
      Null,     --18  @OrientationY,  
      Null,     --19  @OrientationZ,  
      Null,     --20  @Prod_Id,  
      Null,     --21  @Applied_Prod_Id,  
      Null,     --22  @OrderId,  
      Null,     --23  @OrderLineId,  
      Null,     --24  @PPId,  
      Null,     --25  @PPPatternId,  
      Null,     --26  @ShipmentId,  
      Null,     --27  @CommentId,   
      Null,     --28  @EntryOn,  
      @WeightTime,    --29  @TimeStamp,  
      Null     --30  @EventType  
  
               /* Return Event result set to create event record */  
               Select 1, 1, 1, @Weight_Event_Id, @Event_Num, @Weight_PU_Id, @WeightTime, Null, Null, 5, 1, 1, 1  
  
               /************************************************************************************************************************************************************************  
               *                                                                                                 Return Value Into Variable                                                                                     *  
               ************************************************************************************************************************************************************************/  
               /* Return Test result set to create record for weight value */  
               Select 2,      -- Result_Set_Type  
  Var_Id,      -- Var_Id  
  @Weight_PU_Id,    -- PU_Id  
  6,      -- User_Id  
  0,      -- Canceled  
  ltrim(str(@Weight, 10, Var_Precision)),  -- Result  
  @WeightTime,     -- Result_On  
  1,      -- Transaction_Type  
  0      -- Post_Update  
               From Variables  
               Where PU_Id = @Weight_PU_Id And upper(Extended_Info) = @QCS_Weight_Flag  
  
              /************************************************************************************************************************************************************************  
               *                                                                         Push data to Turnover and any Rolls that came before                                                                *  
               ************************************************************************************************************************************************************************/  
               If @Turnover_PU_Id Is Not Null  
                    Begin  
                    /* Find the closest Turnover to this weight's timestamp */  
                    Select TOP 1 @Turnover_TimeStamp  = TimeStamp,  
     @Turnover_Event_Id  = Event_Id  
                    From Events  
                    Where PU_Id = @Turnover_PU_Id And TimeStamp < Dateadd(mi, @Weight_Window, @Weight_TimeStamp) And TimeStamp > Dateadd(mi, -1*@Weight_Window, @Weight_TimeStamp)  
                    Order By Abs(Datediff(s, @Weight_TimeStamp, TimeStamp)) Asc  
  
                    If @Turnover_Event_Id Is Not Null  
                         Begin  
                         /* Get new time delta so that can see if there is a closer weight record to the Turnover weight */  
                         Select @Turnover_TimeDelta = Abs(Datediff(s, @Weight_TimeStamp, @Turnover_TimeStamp))  
  
                         /* Find the closest QCS Weight to that Turnover's timestamp to verify that it is actually this one */  
                         If @Turnover_TimeDelta > 0  
                              Select @Closer_Events  = count(Event_Id)  
                              From Events  
                              Where PU_Id = @Weight_PU_Id  And TimeStamp > Dateadd(s, -1*@Turnover_TimeDelta, @Turnover_TimeStamp) And TimeStamp < Dateadd(s, @Turnover_TimeDelta, @Turnover_TimeStamp)  
  
                         If @Closer_Events = 0 And @QCS_Weight_Var_Id Is Not Null  
                              Begin  
                              /* Return result set for Turnover weight */  
                              Select 2,       -- Result_Set_Type  
    @QCS_Weight_Var_Id,     -- Var_Id  
    @Turnover_PU_Id,     -- PU_Id  
    6,       -- User_Id  
    0,       -- Canceled  
    ltrim(str(@Weight, 15, @QCS_Weight_Precision)),  -- Result  
    @Turnover_TimeStamp,     -- Result_On  
    1,       -- Transaction_Type  
    0       -- Post_Update   
                              /* Loop through rolls and return result sets for Roll Weights */  
                              Select 2, @Roll_Weight_Var_Id, e.PU_Id, 3, 0, ltrim(str(@Weight*ec.Dimension_A/100, 10, @Roll_Weight_Precision)), e.TimeStamp, 1, 0                               From Event_Components ec  
                                   Inner Join Events e On ec.Event_Id = e.Event_Id  
                              Where ec.Source_Event_Id = @Turnover_Event_Id  
  
                              Select 2,       -- Result_Set_Type  
    v.Var_Id,      -- Var_Id  
    v.PU_Id,      -- PU_Id  
    6,       -- User_Id  
    0,       -- Canceled  
    ltrim(str(@Weight*Dimension_A/100, 15, Var_Precision)), -- Result  
     e.TimeStamp,     -- Result_On              
    Case When t.Test_Id Is Null Then 1  
     Else 2  
     End,      -- Transaction_Type  
    0       -- Post_Update  
                              From Event_Components ec  
                                   Inner Join Events e On ec.Event_Id = e.Event_Id  
                                   Inner Join Variables v On e.PU_Id = v.PU_Id And Event_Type = @Production_Event_Type_Id  
                                   Inner Join Variable_Alias va On v.Var_Id = va.Dst_Var_Id And va.Src_Var_Id = @QCS_Weight_Var_Id  
                                   Left Join tests t On e.TimeStamp = t.Result_On And t.Var_Id = va.Dst_Var_Id --v.Var_Id  
                              Where ec.Source_Event_Id = @Turnover_Event_Id  
  
                              End  
                         End  
                    End  
               End  
          Else  
               Begin  
               Select @JumpToTime = convert(varchar(30), TimeStamp, 120)  
               From Events  
               Where Event_Id = @Weight_Event_Id  
               End      
         End  
     End  
  
/* Return Values */  
Select @Success = -1  
Select @ErrorMsg = NULL  
  
  
  
  
  
  
  
  
  
  
  
  