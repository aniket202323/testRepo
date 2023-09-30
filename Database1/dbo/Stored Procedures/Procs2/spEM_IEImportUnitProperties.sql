CREATE PROCEDURE dbo.spEM_IEImportUnitProperties
@PLDesc 	  	  	  	 nVarChar(100),
@PUDesc 	  	  	  	 nVarChar(100),
@DeleteChildEvents 	 nVarChar(100),
@UnitType 	  	  	 nVarChar(100),
@EquipmentType 	  	 nVarChar(100),
@DefDisplay 	  	  	 nVarChar(100),
@DefPath 	  	  	 nVarChar(100),
@DwnUnavCat 	  	  	 nVarChar(100),
@DwnExtCat 	  	  	 nVarChar(100),
@DwnPropSpec 	  	 nVarChar(100),
@DwnCalcInt 	  	  	 nVarChar(100),
@DwnCalcWin 	  	  	 nVarChar(100),
@EffLine 	  	  	 nVarChar(100),
@EffUnit 	  	  	 nVarChar(100),
@EffVar 	  	  	  	 nVarChar(100),
@EffPropSpec 	  	 nVarChar(100),
@EffCalcInt 	  	  	 nVarChar(100),
@EffCalcWin 	  	  	 nVarChar(100),
@ProdLine 	  	  	 nVarChar(100),
@ProdUnit 	  	  	 nVarChar(100),
@ProdVar 	  	  	 nVarChar(100),
@ProdDwnCat 	  	  	 nVarChar(100),
@ProdPropSpec 	  	 nVarChar(100),
@ProdRateUnit 	  	 nVarChar(100),
@ProdCalcInt 	  	 nVarChar(100),
@ProdCalcWin 	  	 nVarChar(100),
@WstPropSpec 	  	 nVarChar(100),
@WstCalcInt 	  	  	 nVarChar(100),
@WstCalcWin 	  	  	 nVarChar(100),
@NptCat 	  	  	  	 nVarChar(100),
@NptTree 	  	  	 nVarChar(100),
@ChainST 	  	  	 nVarChar(100),
@DTAssoc 	  	  	 nVarChar(100),
@WTAssoc 	  	  	 nVarChar(100),
@UseST 	  	  	  	 nVarChar(100),
@User_Id 	  	  	 Int
AS
/* Clean Arguments */
Select @PLDesc = RTrim(LTrim(@PLDesc))
Select @PUDesc = RTrim(LTrim(@PUDesc))
Select @UnitType = LTrim(RTrim(@UnitType))
Select @EquipmentType = LTrim(RTrim(@EquipmentType))
Select @DefDisplay = LTrim(RTrim(@DefDisplay))
Select @DefPath = LTrim(RTrim(@DefPath))
Select @DwnUnavCat = LTrim(RTrim(@DwnUnavCat))
Select @DwnExtCat = LTrim(RTrim(@DwnExtCat))
Select @DwnPropSpec = LTrim(RTrim(@DwnPropSpec))
Select @DwnCalcInt = LTrim(RTrim(@DwnCalcInt))
Select @DwnCalcWin = LTrim(RTrim(@DwnCalcWin))
Select @EffLine = LTrim(RTrim(@EffLine))
Select @EffUnit = LTrim(RTrim(@EffUnit))
Select @EffVar = LTrim(RTrim(@EffVar))
Select @EffPropSpec = LTrim(RTrim(@EffPropSpec))
Select @EffCalcInt = LTrim(RTrim(@EffCalcInt))
Select @EffCalcWin = LTrim(RTrim(@EffCalcWin))
Select @ProdLine = LTrim(RTrim(@ProdLine))
Select @ProdUnit = LTrim(RTrim(@ProdUnit))
Select @ProdVar = LTrim(RTrim(@ProdVar))
Select @ProdDwnCat = LTrim(RTrim(@ProdDwnCat))
Select @ProdPropSpec = LTrim(RTrim(@ProdPropSpec))
Select @ProdRateUnit = LTrim(RTrim(@ProdRateUnit))
Select @ProdCalcInt = LTrim(RTrim(@ProdCalcInt))
Select @ProdCalcWin = LTrim(RTrim(@ProdCalcWin))
Select @WstPropSpec = LTrim(RTrim(@WstPropSpec))
Select @WstCalcInt = LTrim(RTrim(@WstCalcInt))
Select @WstCalcWin = LTrim(RTrim(@WstCalcWin))
Select @NptCat = LTrim(RTrim(@NptCat))
Select @NptTree = LTrim(RTrim(@NptTree))
Select @DeleteChildEvents = LTrim(RTrim(@DeleteChildEvents))
Select @ChainST = LTrim(RTrim(@ChainST))
Select @WTAssoc = LTrim(RTrim(@WTAssoc))
Select @DTAssoc = LTrim(RTrim(@DTAssoc))
Select @UseST = LTrim(RTrim(@UseST))
If @PLDesc = ''  	 Select @PLDesc = Null 
If @PUDesc = ''  	 Select @PUDesc = Null 
If @UnitType = ''  	 Select @UnitType = Null 
If @EquipmentType = ''  	 Select @EquipmentType = Null 
If @DefDisplay = ''  	 Select @DefDisplay = Null 
If @DefPath = ''  	 Select @DefPath = Null 
If @DwnUnavCat = ''  	 Select @DwnUnavCat = Null 
If @DwnExtCat = ''  	 Select @DwnExtCat = Null 
If @DwnPropSpec = ''  	 Select @DwnPropSpec = Null 
If @DwnCalcInt = ''  	 Select @DwnCalcInt = Null 
If @DwnCalcWin = ''  	 Select @DwnCalcWin = Null 
If @EffLine = '' 	 Select @EffLine = Null 
If @EffUnit = ''  	 Select @EffUnit = Null 
If @EffVar = ''  	 Select @EffVar = Null 
If @EffPropSpec = ''  	 Select @EffPropSpec = Null 
If @EffCalcInt = ''  	 Select @EffCalcInt = Null 
If @EffCalcWin = ''  	 Select @EffCalcWin = Null 
If @ProdLine = ''  	 Select @ProdLine = Null 
If @ProdUnit = ''  	 Select @ProdUnit = Null 
If @ProdVar = ''  	 Select @ProdVar = Null 
If @ProdDwnCat = ''  	 Select @ProdDwnCat = Null 
If @ProdPropSpec = ''  	 Select @ProdPropSpec = Null 
If @ProdRateUnit = ''  	 Select @ProdRateUnit = Null 
If @ProdCalcInt = ''  	 Select @ProdCalcInt = Null 
If @ProdCalcWin = ''  	 Select @ProdCalcWin = Null 
If @WstPropSpec = '' 	 Select @WstPropSpec = Null 
If @WstCalcInt = ''  	 Select @WstCalcInt = Null 
If @WstCalcWin = ''  	 Select @WstCalcWin = Null 
If @NptCat = ''  	 Select @NptCat = Null 
If @NptTree = ''  	 Select @NptTree = Null 
If @DeleteChildEvents = '' Select @DeleteChildEvents = Null
If @ChainST = ''  	 Select @ChainST =Null
If @WTAssoc = '' 	 Select @WTAssoc = Null
If @DTAssoc = '' 	 Select @DTAssoc = Null
If @UseST = '' 	  	 Select @UseST = Null
Declare @PL_Id 	  	 int,
 	 @Dept_Id 	 int,
 	 @GroupId 	 int,
 	 @PUId 	  	 Int,
 	 @IStartT 	 Int,
 	 @iUnitType 	 Int,
 	 @iDefDisplay 	 Int,
 	 @iDefPath 	 Int,
 	 @iDwnUnavCat 	 Int,
 	 @iDwnExtCat 	 Int,
 	 @iDwnPropSpec 	 Int,
 	 @iDwnCalcInt 	 Int,
 	 @iDwnCalcWin 	 Int,
 	 @iEffLine 	 Int,
 	 @iEffUnit 	 Int,
 	 @iEffVar 	 Int,
 	 @iEffPropSpec 	 Int,
 	 @iEffCalcInt 	 Int,
 	 @iEffCalcWin 	 Int,
 	 @iProdLine 	 Int,
 	 @iProdUnit 	 Int,
 	 @iProdVar 	 Int,
 	 @iProdDwnCat 	 Int,
 	 @iProdPropSpec 	 Int,
 	 @iProdRateUnit 	 Int,
 	 @iProdCalcInt 	 Int,
 	 @iProdCalcWin 	 Int,
 	 @iWstPropSpec 	 Int,
 	 @iWstCalcInt 	 Int,
 	 @iWstCalcWin 	 Int,
 	 @iNptCat 	 Int,
 	 @iNptTree 	 Int,
 	 @Index 	  	 Int,
    @PropDesc 	 nvarchar(50),
 	 @PropId 	  	 Int,
 	 @iProdVarACCUM 	 Int,
 	 @iDeleteChildEvents 	 Int,
 	 @EffCalcType 	 Int,
 	 @iChainST 	 Int,
 	 @iDTAssoc 	 Int,
 	 @iWTAssoc 	 Int,
 	 @iCalcPUGId 	 Int,
 	 @MaxPUGOrder 	 INT,
 	 @EffCalcId 	  	 Int,
 	 @VarId 	  	  	 INT,
 	 @ATID 	  	  	 INT,
 	 @iUseStartTime 	 Int
