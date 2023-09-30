/* 
Execute spEM_IEImportProductionExecutionPath
'Paper Machine Line',
'Coater 1 Path',
'COATER1',
'0',
'1',
'Independently',
'Paper Machine Line',
'Coater 1',
'1',
'0',
'1',
'Coater Input',
'0',
'OEE Specs/Array Float',
'Data Type Testing/Array Int:001',
'0',
'1',
'Paper Machine Line',
'PM1 Dry End',
'Complete',
1
*/
CREATE PROCEDURE dbo.spEM_IEImportProductionExecutionPath
@PLDesc 	  	  	 nVarChar(100),
@PathDesc 	  	 nVarChar(100),
@PathCode 	  	 nVarChar(100),
@LineProd 	  	 nVarChar(100),
@CreateChild 	 nVarChar(100),
@SControlType 	 nVarChar(100),
@UnitPLDesc 	  	 nVarChar(100),--7
@UnitDesc 	  	 nVarChar(100),--8
@UnitOrder 	  	 nVarChar(100),--9
@ProdPoint 	  	 nVarChar(100),--10
@SchedPoint 	  	 nVarChar(100),--11
@InputName 	  	 nVarChar(100),--12
@AllowMovement 	 nVarChar(100),--13
@PSpec 	  	  	 nVarChar(100),--14
@ASpec 	  	  	 nVarChar(100),--15
@HideUnit 	  	 nVarChar(100),--16
@LockInprogress 	 nVarChar(100),--17
@InputLine 	  	 nVarChar(100),--18
@InputUnit 	  	 nVarChar(100),--19
@InputStatus 	 nVarChar(100),--20
@UserId 	  	 Int
AS
Declare @PathId 	 int,
 	  	 @PLId  	  	 Int,
 	  	 @Dept_Id 	 Int
DECLARE @PEIId 	  	  	  	  	 Integer,
 	  	 @PEPIId 	  	  	  	  	 Integer,
 	  	 @EsId 	  	  	  	  	 Integer,
 	  	 @PSpecId 	  	  	  	 Integer,
 	  	 @ASpecId 	  	  	  	 Integer,
 	  	 @bLockInput 	  	  	  	 Bit,
 	  	 @bHideInput 	  	  	  	 Bit,
 	  	 @bAllowManualMovement 	 Integer,
 	  	 @PropDesc 	  	  	  	 nvarchar(50),
 	  	 @PropId 	  	  	  	  	 Integer,
 	  	 @Index 	  	  	  	  	 Integer,
 	  	 @bSControlled 	  	  	 bit,
 	  	 @iSControlType 	  	  	 TinyInt,
 	  	 @bLineProd 	  	  	  	 Bit,
 	  	 @bCreateChild 	  	  	 Bit,
 	  	 @UpdateCheck 	  	  	 Integer
DECLARE @UnitPLId 	  	  	 Integer,
 	  	 @UnitPUId 	  	  	 Integer,
 	  	 @bSchedulePoint 	  	 Bit,
 	  	 @bProductionPoint 	 Bit,
 	  	 @iUnitOrder 	  	  	 Integer,
 	  	 @PEPUId 	  	  	  	 Integer,
 	  	 @StatusId 	  	  	 Integer,
 	  	 @PEPISId 	  	  	 Integer,
 	  	 @PEPISDId 	  	  	 Integer
/* Clean and verIFy arguments */
SELECT  	 @PLDesc  	  	 = ltrim(rtrim(@PLDesc)),
 	  	 @PathDesc 	  	 = ltrim(rtrim(@PathDesc)),
 	  	 @PathCode 	  	 = ltrim(rtrim(@PathCode)),
 	  	 @LineProd  	  	 = ltrim(rtrim(@LineProd)),
 	  	 @CreateChild 	 = ltrim(rtrim(@CreateChild)),
 	  	 @SControlType  	 = ltrim(rtrim(@SControlType)),
 	  	 @UnitPLDesc 	 = ltrim(rtrim(@UnitPLDesc)),
 	  	 @UnitDesc 	 = ltrim(rtrim(@UnitDesc)),
 	  	 @UnitOrder 	 = ltrim(rtrim(@UnitOrder)),
 	  	 @ProdPoint 	 = ltrim(rtrim(@ProdPoint)),
 	  	 @SchedPoint 	 = ltrim(rtrim(@SchedPoint)),
 	  	 @InputName 	 = ltrim(rtrim(@InputName)),
 	  	 @AllowMovement 	 = ltrim(rtrim(@AllowMovement)),
 	  	 @PSpec 	 = ltrim(rtrim(@PSpec)),
 	  	 @ASpec 	 = ltrim(rtrim(@ASpec)),
 	  	 @HideUnit 	 = ltrim(rtrim(@HideUnit)),
 	  	 @LockInprogress 	 = ltrim(rtrim(@LockInprogress)),
 	  	 @InputLine 	 = ltrim(rtrim(@InputLine)),
 	  	 @InputUnit 	 = ltrim(rtrim(@InputUnit)),
 	  	 @InputStatus 	 = ltrim(rtrim(@InputStatus))
 	  	 
