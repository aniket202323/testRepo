CREATE PROCEDURE dbo.spServer_DBMgrUpdEventDet
 	 @UserId 	  	  	 int,
 	 @EventId 	  	 int,
 	 @PUId 	  	  	 int,
 	 @Future1 	  	 nVarChar(100),  /* EventNum Not Used 11/20/02 */
 	 @TransType 	  	 int,
 	 @TransNum 	  	 int,
 	 @AltEventNum 	 nVarChar(100) output,
 	 @Future2 	  	 int output, /* EventStatus Not Used 11/20/02 */
 	 @InitialDimX 	 float output,
 	 @InitialDimY 	 float output,
 	 @InitialDimZ 	 float output,
 	 @InitialDimA 	 float output,
 	 @FinalDimX 	  	 float output,
 	 @FinalDimY 	  	 float output,
 	 @FinalDimZ 	  	 float output,
 	 @FinalDimA 	  	 float output,
 	 @OrientationX 	 float output,
 	 @OrientationY 	 float output,
 	 @OrientationZ 	 float output,
 	 @Future3 	  	  	 int output, /* ProdId Not Used 11/20/02 */
 	 @Future4 	  	 int output, /* AppProdId Not Used 11/20/02 */
 	 @OrderId 	  	 int output,
 	 @OrderLineId 	 int output,
 	 @PPId 	  	  	 int output,
 	 @PPSetupDetailId int output,
 	 @ShipmentId 	  	 int output,
 	 @CommentId 	  	 int output,
 	 @EntryOn 	  	 datetime output,
 	 @TimeStamp 	  	 datetime output, /* TimeStamp Not Stored - but necessary for variable syncs - If not supplied look it up */
 	 @Future6 	  	 int output, /* EventType Not Used 11/20/02 */
    @SignatureId 	 int = Null,
 	 @ProductDefId 	  	 Int = Null,
 	 @ReturnResultSet 	 Int 	 = 0 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
AS
Declare
  @TmpEventId int,
  @ShouldUpdate int,
  @RetCode int
Declare @DebugFlag tinyint,
 	  	 @ID Int,
 	  	 @Locked TinyInt
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 1 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
--select @DebugFlag = 1 
If @DebugFlag = 1 
BEGIN 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdEventDet /UserId: ' + coalesce(convert(nvarchar(10),@UserId),'Null') + ' /EventId: ' + coalesce(convert(nvarchar(10),@EventId),'Null') + 
   	 ' /PUId: ' + coalesce(convert(nvarchar(10),@PUId),'Null') + ' /TransType: ' + coalesce(convert(nvarchar(10),@TransType),'Null') + 
 	 ' /TransNum: ' + coalesce(convert(nvarchar(10),@TransNum),'Null') + ' /AltEventNum: ' + coalesce(@AltEventNum,'Null') +
 	 ' /InitialDimX: ' + coalesce(convert(nVarChar(25),@InitialDimX),'Null') + ' /InitialDimY: ' + coalesce(convert(nVarChar(25),@InitialDimY),'Null') + 
   ' /InitialDimZ: ' + coalesce(convert(nVarChar(25),@InitialDimZ),'Null') + ' /InitialDimA: ' + coalesce(convert(nVarChar(25),@InitialDimA),'Null') +  
 	 ' /FinalDimX: ' + coalesce(convert(nVarChar(25),@FinalDimX),'Null') + ' /FinalDimY: ' + coalesce(convert(nVarChar(25),@FinalDimY),'Null') +  
 	 ' /FinalDimZ: ' + coalesce(convert(nVarChar(25),@FinalDimZ),'Null') + ' /FinalDimA: ' + coalesce(convert(nVarChar(25),@FinalDimA),'Null') + 
 	 ' /OrientationX: ' + coalesce(convert(nVarChar(25),@OrientationX),'Null') + ' /OrientationY: ' + coalesce(convert(nVarChar(25),@OrientationY),'Null') + 
 	 ' /OrientationZ: ' + coalesce(convert(nvarchar(10),@OrientationZ),'Null') + ' /OrderId: ' + coalesce(convert(nvarchar(10),@OrderId),'Null') + 
 	 ' /OrderLineId: ' + coalesce(convert(nvarchar(10),@OrderLineId),'Null') + ' /PPId: ' + coalesce(convert(nvarchar(10),@PPId),'Null') + 
 	 ' /PPSetupDetailId ' + coalesce(convert(nvarchar(10),@PPSetupDetailId),'Null') + ' /ShipmentId: ' + coalesce(convert(nvarchar(10),@ShipmentId),'Null') + 
 	 ' /CommentId: ' + coalesce(convert(nvarchar(10),@CommentId),'Null') + ' /EntryOn: ' + coalesce(convert(nVarChar(25),@EntryOn),'Null'))
 END
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --   (   4) Event Locked: No action taken.
  --