DECLARE @PrevWstCalc Int,
 	  	 @PrevDwnCalc Int,
 	  	 @PrevEffCalc Int,
 	  	 @PrevProdCalc Int
If  @PLDesc IS NULL
BEGIN
       Select  'Production Line Not Found'
       Return(-100)
END
Select @PL_Id = PL_Id From Prod_Lines Where PL_Desc = @PLDesc
If @PL_Id Is Null
BEGIN
 	 Select 'Failed - Error Finding Line'
 	 Return(-100)
END
If @PUDesc IS NULL 
BEGIN
      Select  'Production Unit Not Found'
      Return(-100)
END
Select @PUId = PU_Id from Prod_Units  	 Where PU_Desc = @PUDesc  and PL_Id = @PL_Id
If @PUId IS NULL
BEGIN
 	 Select 'Failed - error finding unit'
 	 Return(-100)
END
Select @iDeleteChildEvents = 0
If @DeleteChildEvents Is Not Null
BEGIN
 	 If isnumeric(@DeleteChildEvents) = 0
 	 BEGIN
 	  	 Select 'Failed - delete child event is not correct '
 	  	 Return(-100)
 	 END 
 	 SELECT  @iDeleteChildEvents = Convert(Int,@DeleteChildEvents)
END
Select @iUseStartTime = 0
If @UseST Is Not Null
BEGIN
 	 If isnumeric(@UseST) = 0
 	 BEGIN
 	  	 Select 'Failed - delete child event is not correct '
 	  	 Return(-100)
 	 END 
 	 SELECT  @iUseStartTime = Convert(Int,@UseST)
