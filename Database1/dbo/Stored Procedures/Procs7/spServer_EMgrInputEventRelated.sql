CREATE PROCEDURE dbo.spServer_EMgrInputEventRelated
@Event_Id int,
@PEI_Id int,
@Related int OUTPUT
AS
Declare
  @MasterPUId int,
  @PUId int,
  @TmpMasterPUId int
Select @Related = 0
Select @MasterPUId = NULL
Select @MasterPUId = PU_Id From Events Where Event_Id = @Event_Id
If (@MasterPUId Is NULL)
  Return
Select @PUId = NULL
Select @PUId = PU_Id From PrdExec_Inputs Where PEI_Id = @PEI_Id
If (@PUId Is NULL)
  Return
If (@MasterPUId = @PUId)
  Begin
    Select @Related = 1
    Return
  End
Select @TmpMasterPUId = NULL
Select @TmpMasterPUId = Master_Unit From Prod_Units_Base Where PU_Id = @PUId
If (@TmpMasterPUId Is NULL)
  Return
If (@MasterPUId = @TmpMasterPUId)
  Select @Related = 1
