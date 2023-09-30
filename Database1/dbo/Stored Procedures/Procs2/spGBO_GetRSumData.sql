Create Procedure dbo.spGBO_GetRSumData 
@RSum_Id int     
AS
  select * from gb_rsum 
    where rsum_id = @Rsum_Id
  select * from gb_rsum_data
    where rsum_id = @RSum_Id
