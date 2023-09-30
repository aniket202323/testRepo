

CREATE PROCEDURE dbo.spMES_GetBomItemDetailsForProcessOrder
  @ProcessOrderId INT,                       -- Process Order Id (required)
  @UnitInputMaterialTypeField nvarchar(50),   -- Name of the UnitInputMaterialType field in the PrdExec_Inputs UDP (required)
  @BomItemMaterialTypeField nvarchar(50),     -- Name of the BomMaterialType field in the BOM_Formulation_Item UDP (required)
  @InputIsProductionCounterField nvarchar(50) -- Name of the InputIsProductionCounterField field in the PrdExec_Inputs UDP (required)

AS
  DECLARE @Status INT     -- Holds the returned status from validating the inputs.
  SET @Status = 0

  /* Look up the table IDs. This must succeed since it is part of the PA schema.
     However, if they are missing, the field id look up fails and the
     returned status gives a big hint */
  DECLARE @BomItemTableId INT
  DECLARE @PrdExecInputTableId INT
  SELECT @BomItemTableId = TableId FROM [dbo].Tables WHERE TableName = 'Bill_Of_Material_Formulation_Item'
  SELECT @PrdExecInputTableId = TableId FROM [dbo].Tables WHERE TableName = 'PrdExec_Inputs'

  /* Lookup the field IDs
     If any are missing, that is an error. Update the status and exit. */
  DECLARE @UnitInputMaterialTypeFieldId INT
  DECLARE @InputIsProductionCounterFieldId INT
  DECLARE @BomItemMaterialTypeFieldId INT

  SELECT @UnitInputMaterialTypeFieldId = Table_Field_Id
  FROM [dbo].Table_Fields
  WHERE TableId = @PrdExecInputTableId AND
        Table_Field_Desc = @UnitInputMaterialTypeField
  IF @UnitInputMaterialTypeFieldId IS NULL
    SET @Status = @Status - 1

  SELECT @BomItemMaterialTypeFieldId = Table_Field_Id
  FROM [dbo].Table_Fields
  WHERE TableId = @BomItemTableId AND
        Table_Field_Desc = @BomItemMaterialTypeField
  IF @BomItemMaterialTypeFieldId IS NULL
    SET @Status = @Status - 2

  SELECT @InputIsProductionCounterFieldId = Table_Field_Id
  FROM [dbo].Table_Fields
  WHERE TableId = @PrdExecInputTableId AND
        Table_Field_Desc = @InputIsProductionCounterField
  IF @InputIsProductionCounterFieldId IS NULL
    SET @Status = @Status - 4

  IF (@Status != 0)
    RETURN @Status

  /* Inputs are all validated. Continue with query. */

  /* PO gives us path which gives units which gives unit inputs which give material type and is counted */
  DECLARE @UnitInputMaterialType Table (
    LineId INT,
    UnitId INT,
    UnitOrder INT,
    UnitInputName nvarchar(50),
    MaterialType  nvarchar(50)
  )

  INSERT INTO @UnitInputMaterialType(LineId, UnitId, UnitOrder, UnitInputName, MaterialType)
    SELECT unit.PL_Id as LineId,
           unit.PU_Id as UnitId,
           unit.PU_Order as UnitOrder,
           unitInputs.Input_Name as UnitInputName,
           unitInputMaterialType.value as MaterialType
    FROM [dbo].Production_Plan po
      JOIN [dbo].PrdExec_Path_Units pathUnits
        ON pathUnits.Path_Id = po.Path_Id
      JOIN [dbo].Prod_Units_Base unit
        ON unit.PU_Id = pathUnits.PU_Id
      JOIN [dbo].PrdExec_Inputs unitInputs
        ON unitInputs.PU_Id = unit.PU_Id
      JOIN [dbo].Table_Fields_Values unitInputMaterialType
        ON unitInputMaterialType.Table_Field_Id = @UnitInputMaterialTypeFieldId AND
           unitInputMaterialType.TableId = @PrdExecInputTableId AND
           unitInputMaterialType.KeyId = unitInputs.PEI_Id
      JOIN [dbo].Table_Fields_Values isCounterUnitInput
        ON isCounterUnitInput.Table_Field_Id = @InputIsProductionCounterFieldId AND
           isCounterUnitInput.TableId = @PrdExecInputTableId AND
           isCounterUnitInput.KeyId = unitInputs.PEI_Id
    WHERE po.PP_Id = @ProcessOrderId AND
          /* Only include the counted material types */
          isCounterUnitInput.value = '1'

  /* PO links to BOM Formulation which gives items which have quantity and give origin group */
  SELECT po.PP_Id as ProcessOrderId,
         unitInputMaterialType.LineId as LineId,
         unitInputMaterialType.UnitId as UnitId,
         unitInputMaterialType.UnitInputName as UnitInputName,
         bomItemMaterialType.Value as MaterialType,
         bomItem.Quantity as Quantity,
         bomItem.Scrap_Factor as ScrapFactor
  FROM [dbo].Production_Plan po
    JOIN [dbo].Bill_Of_Material_Formulation_Item bomItem
      ON bomItem.BOM_Formulation_Id = po.BOM_Formulation_Id
    JOIN [dbo].Table_Fields_Values bomItemMaterialType
      ON bomItemMaterialType.Table_Field_Id = @BomItemMaterialTypeFieldId AND
         bomItemMaterialType.TableId = @BomItemTableId AND
         bomItemMaterialType.KeyId = bomItem.BOM_Formulation_Item_Id
    JOIN @UnitInputMaterialType unitInputMaterialType
      ON unitInputMaterialType.MaterialType = bomItemMaterialType.Value
  WHERE po.PP_Id = @ProcessOrderId
  ORDER BY unitInputMaterialType.UnitOrder

  RETURN @Status
