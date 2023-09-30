Create Procedure dbo.spRSQ_GetSummary
@PU_Id int,
@STime datetime,
@ETime datetime
AS
If @ETime is Null 
  Begin
    Select * From GB_RSum WITH (index(rsum_by_pu)) Where PU_Id = @PU_Id and Start_Time = @STime
  End
Else
  Begin
    Select * From GB_RSum Where PU_Id = @PU_Id and End_Time = @ETime
  End
