Create Procedure dbo.spASP_wrProcessOrderBOMStatistics
@value int OUTPUT,
@PPId int,
@Topic int
as
CREATE TABLE #MasterBOM (
 	 ScreenOrder int,
  ItemOrder int,
 	 ProdCode nvarchar(25),
 	 ProdDesc nvarchar(50),
 	 LotNumber nVarChar(50) NULL,
 	 Location nvarchar(50),
  QuantityPer real,
  RequiredQuantity real Default 0.0,
  ActualQuantity real Default 0.0,
 	 RemainingQuantity real Default 0.0,
 	 EngineeringUnits nvarchar(50),
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
 	 UseEventComponents bit,
        LotDesc nvarchar(3000),
 	 UnitName nvarchar(3000))
/**/
--**********************************************
-- Get Current BOM and Consumption
--**********************************************
Insert Into #MasterBOM
(ScreenOrder,ItemOrder,ProdCode,ProdDesc,LotNumber,Location,QuantityPer,RequiredQuantity,
ActualQuantity, RemainingQuantity, EngineeringUnits,ScrapFactor,LowerReject,LTolerancePrecision,UpperReject,UTolerancePrecision,
Substitutions,ColorFlag,BackColor,ProdId,PUId,BOMFormulationItemId,BOMFormulationId,QuantityPrecision,ActualQuantityColorFlag,
UseEventComponents)
 	 exec spCmn_GetBOMConsumption @PPId, @Topic, NULL
Update #MasterBOM
  Set #MasterBOM.LotDesc = (Select Lot_Desc From Bill_Of_Material_Formulation_Item Where BOM_Formulation_Item_Id = #MasterBOM.BOMFormulationItemId)
Update #MasterBOM
  Set #MasterBOM.UnitName = (Select PU.PU_Desc From Prod_Units PU Where PU.PU_Id = #MasterBOM.PUId)
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
 	  	  	  UseEventComponents,
 	 LotDesc,
 	 UnitName
  From #MasterBOM
  Order By ScreenOrder, ItemOrder
