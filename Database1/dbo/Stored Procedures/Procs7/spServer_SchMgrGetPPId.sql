CREATE PROCEDURE dbo.spServer_SchMgrGetPPId     
@PathId int,
@Timestamp datetime,
@PPId int OUTPUT
AS
Select @PPId = NULL
Select @PPId = PP_Id 
  From Production_Plan 
  Where (Path_Id = @PathId) And (Actual_Start_Time < @Timestamp) And ((Actual_End_Time >= @Timestamp) Or (Actual_End_Time Is NULL))
If (@PPId Is NULL)
  Select @PPId = 0
