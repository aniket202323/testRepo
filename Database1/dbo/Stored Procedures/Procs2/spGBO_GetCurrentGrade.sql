Create Procedure dbo.spGBO_GetCurrentGrade
@UnitID int,
@Prod_Id int OUTPUT     
AS
  select @Prod_Id = null
  select @Prod_Id = Prod_Id 
    from production_starts
    where pu_id = @UnitID and
          end_time is null
  if @Prod_Id is null 
    return(1) 
  else
    return(100)
