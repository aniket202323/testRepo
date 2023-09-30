   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-09  
Version  : 1.0.5  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetRollStatusFromTurnoverQuality  
Author:   Matthew Wells (MSI)  
Date Created:  09/11/02  
  
Description:  
=========  
If one of the calculation dependent variables changes it tests the value against the Upper and Lower Reject limits to see   
if the value is out of spec.  If it is, it sets the status of the associated rolls events (determined through genealogy) to the passed reject status.    
  
If the event has already been set to that status previously then the stored procedure won't do anything.  This is to prevent  
the stored procedure from repeatedly resetting the status to 'Reject' if the status has been changed back to 'Good'.  As such,  
it will only change the status once.  
  
Change Date  Who  What  
=========== ==== =====  
08/11/01   MKW  Created procedure spLocal_SetStatusFromQuality  
01/30/02   MKW  Added code to allow for non-numeric tests.  
02/11/02   MKW  Changed the trigger type on the calculation definition to Variable (from Event) so had to change arguments to pass TimeStamp/PU_Id and not Event_Id  
      Added capability to reject off string tests (ie Pass/Fail)  
05/29/02   MKW  Modified so that if the value is changed back within limits then the status will be reset.  
09/11/02   MKW  Created procedure from spLocal_SetStatusFromQuality  
05/24/06   FGO  corrected the user code so the code will fire ir the Reliability System user is the user that last changed the event status  
       cleaned up the code  
*/  
  
CREATE   procedure [dbo].[spLocal_SetRollStatusFromTurnoverQuality]  
  
--declare  
@OutputValue   varchar(25) OUTPUT,  
@TimeStamp   datetime,  -- a : TimeStamp  
@VarId   int,   -- b : Triggering Variable Id  
@RejectStatusDesc  varchar(25),  -- c : Status to set event to  
@PUId   int,   -- d : Rolls PU  
@CalculationVarId  int   -- e : Attached Variable Id  
  
As  
SET NOCOUNT ON  
/*  
Select --@TimeStamp   = '2002-05-20 14:15:02',  
 @TimeStamp  = '2006-05-22 13:30:01',  
 @VarId   = 5279,  
 @Reject_Status_Desc = 'Hold',  
 @PU_Id   = 505,  
 @Calculation_Var_Id = 18965  
*/  
  
Declare @TurnoverEventId int,  
 @RollEventId  int,  
 @RollPUId  int,  
 @RollTimeStamp datetime,  
 @AppliedProduct int,  -- So we don't overwrite old values in result set  
 @SourceEvent  int,  -- So we don't overwrite old values in result set  
 @UserId  int,  -- So we don't overwrite old values in result set  
 @EventNum  varchar(50), -- So we don't overwrite old values in result set  
 @StatusId  int,  
 @RejectStatusId int,  
 @Value   float,  
 @URejectStr  varchar(25),  
 @LRejectStr  varchar(25),  
 @UReject  varchar(25),  
 @LReject  varchar(25),  
 @ProdId  int,  
 @Count   int,  
 @Fail   int,  
 @RejectCount  int,  
 @TestId  int,  
 @LastResult  varchar(25),  
 @LastFail  int,  
 @DataTypeId  int,  
 @ResultSetUserid   int,  
 @AppVersion   varchar(30),  
 @LastStatus   int  
   
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @ResultSetUserid = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
/* Initialize */  
Select @Count   = 0,  
 @RejectStatusId  = Null,  
 @Fail   = 0,  
 @TurnoverEventId = Null,  
 @RejectCount  = 0,  
 @LastResult  = Null,  
 @LastFail  = 0,  
 @OutputValue  = '0'  
  
DECLARE @EventRS TABLE(  
 NotUsed    varchar(10),  
 Transaction_Type  int,   
 Event_Id    int ,   
 Event_Num    Varchar(25),   
 PU_Id     int,   
 TimeStamp    datetime,   
 Applied_Product  int,   
 Source_Event   int,   
 Event_Status   int,   
 Confirmed    int,  
 User_Id     int,  
 PostUpdate    int Null,  
 Conformance   Varchar(25) Null,  
 TestPctComplete Varchar(25) Null,  
 Start_Time   DateTime Null,  
 TransNum    Varchar(25) Null,  
 TestingStatus  Varchar(25) Null,  
 CommentId   int Null,  
 EventSubTypeId  int Null,  
 EntryOn    DateTime Null,  
 ApprovedUserId  int Null,  
 SecondUserId  int Null,  
 ApprovedReasonId int Null,  
 UserReasonId  int Null,  
 UserSignOffId  int Null,  
 ExtendedInfo  Varchar(250) Null  
)  
  
