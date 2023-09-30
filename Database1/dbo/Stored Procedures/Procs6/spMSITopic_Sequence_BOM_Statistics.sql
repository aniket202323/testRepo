Create Procedure dbo.spMSITopic_Sequence_BOM_Statistics
@value int OUTPUT,
@PPSetupId int,
@Topic int
as
CREATE TABLE #MasterBOM (
 	 ScreenOrder int,
  ItemOrder int,
 	 ProdCode varchar(25),
 	 ProdDesc varchar(50),
 	 LotNumber varchar(50) NULL,
 	 Location varchar(50),
  QuantityPer real,
  RequiredQuantity real Default 0.0,
  ActualQuantity real Default 0.0,
 	 RemainingQuantity real Default 0.0,
 	 EngineeringUnits varchar(50),
  ScrapFactor real NULL,
 	 LowerReject float Default 0.0,
 	 LTolerancePrecision int,
 	 UpperReject float Default 0.0,
 	 UTolerancePrecision int,
 	 Substitutions bit,
  ColorFlag int Default 24,
  BackColor int Default 2,
 	 ProdId int,
 	 PUId int,
 	 BOMFormulationItemId int,
 	 BOMFormulationId int,
  QuantityPrecision int,
 	 ActualQuantityColorFlag int Default 7,
 	 UseEventComponents bit)
Declare @PPId int
Select @PPId = pp.pp_id
  From production_setup s
  join production_plan pp on pp.pp_id = s.pp_id
  Where s.pp_setup_id = @PPSetupId
--**********************************************
-- Get Current BOM and Consumption
--**********************************************
Insert Into #MasterBOM
 	 exec spCmn_GetBOMConsumption @PPId, @PPSetupId, @Topic
--**********************************************
-- Return Topic
--**********************************************
Select Type = 4, 
 	  	  	  Topic = @Topic, 
       KeyValue = @PPSetupId, 
       ItemOrder, 
       ProdCode, 
       ProdDesc, 
 	  	  	  LotNumber,
 	  	  	  Location,
       QuantityPer, 
       RequiredQuantity, 
       ActualQuantity, 
 	  	  	  RemainingQuantity, 
 	  	  	  EngineeringUnits,
       ScrapFactor, 
       LowerReject,
       LTolerancePrecision,
       UpperReject,
       UTolerancePrecision,
       Substitutions,
       ColorFlag,
       BackColor,
       QuantityPrecision,
 	  	  	  BOMFormulationItemId,
 	  	  	  BOMFormulationId,
 	  	  	  ActualQuantityColorFlag,
 	  	  	  UseEventComponents
  From #MasterBOM
  Order By ScreenOrder, ItemOrder
