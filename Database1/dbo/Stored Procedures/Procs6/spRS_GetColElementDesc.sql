CREATE PROCEDURE dbo.spRS_GetColElementDesc
@Element_Id int,
@Param_Name varchar(50),
@ReturnVal varchar(50) output
 AS
If (@Param_Name = 'Events') or (@Param_Name = 'Events1') or (@Param_Name = 'Events2') or (@Param_Name = 'Events3') or (@Param_Name = 'Events4')
  Begin
    Select @ReturnVal = Event_Num
    From Events
    Where Event_Id = @Element_Id
  End
If (@Param_Name = 'Products') or (@Param_Name = 'Products1') or (@Param_Name = 'Products2')
  Begin
    Select @ReturnVal =  Prod_Desc
    From Products
    Where Prod_Id = @Element_Id
  End
If (@Param_Name = 'Variables') or (@Param_Name = 'Variables1') or (@Param_Name = 'Variables2')
  Begin
    Select  @ReturnVal = Var_Desc
    From Variables
    Where Var_Id = @Element_Id
  End
If @Param_Name = 'Transactions'
  Begin
    Select  @ReturnVal = Trans_Desc
    From Transactions
    Where Trans_Id = @Element_Id
  End
If (@Param_Name = 'MasterUnit') or (@Param_Name = 'SlaveUnit') or (@Param_Name = 'ProductionUnit') or (@Param_Name = 'Units')
  Begin
    Select @ReturnVal = PU_Desc
    From Prod_Units
    Where PU_Id = @Element_Id
  End
If @Param_Name = 'ProductionLine'
  Begin
    Select @ReturnVal = PL_Desc
    From Prod_Lines
    Where PL_Id = @Element_Id
  End
If @Param_Name = 'PrintStyles'
  Begin
    Select @ReturnVal = Style_Name
    From Report_Print_Styles
    Where Style_Id = @Element_Id
  End
If @Param_Name = 'Printers'
  Begin
    Select @ReturnVal = Printer_Name
    From Report_Printers
    Where Printer_Id = @Element_Id
 	 If @ReturnVal Is Null
 	  	 Select @ReturnVal = 'Printer ' + convert(varchar(5), @Element_Id) + ' Removed From System'
  End
If @Param_Name = 'Printer'
  Begin
    Select @ReturnVal =  Printer_Name 
    From Report_Printers
    Where Printer_Id = @Element_Id
  End
If @Param_Name = 'Users' 
  Begin
    Select @ReturnVal = UserName
    From Users
    Where User_Id = @Element_Id
  End
