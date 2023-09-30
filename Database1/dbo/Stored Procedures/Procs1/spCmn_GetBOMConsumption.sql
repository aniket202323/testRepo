CREATE PROCEDURE dbo.spCmn_GetBOMConsumption
-- FOR TESTING
-- Declare
@PPId int,
@Topic int = 201,
@PPSetupId int = NULL
-- FOR TESTING
AS
-- Select @PPId = 16864
-- Select @Topic = 201
-- Select @PPSetupId = NULL
DECLARE 	 @Cnt INT,
@EndTime DATETIME
Declare @ForecastQuantity  	  	  	  	  	 real
Declare @ActualGoodQuantity  	  	  	  	 real
Declare @ActualBadQuantity  	  	  	  	  	 real
Declare @PredictedRemainingQuantity real
Declare @ProductId  	  	  	  	  	  	  	  	  	 int
Declare @StartTime  	  	  	  	  	  	  	  	  	 datetime
Declare @PathId  	  	  	  	  	  	  	  	  	  	 int
Declare @BOMFormulationId  	  	  	  	  	 int
Declare @StandardQuantity  	  	  	  	  	 float
Declare @ProdId 	  	  	  	  	  	  	  	  	  	  	 int
If @Topic = 201 -- Process Order Based BOM
 	 Begin
 	  	 Select @ForecastQuantity = coalesce(forecast_quantity,0.0),
 	  	        @ActualGoodQuantity = coalesce(actual_good_quantity,0.0),
 	  	        @ActualBadQuantity = coalesce(actual_bad_quantity,0.0),
 	  	        @PredictedRemainingQuantity = coalesce(predicted_remaining_quantity,coalesce(forecast_quantity,0.0)),
 	  	        @ProductId = prod_id,
 	  	        @StartTime = coalesce(actual_start_time,dbo.fnServer_CmnGetDate(getUTCdate())),
 	  	        @PathId = path_id,
 	  	  	  	  	  @BOMFormulationId = BOM_Formulation_Id,
 	  	  	  	  	  @ProdId = Prod_Id
 	  	   From production_plan 
 	  	   Where pp_id = @PPId
 	  	  	 -- ECR #30160 
 	  	  	 If @BOMFormulationId is NULL
 	  	  	  	 return (0)
 	 End
Else If @Topic = 211 -- Sequence Based BOM
 	 Begin
 	  	 Select @ForecastQuantity = coalesce(s.forecast_quantity,0.0),
 	  	        @ActualGoodQuantity = coalesce(s.actual_good_quantity,0.0),
 	  	        @ActualBadQuantity = coalesce(s.actual_bad_quantity,0.0),
 	  	        @PredictedRemainingQuantity = coalesce(s.predicted_remaining_quantity,coalesce(s.forecast_quantity,0.0)),
 	  	        @ProductId = pp.prod_id,
 	  	        @StartTime = coalesce(s.actual_start_time,dbo.fnServer_CmnGetDate(getUTCdate())),
 	  	        @PathId = pp.path_id,
 	  	  	  	  	  @BOMFormulationId = BOM_Formulation_Id,
 	  	        @PPId = pp.pp_id,
 	  	  	  	  	  @ProdId = pp.Prod_Id
 	  	   From production_setup s
 	  	   join production_plan pp on pp.pp_id = s.pp_id
 	  	   Where s.pp_setup_id = @PPSetupId
 	 End
--Case Where BOMFormulationId is Not Tied to the Process Order...Must Look At Bill_Of_Material_Product
If @BOMFormulationId is NULL
 	 Select @BOMFormulationId = BOM_Formulation_Id
 	  	 From Bill_Of_Material_Product
 	  	 Where Prod_Id = @ProdId
-- FOR TESTING
--select @BOMFormulationId as BOMFormulationId
Select @StandardQuantity = Standard_Quantity
 	 From Bill_Of_Material_Formulation
 	 Where BOM_Formulation_Id = @BOMFormulationId
DECLARE @tProcessOrder TABLE (
 	 PPId INT,
 	 ProcessOrder VARCHAR(100),
 	 PathId INT,
 	 PPStatusId INT,
 	 StartTime DATETIME,
 	 EndTime 	 DATETIME)
DECLARE @tMasterBOM Table (
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
 	 BOMSubstitutionId int,
  ColorFlag int Default 24,
  BackColor int Default 2,
 	 ProdId int,
 	 PUId int,
 	 BOMFormulationItemId int,
 	 BOMFormulationId int,
  QuantityPrecision int,
 	 ActualQuantityColorFlag int Default 24,
 	 UseEventComponents bit)
DECLARE @tMPA TABLE ( 	 
 	 ProcessOrder VARCHAR(100),
 	 PathId INT, 
 	 EventId INT, 
 	 StartTime 	 DATETIME,
 	 EndTime 	 DATETIME,
 	 PUId INT,
 	 ProdId INT,
 	 Product VARCHAR(100),
 	 EventNum VARCHAR(100),
 	 Quantity VARCHAR(100),
 	 UoM VARCHAR(100))
