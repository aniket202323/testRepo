Create Procedure dbo.spMSITopic_Order_BOM_Statistics
@value int OUTPUT,
@PPId int,
@Topic int
as
/* Needed for multilingual - topics should be in local language */
set nocount on
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
--**********************************************
-- Get Current BOM and Consumption
--**********************************************
Insert Into #MasterBOM
 	 exec spCmn_GetBOMConsumption @PPId, @Topic, NULL
--**********************************************
-- Return Topic
--**********************************************
Select Type = 4, 
 	  	  	  Topic = @Topic, 
       KeyValue = @PPId, 
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
set nocount off
