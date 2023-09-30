CREATE PROCEDURE dbo.spServer_CmnGetProdStartInfo
@Start_Id int,
@PU_Id int OUTPUT,
@Prod_Id int OUTPUT,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT,
@Confirmed int OUTPUT,
@Found int OUTPUT
AS
Select @Found = 1
Select @PU_Id = NULL
Select @PU_Id = PU_Id,
       @Prod_Id = Prod_Id,
       @StartTime = Start_Time,
       @EndTime = End_Time,
       @Confirmed = COALESCE(Confirmed,0)
  From Production_Starts
  Where (Start_Id = @Start_Id)
If @PU_Id Is Null
  Select @Found = 0