DECLARE @tMCA TABLE ( 	 
 	 ProcessOrder VARCHAR(100),
 	 EventCompId 	 INT,
 	 EventId INT, 
 	 EventNum VARCHAR(100),
 	 SourceEventId 	 INT, 
 	 SourceEventNum VARCHAR(100),
 	 StartTime 	 DATETIME,
 	 EndTime 	 DATETIME,
 	 PUId INT,
 	 RacFlag 	 INT,
 	 ProdId INT,
 	 Product 	 VARCHAR(100),
 	 Quantity VARCHAR(100),
 	 UoM 	 VARCHAR(100),
 	 BOMFormulationItemId INT)
SELECT @EndTime = CONVERT(VARCHAR(19), dbo.fnServer_CmnGetDate(getUTCdate()), 126)
INSERT @tProcessOrder (
 	 ProcessOrder,
 	 PPId,
 	 StartTime,
 	 EndTime,
 	 PathId,
 	 PPStatusId)
SELECT pp.Process_Order,
 	 pp.PP_Id,
 	 pp.Actual_Start_Time,
 	 COALESCE(pp.Actual_End_Time, @EndTime),
 	 pp.Path_Id,
 	 pp.PP_Status_Id
 	 FROM Production_Plan PP
 	 WHERE PP.PP_Id = @PPId 	 OR PP.Parent_PP_Id = @PPId
-- FOR TESTING
-- select 'select * from @tProcessOrder'
--select * from @tProcessOrder
--**********************************************
-- Get Current BOM
--**********************************************
If (Select BOM_Formulation_Id From Production_Plan Where PP_Id = @PPId) is NOT NULL
 	 Begin
 	  	 Insert Into @tMasterBOM (ScreenOrder, ItemOrder, ProdCode, ProdDesc, LotNumber, Location, QuantityPer, EngineeringUnits, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ScrapFactor, LowerReject, LTolerancePrecision, UpperReject, UTolerancePrecision, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 BOMSubstitutionId, ProdId, PUId, BOMFormulationItemId, BOMFormulationId, QuantityPrecision, UseEventComponents)
 	  	   Select ScreenOrder = bomfi.bom_formulation_order, 
 	  	  	  	  	  	  ItemOrder = bomfi.bom_formulation_order, 
 	  	  	  	  	  	  ProdCode = p.prod_code,
 	  	  	  	  	  	  ProdDesc = p.prod_desc,
 	  	          LotNumber = bomfi.lot_desc,
 	  	  	  	  	  	  Location = pu.pu_desc,
 	  	  	  	  	  	  QuantityPer = convert(real,coalesce(bomfi.quantity,'0.0')), 
 	  	  	  	  	  	  EngineeringUnits = eu.eng_unit_code,
 	  	          ScrapFactor = convert(real,coalesce(bomfi.scrap_factor,'0.0')), 
 	  	  	  	  	  	  LowerReject = bomfi.lower_tolerance,
 	  	  	  	  	  	  LTolerancePrecision = bomfi.ltolerance_precision,
 	  	  	  	  	  	  UpperReject = bomfi.upper_tolerance,
 	  	  	  	  	  	  UTolerancePrecision = bomfi.utolerance_precision,
 	  	  	  	  	  	  BOMSubstitutionId = NULL,
 	  	  	  	  	  	  ProdId = bomfi.prod_Id,
 	  	  	  	  	  	  PUId = bomfi.pu_id,
 	  	  	  	  	  	  BOMFormulationItemId = bomfi.bom_formulation_item_id, 
 	  	  	  	  	  	  BOMFormulationId = bomfi.BOM_Formulation_Id,
 	  	          QuantityPrecision = bomfi.Quantity_Precision,
 	  	  	  	  	  	  UseEventComponents = bomfi.Use_Event_Components
 	  	  	 From Bill_Of_Material_Formulation_Item bomfi
 	  	  	 Join Bill_Of_Material_Formulation bomf on bomf.bom_formulation_id = bomfi.bom_formulation_id
 	  	  	 Join Production_Plan pp on pp.bom_formulation_id = bomf.bom_formulation_id
 	  	  	 Join Products p on p.prod_id = bomfi.prod_id
 	  	  	 Join Engineering_Unit eu on eu.eng_unit_id = bomfi.eng_unit_id
 	  	  	 Left Outer Join Prod_Units pu on pu.pu_id = bomfi.pu_id
 	  	  	 Left Outer Join Bill_Of_Material_Substitution boms on boms.bom_formulation_item_id = bomfi.bom_formulation_id
 	  	  	 Where pp.PP_Id = @PPId 	 OR PP.Parent_PP_Id = @PPId
 	 End
