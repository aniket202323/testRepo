   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_CreateRollWasteConverting  
@OutputValue    varchar(25) OUTPUT,  
@Var_Id    int,  --a  
@Event_Id    int,  --b  
@End_Time    varchar(25), --c  
@PU_Id    int,  --d  
@Reject_Status_Desc  varchar(25), --e  
@Reject_Weight_Var_Id  int,  --r  
@Reject_WET_Name   varchar(25), --f  
@Reject_Reason_Name  varchar(25), --i  
@Reject_Weight_Factor_Str varchar(25), --l  
@Reject_WEMT_Name  varchar(25), --o  
@Slab_Weight_Var_Id  int,  --s  
@Slab_WET_Name   varchar(25), --g  
@Slab_Reason_Name   varchar(25), --j  
@Slab_Weight_Factor_Str varchar(25), --m  
@Slab_WEMT_Name  varchar(25), --p  
@Teardown_Weight_Var_Id int,  --t  
@Teardown_WET_Name  varchar(25), --h  
@Teardown_Reason_Name varchar(25), --k  
@Teardown_Weight_Factor_Str varchar(25), --n  
@Teardown_WEMT_Name varchar(25) --q  
As  
  
/*  
Insert Into Local_Test (int1, int2, int3)  
Values (@Reject_Weight_Var_Id, @Slab_Weight_Var_Id, @Teardown_Weight_Var_Id)  
*/  
  
SET NOCOUNT ON  
  
Declare @Trans_Type   int,  
   @Reject_Weight    float,  
   @Slab_Weight    float,  
   @Teardown_Weight   float,  
   @EventStatus    int,  
   @Amount    float,  
   @WED_Id    int,  
 @WET_Id   int,  
   @Teardown_Wed_id   int,  
 @Reject_Status_Id  int,  
 @Reject_WET_Id  int,  
 @Slab_WET_Id   int,  
 @Teardown_WET_Id  int,  
 @Reject_Reason_Id  int,  
 @Slab_Reason_Id  int,  
 @Teardown_Reason_Id  int,  
 @Reject_Weight_Factor  float,  
 @Slab_Weight_Factor  float,  
 @Teardown_Weight_Factor float,  
 @Reject_WEMT_Id  int,  
 @Slab_WEMT_Id  int,  
 @Teardown_WEMT_Id  int,  
 @User_id     int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
/* Result Set Type (9) */  
Declare @WasteResultSet Table(  
 Pre   int, -- pre/post update 0  
 TransNum   int, -- always 0  
 UserId    int, -- user 6  
 TransType  int, -- 1 add 2 up 3 del  
 WasteEventId   int Null,   
 PUId    int,  
 SourcePUId   int, ---PU_Id  
 TypeId    int Null,  --- slab =1  tear = 3 Roll = 6  
 MeasId   int Null, ---1(slab,tear) 3(Rolls)  
 Reason1  int Null,  
 Reason2  int Null,  
 Reason3  int Null,  
 Reason4  int Null,  
 EventId   int,  
 Amount   float,  
 Marker1   float Null,    
 Marker2   float Null,  
 TimeStamp  varchar(25),  
 Action1   int Null,  
 Action2   int Null,  
 Action3    int Null,  
 Action4   int Null,  
 ActionCommentId int Null,  
 ResearchCommentId int Null,  
 ResearchStatusId int Null,  
 ResearchOpenDate varchar(25) Null,  
 ResearchCloseDate varchar(25) Null,  
 CommentId  int Null,  
 TargetProdRate  float Null,  
 ResearchUserId  int Null)  
  
/* Initialization */  
Select @Trans_Type  = 1,  
  @Reject_Status_Id = Null,  
 @Reject_WET_Id = Null,  
 @Slab_WET_Id  = Null,  
 @Teardown_WET_Id = Null,  
 @Reject_Reason_Id = Null,  
 @Slab_Reason_Id = Null,  
 @Teardown_Reason_Id = Null,  
 @Amount   = Null,  
 @WED_Id  = Null,  
 @WET_Id  = Null,  
 @Teardown_WED_Id = Null,  
 @Teardown_Weight = Null,  
 @Slab_Weight  = Null,  
 @Reject_Weight  = Null  
  
