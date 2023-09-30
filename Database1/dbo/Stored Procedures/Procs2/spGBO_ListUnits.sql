Create Procedure dbo.spGBO_ListUnits 
  @pl_id int,
  @master tinyint       AS
  if @pl_id <> 0
    begin
      if @Master = 1   
        select pu_id, pu_desc from prod_units
           where pl_id = @pl_id and   
                 master_unit is null and
                 pu_id > 0
      else
        select pu_id, pu_desc from prod_units 
           where pl_id = @pl_id and
                 pu_id > 0
    end
  else
   begin
      if @Master = 1 
        select pu_id, pu_desc from prod_units
           where master_unit is null and
                 pu_id > 0
      else
        select pu_id, pu_desc from prod_units
          where pu_id > 0 
   end
  return(100)
