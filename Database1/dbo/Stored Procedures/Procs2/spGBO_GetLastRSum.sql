Create Procedure dbo.spGBO_GetLastRSum
@PU_Id int,
@Prod_Id int,
@Start_Time datetime,
@RSum_Id int OUTPUT     
AS
  Select @RSum_Id = rsum_id 
    from gb_rsum 
    where (start_time = 
               (select max(start_time) 
                  from gb_rsum 
                  where (pu_id = @PU_Id) and 
                        (prod_id = @Prod_Id) and 
                        (start_time <= @Start_Time) and 
                        (rsum_id <> @RSum_Id))) and
          (pu_id = @PU_Id) and 
          (prod_id = @Prod_Id) and 
          (start_time <= @Start_Time) and 
          (rsum_id <> @RSum_Id)
  if @RSum_Id is null
    return(1)
  else 
    return(100)
