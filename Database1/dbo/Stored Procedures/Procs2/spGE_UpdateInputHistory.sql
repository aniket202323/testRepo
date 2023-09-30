Create Procedure dbo.spGE_UpdateInputHistory
@TransHistoryId 	 int,
@NewEventId 	 int
 AS
Declare @PEI_Id 	  	 Int,
 	 @PEIP_Id 	 Int,
 	 @Event_Id 	 Int,
 	 @Unloaded  	 DateTime,
 	 @Timestamp 	 DateTime,
 	 @User_Id      	 INt,
 	 @Entry_On 	 DateTime,
 	 @Comment_Id 	 Int,
 	 @Dimension_A    Float,
 	 @Dimension_X    Float,
 	 @Dimension_Y    Float,
 	 @Dimension_Z    Float
Select  	 @Entry_On = dbo.fnServer_CmnGetDate(GetUTCdate())
Select @PEI_Id = PEI_Id,
 	 @PEIP_Id = PEIP_Id,
 	 @Event_Id = Event_Id,
 	 @Unloaded = Unloaded,
 	 @Timestamp = Timestamp,
 	 @User_Id = User_Id,
 	 @Comment_Id = Comment_Id,
 	 @Dimension_A = Dimension_A,
 	 @Dimension_X = Dimension_X,
 	 @Dimension_Y = Dimension_Y,
 	 @Dimension_Z = Dimension_Z
From PrdExec_Input_Event_History 
Where Input_Event_History_Id = @TransHistoryId
/*Update record to show substituted*/
Update PrdExec_Input_Event_History set Unloaded = 3 where Input_Event_History_Id = @TransHistoryId
/*Insert substitution*/
Insert InTo PrdExec_Input_Event_History (PEI_Id,PEIP_Id,Event_Id,Unloaded,Timestamp,User_Id,Entry_On,
 	  	  	  	  	  Dimension_A,Dimension_X,Dimension_Y,Dimension_Z)
 Values (@PEI_Id,@PEIP_Id,@NewEventId,0,@Timestamp,@User_Id,@Entry_On,@Dimension_A,@Dimension_X,
 	 @Dimension_Y,@Dimension_Z)