END
If @ChainST Is Not Null
BEGIN
 	 If isnumeric(@ChainST) = 0
 	 BEGIN
 	  	 Select 'Failed - chain start time is not correct '
 	  	 Return(-100)
 	 END 
  	 SELECT  @iChainST = Convert(Int,@ChainST)
END
If @DTAssoc Is Not Null
BEGIN
 	 If isnumeric(@DTAssoc) = 0
 	 BEGIN
 	  	 Select 'Failed - downtime association is not correct '
 	  	 Return(-100)
 	 END 
  	 SELECT  @iDTAssoc = Convert(Int,@DTAssoc)
END
If @WTAssoc Is Not Null
BEGIN
 	 SELECT @iWTAssoc = Case When @WTAssoc = 'Event Based' Then 1
 	  	  	  	 When @WTAssoc = 'Time Based' Then 2
 	  	  	  	 ELSE Null
 	  	  	  	 END
 	 If @iWTAssoc Is Null
 	 BEGIN
 	  	 Select 'Failed - waste association is not correct '
 	  	 Return(-100)
 	 END 
 	 
END
If @UnitType Is not Null
BEGIN
 	 SELECT @iUnitType = Unit_Type_Id FROM Unit_Types WHERE UT_Desc = @UnitType
 	 IF @iUnitType Is Null
 	 BEGIN
 	  	 Select 'Failed - unit type not found'
 	  	 Return (-100)
 	 END
END
If @DefDisplay Is not Null
BEGIN
 	 SELECT @iDefDisplay = Sheet_Id FROM Sheets WHERE Sheet_Desc = @DefDisplay
 	 IF @iDefDisplay Is Null
 	 BEGIN
 	  	 Select 'Failed - display not found'
 	  	 Return (-100)
 	 END
END
If @DefPath Is not Null
BEGIN
 	 SELECT @iDefPath = Path_Id FROM PrdExec_Paths WHERE Path_Code = @DefPath
 	 IF @iDefPath Is Null
 	 BEGIN
 	  	 Select 'Failed - default path not found'
 	  	 Return (-100)
 	 END
END
If @DwnUnavCat Is not Null
BEGIN
 	 SELECT @iDwnUnavCat = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @DwnUnavCat
 	 IF @iDwnUnavCat Is Null
 	 BEGIN
 	  	 Select 'Failed - downtime unavailable category not found'
 	  	 Return (-100)
 	 END
END
If @DwnExtCat Is not Null
BEGIN
 	 SELECT @iDwnExtCat = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @DwnExtCat
 	 IF @iDwnExtCat Is Null
 	 BEGIN
 	  	 Select 'Failed - downtime external category not found'
 	  	 Return (-100)
 	 END
END
If @DwnPropSpec Is not Null
BEGIN
 	 Select @Index = CharIndex('/', @DwnPropSpec)
 	 If @Index > 0
 	 BEGIN
 	  	 Select @PropDesc = Left(@DwnPropSpec, CharIndex('/', @DwnPropSpec)-1)
 	  	 Select @DwnPropSpec = Right(@DwnPropSpec, Len(@DwnPropSpec)- CharIndex('/', @DwnPropSpec))
 	  	 
 	  	 Select @PropId = Prop_Id
 	  	 From Product_Properties
 	  	 Where Prop_Desc = RTrim(LTrim(@PropDesc))
 	  	 
 	  	 Select @iDwnPropSpec = Spec_Id
 	  	 From Specifications
 	  	 Where Prop_Id = @PropId And Spec_Desc = RTrim(LTrim(@DwnPropSpec))
 	  	 
 	  	 If @iDwnPropSpec Is Null
 	  	 BEGIN
 	  	  	 Select 'Failed - invalid downtime specification variable'
 	  	  	 Return(-100) 
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select 'Failed - invalid downtime property/specification variable'
 	  	 Return(-100) 
 	 END
END
If @DwnCalcInt Is not Null
BEGIN
 	 IF isnumeric(@DwnCalcInt) = 0
 	 BEGIN
 	  	 Select 'Failed - downtime interval not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iDwnCalcInt = Convert(int,@DwnCalcInt)
 	 If not (@iDwnCalcInt Between 1 and 1440) 	 
 	 BEGIN
 	  	 Select 'Failed - downtime interval not correct (1 -1440)'
 	  	 Return (-100)
 	 END
 	 
END
If @DwnCalcWin Is not Null
BEGIN
 	 IF isnumeric(@DwnCalcWin) = 0
 	 BEGIN
 	  	 Select 'Failed - downtime window not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iDwnCalcWin = Convert(int,@DwnCalcWin)
 	 If not (@iDwnCalcWin Between @iDwnCalcInt and 44640) --31 days
 	 BEGIN
 	  	 Select 'Failed - downtime window not correct (interval - 44640)'
 	  	 Return (-100)
 	 END
 	 
END
Select @EffCalcType = 0
IF @EffVar Is Not NULL
BEGIN
 	 Select @iEffLine = PL_Id From Prod_Lines Where PL_Desc = @EffLine
 	 If @iEffLine is Null
 	 Begin
 	    Select 'Failed - efficiency production line not found'
 	    Return (-100)
 	 End
     /* Get  PU_Id  */
   Select @iEffUnit = PU_Id From Prod_Units Where PU_Desc = @EffUnit And PL_Id = @iEffLine
   If @iEffUnit Is Null
     Begin
 	    Select 'Failed - efficiency production unit not found'
 	    Return (-100)
 	  End
          /* Get  Var_Id  */
   Select @iEffVar = Var_Id From Variables
 	  Where Var_Desc = @EffVar And PU_Id = @iEffUnit
   If @iEffVar Is Null
 	  Begin
 	    Select 'Failed -  Efficency Variable not found'
 	    Return (-100)
 	  End
 	 Select @EffCalcType = 1
END
If @EffPropSpec Is not Null
BEGIN
 	 Select @Index = CharIndex('/', @EffPropSpec)
 	 If @Index > 0
 	 BEGIN
 	  	 Select @PropDesc = Null,@PropId = Null
 	  	 Select @PropDesc = Left(@EffPropSpec, CharIndex('/', @EffPropSpec)-1)
 	  	 Select @EffPropSpec = Right(@EffPropSpec, Len(@EffPropSpec)- CharIndex('/', @EffPropSpec))
 	  	 
 	  	 Select @PropId = Prop_Id
 	  	 From Product_Properties
 	  	 Where Prop_Desc = RTrim(LTrim(@PropDesc))
 	  	 
 	  	 Select @iEffPropSpec = Spec_Id
 	  	 From Specifications
 	  	 Where Prop_Id = @PropId And Spec_Desc = RTrim(LTrim(@EffPropSpec))
 	  	 
 	  	 If @iEffPropSpec Is Null
 	  	 BEGIN
 	  	  	 Select 'Failed - invalid efficiency specification variable'
 	  	  	 Return(-100) 
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select 'Failed - invalid efficiency property/specification variable'
 	  	 Return(-100) 
 	 END