/***********   TransNums   ************
0    Coalesce all values - set Initial dimensions
2    no Coalesce
3 	  Update ALL Dimensions  (from Common Dialogs)
9    Detail from Material_lot
98   Coalesce all (no dimension update)
99   Coalesce all  except Dimensions 
100  Initial Dim A
101  Initial Dim X
102  Initial Dim Y
103  Initial Dim Z
104  Final Dim A
105  Final Dim X
106  Final Dim Y
107  Final Dim Z
*/
DECLARE 	 @OldDimension 	 Float,
 	  	 @RecordChanged 	 Int 	 
DECLARE @PPSetupId  	 Int
DECLARE @PPCheck 	 Int
Declare @MyOwnTrans  	 Int
SET @Locked = 0
SELECT @Locked = Coalesce(b.LockData,0) 
 	 FROM Events a
 	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status
 	 WHERE Event_Id = @EventId 
IF @Locked = 1  	 RETURN(-200)
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
 	 
IF @TransNum in(9,10)
 	 SET @TransNum = 0
 	 
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
If @TransNum Not In( 0,2,3,1000) and Not (@TransNum Between 98 and 107)
  Return(-2)
If (@UserId Is NULL) Or (@EventId Is NULL)
  Return(-100)
If  (@EventId Is Null)
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@EventId Is NULL on Detail Insert/update')
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'return(-100)')
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 Return(-100)
END
Select @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate())
IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 SET @TmpEventId  = NULL
 	  	 SELECT  @TmpEventId = Event_Id FROM Event_Details WHERE Event_Id  = @EventId
 	  	 IF @TmpEventId is Null RETURN(4)-- Not Found
 	  	  	 UPDATE Event_Details SET Comment_id = @CommentId,Entered_By = @UserId,Entered_On = @EntryOn 
 	  	  	  	 WHERE Event_Id  = @EventId
 	  	 RETURN(2)
 	 END
If   (@PUId Is NULL) or (@TimeStamp Is Null)
 	 Select  @PUId = pu_Id,@TimeStamp = Timestamp
 	 FROM events 
 	 WHERE event_Id = @EventId
Select @RetCode = -1
Select @ShouldUpdate = 1
If @MyOwnTrans = 1 
 	 Begin
 	  	 BEGIN TRANSACTION
    DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	 End
If @TransType = 2
 	 Select @TransType = 1  -- same logic for add as update
