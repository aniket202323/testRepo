    /*  
Stored Procedure: spLocal_EndRateLossEventCVTG  
Author:   Barry Stewart (Stier Automation, LLC.)  
Date Created:  11/13/02  
  
Description:  
=========  
This procedure closes an open rate loss event when the last downtime event is due to a Parent Roll change  
  
Change Date Who What  
=========== ==== =====  
11/13/02 BAS Created procedure.  
01/21/03 BAS Moved End statement and REM'd out @Event_Status = 4  
01/23/03 BAS Subtracted 1 second from end time so that the last Historian value does not get evaluated.  
   Extended @PRC_Reason_Level1_Name and @PRC_Reason_Level2_Name length to 40  
01/28/03 BAS Changed 'Get Last downtime even't query to use TEDet_Id instead of Top 1  
01/30/03 BAS Removed DateAdd -1  
   REMd Get last open rate loss event time   
   Changed from @RL_Start_Time to @RL_Start_Time in Get last downtime event time and reasons query  
02/12/03 BAS Cleaned Up and removed fault code updates  
03/07/03 BAS Added hot insert  
04/22/03 MKW Changed to use Timed_Event_Details only  
04/23/03 MKW Added check to only execute if the reasons were changed manually  
04/24/03 MKW Disabled sp due to new requirements that end rate loss on every downtime event  
*/  
CREATE procedure dbo.spLocal_EndRateLossEventCVTG  
@Output_Value   varchar(25) OUTPUT,  
@TEDet_Id   int,  
@DT_PU_Id   int,  
@PU_Id   int,  
@PRC_Reason_Level1_Name varchar(40),  
@PRC_Reason_Level2_Name varchar(40)  
As  
  
Select   @Output_Value    = '0'  
Return  
  
Create Table #DowntimeEvents (  
 Result_Set_Type int Default 5,  
 PU_Id   int Null,  
 Source_PU_Id  int Null,  
 Status_Id  int Null,  
 Fault_Id   int Null,  
 Reason1  int Null,  
 Reason2  int Null,  
 Reason3  int Null,  
 Reason4  int Null,  
 Prod_Rate  int Null,  
 Duration  float Null,  
 Transaction_Type int Default 4,  -- Transaction Types (   1) Insert/Add;  (   2) Update;  (   3) Delete;   (   4) Complete --01/26/03 BAS Changed from 2 to 4  
 Start_Time  datetime Null,  
 End_Time  datetime Null,  
 TEDet_Id   int Null)  
  