/* Convert factors */  
If IsNumeric(@Reject_Weight_Factor_Str) = 1  
 Select @Reject_Weight_Factor = convert(float, @Reject_Weight_Factor_Str)  
Else  
 Select @Reject_Weight_Factor = 1.0  
If IsNumeric(@Slab_Weight_Factor_Str) = 1  
 Select @Slab_Weight_Factor = convert(float, @Slab_Weight_Factor_Str)  
Else  
 Select @Slab_Weight_Factor = 1.0  
If IsNumeric(@Teardown_Weight_Factor_Str) = 1  
 Select @Teardown_Weight_Factor = convert(float, @Teardown_Weight_Factor_Str)  
Else  
 Select @Teardown_Weight_Factor = 1.0  
  
  
/* Get Status, Type, Reason and Measure Ids */  
Select @Reject_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = LTrim(RTrim(@Reject_Status_Desc))  
Select @Reject_WET_Id = WET_Id From [dbo].Waste_Event_Type Where WET_Name = LTrim(RTrim(@Reject_WET_Name))  
Select @Slab_WET_Id = WET_Id From [dbo].Waste_Event_Type Where WET_Name = LTrim(RTrim(@Slab_WET_Name))  
Select @Teardown_WET_Id = WET_Id From [dbo].Waste_Event_Type Where WET_Name = LTrim(RTrim(@Teardown_WET_Name))  
Select @Reject_Reason_Id = Event_Reason_Id From [dbo].Event_Reasons Where Event_Reason_Name = LTrim(RTrim(@Reject_Reason_Name))  
Select @Slab_Reason_Id = Event_Reason_Id From [dbo].Event_Reasons Where Event_Reason_Name = LTrim(RTrim(@Slab_Reason_Name))  
Select @Teardown_Reason_Id = Event_Reason_Id From [dbo].Event_Reasons Where Event_Reason_Name = LTrim(RTrim(@Teardown_Reason_Name))  
Select @Reject_WEMT_Id = WEMT_Id From [dbo].Waste_Event_Meas Where WEMT_Name = LTrim(RTrim(@Reject_WEMT_Name))  
Select @Slab_WEMT_Id = WEMT_Id From [dbo].Waste_Event_Meas Where WEMT_Name = LTrim(RTrim(@Slab_WEMT_Name))  
Select @Teardown_WEMT_Id = WEMT_Id From [dbo].Waste_Event_Meas Where WEMT_Name = LTrim(RTrim(@Teardown_WEMT_Name))  
  
/* Get the event status */  
Select @EventStatus = Event_Status   
From [dbo].Events   
Where Event_Id  = @Event_Id  
  
/* Get the depend variable And var_id */  
/*  
Select @Reject_Weight_Var_Id = d.Var_Id From calculation_instance_dependencies d   
  inner join variables v on(d.var_id = v.var_id)   
  Where d.Result_Var_Id = @var_id And v.Extended_info = 'Waste RollStatus'  
Select @Slab_Weight_Var_Id = d.Var_Id From calculation_instance_dependencies d   
  inner join variables v on(d.var_id = v.var_id)   
  Where d.Result_Var_Id = @var_id And v.Extended_info = 'Waste Slab'  
Select @Teardown_Weight_Var_Id = d.Var_Id From calculation_instance_dependencies d   
  inner join variables v on(d.var_id = v.var_id)   
  Where d.Result_Var_Id = @var_id And v.Extended_info ='Waste TearDown'  
*/  
  
