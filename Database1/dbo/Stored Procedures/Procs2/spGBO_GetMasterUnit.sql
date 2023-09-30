Create Procedure dbo.spGBO_GetMasterUnit
@PU_Id int,
@Master_Id int OUTPUT     
AS
  select @Master_Id = null
  Select @Master_Id = master_unit from 
    prod_units where pu_id = @PU_Id
  if @Master_Id is null
    begin 
       select @Master_Id = @PU_Id
       return(100)
    end
  else
   begin
      return(100)
   end