Else
 	 Begin
 	  	 Insert Into @tMasterBOM (ScreenOrder, ItemOrder, ProdCode, ProdDesc, LotNumber, Location, QuantityPer, EngineeringUnits, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ScrapFactor, LowerReject, LTolerancePrecision, UpperReject, UTolerancePrecision, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 BOMSubstitutionId, ProdId, PUId, BOMFormulationItemId, BOMFormulationId, QuantityPrecision, UseEventComponents)
 	  	   Select ScreenOrder = bomfi.bom_formulation_order, 
 	  	  	  	  	  	  ItemOrder = bomfi.bom_formulation_order, 
 	  	  	  	  	  	  ProdCode = p.prod_code,
 	  	  	  	  	  	  ProdDesc = p.prod_desc,
 	  	          LotNumber = bomfi.lot_desc,
 	  	  	  	  	  	  Location = pu.pu_desc,
 	  	  	  	  	  	  QuantityPer = convert(real,coalesce(bomfi.quantity,'0.0')), 
 	  	  	  	  	  	  EngineeringUnits = eu.eng_unit_code,
 	  	          ScrapFactor = convert(real,coalesce(bomfi.scrap_factor,'0.0')), 
 	  	  	  	  	  	  LowerReject = bomfi.lower_tolerance,
 	  	  	  	  	  	  LTolerancePrecision = bomfi.ltolerance_precision,
 	  	  	  	  	  	  UpperReject = bomfi.upper_tolerance,
 	  	  	  	  	  	  UTolerancePrecision = bomfi.utolerance_precision,
 	  	  	  	  	  	  BOMSubstitutionId = NULL,
 	  	  	  	  	  	  ProdId = bomfi.prod_Id,
 	  	  	  	  	  	  PUId = bomfi.pu_id,
 	  	  	  	  	  	  BOMFormulationItemId = bomfi.bom_formulation_item_id, 
 	  	  	  	  	  	  BOMFormulationId = bomfi.BOM_Formulation_Id,
 	  	          QuantityPrecision = bomfi.Quantity_Precision,
 	  	  	  	  	  	  UseEventComponents = bomfi.Use_Event_Components
 	  	  	 From Bill_Of_Material_Formulation_Item bomfi
 	  	  	 Join Bill_Of_Material_Formulation bomf on bomf.bom_formulation_id = bomfi.bom_formulation_id
 	  	  	 Join Bill_Of_Material_Product bomp on bomp.bom_formulation_id = bomf.bom_formulation_id
 	  	  	 Join Production_Plan pp on pp.prod_id = bomp.prod_id
 	  	  	 Join Products p on p.prod_id = bomfi.prod_id
 	  	  	 Join Engineering_Unit eu on eu.eng_unit_id = bomfi.eng_unit_id
 	  	  	 Left Outer Join Prod_Units pu on pu.pu_id = bomfi.pu_id
 	  	  	 Left Outer Join Bill_Of_Material_Substitution boms on boms.bom_formulation_item_id = bomfi.bom_formulation_id
 	  	  	 Where pp.PP_Id = @PPId
 	  	  	 OR PP.Parent_PP_Id = @PPId
 	 End
INSERT @tMPA (
 	 EventId, 
 	 EndTime,  	 
 	 PUId,  	 
 	 ProdId, 
 	 ProcessOrder,  	 
 	 PathId, 
 	 Quantity,  	 
 	 EventNum,
 	 UoM, 
 	 StartTime) 
SELECT  	 ee.Event_Id, 
 	 ee.Timestamp, 
 	 ee.PU_Id, 
 	 ee.Applied_Product,
 	 po.ProcessOrder,
 	 po.PathId,
 	 isnull(ed.Initial_Dimension_X,0),
 	 ee.Event_num, 
 	 subtype.Dimension_X_Eng_Units, 
 	 ee.Start_Time 
FROM @tProcessOrder po
JOIN Production_Plan_Starts PPS ON po.PPId = pps.PP_Id
JOIN PrdExec_Path_Units ppu ON ppu.Path_Id = po.PathId  	 AND Is_Production_Point = 1 	 AND pps.PU_Id = ppu.PU_Id
JOIN Events ee ON ppu.PU_Id = ee.PU_Id 	 AND pps.Start_Time < ee.Timestamp 
 	  	  AND (ee.Timestamp <= pps.End_Time OR pps.End_Time is NULL)
JOIN 	 Event_Details ed ON ed.Event_Id = ee.Event_Id  and ed.PP_Id IS NULL 
JOIN Event_Configuration ec ON ec.PU_Id = ee.PU_Id AND ec.ET_Id = 1
JOIN Event_Subtypes subtype ON subtype.Event_Subtype_Id = ec.Event_Subtype_Id
Update @tMPA set ProdId = isnull(ProdId,Prod_Id)
 From @tMPA t
 Join Production_Starts ps ON t.PUId = ps.PU_Id
 	 AND 	 t.EndTime >= ps.Start_Time
 	 AND (t.EndTime < ps.End_Time 	 OR ps.End_Time IS NULL)
 	 
-- We also have to include all production that is specifically identified against these process orders.
DEclare @EventDetailData Table (Event_Id Int,ProcessOrder  varchar(100),PathId Int,Initial_Dimension_X Float)
Insert Into @EventDetailData(Event_Id,ProcessOrder,PathId,Initial_Dimension_X)
 	 Select ed.Event_Id,po.ProcessOrder,po.PathId,ed.Initial_Dimension_X
 	 From @tProcessOrder po
 	 Join Event_Details ed ON ed.PP_Id = po.PPId
