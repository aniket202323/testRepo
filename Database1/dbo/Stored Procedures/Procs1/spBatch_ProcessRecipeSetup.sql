CREATE Procedure dbo.spBatch_ProcessRecipeSetup
  	  @EventTransactionId  	  	  	  	  	 Int,
  	  @BatchUnitId  	   	  	  	  	  	  	  	 Int,
  	  @BatchProcedureUnitId  	    	   	 Int,
 	  @BatchProcedureGroupId 	  	  	  	 int, 	 
  	  @ProcedureUnitId  	   	  	  	  	  	 Int,
  	  @UserId  	   	  	  	  	  	  	  	  	  	  	 Int,
  	  @SecondUserId  	  	  	  	  	  	  	  	 Int,
 	  @Debug  	  	  	  	  	  	  	  	  	  	  	 Int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
Declare @ID Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_ProcessRecipeSetup)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_ProcessRecipeSetup /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') + ' /BatchUnitId: ' + IsNull(convert(nvarchar(10),@BatchUnitId),'Null') + 
 	 ' /BatchProcedureUnitId: ' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null') + ' /BatchProcedureGroupId: ' + isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null') + 
 	 ' /ProcedureUnitId: ' + isnull(convert(nvarchar(10),@ProcedureUnitId),'Null') + ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + 
 	 ' /@SecondUserId: ' + isnull(convert(nvarchar(10),@SecondUserId),'Null') + ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
  End
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
Declare 
 	 @EventTimeStamp  	    	    	 DateTime,
  	 @BatchName  	    	    	    	 nvarchar(50),
  	 @UnitProcedureName  	    	    	 nvarchar(50),
  	 @OperationName  	    	    	 nvarchar(50),
  	 @PhaseName  	    	    	    	 nvarchar(50),
  	 @PhaseInstance  	    	    	 Int,
  	 @ParameterName  	    	    	 nvarchar(50),
  	 @ParameterAttributeName  	    	 nvarchar(50),
  	 @ParameterAttributeUOM  	    	 nvarchar(50),
  	 @ParameterAttributeValue  	 nvarchar(50),
  	 @ParameterAttributeComments  	 nvarchar(255),
 	 @VarUOM 	  	  	  	  	 nvarchar(15),
 	 @VarPercision 	  	  	  	 Int
Declare
 	 @EventNum 	  	  	  	 nvarchar(50),
 	 @EventId  	    	   	  	 Int,
 	 @EventUnit             	 Int,
 	 @DataType 	    	   	  	 Int,
 	 @ParameterType 	    	  	 nvarchar(10),
 	 @BatchStartTime 	  	 datetime,
 	 @BatchEndTime  	  	  	 datetime,
 	 @BatchProductId  	  	 int,
 	 @VarId  	    	     	  	 Int,
 	 @VarUnitId       	  	 int,
 	 @UnitProcedureInstance 	 Int,
 	 @BatchInstance 	  	  	 Int,
 	 @OperationInstance 	  	 Int
Declare
 	  @VSID  	    	    	    	   	  	 Int,
 	  @Limit  	    	    	    	   	 nvarchar(25),
 	  @ApprovalTime  	    	   	  	 DateTime,
 	  @SQLParameterName  	   	  	 nvarchar(50),
 	  @Sql  	    	    	    	   	  	 nvarchar(1000)
