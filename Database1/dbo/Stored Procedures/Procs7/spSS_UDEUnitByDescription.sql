Create Procedure dbo.spSS_UDEUnitByDescription
 @Desc nVarChar(50),
 @PLId Integer = Null
AS
---------------------------------------------------------
--
---------------------------------------------------------
 If (@PLId = 0) Or (@PLId Is Null) 
  Begin
   Select PU_Id, PU_Desc
    From Prod_Units
     Where PU_Desc Like '%' + @Desc + '%' and PU_Id > 0
      Order by PU_Desc
  End
 Else
  Begin
   Select PU_Id, PU_Desc
    From Prod_Units
     Where PU_Desc Like '%' + @Desc + '%'  and PU_Id > 0
      And PL_Id = @PLId
       Order by PU_Desc
  End
