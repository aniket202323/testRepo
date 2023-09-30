  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_CreateClothingDowntimeEvent  
Author:   Matthew Wells (MSI)  
Date Created:  11/28/01  
  
Description:  
=========  
This procedure monitors yankee speed and crepe signals and creates clothing downtime events when the value of the signal changes falls  
below 1000 fpm.  The yankee speed and crepe values are used to calculate reel speed signals.  This is used instead of the raw reel speed signal   
b/c the reel speed signal can show a zero value during a sheetbreak.  
  
Change Date Who What  
=========== ==== =====  
11/28/01 MKW Created procedure.  
01/29/01 MKW Removed old Drop references to non-existent tables.  
*/  
  
CREATE procedure dbo.spLocal_CreateClothingDowntimeEvent  
@Success int OUTPUT,  
@ErrorMsg varchar(255) OUTPUT,  
@JumpToTime varchar(30) OUTPUT,  
@ECId int,  
@Reserved1 varchar(30),  
@Reserved2 varchar(30),  
@Reserved3 varchar(30),  
@ChangedTagNum int,  
@ChangedTagPrevValue varchar(30),  
@ChangedTagNewValue varchar(30),  
@ChangedTagPrevTime varchar(30),  
@ChangedTagNewTime varchar(30),  
@SpeedPrevValue varchar(30),  
@SpeedNewValue varchar(30),  
@SpeedPrevTime varchar(30),  
@SpeedNewTime varchar(30),  
@CrepePrevValue varchar(30),  
@CrepeNewValue varchar(30),  
@CrepePrevTime varchar(30),  
@CrepeNewTime varchar(30)  
As  
SET NOCOUNT ON  
  
DECLARE @DowntimeEvents TABLE(  
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
 Trans_Type  int Default 1,  
 Start_Time  datetime Null,  
 End_Time  datetime Null,  
 TEDet_Id   int Null,  
 PostDB  int Null,  
 TransNum  varchar(50) Null,  
 Action1  int Null,  
 Action2  int Null,  
 Action3  int Null,  
 Action4  int Null,  
 ActionCommentId int Null,  
 ResearchCommentId int Null,  
 ResearchStatusId int Null,  
 ResearchOpenDate datetime Null,  
 ResearchCloseDate datetime Null,  
 CommentId   int Null,  
 TargetProdRate  varchar(50) Null,  
 DimensionX1   float Null,  
 DimensionX2   float Null,  
 DimensionY1   float Null,  
 DimensionY2   float Null,  
 DimensionZ1   float Null,  
 DimensionZ2   float Null,  
 ResearchUserId  int Null,  
 RsnTreeDataId  int Null)  
  
Declare @Julian_Date  varchar(25),  
 @RL_Start_Date varchar(30),  
 @Prod_Start_Date datetime,  
 @Event_Count  int,  
 @Event_Num  varchar(25),  
 @Event_Id  int,   
 @New_Event_Id int,  
 @PU_Id  int,   
 @PL_Id   int,  
 @DT_PU_Id  int,  
 @DT_PU_Flag  varchar(25),  
 @DT_Start_Time datetime,   
 @DT_End_Time datetime,  
 @RL_Start_Time datetime,   
 @RL_End_Time  datetime,  
 @TEDet_Id  int,  
 @TimeStamp  datetime,  
 @Last_TimeStamp datetime,  
 @Last_Event_Id int,  
 @Speed  float,  
 @Speed_Target  float,  
 @Speed_Target_Flag varchar(25),  
 @Speed_Target_Name varchar(25),  
 @Speed_Target_Var_Id int,  
 @Last_Speed  float,  
 @Last_Speed_Target float,  
 @Result_On  datetime,  
 @Limit   float,  
 @Prod_Id  int,  
 @Prod_PU_Id  int,  
 @Prod_Start_Time datetime,  
 @Event_Status  int,  
 @Running_Status int,  
 @Complete_Status int,  
 @Default_Window int,  
 @Range_Start_Time datetime,  
 @Duplicate_Count int,  
 @Loop_Count  int,  
 @TESum_Id  int,  
 @AppVersion   varchar(30),  
 @User_id   int  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
If @ChangedTagPrevValue <> @ChangedTagNewValue  
     Begin  