Declare @Event_Num   varchar(25),  
 @Event_Id   int,   
 @DT_Start_Time  datetime,   
 @Start_Time   datetime,   
 @RL_TEDet_Id   int,  
 @RL_Event_Id   int,  
 @TimeStamp   datetime,  
 @Event_Status   int,  
 @Running_Status  int,  
 @Complete_Status  int,  
 @User_Id   int,   
 @Reason_Level1_Id  int,    
 @Reason_Level2_Id  int,    @Reason_Level1_Name  varchar(40),   
 @Reason_Level2_Name  varchar(40),  
 @Max_Window   datetime,  
 @DT_User_Id   int  
  
 /************************************************************************************************************************************************************************  
 *                                                                                         Initialization and Arguments                                                                                           *  
      ************************************************************************************************************************************************************************/  
     /* Initialization */  
      Select  @Running_Status   = 4,  
     @Complete_Status   = 5,  
     @RL_TEDet_Id   = Null,  
  @User_Id   = Null,  
  @Max_Window   = getdate () - 7,  
  @Output_Value    = '0'  
   
 /* Testing  
 Select @DT_PU_Id   = 864,  
  @PU_Id   = 1534,  
  @PRC_Reason_Level1_Name = 'UWS05 PRC',  
  @PRC_Reason_Level2_Name = 'Roll End - Double PRC'  
 */  
        /************************************************************************************************************************************************************************  
              *                                                                                              Get current event data                                                                                              *  
              ************************************************************************************************************************************************************************/  
 /* Get last downtime event time and reasons */  
 Select @DT_Start_Time  = Start_Time,  
  @Reason_Level1_Id = Reason_Level1,  
  @Reason_Level2_Id = Reason_Level2,  
  @DT_User_Id  = User_Id  
 From Timed_Event_Details  
 Where TEDet_Id = @TEDet_Id  
  
 /* Get last open Rate Loss Event */  
 Select TOP 1 @TEDet_Id  = TEDet_Id,  
   @Start_Time   = Start_Time  
 From Timed_Event_Details  
 Where PU_Id = @PU_Id  
 And Start_Time < @DT_Start_Time  
 And End_Time Is Null  
 Order By Start_Time Desc  
  
 /****************************** Close the event if last downtime event is a PR change *************************/    
           If @Reason_Level1_Id Is Not Null  
 And @Reason_Level2_Id Is Not Null  
 And @TEDet_Id Is Not Null  
 And @DT_User_Id > 50  
  Begin  
  /* Get downtime failure mode and failure mode cause */  
  Select  @Reason_Level1_Name = Event_Reason_Name  
       From Event_Reasons        Where Event_Reason_Id = @Reason_Level1_Id  
  
       Select  @Reason_Level2_Name = Event_Reason_Name  
       From Event_Reasons  
       Where Event_Reason_Id = @Reason_Level2_Id  
  
  /* Clean Arguments */  
  Select  @Reason_Level1_Name = LTrim(RTrim(@Reason_Level1_Name)),  
   @Reason_Level2_Name = LTrim(RTrim(@Reason_Level2_Name))   
  
                    /******************************Check if last downtime event is a parent roll change  *************************/  
                   If @Reason_Level1_Name = @PRC_Reason_Level1_Name  
  And @Reason_Level2_Name = @PRC_Reason_Level2_Name  
   Begin  
                                    /********************************************************************************************************************************************************************  
                                   *                                                                                      Close Open Rate Loss Event                                                              *  
                                    *********************************************************************************************************************************************************************/  
   -- Close open record  
                                        Exec spServer_DBMgrUpdTimedEvent @TEDet_Id OUTPUT, --@TEDet_Id  
        @PU_Id,  --@PU_Id  
        @PU_Id,  --@Source_PU_Id  
        @Start_Time,  --@Start_Time  
        @DT_Start_Time, --@End_Time  
        NULL,   --@TEStatus_Id  
        NULL,   --@TEFault_Id  
        NULL,   --@Reason_Level1  
        NULL,   --@Reason_Level2  
        NULL,   --@Reason_Level3  
        NULL,   --@Reason_Level4  
        NULL,   --@Future1  
        NULL,   --@Future2  
        4,   --@Transaction_Type  
        NULL,   --@TransNum  
        6,   --@UserId  
        NULL,   --@Action1  
        NULL,   --@Action2  
        NULL,   --@Action3  
        NULL,   --@Action4  
        NULL,   --@ActionCommentId  
        NULL,   --@ResearchCommentId  
        NULL,   --@ResearchStatusId  
        NULL,   --@CommentId  
        NULL,   --@DemX1  
        NULL,   --@DemX2  
        NULL,   --@DemY1  
        NULL,   --@DemY2  
        NULL,   --@DemZ1  
        NULL,   --@DemZ2  
        NULL,   --@TargetProdRate  
        NULL,   --@ResearchOpenDate  
        NULL,   --@ResearchCloseDate  
        NULL   --@ResearchUserId  
  
/* Normally we'd want to issue a transaction type of 4 but it generates nuisance errors in the DBMgr log file if we do  
   Insert Into #DowntimeEvents ( PU_Id,  
       Transaction_Type,  
       Start_Time,  
       End_Time)  
                           Values ( @PU_Id,  
    4,  
    @Start_Time,  
    @Timestamp)  
*/  
   Insert Into #DowntimeEvents ( TEDet_Id,  
       PU_Id,  
       Transaction_Type,  
       Start_Time,  
       End_Time,  
       Source_PU_Id,  
       Status_Id,  
       Fault_Id,  
       Reason1,  
       Reason2,  
       Reason3,  
       Reason4,  
  --     Prod_Rate,  
       Duration)  
                           Select TEDet_Id,  
    PU_Id,  
    2,  
    Start_Time,  
    @DT_Start_Time,  
    Source_PU_Id,  
    TEStatus_Id,  
    TEFault_Id,  
    Reason_Level1,  
    Reason_Level2,  
    Reason_Level3,  
    Reason_Level4,  
  --  Production_Rate,  
    Duration  
   From Timed_Event_Details  
                                        Where TEDet_Id = @TEDet_Id  
   End  
  
                      /* Return result sets */  
                      If (Select count(Result_Set_Type) From #DowntimeEvents) > 0  
    Begin  
    Select Result_Set_Type,  
     PU_Id,  
     Source_PU_Id,  
     Status_Id,  
     Fault_Id,  
     Reason1,  
     Reason2,  
     Reason3,  
     Reason4,  
     Prod_Rate,  
     Duration,  
     Transaction_Type,  
     Start_Time,  
     End_Time,  
     TEDet_Id  
    From #DowntimeEvents  
    End  
         
   Select @Output_Value = '1'  
  End  
  
/* Clean Up */  
Drop Table #DowntimeEvents  
  
