CREATE PROCEDURE dbo.spServer_CmnGetProdPlanStartInfo
@PPStartId int,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT,
@Found int OUTPUT
AS
Select @StartTime = NULL
Select @EndTime = NULL
Select @Found = 0
Select @StartTime = Start_Time,
       @EndTime = End_Time
  From Production_Plan_Starts
  Where (PP_Start_Id = @PPStartId)
If (@StartTime Is Null)
  Return
Select @Found = 1