/*  
Insert Into Local_TestRateLossEvent (ECId, Reserved1, Reserved2, Reserved3, ChangedTagNum,ChangedTagPrevValue, ChangedTagNewValue, ChangedTagPrevTime, ChangedTagNewTime, SpeedPrevValue, SpeedNewValue, SpeedPrevTime, SpeedNewTime, CrepePrevValue, CrepeNewV
alue, CrepePrevTime, CrepeNewTime, ReliabilityPrevValue, ReliabilityNewValue, ReliabilityPrevTime, ReliabilityNewTime)  
Values (@ECId, @Reserved1, @Reserved2, @Reserved3, @ChangedTagNum, @ChangedTagPrevValue, @ChangedTagNewValue, @ChangedTagPrevTime, @ChangedTagNewTime, @SpeedPrevValue, @SpeedNewValue, @SpeedPrevTime, @SpeedNewTime, @CrepePrevValue, @CrepeNewValue, @CrepeP
revTime, @CrepeNewTime, @ReliabilityPrevValue, @ReliabilityNewValue, @ReliabilityPrevTime, @ReliabilityNewTime)  
*/  
     /************************************************************************************************************************************************************************  
     *                                                                                         Initialization and Arguments                                                                                           *  
     ************************************************************************************************************************************************************************/  
    /* Initialization */  
     Select @Limit   = 1000,  
    @DT_PU_Flag  = '/Machine_Downtime_PU/',  
    @Speed_Target_Flag  = '/Target_Speed/',  
    @Speed_Target_Name = '%',  
    @Running_Status   = 4,  
    @Complete_Status   = 5,  
    @Event_Id    = Null,  
    @New_Event_Id   = 0,  
    @Default_Window   = 365,  
    @TEDet_Id   = Null,  
    @Duplicate_Count   = 1,  
    @Loop_Count   = 0,  
    @TimeStamp    = convert(datetime, rtrim(ltrim(@ChangedTagNewTime))),  
    @Range_Start_Time   = DateAdd(dd, -@Default_Window, @TimeStamp),  
    @Speed    = convert(float, rtrim(ltrim(@SpeedNewValue)))*(1+convert(float, rtrim(ltrim(@CrepeNewValue)))/100)  
  
     /************************************************************************************************************************************************************************  
     *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
     ************************************************************************************************************************************************************************/  
     Select TOP 1 @TESum_Id = TESum_Id  
     From [dbo].Timed_Event_Summarys  
     Where PU_Id = @PU_Id And Start_Time > @TimeStamp  
     Order By Start_Time Desc  
  
     If @TESum_Id Is Null  
          Begin  
          /************************************************************************************************************************************************************************  
          *                                                                                                         Get Inputs                                                                                                      *  
          ************************************************************************************************************************************************************************/  
          /* Get PU Id And PL_Id */  
          Select @PU_Id = PU_Id  
          From [dbo].Event_Configuration  
          Where EC_Id = @ECId  
  
          /************************************************************************************************************************************************************************  
          *                                                                                              Get current event data                                                                                              *  
          ************************************************************************************************************************************************************************/  
          Select @TEDet_Id = TEDet_Id  
          From [dbo].Timed_Event_Details  
          Where PU_Id = @PU_Id And Start_Time < @TimeStamp And End_Time Is Null  
            
          If Abs(@Speed) > @Limit And @TEDet_Id Is Not Null  
               Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Trans_Type)  
               Values(@PU_Id, @RL_Start_Date, @ChangedTagNewTime, 2)  
          /* Create new downtime event */  
          Else If @TEDet_Id Is Null  
               Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Trans_Type)  
               Values(@PU_Id, @TimeStamp, Null, 1)  
          End  
     Else  
          Begin  
          Select @JumpToTime = convert(varchar(30), Start_Time, 120)  
          From [dbo].Timed_Event_Summarys  
          Where TESum_Id = @TESum_Id  
          End  
     End  
  
  
If (Select count(*) From @DowntimeEvents) > 0  
 BEGIN  
    IF @AppVersion LIKE '4%'  
    BEGIN  
     SELECT 5,  
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
      Trans_Type,  
      Start_Time,  
      End_Time,  
      TEDET_Id,  
      PostDB,  
      TransNum,  
      Action1,  
      Action2,  
      Action3,  
      Action4,  
      ActionCommentId,  
      ResearchCommentId,  
      ResearchStatusId,  
      ResearchOpenDate,  
      ResearchCloseDate,  
      CommentId,  
      TargetProdRate,  
      DimensionX1,  
      DimensionX2,  
      DimensionY1,  
      DimensionY2,  
      DimensionZ1,  
      DimensionZ2,  
      ResearchUserId,  
      RsnTreeDataId  
     FROM @DowntimeEvents     
    END  
   ELSE  
    BEGIN  
     SELECT 5,  
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
      Trans_Type,  
      Start_Time,  
      End_Time,  
      TEDET_Id  
     FROM @DowntimeEvents      
    END  
 END  
  
/* Return Values */  
Select @Success = -1  
Select @ErrorMsg = NULL  
  
SET NOCOUNT OFF  
  