If (@TransType = 1)
BEGIN
    Select @TmpEventId = NULL
    Select @TmpEventId = Event_Id From Event_Details Where (Event_Id = @EventId)
    If (@TmpEventId Is NULL) -- It's already in the table, switch to an update 
    BEGIN/* ECR #28252 */
 	  	 If @PPId Is Not Null And @PPSetupDetailId Is Not Null
 	  	 BEGIN
 	  	  	 Select @PPCheck = ps.pp_Id, @PPSetupId = pd.PP_Setup_Id
 	  	  	  	 From Production_Setup_Detail pd
 	  	  	  	 JOIN Production_Setup ps ON pd.PP_Setup_Id = ps.PP_Setup_Id
 	  	  	  	 WHERE pd.PP_Setup_Detail_Id =@PPSetupDetailId
 	  	  	 If @PPCheck <> @PPId
 	  	  	 BEGIN
 	  	  	  	 -- UNmatched detail to plan
 	  	  	  	 SELECT @PPSetupDetailId = Null,@PPSetupId = Null
 	  	  	 END
 	  	 END
 	  	 ELSE If @PPId Is Null And @PPSetupDetailId Is Not Null
 	  	  	 BEGIN
 	  	  	  	 Select @PPId = ps.pp_Id, @PPSetupId = pd.PP_Setup_Id
 	  	  	  	  	 From Production_Setup_Detail pd
 	  	  	  	  	 JOIN Production_Setup ps ON pd.PP_Setup_Id = ps.PP_Setup_Id 	  	  	 
 	  	  	  	 WHERE pd.PP_Setup_Detail_Id =@PPSetupDetailId
 	  	  	 END
 	  	 If @InitialDimX is not null Select @FinalDimX = isnull(@FinalDimX,@InitialDimX)
 	  	 If @InitialDimY is not null Select @FinalDimY = isnull(@FinalDimY,@InitialDimY)
 	  	 If @InitialDimZ is not null Select @FinalDimZ = isnull(@FinalDimZ,@InitialDimZ)
 	  	 If @InitialDimA is not null Select @FinalDimA = isnull(@FinalDimA,@InitialDimA)
 	  	 If @FinalDimX is not null Select @InitialDimX = isnull(@InitialDimX,@FinalDimX)
 	  	 If @FinalDimY is not null Select @InitialDimY = isnull(@InitialDimY,@FinalDimY)
 	  	 If @FinalDimZ is not null Select @InitialDimZ = isnull(@InitialDimZ,@FinalDimZ)
 	  	 If @FinalDimA is not null Select @InitialDimA = isnull(@InitialDimA,@FinalDimA)
 	  	 Insert Into Event_Details (Event_Id,PU_Id,Alternate_Event_Num,Initial_Dimension_X,Initial_Dimension_Y,
 	  	  	  	 Initial_Dimension_Z,Initial_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,
 	  	  	  	 Final_Dimension_A,Orientation_X,Orientation_Y,Orientation_Z,Order_Id,
 	  	  	  	 Order_Line_Id,PP_Id,PP_Setup_Detail_Id,Shipment_Item_Id,Entered_By,
 	  	  	  	 Entered_On,Comment_Id,Signature_Id,PP_Setup_Id,Product_Definition_Id)
 	  	  	 values(@EventId,@PUId,@AltEventNum,@InitialDimX,@InitialDimY,
 	  	  	  	  	 @InitialDimZ,@InitialDimA,@FinalDimX,@FinalDimY,@FinalDimZ,
 	  	  	  	  	 @FinalDimA,@OrientationX,@OrientationY,@OrientationZ,@OrderId,
 	  	  	  	  	 @OrderLineId,@PPId,@PPSetupDetailId,@ShipmentId,@UserId,
 	  	  	  	  	 @EntryOn,@CommentId,@SignatureId,@PPSetupId,@ProductDefId)
 	  	 If @MyOwnTrans = 1 Commit transaction
 	  	 Select @RetCode = 1
 	  	 goto DoReturnResultSet
 	 END      
