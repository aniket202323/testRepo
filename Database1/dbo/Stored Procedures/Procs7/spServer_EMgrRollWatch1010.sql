CREATE PROCEDURE dbo.spServer_EMgrRollWatch1010
@Event_Id int,
@Success int OUTPUT,
@ErrorMsg nVarChar(255) OUTPUT,
@ChildEvent_Id int OUTPUT,
@C_IDX float OUTPUT,
@C_IDY float OUTPUT,
@C_IDZ float OUTPUT,
@C_IDA float OUTPUT,
@C_FDX float OUTPUT,
@C_FDY float OUTPUT,
@C_FDZ float OUTPUT,
@C_FDA float OUTPUT,
@ChildPUId int OUTPUT,
@ChildEventStatus int OUTPUT,
@ChildEventNum nVarChar(100) OUTPUT,
@ChildTimeStamp datetime OUTPUT
AS
Declare
  @NumChildRolls int,
  @ParentPU_Id int,
  @ParentTimeStamp Datetime,
  @P_IDX float,
  @P_IDY float,
  @P_IDZ float,
  @P_IDA float,
  @P_FDX float,
  @P_FDY float,
  @P_FDZ float,
  @P_FDA float,
  @Found int,
  @TmpError nVarChar(255),
  @Retry int,
  @EventStatus int,
  @AppProdId int,
  @PUId int,
  @PriEventNum nVarChar(255),
  @AltEventNum nVarChar(255),
  @Timestamp datetime,
  @UserId int
Select @ChildEvent_Id = 0
Select @Success = 1
Select @ErrorMsg = 'Success'
Declare @PossibleUnits Table (PU_Id int)
Insert Into @PossibleUnits
Select PU_Id From Prod_Units_Base Where Def_Production_Src = (Select PU_Id From Events Where Event_Id = @Event_Id)
Select @ParentPU_Id = PU_Id,
       @ParentTimeStamp = TimeStamp 
  From Events 
  Where (Event_Id = @Event_Id)
If (@ParentPU_Id Is Null)
  Begin
    Select @Success = 0
    Select @ErrorMsg = 'Parent Event Not Found [' + Convert(nVarChar(20),@Event_Id) + ']'
    Goto TheEnd
  End
Select @Success = 0
Select @ErrorMsg = 'Event Detail Data Not Found For Inventory Roll [' + Convert(nVarChar(30),@Event_Id) + ']'
Execute spServer_CmnGetEventDetailInfo @Event_Id, 	 @P_IDX output,@P_IDY output,@P_IDZ output,@P_IDA output,
 	  	  	  	  	 @P_FDX output,@P_FDY output,@P_FDZ output,@P_FDA output, @EventStatus output, @AppProdId output, @PUId output,
 	  	  	  	  	 @PriEventNum output, @AltEventNum output, @Timestamp output, @UserId output, @Found output
If (@Found Is NULL) Or (@Found <= 0)
  Begin
    Select @Success = 0
    Goto TheEnd
  End
Select @Success = 1
Select @ErrorMsg = ''
Select @Retry = 0
FindChild:
Select @NumChildRolls = Count(a.Event_Id) 
  From Events a
  Join @PossibleUnits b On b.PU_Id = a.PU_Id
  Where (a.Source_Event = @Event_Id) And
        (a.Event_Status In (1,2,3,4))
If (@NumChildRolls = 0)
  Begin
    Select @Retry = @Retry + 1
    if @Retry > 1 
      Begin 
        Select @Success = 0
        Select @ErrorMsg = 'No Possible Child Rolls Found For Parent Roll [' + Convert(nVarChar(30),@Event_Id) + ']'
        Goto TheEnd  
      End
    Else
      Begin
         WaitFor Delay '00:00:15'
         Goto FindChild
      End
  End
If (@NumChildRolls > 1)
  Begin
    Select @Success = 0
    Select @ErrorMsg = 'More Than One Roll With Source Event [' + Convert(nVarChar(20),@Event_Id) + ']'
    Goto TheEnd
  End
Select @ChildEvent_Id = a.Event_Id,
       @ChildPUId = a.PU_Id,
       @ChildTimeStamp = a.TimeStamp,
       @ChildEventStatus = a.Event_Status,
       @ChildEventNum = a.Event_Num
  From Events a
  Join @PossibleUnits b On b.PU_Id = a.PU_Id
  Where (a.Source_Event = @Event_Id) And
        (a.Event_Status In (1,2,3,4))
Execute spServer_CmnGetEventDetailInfo @ChildEvent_Id,@C_IDX output,@C_IDY output,@C_IDZ output,@C_IDA output,
 	  	  	  	  	 @C_FDX output,@C_FDY output,@C_FDZ output,@C_FDA output, @EventStatus output, @AppProdId output, @PUId output,
 	  	  	  	  	 @PriEventNum output, @AltEventNum output, @Timestamp output, @UserId output, @Found output
Select @C_IDX = @P_FDX
Select @C_IDY = @P_FDY
Select @C_IDZ = @P_FDZ
Select @C_IDA = @P_FDA
If (@C_FDX Is NULL) Select @C_FDX = @P_FDX
If (@C_FDY Is NULL) Select @C_FDY = @P_FDY
If (@C_FDZ Is NULL) Select @C_FDZ = @P_FDZ
If (@C_FDA Is NULL) Select @C_FDA = @P_FDA
Select @Success = 1
Select @ErrorMsg = ''
TheEnd:
