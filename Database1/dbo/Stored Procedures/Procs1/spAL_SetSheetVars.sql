Create Procedure dbo.spAL_SetSheetVars
  @SheetID int,
  @VarId int,
  @VarOrder int,
  @TransType tinyint, 
  @Title nvarchar(50)
AS
--TransType 1: Add Variable
--TransType 2. Delete Variable
--TransType 3: Update Variable Order
if @TransType = 1 
  begin
     insert into sheet_variables (Sheet_Id, Var_id, Var_Order, Title)
       values (@SheetID, @VarId, @VarOrder, @Title)
  end
else if @TransType = 2
  begin
     delete from sheet_variables
       where Sheet_Id = @SheetID and Var_Id = @VarId
  end
else
  begin
     update sheet_variables
       set Var_Order = @VarOrder
       where Sheet_Id = @SheetID and Var_Id = @VarId
  end
