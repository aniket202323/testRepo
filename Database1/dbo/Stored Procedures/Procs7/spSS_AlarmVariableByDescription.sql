Create Procedure dbo.spSS_AlarmVariableByDescription
 @Desc nVarChar(50),
 @SheetId int = Null
AS
---------------------------------------------------------
--
---------------------------------------------------------
If (@SheetId=0) Or (@SheetId Is Null)
 Select Var_Id, Var_Desc
  From Variables
   Where Var_Desc Like '%' + @Desc + '%'
    And PU_ID <> 0
    Order by Var_Desc
Else
 Select V.Var_Id, V.Var_Desc
  From Variables V
   Inner Join Sheet_Variables S
    On V.Var_Id = S.Var_Id
     Where V.Var_Desc Like '%' + @Desc + '%'
      And V.PU_ID <> 0
      And S.Sheet_Id = @SheetId
       Order by V.Var_Desc