END
If (@TransType = 1)
BEGIN
 	 If @TransNum = 100/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Initial_Dimension_A = @InitialDimA,Entered_By = @UserId,Entered_On = @EntryOn
 	  	  	 Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 101/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Initial_Dimension_X = @InitialDimX,Entered_By = @UserId,Entered_On = @EntryOn
 	  	 Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 102/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Initial_Dimension_Y = @InitialDimY,Entered_By = @UserId,Entered_On = @EntryOn
 	  	 Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 103/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Initial_Dimension_Z = @InitialDimZ,Entered_By = @UserId,Entered_On = @EntryOn
 	  	 Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 104/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Final_Dimension_A = @FinalDimA,Entered_By = @UserId,Entered_On = @EntryOn
 	  	  Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 105/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Final_Dimension_X = @FinalDimX,Entered_By = @UserId,Entered_On = @EntryOn
 	  	  Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 106/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Final_Dimension_Y = @FinalDimY,Entered_By = @UserId,Entered_On = @EntryOn
 	  	  Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
 	 If @TransNum = 107/* Only the dimension has changed */
 	 BEGIN
 	  	 SELECT @ShouldUpdate = 0
 	  	 UPDATE Event_Details Set 	 Final_Dimension_Z = @FinalDimZ,Entered_By = @UserId,Entered_On = @EntryOn
 	  	  Where (Event_Id = @EventId)
 	  	 SELECT @RetCode = 2
 	 END
END
If (@ShouldUpdate = 1)
BEGIN
 	 If @TransNum = 0 or @TransNum = 99
 	 BEGIN
 	  	 Select  @AltEventNum = Coalesce(@AltEventNum,Alternate_Event_Num),
 	  	  	 @OrderId = Coalesce(@OrderId,Order_Id),
 	  	  	 @OrderLineId = Coalesce(@OrderLineId,Order_Line_Id),
 	  	  	 @PPId = Coalesce(@PPId,PP_Id),
 	  	  	 @PPSetupDetailId = Coalesce(@PPSetupDetailId,PP_Setup_Detail_Id),
 	  	  	 @PPSetupId = Coalesce(@PPSetupId,PP_Setup_Id),
 	  	  	 @ShipmentId = Coalesce(@ShipmentId,Shipment_Item_Id),
 	  	  	 @CommentId = Coalesce(@CommentId,Comment_Id),
 	  	  	 @InitialDimX = Coalesce(@InitialDimX,Initial_Dimension_X),
 	  	  	 @InitialDimY = Coalesce(@InitialDimY,Initial_Dimension_Y),
 	  	  	 @InitialDimZ = Coalesce(@InitialDimZ,Initial_Dimension_Z),
 	  	  	 @InitialDimA = Coalesce(@InitialDimA,Initial_Dimension_A),
 	  	  	 @OrientationX = Coalesce(@OrientationX,Orientation_X),
 	  	  	 @OrientationY = Coalesce(@OrientationY,Orientation_Y),
 	  	  	 @OrientationZ = Coalesce(@OrientationZ,Orientation_Z),
            @SignatureId = Coalesce(@SignatureId,Signature_Id),
 	  	  	 @ProductDefId = Coalesce(@ProductDefId,Product_Definition_Id) 
 	  	  From Event_Details
 	  	  Where (Event_Id = @EventId)
