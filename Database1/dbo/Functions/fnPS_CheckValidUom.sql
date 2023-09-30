
CREATE FUNCTION  dbo.fnPS_CheckValidUom (@PU_Id Int)
  RETURNS Int
AS 
BEGIN 
    DECLARE @eng_Unit_Id Int;
	select @eng_Unit_Id = es.Dimension_X_Eng_Unit_Id
      from prod_units_base u
      join Event_Configuration ec on ec.PU_ID = u.PU_ID and ec.ET_Id = 1
      join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
where u.pu_id=@PU_ID;
RETURN @eng_Unit_Id;
	
END