IF @PLDesc = '' 	  	  	 SELECT @PLDesc = Null
IF @PathDesc = '' 	  	 SELECT @PathDesc = Null
IF @PathCode = '' 	  	 SELECT @PathCode = Null
IF @LineProd = '' 	  	 SELECT @LineProd = Null
IF @CreateChild = '' 	 SELECT @CreateChild = Null
IF @SControlType = '' 	 SELECT @SControlType = Null
IF @UnitPLDesc = '' 	  	 SELECT @UnitPLDesc = Null
IF @UnitDesc = '' 	  	 SELECT @UnitDesc = Null
IF @UnitOrder = '' 	  	 SELECT @UnitOrder = Null
IF @ProdPoint = '' 	  	 SELECT @ProdPoint = Null
IF @SchedPoint = '' 	  	 SELECT @SchedPoint = Null
IF @InputName = '' 	  	 SELECT @InputName = Null
IF @AllowMovement = '' 	 SELECT @AllowMovement = Null
IF @PSpec = '' 	  	  	 SELECT @PSpec = Null
IF @ASpec = '' 	  	  	 SELECT @ASpec = Null
IF @HideUnit = '' 	  	 SELECT @HideUnit = Null
IF @LockInprogress = '' 	 SELECT @LockInprogress = Null
IF @InputLine = '' 	  	 SELECT @InputLine = Null
IF @InputUnit = '' 	  	 SELECT @InputUnit = Null
IF @InputStatus = '' 	 SELECT @InputStatus = Null
IF @LineProd = '1'
  SELECT @bLineProd = 1
ELSE
  SELECT @bLineProd = 0
IF @SControlType IS NULL
BEGIN
 	 SELECT @bSControlled = 0
END
ELSE
BEGIN
 	 SELECT @bSControlled = 1
 	 IF @SControlType = 'By Event'
 	   SELECT  @iSControlType = 1
 	 ELSE IF @SControlType = 'Independently'
 	   SELECT  @iSControlType = 2
 	 ELSE IF @SControlType = 'Same Schedule'
 	   SELECT  @iSControlType = 0
 	 ELSE
 	   BEGIN
 	  	 SELECT  @iSControlType = Null
 	  	 SELECT @bSControlled = 0
 	   END
END
IF @CreateChild = '1'
  SELECT @bCreateChild = 1
ELSE
  SELECT @bCreateChild = 0
IF @PathDesc Is Null 
  BEGIN
 	 SELECT 'Failed - Path Description Missing'
    Return (-100)
  End
IF @PathCode Is Null 
  BEGIN
 	 SELECT 'Failed - Path Code Missing'
    Return (-100)
  End
IF @PLDesc Is Null 
  BEGIN
 	 SELECT 'Failed - Production Line Missing'
    Return (-100)
  End
/* Check line */
SELECT @PLId = PL_Id
FROM Prod_Lines
WHERE PL_Desc = @PLDesc
IF @PLId Is Null
  BEGIN
 	 SELECT 'Failed - Production Line Not Found'
    Return (-100)
  End
SELECT @PathId = Path_Id FROM PrdExec_Paths WHERE Path_Code = @PathCode
SELECT @UpdateCheck = Null
IF @PathId Is Not Null
BEGIN
 	 SELECT @UpdateCheck = Path_Id FROM PrdExec_Paths WHERE Path_Code = @PathCode and PL_Id = @PLId
 	 IF @UpdateCheck Is Null
 	 BEGIN
 	  	 SELECT 'Failed - Path Code Found On Different Line'
 	  	 Return (-100)
 	 End
 	 SELECT @UpdateCheck = Null
 	 SELECT @UpdateCheck = Path_Id
 	  	 FROM PrdExec_Paths 
 	  	 WHERE Path_Code = @PathCode And Create_Children = @bCreateChild 
 	  	  	 AND Is_Line_Production = @bLineProd And Is_Schedule_Controlled = @bSControlled
 	  	  	 And Path_Desc = @PathDesc AND PL_Id = @PLId AND Schedule_Control_Type = @iSControlType