Declare
  	  @Error  	    	    	    	   	 nvarchar(255),
   @Rc  	  	  	  	  	  	  	  	  	  	 int
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select @Error = ''
Select @Rc = 0
-------------------------------------------------------------------------------
-- Load Variables with the Event_Transactions record being processed
-------------------------------------------------------------------------------
Select   	 @EventTimeStamp   	    	    	   	  	 = EventTimeStamp,
  	   	  	  	  	 @BatchName  	    	    	    	 = LTrim(RTrim(BatchName)),
  	   	  	  	  	 @UnitProcedureName  	    	    	 = LTrim(RTrim(UnitProcedureName)),
  	   	  	  	  	 @OperationName  	    	    	 = LTrim(RTrim(OperationName)),
  	   	  	  	  	 @PhaseName  	    	    	    	 = LTrim(RTrim(PhaseName)),
  	   	  	  	  	 @PhaseInstance  	    	    	 = PhaseInstance,
  	   	  	  	  	 @BatchInstance  	    	    	 = BatchInstance,
  	   	  	  	  	 @UnitProcedureInstance   	    	 = UnitProcedureInstance,
  	   	  	  	  	 @OperationInstance  	    	    	 = OperationInstance,
  	   	  	  	  	 @ParameterName  	    	    	 = LTrim(RTrim(ParameterName)),
  	   	  	  	  	 @ParameterAttributeName  	    	 = LTrim(RTrim(ParameterAttributeName)),
  	   	  	  	  	 @ParameterAttributeUOM  	    	 = LTrim(RTrim(ParameterAttributeUOM)),
  	   	  	  	  	 @ParameterAttributeValue  	 = LTrim(RTrim(ParameterAttributeValue)),
  	   	  	  	  	 @ParameterAttributeComments  	 = LTrim(RTrim(ParameterAttributeComments))
 	 From  Event_Transactions 
 	 Where EventTransactionId = @EventTransactionId
-------------------------------------------------------------------------------
-- Check record
-------------------------------------------------------------------------------
IF 	 @BatchName = '' or @BatchName Is Null
 	 SELECT 	 @BatchName = Null
ELSE
 SELECT 	 @BatchName = @BatchName + Isnull('|' + Convert(nvarchar(10),@BatchInstance),'')
IF 	 @UnitProcedureName = '' or @UnitProcedureName Is Null
 	  SELECT 	 @UnitProcedureName = Null
ELSE
 	  SELECT 	 @UnitProcedureName = @UnitProcedureName + Isnull(':' + Convert(nvarchar(10),@UnitProcedureInstance),'')
 	 
IF 	 @OperationName = '' or @OperationName Is Null
 	 SELECT 	 @OperationName = Null
ELSE
 	 SELECT 	 @OperationName = @OperationName  + Isnull(':' + Convert(nvarchar(10),@OperationInstance),'')
IF 	 @PhaseName = '' SELECT 	 @PhaseName = Null
IF 	 @ParameterName = '' SELECT 	 @ParameterName = Null
IF 	 @ParameterAttributeName = '' SELECT 	 @ParameterAttributeName = Null
IF 	 @ParameterAttributeUOM = '' SELECT 	 @ParameterAttributeUOM = Null
IF 	 @ParameterAttributeValue = '' SELECT 	 @ParameterAttributeValue = Null
IF 	 @ParameterAttributeComments = '' SELECT 	 @ParameterAttributeComments = Null
If (@ParameterName is Null) 
  Begin
  	  Select @Error = 'Missing Parameter Name'
  	  Goto Errc
  End
If (@ParameterAttributeName is null) Or
   (@ParameterAttributeName Not In ('Target','UpperUser','LowerUser','UpperWarning','LowerWarning','UpperReject','LowerReject'))
  Begin
  	  Select @Error = 'Bad Parameter Attribute Name'
  	  Goto Errc
  End
If (@ParameterAttributeValue is null)
  Begin
  	  Select @Error = 'Missing Parameter Attribute Value'
  	  Goto Errc
  End
If LEN(@ParameterAttributeValue) > 25
  Begin
  	  Select @Error = 'Parameter Attribute Value must be < 25'
  	  Goto Errc
  End
Select @DataType = 2
If isnumeric(@ParameterAttributeValue) = 0
  Select  @DataType = 3
If @BatchProcedureGroupId Is Null
  Begin
  	  Select @Error = 'Variable Group Is Null'
  	  Goto Errc
  End
--Select @PhaseName = @PhaseName + ':' + Convert(nvarchar(25),@PhaseInstance)
Select @SQLParameterName = case when @ParameterAttributeName = 'Target' Then 'Target'
  	    	    	    	    	    	    	   Else substring(@ParameterAttributeName,1,1) + '_' +  substring(@ParameterAttributeName,6,LEN(@ParameterAttributeName)-5)
  	    	    	    	    	    	     End
