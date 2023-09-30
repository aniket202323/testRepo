CREATE PROCEDURE dbo.spServer_CmnGetEventProduct
@Event_Id int,
@ProdId int OUTPUT,
@PUId int OUTPUT
AS
set @ProdId = -1
set @PUId = -1
Select @PUId = e.PU_Id, @ProdId = COALESCE(e.Applied_Product, s.Prod_Id)
  From Events e WITH (NOLOCK)
  join Production_Starts s WITH (NOLOCK) on s.PU_Id = e.PU_Id and e.TimeStamp >= s.Start_Time and (s.End_Time is null or s.End_Time > e.TimeStamp)
  Where (Event_Id = @Event_Id)