END
If @EffCalcInt Is not Null
BEGIN
 	 IF isnumeric(@EffCalcInt) = 0
 	 BEGIN
 	  	 Select 'Failed - efficiency interval not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iEffCalcInt = Convert(int,@EffCalcInt)
 	 If not (@iEffCalcInt Between 1 and 1440) 	 
 	 BEGIN
 	  	 Select 'Failed - efficiency interval not correct (1 -1440)'
 	  	 Return (-100)
 	 END
 	 
END
If @EffCalcWin Is not Null
BEGIN
 	 IF isnumeric(@EffCalcWin) = 0
 	 BEGIN
 	  	 Select 'Failed - efficiency window not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iEffCalcWin = Convert(int,@EffCalcWin)
 	 If not (@iEffCalcWin Between @iEffCalcInt and 44640) --31 days
 	 BEGIN
 	  	 Select 'Failed - efficiency window not correct (interval - 44640)'
 	  	 Return (-100)
 	 END
 	 
END
Select @iProdVarACCUM = 0
IF @ProdVar Is Not NULL
BEGIN
 	 Select @iProdLine = PL_Id From Prod_Lines Where PL_Desc = @ProdLine
 	 If @iProdLine is Null
 	 BEGIN
 	  	 Select 'Failed - Production production line not found'
 	  	 Return (-100)
 	 END
 	 /* Get  PU_Id  */
 	 Select @iProdUnit = PU_Id From Prod_Units Where PU_Desc = @ProdUnit And PL_Id = @iProdLine
 	 If @iProdUnit Is Null
 	 BEGIN
 	  	 Select 'Failed - Production production unit not found'
 	  	 Return (-100)
 	 END
          /* Get  Var_Id  */
 	 Select @iProdVar = Var_Id From Variables Where Var_Desc = @ProdVar And PU_Id = @iProdUnit
 	 If @iProdVar Is Null
 	 BEGIN
 	  	 Select 'Failed -  Production Variable not found'
 	  	 Return (-100)
 	 END
 	 Select @iProdVarACCUM = 1
END
If @ProdDwnCat Is not Null
BEGIN
 	 SELECT @iProdDwnCat = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @ProdDwnCat
 	 IF @iProdDwnCat Is Null
 	 BEGIN
 	  	 Select 'Failed - Production downtime category not found'
 	  	 Return (-100)
 	 END
END
If @ProdPropSpec Is not Null
BEGIN
 	 Select @Index = CharIndex('/', @ProdPropSpec)
 	 If @Index > 0
 	 BEGIN
 	  	 Select @PropDesc = Null,@PropId = Null
 	  	 Select @PropDesc = Left(@ProdPropSpec, CharIndex('/', @ProdPropSpec)-1)
 	  	 Select @ProdPropSpec = Right(@ProdPropSpec, Len(@ProdPropSpec)- CharIndex('/', @ProdPropSpec))
 	  	 
 	  	 Select @PropId = Prop_Id
 	  	 From Product_Properties
 	  	 Where Prop_Desc = RTrim(LTrim(@PropDesc))
 	  	 
 	  	 Select @iProdPropSpec = Spec_Id
 	  	 From Specifications
 	  	 Where Prop_Id = @PropId And Spec_Desc = RTrim(LTrim(@ProdPropSpec))
 	  	 
 	  	 If @iProdPropSpec Is Null
 	  	 BEGIN
 	  	  	 Select 'Failed - invalid Production specification variable'
 	  	  	 Return(-100) 
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select 'Failed - invalid Production property/specification variable'
 	  	 Return(-100) 
 	 END
END
If @ProdRateUnit Is not Null
BEGIN
 	 Select @iProdRateUnit = Case When @ProdRateUnit = 'Hour' Then 0
 	  	  	  	  	 When @ProdRateUnit = 'Minute' Then 1
 	  	  	  	  	 When @ProdRateUnit = 'Second' Then 2
 	  	  	  	  	 When @ProdRateUnit = 'Day' Then 3
 	  	  	  	  	 ELSE Null
 	  	  	  	 END
END
If @ProdCalcInt Is not Null
BEGIN
 	 IF isnumeric(@ProdCalcInt) = 0
 	 BEGIN
 	  	 Select 'Failed - Production interval not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iProdCalcInt = Convert(int,@ProdCalcInt)
 	 If not (@iProdCalcInt Between 1 and 1440) 	 
 	 BEGIN
 	  	 Select 'Failed - Production interval not correct (1 -1440)'
 	  	 Return (-100)
 	 END
 	 
END
If @ProdCalcWin Is not Null
BEGIN
 	 IF isnumeric(@ProdCalcWin) = 0
 	 BEGIN
 	  	 Select 'Failed - Production window not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iProdCalcWin = Convert(int,@ProdCalcWin)
 	 If not (@iProdCalcWin Between @iProdCalcInt and 44640) --31 days
 	 BEGIN
 	  	 Select 'Failed - Production window not correct (interval - 44640)'
 	  	 Return (-100)
 	 END
 	 
END
If @WstPropSpec Is not Null
BEGIN
 	 Select @Index = CharIndex('/', @WstPropSpec)
 	 If @Index > 0
 	 BEGIN
 	  	 Select @PropDesc = Null,@PropId = Null
 	  	 Select @PropDesc = Left(@WstPropSpec, CharIndex('/', @WstPropSpec)-1)
 	  	 Select @WstPropSpec = Right(@WstPropSpec, Len(@WstPropSpec)- CharIndex('/', @WstPropSpec))
 	  	 
 	  	 Select @PropId = Prop_Id
 	  	 From Product_Properties
 	  	 Where Prop_Desc = RTrim(LTrim(@PropDesc))
 	  	 
 	  	 Select @iWstPropSpec = Spec_Id
 	  	 From Specifications
 	  	 Where Prop_Id = @PropId And Spec_Desc = RTrim(LTrim(@WstPropSpec))
 	  	 
 	  	 If @iWstPropSpec Is Null
 	  	 BEGIN
 	  	  	 Select 'Failed - invalid waste specification variable'
 	  	  	 Return(-100) 
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select 'Failed - invalid waste property/specification variable'
 	  	 Return(-100) 
 	 END
END
If @WstCalcInt Is not Null
BEGIN
 	 IF isnumeric(@WstCalcInt) = 0
 	 BEGIN
 	  	 Select 'Failed - Production interval not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iWstCalcInt = Convert(int,@WstCalcInt)
 	 If not (@iWstCalcInt Between 1 and 1440) 	 
 	 BEGIN
 	  	 Select 'Failed - Production interval not correct (1 -1440)'
 	  	 Return (-100)
 	 END
 	 
END
If @WstCalcWin Is not Null
BEGIN
 	 IF isnumeric(@WstCalcWin) = 0
 	 BEGIN
 	  	 Select 'Failed - Waste window not correct'
 	  	 Return (-100)
 	 END
 	 SELECT @iWstCalcWin = Convert(int,@WstCalcWin)
 	 If not (@iWstCalcWin Between @iWstCalcInt and 44640) --31 days
 	 BEGIN
 	  	 Select 'Failed - Waste window not correct (interval - 44640)'
 	  	 Return (-100)
 	 END
END
If @NptCat Is not Null
BEGIN
 	 SELECT @iNptCat = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @NptCat
 	 IF @iNptCat Is Null
 	 BEGIN
 	  	 Select 'Failed - Non Productive category not found'
 	  	 Return (-100)
 	 END
END
If @NptTree Is not Null
BEGIN
 	 SELECT @iNptTree = Tree_Name_Id FROM Event_reason_Tree WHERE Tree_Name = @NptTree
 	 IF @iNptTree Is Null
 	 BEGIN
 	  	 Select 'Failed - Non Productive category not found'
 	  	 Return (-100)
 	 END
END
Declare @Extended_Info nvarchar(255),@External_Link nvarchar(255)
Select @Extended_Info = Extended_Info,@External_Link = External_Link From Prod_Units where PU_Id = @PUId
EXECUTE spEMUP_PutUnitProperties 1,@PUId,@Extended_Info,@External_Link,@iUnitType,@EquipmentType,@iDefDisplay,@iProdVarACCUM,@iProdVar,@iProdRateUnit,
 	 @iProdPropSpec,@iProdCalcInt,@iProdCalcWin,@iWstPropSpec,@iWstCalcInt,@iWstCalcWin,@iDwnUnavCat,@iDwnExtCat,@iDwnPropSpec,@iDwnCalcInt,
 	 @iDwnCalcWin,@EffCalcType,@iEffVar,@iEffPropSpec,@iEffCalcInt,@iEffCalcWin,@iDeleteChildEvents,@User_Id,@iProdDwnCat,Null,@iNptCat,@iNptTree,@iDefPath
