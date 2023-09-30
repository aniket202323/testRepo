Create Procedure dbo.spAL_LookupUnit
  @unit_id int,
  @unit_desc nvarchar(50) OUTPUT  AS
  SELECT @unit_desc = pu_desc
    FROM prod_units
    WHERE pu_id = @unit_id
  return(100)