-- Get values  
Select @Reject_Weight = convert(float,Result) * convert(float, @Reject_Weight_Factor) From [dbo].tests Where Result_On = @End_Time And Var_id = @Reject_Weight_Var_Id  
Select @Slab_Weight = convert(float,Result) * convert(float, @Slab_Weight_Factor) From [dbo].tests Where Result_On = @End_Time And Var_id = @Slab_Weight_Var_Id  
Select @Teardown_Weight = convert(float,Result) * convert(float, @Teardown_Weight_Factor) From [dbo].tests Where Result_on = @End_Time And Var_id = @Teardown_Weight_Var_Id  
If @Teardown_Weight Is Null   
 Select @Teardown_Weight = 0.0  
  
/* Check for Rejected rolls that have been Reaccepted And, if so, delete waste entry */  
/*  
Select @Amount = Amount, @WED_Id = WED_Id  
From Waste_Event_Details   
Where Timestamp = @End_Time And WET_Id = @Reject_WET_Id And PU_Id = @PU_Id  
  
If (@EventStatus <> @Reject_Status_Id And @Amount Is Not Null)  
Begin  
 Insert Into #WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
  Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
  Action1,Action2,Action3,Action4,ActionCommentId,  
  ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,TargetProdRate,ResearchUserId)  
 Values(1,0,6,3,@WED_Id,@PU_Id,@PU_Id,@Reject_WET_Id,Null,Null,Null,Null,Null,@Event_id,@Reject_Weight,Null,Null,@End_Time,Null,  
  Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null)  
End  
*/  
  
/* Reinitialization */  
Select @Amount  = Null,  
 @WED_Id = Null,  
 @WET_Id = Null  
  
Select @Amount = Amount, @WED_Id = WED_Id, @WET_Id = WET_Id  
From [dbo].Waste_Event_Details   
Where Timestamp = @End_Time And PU_Id = @PU_Id  
  
-- If it's reject  
If (@EventStatus = @Reject_Status_Id And @Reject_Weight > 0 And @Reject_Weight Is Not Null)  
Begin  
 If (@WED_Id Is Null)    -- Must create new Reject Waste record  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,TargetProdRate,ResearchUserId)  
  Values(1,0,@User_id,1,Null,@PU_Id,@PU_Id,@Reject_WET_Id,@Reject_WEMT_Id,@Reject_Reason_Id,Null,Null,Null,@Event_id,@Reject_Weight,Null,Null,@End_Time,Null,  
   Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null)  
 End  
 Else If (@WET_Id <> @Reject_WET_Id )  -- Convert existing record to Reject Waste  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,--TargetProdRate,
ResearchUserId)  
  Values(1,0,@User_id,2,@WED_Id,@PU_Id,@PU_Id,@Reject_WET_Id,@Reject_WEMT_Id,@Reject_Reason_Id,Null,Null,Null,@Event_id,@Reject_Weight,Null,Null,@End_Time,Null,  
   Null,Null,Null,Null,Null,Null,Null,Null,Null,--Null,
Null)  
 End  
 Else If (@Amount <> @Reject_Weight )  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,--TargetProdRate,
ResearchUserId)  
  Select 1,0,@User_id,2,@WED_Id,@PU_Id,@PU_Id,@Reject_WET_Id,WEMT_Id,  
   Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,@Event_id,@Reject_Weight,Null,Null,@End_Time,  
   Action_Level1,Action_Level2,Action_Level3,Action_Level4,Action_Comment_Id,  
   Research_Comment_Id,Research_Status_Id,Research_Open_Date,Research_Close_Date,Null,--Target_Prod_Rate,
Research_User_Id  
  From [dbo].Waste_Event_Details  
  Where WED_Id = @WED_Id  
 End  
End  
Else If (@Slab_Weight > 0 And @Slab_Weight Is Not Null)  
Begin  
 If (@Amount Is Null)  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,Action1,Action2,Action3,Action4,  
   ActionCommentId,ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,  
   --TargetProdRate,
