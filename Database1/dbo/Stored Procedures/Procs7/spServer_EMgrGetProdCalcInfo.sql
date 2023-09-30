CREATE PROCEDURE dbo.spServer_EMgrGetProdCalcInfo
@Event_Id int,
@InvPU_Id int,
@Success int OUTPUT,
@ErrorMsg nVarChar(100) OUTPUT,
@WTValue nVarChar(30) OUTPUT,
@LFValue nVarChar(30) OUTPUT,
@DIValue nVarChar(30) OUTPUT,
@WTOrigVarId int OUTPUT,
@LFOrigVarId int OUTPUT,
@DIOrigVarId int OUTPUT,
@WTLastVarId int OUTPUT,
@LFLastVarId int OUTPUT,
@DILastVarId int OUTPUT
 AS
Declare
  @PU_Id int,
  @TimeStamp Datetime
Select @Success = 0
Select @ErrorMsg = ''
Select @PU_Id = PU_Id,
       @TimeStamp = TimeStamp
  From Events
  Where Event_Id = @Event_Id
If (@PU_Id Is Null) Or (@TimeStamp Is Null)
  Begin
    Select @ErrorMsg = 'Source Event Id [' + Convert(nVarChar(10),@Event_Id) + '] Not Found'
    return
  End
Execute spServer_EMgrGetProdCalcValue 'LAST Basis Wgt',@Event_Id,@PU_Id,@TimeStamp,2,@Success OUTPUT,@ErrorMsg OUTPUT, @WTValue OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcValue 'LAST Lineal Ft',@Event_Id,@PU_Id,@TimeStamp,4,@Success OUTPUT,@ErrorMsg OUTPUT, @LFValue OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcValue 'LAST Diameter' ,@Event_Id,@PU_Id,@TimeStamp,6,@Success OUTPUT,@ErrorMsg OUTPUT, @DIValue OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcVarId 'ORIG Basis Wgt',@InvPU_Id,1,@Success OUTPUT,@ErrorMsg OUTPUT,@WTOrigVarId OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcVarId 'ORIG Lineal Ft',@InvPU_Id,3,@Success OUTPUT,@ErrorMsg OUTPUT,@LFOrigVarId OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcVarId 'ORIG Diameter' ,@InvPU_Id,5,@Success OUTPUT,@ErrorMsg OUTPUT,@DIOrigVarId OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcVarId 'LAST Basis Wgt',@InvPU_Id,2,@Success OUTPUT,@ErrorMsg OUTPUT,@WTLastVarId OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcVarId 'LAST Lineal Ft',@InvPU_Id,4,@Success OUTPUT,@ErrorMsg OUTPUT,@LFLastVarId OUTPUT
If (@Success = 0)
  return
Execute spServer_EMgrGetProdCalcVarId 'LAST Diameter' ,@InvPU_Id,6,@Success OUTPUT,@ErrorMsg OUTPUT,@DILastVarId OUTPUT
If (@Success = 0)
  return
Select @Success = 1