Select @BatchEndTime = @EventTimeStamp
Select @ApprovalTime = @EventTimeStamp
-------------------------------------------------------------------------------
-- Create Variable And Get Timestamp Of Batch
-------------------------------------------------------------------------------
Select @Rc = 0
exec @Rc = spBatch_GetSingleVariable
 	 @EventTransactionId,
 	 @VarId OUTPUT,
 	 @BatchName OUTPUT,
 	 @BatchUnitId,
 	 @BatchProcedureUnitId,
 	 @BatchProcedureGroupId,
 	 @BatchStartTime OUTPUT,
 	 @BatchEndTime OUTPUT, 	  	  	  	 
 	 @BatchProductId OUTPUT,
 	 1,
 	 @UnitProcedureName,
 	 @OperationName,
 	 @PhaseName,
 	 @PhaseInstance,
 	 @ParameterName,
 	 @ParameterAttributeUOM,
 	 @DataType,
 	 @ParameterType OUTPUT,
 	 @VarUOM 	 OUTPUT,
 	 @VarPercision 	 OUTPUT,
 	 @UserId,
 	 @Debug
If @Rc <> 1 Goto Errc
Select @ParameterAttributeValue = dbo.fnCmn_ConvertEngUnit(@ParameterAttributeUOM,@VarUOM,@ParameterAttributeValue,@VarPercision)
-------------------------------------------------------------------------------
-- Make Sure We Know The Product (Assumes Product Is Set B4 Recipe Setup)
-------------------------------------------------------------------------------
If @BatchProductId is null
  Begin
   Select @Error = 'Unable to Determine Product For Batch [' + @BatchName + ']'
   Goto Errc
  End
-------------------------------------------------------------------------------
-- Calculate Time To Approve Specifications For
-------------------------------------------------------------------------------
Select @ApprovalTime = coalesce(@BatchStartTime, @ApprovalTime)
--***************************************
--  See If This is the First Limit
--***************************************
Select @VSID = Null
Select @VSID = min(VS_Id)
 From Var_Specs
  	  Where Prod_Id = @BatchProductId and 
         Var_Id = @VarId
If @VSID is null 
  Begin
   If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'First Limit For Variable [' + coalesce(convert(nvarchar(10),@VarId) , '?') + '] Product [' + coalesce(convert(nvarchar(10),@BatchProductId) , '?') + ']')
   -- this is the first specification entry
  	  Select @Sql = 'Insert InTo Var_Specs (Effective_Date,Var_Id,Prod_Id,' + @SQLParameterName + ') Values (''' + convert(nvarchar(25),@ApprovalTime,13) + ''',' + Convert(nvarchar(10),@VarId) + ',' + Convert(nvarchar(10),@BatchProductId) + ',''' + @ParameterAttributeValue + ''')'
  	  Execute (@Sql)
  	  goto Finish
  End
--***************************************
--  See If We Already Have This Limit
--***************************************
Declare @OldVSId Int
Select @OldVSId = NULL
Select @OldVSId = Vs_Id,@Limit = Case  When @ParameterAttributeName = 'Target' Then Target
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'UpperUser' Then U_User
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'LowerUser' Then L_User
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'UpperWarning' Then U_Warning
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'LowerWarning' Then L_Warning
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'UpperReject' Then U_Reject
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'LowerReject' Then L_Reject
  	    	    	    	    	    	    	   End
  	    From Var_Specs 
     Where Var_Id = @VarId and 
           Prod_Id = @BatchProductId and 
           Effective_Date  = @ApprovalTime
IF @OldVSId is Not null
  Begin
   -- have specs at the exact same time, update new limit  
  	  If @ParameterAttributeValue <> @Limit or (@Limit Is Null and @ParameterAttributeValue Is Not Null)
  	    Begin
 	  	  	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Updating Limit For Variable [' + coalesce(convert(nvarchar(10),@VarId) , '?') + '] Product [' + coalesce(convert(nvarchar(10),@BatchProductId) , '?') + ']')
  	    	  Select @Sql = 'Update Var_Specs Set ' + @SQLParameterName + ' = ''' + @ParameterAttributeValue + ''' Where Vs_Id = ' + Convert(nvarchar(10),@OldVSId)
 	  	  	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @sql)
  	    	  Execute (@Sql)
  	    End
  	  Goto Finish
  End
--***************************************
--  See If We Have Limits To Expire, etc
--***************************************
Declare @CurrentVSId Int
Declare @NextVSId  Int
Declare @NextEffective DateTime
Declare @NextLimit nvarchar(25)
Select @CurrentVSId =  Vs_Id,@Limit = Case  When @ParameterAttributeName = 'Target' Then Target
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'UpperUser' Then U_User
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'LowerUser' Then L_User
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'UpperWarning' Then U_Warning
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'LowerWarning' Then L_Warning
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'UpperReject' Then U_Reject
  	    	    	    	    	    	    	    	    	  When @ParameterAttributeName = 'LowerReject' Then L_Reject
  	    	    	    	    	    	    	   End
  	    From Var_Specs 
     Where Var_Id = @VarId and 
           Prod_Id = @BatchProductId  and 
           Effective_Date < @ApprovalTime and 
          (Expiration_Date is null or Expiration_Date > @ApprovalTime)
--***************************************************
--  If We Have Future Specs, We Can't Go Further
--***************************************************
Select @NextEffective = Min(Effective_Date)
  	  From Var_Specs 
  	  Where Var_Id = @VarId and 
         Prod_Id = @BatchProductId  and 
         Effective_Date > @ApprovalTime
If @NextEffective is Not Null
  Begin
  	  Select @Error = 'Future specs already exist - no update'
  	  goto errc
  End
--***************************************************
--  Expire Old Specifications, Insert New Row
--***************************************************
If @ParameterAttributeValue <> @Limit or (@Limit Is Null and @ParameterAttributeValue Is Not Null)
  Begin
 	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Expiring Old Specifications For Variable [' + coalesce(convert(nvarchar(10),@VarId) , '?') + '] Product [' + coalesce(convert(nvarchar(10),@BatchProductId) , '?') + ']')
  	  Select @Sql = 'Update Var_Specs Set Expiration_Date = ''' + convert(nvarchar(25),@ApprovalTime,13) + ''' Where Vs_Id = ' + Convert(nvarchar(10),@CurrentVSId)
 	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @sql)
  	  Execute (@Sql)
 	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Inserting New Specifications For Variable [' + coalesce(convert(nvarchar(10),@VarId) , '?') + '] Product [' + coalesce(convert(nvarchar(10),@BatchProductId) , '?') + ']')
  	  Insert Into Var_Specs (Effective_Date,Test_Freq,Comment_Id,Var_Id,Prod_Id,L_Warning,L_Reject,L_Entry,U_User,Target,L_User,U_Entry,U_Reject,U_Warning)
  	    	  Select @ApprovalTime,Test_Freq,Comment_Id,Var_Id,Prod_Id,L_Warning,L_Reject,L_Entry,U_User,Target,L_User,U_Entry,U_Reject,U_Warning
  	    	  From Var_Specs where VS_Id = @CurrentVSId
  	  select @NextVSId = Vs_Id From Var_Specs Where Var_Id = @VarId and Prod_Id = @BatchProductId  and Effective_Date = @ApprovalTime
  	  Select @Sql = 'Update Var_Specs Set ' + @SQLParameterName + ' = ''' + @ParameterAttributeValue + ''' Where Vs_Id = ' + Convert(nvarchar(10),@NextVSId)
 	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @sql)
  	  Execute (@Sql)
  End
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessRecipeSetup)')
RETURN(@Rc)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag  	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessRecipeSetup)')
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
RETURN(-100)