/* Convert arguments */  
Select @RejectStatusId = ProdStatus_Id  
From [dbo].Production_Status  
Where ProdStatus_Desc = @RejectStatusDesc  
  
  
If @RejectStatusId Is Not Null   
     Begin  
     /* Get current product */  
     Select @ProdId = Prod_Id  
     From [dbo].Production_Starts  
     Where PU_Id = @PUId And Start_Time <= @TimeStamp And (End_Time > @TimeStamp Or End_Time Is Null)  
        
     /* Get data type */  
     Select @DataTypeId = Data_Type_Id  
     From [dbo].Variables  
     Where Var_Id = @VarId  
  
     /* Get variables limits */  
     Select  @UReject = nullif(ltrim(rtrim(U_Reject)), ''),  
  @LReject = nullif(ltrim(rtrim(L_Reject)), '')  
     From [dbo].Var_Specs  
     Where Var_Id = @VarId And Prod_Id = @ProdId And Effective_Date <= @TimeStamp And (Expiration_Date > @TimeStamp Or Expiration_Date Is Null)  
 If @UReject Is Not Null or @LReject Is Not Null  
            Begin  
            Select @TestId = Test_Id,  
    @Fail  = Case  
     When @DataTypeId = 1 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
     When @DataTypeId = 1 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
     When @DataTypeId = 2 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
     When @DataTypeId = 2 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
     When @DataTypeId = 6 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
     When @DataTypeId = 6 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
     When @DataTypeId = 7 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
     When @DataTypeId = 7 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
     When t.Result = @UReject Or t.Result = @LReject Then 1  
     Else 0  
    End  
             From [dbo].tests t  
             Where t.Var_Id = @VarId And t.Result_On = @TimeStamp  
  
          /* If passed, check to see if prior value was reject for status reset */  
          If @Fail = 0  
  If @UReject Is Not Null or @LReject Is Not Null  
   BEGIN  
                 Select TOP 1 @LastFail =  Case  
    When @DataTypeId = 1 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
    When @DataTypeId = 1 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
    When @DataTypeId = 2 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
    When @DataTypeId = 2 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
    When @DataTypeId = 6 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
    When @DataTypeId = 6 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
    When @DataTypeId = 7 And isnumeric(t.Result) = 1 And isnumeric(@UReject) = 1 And convert(real, t.Result) > convert(real, @UReject) Then 1  
    When @DataTypeId = 7 And isnumeric(t.Result) = 1 And isnumeric(@LReject) = 1 And convert(real, t.Result) < convert(real, @LReject) Then 1  
    When t.Result = @UReject Or t.Result = @LReject Then 1  
    Else 0  
    End  
                 From [dbo].Test_History t  
                 Where t.Test_Id = @TestId  
                 Order By t.Entry_On Desc  
   END  
          If @Fail = 1 Or @LastFail = 1  
               Begin  
               Select @TurnoverEventId = Event_Id  
               From [dbo].Events  
               Where PU_Id = @PUId And TimeStamp = @TimeStamp  
  
               /* Get Roll Information */  
               Declare Rolls Cursor Static For      
               Select e.Event_Status,   
        e.Event_Num,  
        e.Applied_Product,  
        e.Source_Event,  
        e.User_Id,  
        ec.Event_Id,  
        e.PU_Id,  
        e.TimeStamp  
               From [dbo].Event_Components ec  
                    Inner Join [dbo].Events e On ec.Event_Id = e.Event_Id  
               Where ec.Source_Event_Id = @TurnoverEventId  
               For Read Only  
               Open Rolls   
  
               Fetch Next From Rolls Into @StatusId, @EventNum, @AppliedProduct, @SourceEvent, @UserId, @RollEventId, @RollPUId, @RollTimeStamp  
               While @@FETCH_STATUS = 0  
                    Begin  
                    /* Check for modifications to the status by a user and if so don't do anything */  
     IF @Userid = @ResultSetUserid  
                         Begin  
                         If @StatusId <> @RejectStatusId And @Fail = 1  
                              Begin  
                              /* Set the roll status to 'Reject' */  
          INSERT INTO @EventRS (NotUsed,Transaction_Type,Event_Id,Event_Num, PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed,User_Id,PostUpdate)  
                              Select  1,    -- Order  
             2,    -- Transaction Type  
             @RollEventId,  -- Event Id  
             @EventNum,   -- Event Number  
             @RollPUId,   -- PU Id  
             @RollTimeStamp,  -- TimeStamp  
             @AppliedProduct,  -- Applied Product  
             @SourceEvent,  -- Source Event  
             @RejectStatusId,  -- Event Status  
             1,    -- Confirmed  
             @ResultSetUserid,    -- User Id  
             0    -- Post Update  
                              Select @OutputValue = convert(varchar(25), @VarId)  
                              End  
                         Else If @StatusId = @RejectStatusId And @LastFail = 1 And @Fail = 0  
                              Begin  
                              Select @RejectCount = sum( Case  
           When v.Data_Type_Id = 1 And isnumeric(t.Result) = 1 And isnumeric(vs.U_Reject) = 1 And convert(real, t.Result) > convert(real, vs.U_Reject) Then 1  
           When v.Data_Type_Id = 1 And isnumeric(t.Result) = 1 And isnumeric(vs.L_Reject) = 1 And convert(real, t.Result) < convert(real, vs.L_Reject) Then 1  
           When v.Data_Type_Id = 2 And isnumeric(t.Result) = 1 And isnumeric(vs.U_Reject) = 1 And convert(real, t.Result) > convert(real, vs.U_Reject) Then 1  
           When v.Data_Type_Id = 2 And isnumeric(t.Result) = 1 And isnumeric(vs.L_Reject) = 1 And convert(real, t.Result) < convert(real, vs.L_Reject) Then 1  
           When v.Data_Type_Id = 6 And isnumeric(t.Result) = 1 And isnumeric(vs.U_Reject) = 1 And convert(real, t.Result) > convert(real, vs.U_Reject) Then 1  
           When v.Data_Type_Id = 6 And isnumeric(t.Result) = 1 And isnumeric(vs.L_Reject) = 1 And convert(real, t.Result) < convert(real, vs.L_Reject) Then 1  
           When v.Data_Type_Id = 7 And isnumeric(t.Result) = 1 And isnumeric(vs.U_Reject) = 1 And convert(real, t.Result) > convert(real, vs.U_Reject) Then 1  
           When v.Data_Type_Id = 7 And isnumeric(t.Result) = 1 And isnumeric(vs.L_Reject) = 1 And convert(real, t.Result) < convert(real, vs.L_Reject) Then 1  
           When t.Result = vs.U_Reject Or t.Result = vs.L_Reject Then 1  
           Else 0  
           End)  
                              From [dbo].Calculation_Instance_Dependencies cid  
                                   Inner Join [dbo].tests t On cid.Var_Id = t.Var_Id And t.Result_On = @TimeStamp And t.Result Is Not Null  
                                   Inner Join [dbo].Variables v On t.Var_Id = v.Var_Id  
                                   Inner Join [dbo].Var_Specs vs On v.Var_Id = vs.Var_Id And vs.Prod_Id = @ProdId And vs.Effective_Date < @TimeStamp And (vs.Expiration_Date > @TimeStamp Or vs.Expiration_Date Is Null) And (vs.U_Reject Is Not Null Or vs.L_Reject Is Not Null)  
                              Where Result_Var_Id = @CalculationVarId  
  
                              If @RejectCount = 0  
                                   Begin  
                                   /* Reset the roll status to the default status */  
    select top 1 @lastStatus=event_status  
     from dbo.event_history eh  
      left join dbo.production_status ps on ps.prodstatus_id = eh.event_status  
      where event_id = @RollEventId  
     order by entry_on desc  
           INSERT INTO @EventRS (NotUsed,Transaction_Type,Event_Id,Event_Num, PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed,User_Id,PostUpdate)  
                                   Select  1,    -- Order  
               2,    -- Transaction Type  
               @RollEventId,  -- Event Id  
               @EventNum,   -- Event Number  
               @RollPUId,   -- PU Id  
               @RollTimeStamp,  -- TimeStamp  
               @AppliedProduct,  -- Applied Product  
               @SourceEvent,  -- Source Event  
               @LastStatus,  -- Event Status  
               1,    -- Confirmed  
               @ResultSetUserid,    -- User Id  
               0    -- Post Update  
                                   Select @OutputValue = convert(varchar(25), @VarId)  
                                   End  
                              End  
                         End  
                    Fetch Next From Rolls Into @StatusId, @EventNum, @AppliedProduct, @SourceEvent, @UserId, @RollEventId, @RollPUId, @RollTimeStamp  
                    End  
               Close Rolls  
               Deallocate Rolls  
               End  
          End   
     End  
  
IF @AppVersion LIKE '4%'  
 BEGIN  
  SELECT 1,NotUsed,Transaction_Type,Event_Id,Event_Num, PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed,User_Id,PostUpdate,Conformance,TestPctComplete,Start_Time,TransNum,TestingStatus,CommentId,EventSubTypeId,EntryOn,ApprovedUserId,SecondUserId,ApprovedReasonId,UserReasonId,UserSignOffId,ExtendedInfo  
  FROM @EventRS  
 END  
ELSE  
 BEGIN  
  SELECT 1,NotUsed,Transaction_Type,Event_Id,Event_Num, PU_Id,TimeStamp,Applied_Product,Source_Event,Event_Status,Confirmed,User_Id,PostUpdate  
  FROM @EventRS  
 END  
/*  
select @ureject,@LReject  
select @rejectcount, @fail,@lastFail,@StatusId,@RejectStatusId,@appversion, @Userid,@ResultSetUserid  
select @outputvalue   
*/  
SET NOCOUNT OFF  
  
