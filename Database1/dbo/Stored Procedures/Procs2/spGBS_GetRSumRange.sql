Create Procedure dbo.spGBS_GetRSumRange
@PU_Id int,
@Prod_Id int,
@StartTime datetime,
@EndTime datetime,
@MaxNumber int       
AS
If @MaxNumber > 5 
  Select @MaxNumber = 5
If @MaxNumber = 1
  Set Rowcount 1
Else If @MaxNumber = 2
  Set Rowcount 2
Else If @MaxNumber = 3
  Set Rowcount 3
Else If @MaxNumber = 4
  Set Rowcount 4
Else If @MaxNumber = 5
  Set Rowcount 5
Select rsum_id 
  from gb_rsum 
  where PU_Id = @PU_Id and
        Start_Time Between @StartTime and @EndTime and
        Prod_Id = @Prod_Id
 Order by Start_Time desc
Set Rowcount 0
