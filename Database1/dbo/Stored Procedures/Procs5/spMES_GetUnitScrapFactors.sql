

CREATE PROCEDURE dbo.spMES_GetUnitScrapFactors
    @LineId INT,                               -- Line Id. May be null to retrieve all units on all lines. Not used if @UnitId is specified.
    @UnitId INT,                               -- Unit Id. May be null to retrieve all units on the specified line.
    @UseScrapFactorField nvarchar(50),          -- Name of the UseScrapFactor field in the PrdExec_Inputs UDP (required)
    @ScrapFactorField nvarchar(50),             -- Name of the ScrapFactor field in the PrdExec_Inputs UDP (required)
    @InputIsProductionCounterField nvarchar(50) -- Name of the InputIsProductionCounterField field in the PrdExec_Inputs UDP (required)
AS
  DECLARE @Status INT     -- Holds the returned status from validating the inputs.
  SET @Status = 0

  /* Look up the table IDs. This must succeed since it is part of the PA schema.
     However, if they are missing, the field id look up fails and the
     returned status gives a big hint */
  DECLARE @PrdExecInputTableId INT
  SELECT @PrdExecInputTableId = TableId FROM [dbo].Tables WHERE TableName = 'PrdExec_Inputs'

  /* Lookup the field IDs
     If any are missing, that is an error. Update the status and exit. */
  DECLARE @UseScrapFactorFieldId INT
  DECLARE @ScrapFactorFieldId INT
  DECLARE @InputIsProductionCounterFieldId INT

  SELECT @UseScrapFactorFieldId = Table_Field_Id
  FROM [dbo].Table_Fields
  WHERE TableId = @PrdExecInputTableId AND
        Table_Field_Desc = @UseScrapFactorField
  IF @UseScrapFactorFieldId IS NULL
    SET @Status = @Status - 1

  SELECT @ScrapFactorFieldId = Table_Field_Id
  FROM [dbo].Table_Fields
  WHERE TableId = @PrdExecInputTableId AND
        Table_Field_Desc = @ScrapFactorField
  IF @ScrapFactorFieldId IS NULL
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

  SELECT unit.PL_Id as LineId,
         unit.PU_Id as UnitId,
         unitInputs.Input_Name as UnitInputName,
         scrapFactor.value as ScrapFactor
  FROM [dbo].Prod_Units_Base unit
    JOIN [dbo].PrdExec_Inputs unitInputs
      ON unitInputs.PU_Id = unit.PU_Id
    JOIN [dbo].Table_Fields_Values isCounterUnitInput
      ON isCounterUnitInput.Table_Field_Id = @InputIsProductionCounterFieldId AND
         isCounterUnitInput.TableId = @PrdExecInputTableId AND
         isCounterUnitInput.KeyId = unitInputs.PEI_Id
    JOIN [dbo].Table_Fields_Values useScrapFactor
      ON useScrapFactor.Table_Field_Id = @UseScrapFactorFieldId AND
         useScrapFactor.TableId = @PrdExecInputTableId AND
         useScrapFactor.KeyId = unitInputs.PEI_Id
    JOIN [dbo].Table_Fields_Values scrapFactor
      ON scrapFactor.Table_Field_Id = @ScrapFactorFieldId AND
         scrapFactor.TableId = @PrdExecInputTableId AND
         scrapFactor.KeyId = unitInputs.PEI_Id
  WHERE (@UnitId is null or @UnitId = unit.PU_Id)
        AND (@LineId is null or @LineId = unit.PL_Id)
        AND (isCounterUnitInput.value = 1)
        AND (useScrapFactor.value = 1)
  ORDER BY unit.PL_Id, unit.PU_Order

  RETURN @Status