--TransNum 99 - use dimensions passed into SP
 	  	 If @TransNum = 0 
       	 BEGIN
 	  	  	 Select @FinalDimX = Coalesce(@FinalDimX,Final_Dimension_X,@InitialDimX,Initial_Dimension_X),
 	  	  	  	 @FinalDimY = Coalesce(@FinalDimY,Final_Dimension_Y,@InitialDimY,Initial_Dimension_Y),
 	  	  	  	 @FinalDimZ = Coalesce(@FinalDimZ,Final_Dimension_Z,@InitialDimZ,Initial_Dimension_Z),
 	  	  	  	 @FinalDimA = Coalesce(@FinalDimA,Final_Dimension_A,@InitialDimA,Initial_Dimension_A),
 	  	  	  	 @SignatureId = Coalesce(@SignatureId,Signature_Id)
 	  	  	 From Event_Details
 	  	  	 Where (Event_Id = @EventId)
 	  	 END
 	 END
 	 if @TransNum = 98
 	 BEGIN
 	  	 Select  @AltEventNum = Coalesce(@AltEventNum,Alternate_Event_Num),
 	  	  	 @OrderId = Coalesce(@OrderId,Order_Id),
 	  	  	 @OrderLineId = Coalesce(@OrderLineId,Order_Line_Id),
 	  	  	 @PPId = Coalesce(@PPId,PP_Id),
 	  	  	 @PPSetupDetailId = Coalesce(@PPSetupDetailId,PP_Setup_Detail_Id),
 	  	  	 @PPSetupId = Coalesce(@PPSetupId,PP_Setup_Id),
 	  	  	 @ShipmentId = Coalesce(@ShipmentId,Shipment_Item_Id),
 	  	  	 @CommentId = Coalesce(@CommentId,Comment_Id),
             	  	 @SignatureId = Coalesce(@SignatureId,Signature_Id),
 	  	  	 @ProductDefId = Coalesce(@ProductDefId,Product_Definition_Id),
 	  	  	 @InitialDimX = Initial_Dimension_X,
 	  	  	 @InitialDimY = Initial_Dimension_Y,
 	  	  	 @InitialDimZ = Initial_Dimension_Z,
 	  	  	 @InitialDimA = Initial_Dimension_A, 	  	  	 
 	  	  	 @FinalDimX = Final_Dimension_X,
 	  	  	 @FinalDimY = Final_Dimension_Y,
 	  	  	 @FinalDimZ = Final_Dimension_Z,
 	  	  	 @FinalDimA = Final_Dimension_A
 	  	  From Event_Details
 	  	  Where (Event_Id = @EventId) 	 
 	 END
 	 --Only update the dimension fields
 	 If @TransNum = 3
 	 BEGIN
 	  	 Update Event_Details Set 
 	  	  	 Initial_Dimension_X = @InitialDimX,
 	  	  	 Initial_Dimension_Y = @InitialDimY,
 	  	  	 Initial_Dimension_Z = @InitialDimZ,
 	  	  	 Initial_Dimension_A = @InitialDimA,
 	  	  	 Final_Dimension_X = @FinalDimX,
 	  	  	 Final_Dimension_Y = @FinalDimY,
 	  	  	 Final_Dimension_Z = @FinalDimZ,
 	  	  	 Final_Dimension_A = @FinalDimA,
 	  	  	 Signature_Id = @SignatureId
 	  	 Where (Event_Id = @EventId)
 	  	 Select @RetCode = 2
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @PPSetupId = Null,@PPCheck = Null
 	  	 If @PPId Is Not Null And @PPSetupDetailId Is Not Null
 	  	 BEGIN
 	  	  	 Select @PPCheck = ps.pp_Id, @PPSetupId = pd.PP_Setup_Id
 	  	  	  	 From Production_Setup_Detail pd
 	  	  	  	 JOIN Production_Setup ps ON pd.PP_Setup_Id = ps.PP_Setup_Id
 	  	  	  	 WHERE pd.PP_Setup_Detail_Id =@PPSetupDetailId
 	  	  	 If @PPCheck <> @PPId
 	  	  	 BEGIN
 	  	  	  	 -- UNmatched detail to plan
 	  	  	  	 SELECT @PPSetupDetailId = Null,@PPSetupId = Null
 	  	  	 END
 	  	 END
 	  	 ELSE If @PPId Is Null And @PPSetupDetailId Is Not Null
 	  	  	 BEGIN
 	  	  	  	 Select @PPId = ps.pp_Id, @PPSetupId = pd.PP_Setup_Id
 	  	  	  	  	 From Production_Setup_Detail pd
 	  	  	  	  	 JOIN Production_Setup ps ON pd.PP_Setup_Id = ps.PP_Setup_Id 	  	  	 
 	  	  	  	 WHERE pd.PP_Setup_Detail_Id =@PPSetupDetailId
 	  	  	 END
 	  	 Update Event_Details Set 
 	  	  	 Entered_By = @UserId, 
 	  	  	 Entered_On = @EntryOn,
 	  	  	 PU_Id = @PUId,
 	  	  	 Alternate_Event_Num = @AltEventNum,
 	  	  	 Order_Id = @OrderId,
 	  	  	 Order_Line_Id = @OrderLineId,
 	  	  	 PP_Id = @PPId,
 	  	  	 PP_Setup_Detail_Id = @PPSetupDetailId,
 	  	  	 PP_Setup_Id = @PPSetupId,
 	  	  	 Shipment_Item_Id = @ShipmentId,
 	  	  	 Comment_Id = @CommentId,
 	  	  	 Initial_Dimension_X = @InitialDimX,
 	  	  	 Initial_Dimension_Y = @InitialDimY,
 	  	  	 Initial_Dimension_Z = @InitialDimZ,
 	  	  	 Initial_Dimension_A = @InitialDimA,
 	  	  	 Final_Dimension_X = @FinalDimX,
 	  	  	 Final_Dimension_Y = @FinalDimY,
 	  	  	 Final_Dimension_Z = @FinalDimZ,
 	  	  	 Final_Dimension_A = @FinalDimA,
 	  	  	 Orientation_X = @OrientationX,
 	  	  	 Orientation_Y = @OrientationY,
 	  	  	 Orientation_Z = @OrientationZ,
            Signature_Id = @SignatureId,
 	  	  	 Product_Definition_Id = @ProductDefId
 	  	 Where (Event_Id = @EventId)
 	     Select @RetCode = 2
 	 END