EXECUTE spEMUP_PutUnitProperties 3,@PUId,@Extended_Info,@External_Link,@iUnitType,@EquipmentType,@iDefDisplay,@iProdVarACCUM,@iProdVar,@iProdRateUnit,
 	 @iProdPropSpec,@iProdCalcInt,@iProdCalcWin,@iWstPropSpec,@iWstCalcInt,@iWstCalcWin,@iDwnUnavCat,@iDwnExtCat,@iDwnPropSpec,@iDwnCalcInt,
 	 @iDwnCalcWin,@EffCalcType,@iEffVar,@iEffPropSpec,@iEffCalcInt,@iEffCalcWin,@iDeleteChildEvents,@User_Id,@iProdDwnCat,Null,@iNptCat,@iNptTree,@iDefPath
EXECUTE spEMEC_DTAssociation @PUId,2,@iDTAssoc,@User_Id
EXECUTE spEMEC_DTAssociation @PUId,3,@iWTAssoc,@User_Id
EXECUTE spEMEC_UsesStartTime @PUId,@User_Id,@iUseStartTime,@iChainST
SET NOCOUNT ON
IF (@iProdCalcInt Is Not Null) or (@iWstCalcInt Is Not Null) or (@iDwnCalcInt Is Not Null) or (@iEffCalcInt Is Not Null)
BEGIN
 	 SELECT @iCalcPUGId = PUG_Id 
 	  	 FROM PU_Groups 
 	  	 WHERE PUG_Desc = 'Production Metric Variables' AND PU_Id = @PUId
 	 IF @iCalcPUGId Is NULL
 	 BEGIN
 	  	 SELECT @MaxPUGOrder = Max(PUG_Order) FROM PU_Groups WHERE PU_Id = @PUId
 	  	 SELECT @MaxPUGOrder = IsNull(@MaxPUGOrder,0)
 	  	 SELECT @MaxPUGOrder = @MaxPUGOrder + 1
 	  	 EXECUTE spEM_CreatePUG 'Production Metric Variables', @PUId,@MaxPUGOrder , @User_Id, @iCalcPUGId Output
 	 END
 	 SELECT @ATID = AT_ID FROM Alarm_Templates WHERE AT_Desc = 'Production Metrics'
END
SELECT  @PrevProdCalc = Var_Id 
 	 FROM Variables
 	 WHERE PU_Id =  @PUId AND  Var_Desc = 'Production Metrics - Production Rate' 
IF @iProdCalcInt Is Not Null and @PrevProdCalc IS Null
BEGIN
 	 SELECT @VarId = Null
 	 Select @EffCalcId = Null
 	 Select @EffCalcId = Calculation_Id FROM Calculations Where Calculation_Desc = 'MSI_Calc_Production'
 	 EXECUTE spEM_CreateVariable 'Production Metrics - Production Rate',@PUId,@iCalcPUGId,-2,@User_Id,@VarId  OUTPUT
 	 EXECUTE spEM_UpdateVariable @VarId,@iProdCalcInt,@iProdCalcWin,@iProdPropSpec,1,@User_Id
 	 EXECUTE spEMAC_AddAttachedVariables @ATID,@VarId,Null,@User_Id
   	 UPDATE Variables_Base set calculation_id = @EffCalcId, DS_Id = 16 WHERE var_id = @VarId 
END
IF @iProdCalcInt Is Null and @PrevProdCalc IS Not Null
BEGIN
 	 EXECUTE spEMAC_DeleteAttachedVariables @ATID,@PrevProdCalc,@User_Id
 	 EXECUTE spEM_DropVariable @PrevProdCalc,@User_Id 
END
IF @iProdCalcInt Is Not Null and @PrevProdCalc IS Not Null
BEGIN
 	 EXECUTE spEM_UpdateVariable @PrevProdCalc,@iProdCalcInt,@iProdCalcWin,@iProdPropSpec, 1,@User_Id
END
SELECT  @PrevWstCalc = Var_Id 
 	 FROM Variables
 	 WHERE PU_Id =  @PUId AND  Var_Desc = 'Production Metrics - Waste' 