ResearchUserId)  
  Values(1,0,@User_id,1,Null,@PU_Id,@PU_Id,@Slab_WET_Id,@Slab_WEMT_Id,@Slab_Reason_Id,Null,Null,Null,@Event_id,@Slab_Weight,Null,Null,@End_Time,Null,  
   Null,Null,Null,Null,Null,Null,Null,Null,Null,
--Null,
Null)  
 End  
 Else If (@WET_Id <> @Slab_WET_Id )  -- Convert existing record to Reject Waste  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,--TargetProdRate,
ResearchUserId)  
  Values(1,0,@User_id,2,@WED_Id,@PU_Id,@PU_Id,@Slab_WET_Id,@Slab_WEMT_Id,@Slab_Reason_Id,Null,Null,Null,@Event_id,@Slab_Weight,Null,Null,@End_Time,Null,  
   Null,Null,Null,Null,Null,Null,Null,Null,Null,--Null,
Null)  
 End  
 Else If (@Amount <> @Slab_Weight)  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,
--TargetProdRate,
ResearchUserId)  
  Select 1,0,@User_id,2,@WED_Id,@PU_Id,@PU_Id,@Slab_WET_Id,WEMT_Id,  
   Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,@Event_id,@Slab_Weight,Null,Null,@End_Time,  
   Action_Level1,Action_Level2,Action_Level3,Action_Level4,Action_Comment_Id,  
   Research_Comment_Id,Research_Status_Id,Research_Open_Date,Research_Close_Date,Null,--Target_Prod_Rate,
Research_User_Id  
  From [dbo].Waste_Event_Details  
  Where WED_Id = @WED_Id  
 End  
End  
Else --If (@Teardown_Weight <> 0)  
Begin  
 If (@Amount Is Null)  
 Begin  
   Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,TargetProdRate,ResearchUserId)  
   Values(1,0,@User_id,1,Null,@PU_Id,@PU_Id,@Teardown_WET_Id,Null,@Teardown_Reason_Id,Null,Null,Null,@Event_id,@Teardown_Weight,Null,Null,@End_Time,Null,  
   Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null)  
 End  
 Else If (@WET_Id <> @Slab_WET_Id )  -- Convert existing record to Reject Waste  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,--TargetProdRate,
ResearchUserId)  
  Values(1,0,@User_id,2,@WED_Id,@PU_Id,@PU_Id,@Teardown_WET_Id,@Teardown_WEMT_Id,@Teardown_Reason_Id,Null,Null,Null,@Event_id,@Teardown_Weight,Null,Null,@End_Time,Null,  
   Null,Null,Null,Null,Null,Null,Null,Null,Null,--Null,
Null)  
 End  
 Else If (@Amount <> @Teardown_Weight)  
 Begin  
  Insert Into @WasteResultSet(Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
   Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,  
   Action1,Action2,Action3,Action4,ActionCommentId,  
   ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,--TargetProdRate,
ResearchUserId)  
  Select 1,0,@User_id,2,@WED_Id,@PU_Id,@PU_Id,@Teardown_WET_Id,WEMT_Id,  
   Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,@Event_id,@Teardown_Weight,Null,Null,@End_Time,  
   Action_Level1,Action_Level2,Action_Level3,Action_Level4,Action_Comment_Id,  
   Research_Comment_Id,Research_Status_Id,Research_Open_Date,Research_Close_Date,Null,--Target_Prod_Rate,
Research_User_Id  
  From [dbo].Waste_Event_Details  
  Where WED_Id = @WED_Id  
 End  
End  
  
Select 9,Pre,TransNum,UserId,Transtype,WasteEventId,PuId,SourcePuId,TypeId,MeasId,  
  Reason1,Reason2,Reason3,Reason4,EventId,Amount,Marker1,Marker2,Timestamp,Action1,Action2,Action3,Action4,  
  ActionCommentId,ResearchCommentId,ResearchStatusId,ResearchOpenDate,ResearchCloseDate,CommentId,  
  --TargetProdRate,
ResearchUserId   
From @WasteResultSet  
Order By TransNum Asc  
  
Select @OutputValue = @WED_Id  
  
--DROP TABLE #WasteResultSet  
--- end  
  
SET NOCOUNT OFF  
  
