CREATE PROCEDURE dbo.spRS_GetSlaveUnits
@ProdLine int = Null
 AS
If @ProdLine is null
  Begin
    Select PU_Id, PU_Desc
    From Prod_Units
    Where Master_Unit is null
    Order By PU_Desc
  End
Else
  Begin
    Select PU_Id, PU_Desc
    From Prod_Units
    Where Master_Unit = @ProdLine
    Or PU_Id = @ProdLine
    Order By PU_Desc
  End
