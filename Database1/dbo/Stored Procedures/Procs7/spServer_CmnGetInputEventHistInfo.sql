CREATE PROCEDURE dbo.spServer_CmnGetInputEventHistInfo
@Id int,
@PEIId int OUTPUT,
@Found int OUTPUT
AS
Select @Found = 0
Select @PEIId = NULL
Select @PEIId = PEI_Id
  From PrdExec_Input_Event_History
  Where (Input_Event_History_Id = @Id)
If (@PEIId Is Not NULL)
  Select @Found = 1