END
 	  	 
IF @UpdateCheck IS NULL
 	 Execute spEMEPC_PutExecPaths @PLId,@PathDesc,@PathCode, @bSControlled,@iSControlType,@bLineProd,@bCreateChild,@UserId,@PathId Output
IF @PathId Is null
BEGIN
 	 SELECT 'Failed - Unable to create Path'
 	 Return (-100)
END
IF @UnitDesc Is Null  --No Unit = Done
 	 Return(0)
SELECT @UnitPLId = PL_Id
FROM Prod_Lines
WHERE PL_Desc = @UnitPLDesc
IF @UnitPLId Is Null
BEGIN
 	 SELECT 'Failed - Path Unit Line Not Found'
    Return (-100)
END
SELECT @UnitPUId = PU_Id
 	 FROM Prod_Units
 	 WHERE PU_Desc = @UnitDesc And PL_Id = @UnitPLId
IF @UnitPUId Is Null
BEGIN
 	 SELECT 'Failed - Path Unit Not Found'
    Return (-100)
END
IF @SchedPoint = '1'
  SELECT @bSchedulePoint = 1
ELSE
  SELECT @bSchedulePoint = 0
IF @ProdPoint = '1'
  SELECT @bProductionPoint = 1
ELSE
  SELECT @bProductionPoint = 0
IF IsNumeric(@UnitOrder) = 1
  SELECT @iUnitOrder = convert(int,@UnitOrder)
ELSE
  SELECT @iUnitOrder = 0
SELECT @PEPUId = PEPU_Id FROM Prdexec_Path_Units WHERE PU_Id = @UnitPUId AND Path_Id = @PathId
SELECT @UpdateCheck = Null
SELECT @UpdateCheck = PEPU_Id
 	 FROM Prdexec_Path_Units 
 	 WHERE Is_Production_Point = @bProductionPoint And Is_Schedule_Point = @bSchedulePoint 
 	  	 AND Path_Id = @PathId And PU_Id = @UnitPUId
 	  	 And Unit_Order = @iUnitOrder
IF @UpdateCheck Is Null
BEGIN
 	 INSERT INTO PrdExec_Path_Units (PU_Id, Path_Id, Is_Schedule_Point, Is_Production_Point, Unit_Order)
      VALUES (@UnitPUId, @PathId, @bSchedulePoint, @bProductionPoint, @iUnitOrder)
 	 SELECT @PEPUId = PEPU_Id
 	  	 FROM Prdexec_Path_Units 
 	  	 WHERE Path_Id = @PathId And PU_Id = @UnitPUId
END
IF @PEPUId Is null
BEGIN
 	 SELECT 'Failed - Unable to create Path Unit'
 	 Return (-100)
END
IF @InputName Is Null -- No Inputs done
 	 Return(0)
SELECT @PEIId = PEI_Id,@EsId = Event_Subtype_Id
FROM PrdExec_Inputs
WHERE Input_Name = @InputName AND PU_Id = @UnitPUId
IF @PEIId Is null
BEGIN
 	 SELECT 'Failed - Unable to find Input'
 	 Return (-100)
END
SELECT @PEPIId = PEPI_Id
 	 FROM PrdExec_Path_Inputs
 	 WHERE PEI_Id = @PEIId AND Path_Id = @PathId
/************************************************************************************/
/* Get the Primary Spec Id 	  	  	  	  	  	  	             */
/************************************************************************************/
IF @PSpec Is Not Null
BEGIN
 	 SELECT @Index = CharIndex('/', @PSpec)
 	 IF @Index > 0
 	 BEGIN
 	  	 SELECT @PropDesc = RTrim(LTrim(Left(@PSpec, CharIndex('/', @PSpec)-1)))
 	  	 SELECT @PSpec = Right(@PSpec, Len(@PSpec)- CharIndex('/', @PSpec))
 	  	 SELECT @PropId = Prop_Id
 	  	  	 FROM Product_Properties
 	  	  	 WHERE Prop_Desc = @PropDesc
 	  	 SELECT @PSpecId = Spec_Id
 	  	  	 FROM Specifications
 	  	  	 WHERE Prop_Id = @PropId And Spec_Desc = @PSpec
 	  	 IF @PSpecId Is Null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - invalid primary specification variable'
 	  	  	 RETURN(-100) 
 	  	 End
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT 'Failed - invalid primary property/specification variable'
 	  	 RETURN(-100) 
 	 End