END
if (@RetCode > 0)
  Begin
    Select @AltEventNum = Alternate_Event_Num,
           @OrderId = Order_Id,
           @OrderLineId = Order_Line_Id,
           @PPId = PP_Id,
           @PPSetupDetailId = PP_Setup_Detail_Id,
           @ShipmentId = Shipment_Item_Id,
           @CommentId = Comment_Id,
           @InitialDimX = Initial_Dimension_X,
           @InitialDimY = Initial_Dimension_Y,
           @InitialDimZ = Initial_Dimension_Z,
           @InitialDimA = Initial_Dimension_A,
           @FinalDimX = Final_Dimension_X,
           @FinalDimY = Final_Dimension_Y,
           @FinalDimZ = Final_Dimension_Z,
           @FinalDimA = Final_Dimension_A,
           @OrientationX = Orientation_X,
           @OrientationY = Orientation_Y,
           @OrientationZ = Orientation_Z 
      From Event_Details
      Where (Event_Id = @EventId)
  End
If @MyOwnTrans = 1 Commit transaction
DoReturnResultSet:
If (@RetCode > 0)
Begin
 	 If (@ReturnResultSet = 1)
 	 Begin
 	  	 SELECT 	 10, 0, @UserId, @TransType, @TransNum, @EventId, @PUId, NULL, @AltEventNum, @CommentId, NULL, NULL, NULL, NULL, @TimeStamp, @EntryOn,
 	  	  	  	 @PPSetupDetailId, @ShipmentId, @OrderId, @OrderLineId, @PPId, @InitialDimX, @InitialDimY, @InitialDimZ, @InitialDimA, @FinalDimX,
 	  	  	  	 @FinalDimY, @FinalDimZ, @FinalDimA, @OrientationX, @OrientationY, @OrientationZ, @SignatureId
 	 End
 	 If (@ReturnResultSet = 2)
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 SELECT 	 RSTId=10, PreDB=0, @UserId, @TransType, @TransNum, @EventId, @PUId, Obsolete1=NULL, @AltEventNum, @CommentId, Obsolete2=NULL, Obsolete3=NULL,
 	  	  	  	  	 Obsolete4=NULL, Obsolete5=NULL, @TimeStamp, @EntryOn,
 	  	  	  	  	 @PPSetupDetailId, @ShipmentId, @OrderId, @OrderLineId, @PPId, @InitialDimX, @InitialDimY, @InitialDimZ, @InitialDimA, @FinalDimX,
 	  	  	  	  	 @FinalDimY, @FinalDimZ, @FinalDimA, @OrientationX, @OrientationY, @OrientationZ, @SignatureId
 	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 End
End
return(@RetCode)
