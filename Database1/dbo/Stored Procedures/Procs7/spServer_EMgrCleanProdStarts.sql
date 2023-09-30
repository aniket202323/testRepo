CREATE PROCEDURE dbo.spServer_EMgrCleanProdStarts
@PUId int,
@TimeStamp datetime
 AS
Declare
  @ProdId int,
  @StartTime datetime
Select @ProdId = NULL
Select @ProdId = Prod_Id, @StartTime = Start_Time From Production_Starts Where (PU_Id = @PUId) And (Start_Time < @TimeStamp) And ((End_Time >= @TimeStamp) Or (End_Time Is NULL))
If (@ProdId Is NULL)
  Return
Select Start_Id,Prod_Id = @ProdId,Start_Time From Production_Starts Where (PU_Id = @PUId) And (Start_Time > @StartTime) Order By Start_Time