END
IF @ASpec Is Not Null
BEGIN
 	 SELECT @Index = CharIndex('/', @ASpec)
 	 IF @Index > 0
 	 BEGIN
 	  	 SELECT @PropDesc = NULL,@PropId = Null
 	  	 SELECT @PropDesc = RTrim(LTrim(Left(@ASpec, CharIndex('/', @ASpec)-1)))
 	  	 SELECT @ASpec = Right(@ASpec, Len(@ASpec)- CharIndex('/', @ASpec))
 	  	 SELECT @PropId = Prop_Id
 	  	  	 FROM Product_Properties
 	  	  	 WHERE Prop_Desc = @PropDesc
 	  	 SELECT @ASpecId = Spec_Id
 	  	  	 FROM Specifications
 	  	  	 WHERE Prop_Id = @PropId And Spec_Desc = @ASpec
 	  	 IF @ASpecId Is Null
 	  	 BEGIN
 	  	  	 SELECT 'Failed - invalid alternate specification variable'
 	  	  	 RETURN(-100) 
 	  	 End
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT 'Failed - invalid alternate property/specification variable'
 	  	 RETURN(-100) 
 	 End
END
IF @AllowMovement = '1'
  SELECT @bAllowManualMovement = 1
ELSE
  SELECT @bAllowManualMovement = 0
IF @HideUnit = '1'
  SELECT @bHideInput = 1
ELSE
  SELECT @bHideInput = 0
IF @LockInprogress = '1'
  SELECT @bLockInput = 1
ELSE
  SELECT @bLockInput = 0
EXECUTE spEMEPC_PutPathInputs @PathId,@PEIId,@EsId,@PSpecId,@ASpecId,@bLockInput,
 	  	 @bHideInput,@bAllowManualMovement,@UserId,@PEPIId Output
IF @PEPIId Is null
BEGIN
 	 SELECT 'Failed - Unable to create path input'
 	 Return (-100)
END
IF @InputUnit Is Null -- No Inputs to set done
 	 Return(0)
SELECT @UnitPLId = Null,@UnitPUId = Null
SELECT @UnitPLId = PL_Id
FROM Prod_Lines
WHERE PL_Desc = @InputLine
IF @UnitPLId Is Null
BEGIN
 	 SELECT 'Failed - Input Unit Line Not Found'
    Return (-100)
END
SELECT @UnitPUId = PU_Id
 	 FROM Prod_Units
 	 WHERE PU_Desc = @InputUnit And PL_Id = @UnitPLId
IF @UnitPUId Is Null
BEGIN
 	 SELECT 'Failed - Input Unit Not Found'
    Return (-100)
END
SELECT @PEPISId = PEPIS_Id
 	 FROM PrdExec_Path_Input_Sources
 	 WHERE Path_Id = @PathId And PEI_Id = @PEIId And PU_Id = @UnitPUId
IF @PEPISId Is Null
BEGIN
 	 EXECUTE spEMEPC_PutInputSources @PathId,@PEIId,@UnitPUId,@UserId,@PEPISId  OUTPUT
 	 IF @PEPISId Is Null
 	 BEGIN
 	  	 SELECT 'Failed - Unable to add source input'
 	  	 Return (-100)
 	 END
END
IF @InputStatus is not Null
BEGIN
 	 SELECT @StatusId = ProdStatus_Id
 	  	 FROM Production_Status
 	  	 WHERE ProdStatus_Desc = @InputStatus
 	 IF @StatusId Is Null
 	 BEGIN
 	  	 SELECT 'Failed - Input Status Not Found'
 	  	 Return (-100)
 	 END
 	 SELECT @PEPISDId = PEPISD_Id
 	  	 FROM PrdExec_Path_Input_Source_Data
 	  	 WHERE PEPIS_Id = @PEPISId and  Valid_Status = @StatusId
 	 IF @PEPISDId is Null
 	  	 EXECUTE spEMEPC_PutInputStatuses @StatusId,@PathId,@PEIId,@UnitPUId,0,@UserId,@PEPISId Output
END