IF @iWstCalcInt Is Not Null And @PrevWstCalc Is NULL
BEGIN
 	 SELECT @VarId = Null
 	 Select @EffCalcId = Null
 	 Select @EffCalcId = Calculation_Id FROM Calculations Where Calculation_Desc = 'MSI_Calc_Waste'
 	 EXECUTE spEM_CreateVariable 'Production Metrics - Waste',@PUId,@iCalcPUGId,-2,@User_Id,@VarId  OUTPUT
 	 EXECUTE spEM_UpdateVariable @VarId,@iWstCalcInt,@iWstCalcWin,@iWstPropSpec,1,@User_Id
 	 EXECUTE spEMAC_AddAttachedVariables @ATID,@VarId,Null,@User_Id
   	 UPDATE Variables_Base set calculation_id = @EffCalcId, DS_Id = 16 WHERE var_id = @VarId 
END
IF @iWstCalcInt Is Null and @PrevWstCalc IS Not Null
BEGIN
 	 EXECUTE spEMAC_DeleteAttachedVariables @ATID,@PrevWstCalc,@User_Id
 	 EXECUTE spEM_DropVariable @PrevWstCalc,@User_Id 
END
IF @iWstCalcInt Is Not Null and @PrevWstCalc IS Not Null
BEGIN
 	 EXECUTE spEM_UpdateVariable @PrevWstCalc,@iWstCalcInt,@iWstCalcWin,@iWstPropSpec, 1,@User_Id
END
SELECT  @PrevDwnCalc = Var_Id  
 	 FROM Variables
 	 WHERE PU_Id =  @PUId AND  Var_Desc = 'Production Metrics - Downtime' 
IF @iDwnCalcInt Is Not Null And @PrevDwnCalc Is NULL
BEGIN
 	 SELECT @VarId = Null
 	 Select @EffCalcId = Null
 	 Select @EffCalcId = Calculation_Id FROM Calculations Where Calculation_Desc = 'MSI_Calc_Downtime'
 	 EXECUTE spEM_CreateVariable 'Production Metrics - Downtime',@PUId,@iCalcPUGId,-2,@User_Id,@VarId  OUTPUT
 	 EXECUTE spEM_UpdateVariable @VarId,@iDwnCalcInt,@iDwnCalcWin,@iDwnPropSpec,1,@User_Id
 	 EXECUTE spEMAC_AddAttachedVariables @ATID,@VarId,Null,@User_Id
   	 UPDATE Variables_Base set calculation_id = @EffCalcId, DS_Id = 16 WHERE var_id = @VarId 
END
IF @iDwnCalcInt Is Null and @PrevDwnCalc IS Not Null
BEGIN
 	 EXECUTE spEMAC_DeleteAttachedVariables @ATID,@PrevDwnCalc,@User_Id
 	 EXECUTE spEM_DropVariable @PrevDwnCalc,@User_Id 
END
IF @iDwnCalcInt Is Not Null and @PrevDwnCalc IS Not Null
BEGIN
 	 EXECUTE spEM_UpdateVariable @PrevDwnCalc,@iDwnCalcInt,@iDwnCalcWin,@iDwnPropSpec, 1,@User_Id
END
SELECT  @PrevEffCalc = Var_Id  
 	 FROM Variables
 	 WHERE PU_Id =  @PUId AND  Var_Desc = 'Production Metrics - Efficiency' 
IF @iEffCalcInt Is Not Null And @PrevEffCalc Is NULL
BEGIN
 	 SELECT @VarId = Null
 	 Select @EffCalcId = Null
 	 Select @EffCalcId = Calculation_Id FROM Calculations Where Calculation_Desc = 'MSI_Calc_Efficiency'
 	 EXECUTE spEM_CreateVariable 'Production Metrics - Efficiency',@PUId,@iCalcPUGId,-2,@User_Id,@VarId  OUTPUT
 	 EXECUTE spEM_UpdateVariable @VarId,@iEffCalcInt,@iEffCalcWin,@iEffPropSpec,1,@User_Id
 	 EXECUTE spEMAC_AddAttachedVariables @ATID,@VarId,Null,@User_Id
  	 UPDATE Variables_Base set calculation_id = @EffCalcId, DS_Id = 16 WHERE var_id = @VarId 
END
IF @iEffCalcInt Is Null and @PrevEffCalc IS Not Null
BEGIN
 	 EXECUTE spEMAC_DeleteAttachedVariables @ATID,@PrevEffCalc,@User_Id
 	 EXECUTE spEM_DropVariable @PrevEffCalc,@User_Id 
END
IF @iEffCalcInt Is Not Null and @PrevEffCalc IS Not Null
BEGIN
 	 EXECUTE spEM_UpdateVariable @PrevEffCalc,@iEffCalcInt,@iEffCalcWin,@iEffPropSpec, 1,@User_Id
END
SET NOCOUNT OFF