INSERT @tMPA (
 	 EventId, 
 	 EndTime, 
 	 PUId,  	 
 	 ProdId,  	 
 	 ProcessOrder,  	 
 	 PathId, 
 	 Quantity, 	 
 	 EventNum,
 	 UoM, 	 
 	 StartTime)
SELECT edd.Event_Id, 
 	 ee.Timestamp, 
 	 ee.PU_Id,  
 	 COALESCE(ee.Applied_Product, ps.Prod_Id),
 	 edd.ProcessOrder, 
 	 edd.PathId, 
 	 edd.Initial_Dimension_X,
 	 ee.Event_Num, 
 	 subtype.Dimension_X_Eng_Units, 
 	 ee.Start_Time
FROM @EventDetailData edd
JOIN Events ee ON ee.Event_Id = edd.Event_Id
JOIN Production_Starts ps ON ee.PU_Id = ps.PU_Id
 	 AND 	 ee.TimeStamp >= ps.Start_Time 	 AND 	 (ee.TimeStamp < ps.End_Time 	 OR ps.End_Time IS NULL)
JOIN Prdexec_Path_Units ppu ON ppu.PU_Id = ee.PU_Id  	 AND ppu.is_Production_Point = 1
JOIN Event_Configuration ec ON ec.PU_Id = ee.PU_Id 	 AND ec.ET_Id = 1
JOIN Event_Subtypes subtype ON subtype.Event_Subtype_Id = ec.Event_Subtype_Id
-- Retrieve the Product Code for the mpa records.
UPDATE mpa
 	 SET 	 Product = p.Prod_Code
 	 FROM @tMPA mpa
 	 JOIN Products p ON mpa.ProdId = p.Prod_Id
-- FOR TESTING
-- select 'select * from @tMPA'
-- select * from @tMPA
-- Retrieve the Material Consumed Actuals.  This is accomplished by cycling up the Family Tree and
-- collecting all Event_Compoenent records where Report_As_Consumption is set to 1.  The search up
-- the Family Tree will stop once the end of the line is reached or a Report_As_Consumption = 1 is
-- found.  Begin at the Material Produced Actual records.
-- INSERT level 1 Event_components ids
INSERT @tMCA (
 	 EventCompId,
 	 EventId,
 	 EventNum,
 	 SourceEventId,
 	 SourceEventNum,
 	 ProcessOrder,
 	 Quantity,
 	 RACFlag,
 	 PUId,
 	 StartTime, 
 	 EndTime, 
 	 UoM,
 	 ProdId)
SELECT ec.Component_Id,
 	 ec.Event_Id,
 	 ee.Event_Num,
 	 ec.Source_Event_Id,
 	 ep.Event_Num,
 	 mpa.ProcessOrder,
 	 coalesce (ec.Dimension_X,0),
 	 Coalesce(ec.Report_As_Consumption, 0),
 	 ep.PU_Id,
 	 ee.Start_Time,
 	 ee.TimeStamp,
 	 subtype.Dimension_X_Eng_Units,
 	 COALESCE(ep.Applied_Product, ps.Prod_Id)
FROM @tMPA mpa
JOIN Event_Components ec ON ec.Event_Id = mpa.EventId
JOIN Events ee ON ee.Event_Id = ec.Event_Id
JOIN Events ep ON ep.Event_Id = ec.Source_Event_Id
LEFT JOIN 	 Event_Configuration econ ON econ.PU_Id = ep.PU_Id 	 AND econ.ET_Id = 1
LEFT JOIN 	 Event_Subtypes subtype ON subtype.Event_Subtype_Id = econ.Event_Subtype_Id
JOIN Production_Starts ps ON ps.PU_Id = ep.PU_Id 	 AND 	 ps.Start_Time <= ep.TimeStamp
 	 AND 	 (ps.End_Time > ep.TimeStamp 	  	 OR ps.End_Time IS NULL)
-- FOR TESTING
-- select 'select * from @tMCA - FIRST'
-- select * from @tMCA
UPDATE  	 @tMCA 
 	 SET RACFlag = -1 
 	 WHERE RACFlag = 0
SELECT @Cnt=0 -- This is a sanity check to keep the next loop from potentially being infinite
WHILE (@Cnt < 10 
 	 AND (SELECT count(*) 
 	  	  	 FROM @tMCA 
 	  	  	 WHERE RACFlag = -1 )>0 )
 	 BEGIN
 	  	 SELECT @Cnt = @Cnt + 1
 	  	 -- INSERT subsequent level
 	  	 INSERT @tMCA (
 	  	  	 EventCompId,
 	  	  	 EventId, 
 	  	  	 EventNum,
 	  	  	 SourceEventId,
 	  	  	 SourceEventNum,
 	  	  	 ProcessOrder,
 	  	  	 PUId,
 	  	  	 Quantity,
 	  	  	 RACFlag,
 	  	  	 StartTime, 
 	  	  	 EndTime,
 	  	  	 UoM,
 	  	  	 ProdId)
 	  	 SELECT ec.Component_Id,
 	  	  	 ec.Event_Id,
 	  	  	 ee.Event_Num,
 	  	  	 ec.Source_Event_Id, 
 	  	  	 ep.Event_Num,
 	  	  	 mca.ProcessOrder,
 	  	  	 ep.PU_Id,
 	  	  	 COALESCE (ec.Dimension_X,0),
 	  	  	 COALESCE(ec.Report_As_Consumption, 0),
 	  	  	 ee.Start_Time,
 	  	  	 ee.TimeStamp,
 	  	  	 subtype.Dimension_X_Eng_Units,
 	  	  	 COALESCE(ep.Applied_Product, ps.Prod_Id)
 	  	 FROM 	 @tMCA mca
 	  	 JOIN 	 Event_Components ec ON ec.Event_Id = mca.SourceEventId
 	  	 JOIN 	 Events ee ON ee.Event_Id = ec.Event_Id 	  	  	 
 	  	 JOIN 	 Events ep ON ep.Event_Id = ec.Source_Event_Id
 	  	 LEFT JOIN 	 Event_Configuration econ ON econ.PU_Id = ep.PU_Id
 	  	  	  	 AND econ.ET_Id = 1
 	  	 LEFT JOIN 	 Event_Subtypes subtype ON subtype.Event_Subtype_Id = econ.Event_Subtype_Id
 	  	 JOIN 	 Production_Starts ps ON ps.PU_Id = ep.PU_Id
 	  	  	 AND 	 ps.Start_Time <= ep.TimeStamp
 	  	  	 AND 	 (ps.End_Time > ep.TimeStamp
 	  	  	  	 OR 	 ps.End_Time IS NULL)
 	  	 WHERE 	 RACFlag = -1
-- FOR TESTING
-- select 'select * from @tMCA - LOOP'
-- select * from @tMCA
 	  	 -- DELETE the old ones 
 	  	 DELETE FROM @tMCA 
 	  	  	 WHERE RACFlag = -1
 	  	 UPDATE @tMCA 
 	  	  	 SET RACFlag = -1 	 
 	  	  	 WHERE RACFlag = 0
 	 END
-- Retrieve the Product Code for the mca records.
UPDATE mca
 	 SET 	 Product = p.Prod_Code
 	 FROM @tMCA mca
 	 JOIN Products p ON mca.ProdId = p.Prod_Id
--------------------------------------------
-- TIE CONSUMPTION ACTUALS BACK TO BOM ITEMS
--------------------------------------------
--Case Where We Have LotNumber, PUId, and ProdId
UPDATE mca
 	 SET mca.BOMFormulationItemId = bom.BOMFormulationItemId
 	  	 FROM @tMasterBOM bom, @tMCA mca
 	  	 WHERE bom.LotNumber = mca.SourceEventNum
 	  	 AND bom.PUId = mca.PUId
 	  	 AND bom.ProdId = mca.ProdId
 	  	 AND mca.BOMFormulationItemId IS NULL
--Case Where We Only Have PUId and ProdId
UPDATE mca
 	 SET mca.BOMFormulationItemId = bom.BOMFormulationItemId
 	  	 FROM @tMasterBOM bom, @tMCA mca
 	  	 WHERE bom.PUId = mca.PUId
 	  	 AND bom.ProdId = mca.ProdId
 	  	 AND mca.BOMFormulationItemId IS NULL
--Case Where We Only Have ProdId
UPDATE mca
 	 SET mca.BOMFormulationItemId = bom.BOMFormulationItemId
 	  	 FROM @tMasterBOM bom, @tMCA mca
 	  	 WHERE bom.ProdId = mca.ProdId
 	  	 AND mca.BOMFormulationItemId IS NULL
--Case Where We Have None Of Them...Must Look At Bill_Of_Material_Substitution
UPDATE bom
 	 SET bom.BOMSubstitutionId = (SELECT boms.BOM_Substitution_Id FROM Bill_Of_Material_Substitution boms WHERE boms.BOM_Formulation_Item_Id = bom.BOMFormulationItemId)
 	  	 FROM @tMasterBOM bom, @tMCA mca
 	  	 WHERE mca.BOMFormulationItemId IS NULL
UPDATE mca
 	 SET mca.BOMFormulationItemId = (SELECT boms.BOM_Formulation_Item_Id FROM Bill_Of_Material_Substitution boms WHERE boms.BOM_Formulation_Item_Id = bom.BOMFormulationItemId AND boms.Prod_Id = mca.ProdId)
 	  	 FROM @tMasterBOM bom, @tMCA mca
 	  	 WHERE mca.BOMFormulationItemId IS NULL
UPDATE bom
 	 SET bom.ProdId = boms.Prod_Id, bom.EngineeringUnits = boms.Eng_Unit_Id
 	  	 FROM @tMasterBOM bom, Bill_Of_Material_Substitution boms
 	  	 WHERE boms.BOM_Substitution_Id = bom.BOMSubstitutionId
Insert Into @tMasterBOM (ScreenOrder, ItemOrder, ProdCode, ProdDesc, LotNumber, Location, QuantityPer, EngineeringUnits, 
 	  	  	  	  	  	  	  	  	  	  	  	 ScrapFactor, LowerReject, LTolerancePrecision, UpperReject, UTolerancePrecision, 
 	  	  	  	  	  	  	  	  	  	  	  	 BOMSubstitutionId, ProdId, PUId, BOMFormulationItemId, BOMFormulationId, QuantityPrecision, UseEventComponents)
  Select Distinct ScreenOrder = NULL,
 	  	  	  	  ItemOrder = NULL, 
 	  	  	  	  ProdCode = p.prod_code,
 	  	  	  	  ProdDesc = p.prod_desc,
         LotNumber = mca.SourceEventNum,
 	  	  	  	  Location = pu.pu_desc,
 	  	  	  	  QuantityPer = NULL, 
 	  	  	  	  EngineeringUnits = mca.UoM,
         ScrapFactor = 0.0, 
 	  	  	  	  LowerReject = NULL,
 	  	  	  	  LTolerancePrecision = 2,
 	  	  	  	  UpperReject = NULL,
 	  	  	  	  UTolerancePrecision = 2,
 	  	  	  	  BOMSubstitutionId = NULL,
 	  	  	  	  ProdId = mca.ProdId,
 	  	  	  	  PUId = mca.PUId,
 	  	  	  	  BOMFormulationItemId = NULL, 
 	  	  	  	  BOMFormulationId = NULL,
         QuantityPrecision = 2,
 	  	  	  	  UseEventComponents = 1
 	 From @tMCA mca
 	 Join Products p on p.prod_id = mca.ProdId
 	 Left Outer Join Prod_Units pu on pu.pu_id = mca.PUId
 	 Where BOMFormulationItemId IS NULL
-- FOR TESTING
-- select 'select * from @tMCA - FINAL'
-- select * from @tMCA
-- select SourceEventNum, ProdId, PUId, Quantity from @tMCA order by ProdId asc
Declare @@BOMFormulationItemId int
Declare @ConsumptionAmount real
Declare @@LotNumber varchar(50)
Declare @@ProdId int
Declare @@PUId int
Declare @MaxOrder int
-- Cursor Through Each BOM Item
Declare BOMItem_Cursor Insensitive Cursor 
  For Select BOMFormulationItemId, LotNumber, ProdId, PUId From @tMasterBOM 
  For Read Only
Open BOMItem_Cursor
Fetch Next From BOMItem_Cursor Into @@BOMFormulationItemId, @@LotNumber, @@ProdId, @@PUId
While @@Fetch_Status = 0
  Begin
    Select @ConsumptionAmount = NULL 	  	 
 	  	 Select @MaxOrder = max(ScreenOrder) From @tMasterBOM Where ScreenOrder IS NOT NULL
 	  	 Select @MaxOrder = coalesce(@MaxOrder, 0) + 1
 	  	 If @@BOMFormulationItemId is NOT NULL
 	  	  	 Begin
 	  	     -- Totalize Consumption Over This Time Period That Does Tie To A BOM Item
 	  	     Select @ConsumptionAmount = sum(convert(real, Quantity))
 	  	       From @tMCA
 	  	       Where BOMFormulationItemId = @@BOMFormulationItemId
 	  	                       	  	 
 	  	     -- If There Was Consumption, Add To Master BOM
 	  	     If @ConsumptionAmount > 0.0
 	  	       Begin
 	  	          Update @tMasterBOM
 	  	            Set ActualQuantity = ActualQuantity + coalesce(@ConsumptionAmount, 0.0), ScreenOrder = Coalesce(ItemOrder, @MaxOrder)
 	  	             From @tMasterBOM 
 	  	            Where BOMFormulationItemId = @@BOMFormulationItemId
 	  	  	  	  	  	  	  And UseEventComponents = 1
 	  	       End  
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	     -- Totalize Consumption Over This Time Period That Does Not Tie To A BOM Item
 	  	     Select @ConsumptionAmount = sum(convert(real, Quantity))
 	  	       From @tMCA
          Where SourceEventNum = @@LotNumber
 	  	  	  	   And ProdId = @@ProdId
 	  	  	  	   And PUId = @@PUId
 	  	                       	  	 
 	  	     -- If There Was Consumption, Add To Master BOM
 	  	     If @ConsumptionAmount > 0.0
 	  	       Begin
 	  	          Update @tMasterBOM
 	  	            Set ActualQuantity = ActualQuantity + coalesce(@ConsumptionAmount, 0.0), ScreenOrder = Coalesce(ItemOrder, @MaxOrder)
 	  	             From @tMasterBOM 
 	  	  	          Where LotNumber = @@LotNumber
 	  	  	  	  	  	    And ProdId = @@ProdId
 	  	  	  	  	  	    And PUId = @@PUId
 	  	  	  	  	  	  	  And UseEventComponents = 1
 	  	       End  
 	  	  	 End
 	  	 Fetch Next From BOMItem_Cursor Into @@BOMFormulationItemId, @@LotNumber, @@ProdId, @@PUId
  End
 	  	  	 
Close BOMItem_Cursor
Deallocate BOMItem_Cursor
--Use Event Components is False
Update @tMasterBOM
 Set ActualQuantity = QuantityPer * (select count(*) from @tMPA)
  From @tMasterBOM 
 Where UseEventComponents = 0
-- Update Background Color For Measured, Derived, Extra Type Items
Update @tMasterBOM 
  set BackColor = Case
      When UseEventComponents = 1 and ActualQuantity > 0 and ItemOrder Is Null Then 
         23 -- Extra Item With Consumption (LtRed)
      When UseEventComponents = 1 and ActualQuantity > 0 and ItemOrder Is Not Null Then 
         2 -- Consumption Measured Directly (LtGreen)
      Else 
         5 -- Derived Consumption (LtYellow)
    End
--Update Required Quantity
UPDATE bom
 	 SET bom.RequiredQuantity = ((@ForecastQuantity/@StandardQuantity) * bom.QuantityPer + 
 	  	 ((bom.ScrapFactor  * bom.QuantityPer /100) * (@ForecastQuantity/@StandardQuantity))) * CASE When bom.BOMSubstitutionId is NULL Then 1 Else boms.Conversion_Factor End
 	  	 FROM @tMasterBOM bom 
 	  	 LEFT OUTER JOIN Bill_Of_Material_Substitution boms on boms.BOM_Substitution_Id = bom.BOMSubstitutionId
--Update Upper Reject
UPDATE bom
 	 SET bom.UpperReject = ((@ForecastQuantity/@StandardQuantity) * bom.UpperReject)* CASE When bom.BOMSubstitutionId is NULL Then 1 Else boms.Conversion_Factor End
 	  	 FROM @tMasterBOM bom 
 	  	 LEFT OUTER JOIN Bill_Of_Material_Substitution boms on boms.BOM_Substitution_Id = bom.BOMSubstitutionId
--Update Lower Reject
UPDATE bom
 	 SET bom.LowerReject = ((@ForecastQuantity/@StandardQuantity) * bom.LowerReject)* CASE When bom.BOMSubstitutionId is NULL Then 1 Else boms.Conversion_Factor End
 	  	 FROM @tMasterBOM bom 
 	  	 LEFT OUTER JOIN Bill_Of_Material_Substitution boms on boms.BOM_Substitution_Id = bom.BOMSubstitutionId
--Update Remaining Quantity - ErikU Calcs
Update @tMasterBOM
   Set RemainingQuantity = Case
        When BackColor = 5 Then 
          -- Base Requirements On Amounts Remaining + Current Waste Rate (assumed)
          -- TODO: Predicted Remaining may already take into account current waste rates
          (@PredictedRemainingQuantity + (@PredictedRemainingQuantity * case when @ActualGoodQuantity > 0 Then (@ActualBadQuantity / (@ActualBadQuantity + @ActualGoodQuantity)) Else 0 End)) + (QuantityPer * (1.0 + (ScrapFactor/100)))
        When BackColor = 2 Then
          -- Base Requirements On Forecast Total + Current Waste Rate (assumed) - Amount Consumed So Far
          (
            (
              @ForecastQuantity + 
                    (
                      @ForecastQuantity * (case when @ActualGoodQuantity > 0 Then (@ActualBadQuantity / (@ActualBadQuantity + @ActualGoodQuantity)) Else 0 End)
                    ) 
             ) + (QuantityPer * (1.0 + (ScrapFactor/100)))
           ) - ActualQuantity
 	  	  	  	 Else
          -- Base Requirements On Amount Consumed So Far, Projected To Remaining
          case when @ActualGoodQuantity > 0 Then
            (@PredictedRemainingQuantity + (@PredictedRemainingQuantity * (@ActualBadQuantity / (@ActualBadQuantity + @ActualGoodQuantity)))) + (ActualQuantity  / (@ActualBadQuantity + @ActualGoodQuantity)) 
          else
            0
          End                       
      End
-- FOR TESTING
-- select 'select * from @tMasterBOM - ErikU Calcs'
-- Select LotNumber, ProdId, PUId, QuantityPer, RequiredQuantity, ActualQuantity, RemainingQuantity, BackColor, BOMFormulationItemId
--   From @tMasterBOM
--   Order By ProdId
--Update Remaining Quantity - WadeM Calcs
Update @tMasterBOM
   Set RemainingQuantity = Case
        When BackColor = 5 Then 
          -- Base Requirements On Amounts Remaining + Current Waste Rate (assumed)
          -- TODO: Predicted Remaining may already take into account current waste rates
          (
 	  	  	  	  	  	 (RequiredQuantity - ActualQuantity) + 
 	  	  	  	  	  	  	 (
 	  	  	  	  	  	  	  	 (RequiredQuantity - ActualQuantity) * case when @ActualGoodQuantity > 0 Then (@ActualBadQuantity / (@ActualBadQuantity + @ActualGoodQuantity)) Else 0 End)
 	  	  	  	  	  	  	 )
        When BackColor = 2 Then
          -- Base Requirements On Amounts Remaining + Current Waste Rate (assumed) - Amount Consumed So Far
          (
            (
              (RequiredQuantity - ActualQuantity) + 
                    (
                      (RequiredQuantity - ActualQuantity) * (case when @ActualGoodQuantity > 0 Then (@ActualBadQuantity / (@ActualBadQuantity + @ActualGoodQuantity)) Else 0 End)
                    ) 
             )
           )
 	  	  	  	 Else
          -- Base Requirements On Amount Consumed So Far, Projected To Remaining
          case when @ActualGoodQuantity > 0 Then
            ((RequiredQuantity - ActualQuantity) + ((RequiredQuantity - ActualQuantity) * (@ActualBadQuantity / (@ActualBadQuantity + @ActualGoodQuantity)))) + (ActualQuantity  / (@ActualBadQuantity + @ActualGoodQuantity)) 
          else
            0
          End                       
      End
UPDATE mca
 	 SET mca.BOMFormulationItemId = bom.BOMFormulationItemId
 	  	 FROM @tMasterBOM bom, @tMCA mca
 	  	 WHERE bom.LotNumber = mca.SourceEventNum
 	  	 AND bom.PUId = mca.PUId
 	  	 AND bom.ProdId = mca.ProdId
 	  	 AND mca.BOMFormulationItemId IS NULL
-- FOR TESTING
-- select 'select * from @tMasterBOM - WadeM Calcs'
-- Select LotNumber, ProdId, PUId, QuantityPer, RequiredQuantity, ActualQuantity, RemainingQuantity, BackColor, BOMFormulationItemId
--   From @tMasterBOM
--   Order By ProdId
-- Update Foreground Color
Update @tMasterBOM 
  set ColorFlag = Case
 	       When RemainingQuantity < 0 then
 	         6 -- Over Produced / Consumed (Blue)
 	       Else
 	         24 -- Quantity Still Remaining  (Black)
 	     End
-- Update Foreground Color of "Actual Quantity" Cell
Update @tMasterBOM 
  set ActualQuantityColorFlag = Case
 	       When (ActualQuantity <= LowerReject or ActualQuantity >= UpperReject) and ActualQuantity > 0 then
 	         3 -- Outside Reject Limits (Red)
 	       Else
 	         24 -- Inside Reject Limits (Black)
 	     End
--------------------------------------------
-- 	  	 OUTPUT
--------------------------------------------
-- FOR TESTING
-- select 'select * from @tMasterBOM'
Select ScreenOrder,
 	  	  	  ItemOrder, 
       ProdCode, 
       ProdDesc, 
 	  	  	  LotNumber,
 	  	  	  Location,
       QuantityPer = Coalesce(QuantityPer, 0.0), 
       RequiredQuantity = Coalesce(RequiredQuantity, 0.0), 
       ActualQuantity = Coalesce(ActualQuantity, 0.0), 
       RemainingQuantity = Coalesce(RemainingQuantity, 0.0), 
 	  	  	  EngineeringUnits,
       ScrapFactor = Coalesce(ScrapFactor, 0.0), 
       LowerReject = Coalesce(LowerReject, 0.0),
       LTolerancePrecision,
       UpperReject = Coalesce(UpperReject, 0.0),
       UTolerancePrecision,
       'Substitutions' = Coalesce(BOMSubstitutionId, 0),
       ColorFlag,
       BackColor,
 	  	  	  ProdId,
 	  	  	  PUId,
 	  	  	  BOMFormulationItemId = Coalesce(BOMFormulationItemId, 0),
 	  	  	  BOMFormulationId = Coalesce(BOMFormulationId, 0),
       QuantityPrecision,
 	  	  	  ActualQuantityColorFlag,
 	  	  	  UseEventComponents
  From @tMasterBOM
  Order By ScreenOrder, ItemOrder
-- FOR TESTING
-- select 'select * from @tMasterBOM'
-- Select LotNumber, ProdId, PUId, QuantityPer, RequiredQuantity, ActualQuantity, RemainingQuantity, BackColor, ScrapFactor, UseEventComponents, ItemOrder, BOMFormulationItemId
--   From @tMasterBOM
--   Order By ProdId
-- FOR TESTING
-- Select 'Select Process Order Fields'
-- Select @ForecastQuantity as ForecastQuantity,
--        @ActualGoodQuantity as ActualGoodQuantity,
--        @ActualBadQuantity as ActualBadQuantity,
--        @PredictedRemainingQuantity as PredictedRemainingQuantity,
--        @ProductId as ProductId,
--        @StartTime as StartTime,
--        @PathId as PathId,
--        @PPId as PPId
