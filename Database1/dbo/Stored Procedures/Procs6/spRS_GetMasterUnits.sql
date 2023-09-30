CREATE PROCEDURE dbo.spRS_GetMasterUnits
@Prod_Line int = Null
AS
If @Prod_Line Is Null
  Begin
    Select PU_Id, PU_Desc
    From Prod_Units
    Where Master_Unit is null
    And PU_Id <> 0
    Order By PU_Desc
  End
Else
  Begin
    Select PU_Id, PU_Desc
    From Prod_Units
    Where Master_Unit is null
    And PU_Id <> 0
    And PL_Id = @Prod_Line
    Order By PU_Desc
  End
