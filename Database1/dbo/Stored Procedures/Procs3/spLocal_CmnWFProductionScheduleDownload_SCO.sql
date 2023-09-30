
CREATE PROCEDURE [dbo].[spLocal_CmnWFProductionScheduleDownload_SCO]   
--Declare 
    @XML                       xml    -- The B2MML Production Schedule Message           
AS
--Select
--@xml = ' <ProductionSchedule xmlns="http://www.wbf.org/xml/B2MML-V0401" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:Extended="http://www.wbf.org/xml/B2MML-V0401-AllExtensions" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">   <ID>0000004411741946</ID>   <Location>     <EquipmentID>XX01</EquipmentID>     <EquipmentElementLevel>Site</EquipmentElementLevel>     <Location>       <EquipmentID>0</EquipmentID>       <EquipmentElementLevel>Area</EquipmentElementLevel>     </Location>   </Location>   <ProductionRequest>     <ID>000UTSCOA156</ID>     <Description>Low Sugar Blue Bears 150g (01)</Description>     <ProductProductionRuleID>SCO0</ProductProductionRuleID>     <StartTime>2017-01-11T14:00:00</StartTime>     <EndTime>2017-01-11T19:00:00</EndTime>     <SegmentRequirement>       <ID>1</ID>       <EarliestStartTime>2017-01-11T14:00:00</EarliestStartTime>       <LatestEndTime>2017-01-11T19:00:00</LatestEndTime>       <EquipmentRequirement>         <EquipmentID>PESCO00</EquipmentID>       </EquipmentRequirement>       <MaterialProducedRequirement>         <MaterialDefinitionID>000000000080009901</MaterialDefinitionID>         <MaterialLotID>SAPBATCH0A</MaterialLotID>         <Description>HS 400ml</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>SL01</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>           </Location>         </Location>         <Quantity>           <QuantityString>515.000</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>CS</UnitOfMeasure>           <Key>MPRKey01</Key>         </Quantity>         <Quantity>           <QuantityString>0.000</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>CS</UnitOfMeasure>           <Key>MPRKey02</Key>         </Quantity>         <MaterialProducedRequirementProperty>           <ID>QualityStatus</ID>           <Value>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>InspectionLotID</ID>           <Value>             <ValueString>000000000000</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>ExpirationDate</ID>           <Value>             <ValueString>00000000</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>Planned Scrap</ID>           <Value>             <ValueString>0.000</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>Order Type</ID>           <Value>             <ValueString>PI01</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <Value />         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>Planning Seq Number</ID>           <Value>             <ValueString>00000000000000</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>Origin GroupID</ID>           <Value>             <ValueString>F100</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>         <MaterialProducedRequirementProperty>           <ID>Origin Group</ID>           <Value>             <ValueString>Finished Goods</ValueString>             <DataType>string</DataType>           </Value>         </MaterialProducedRequirementProperty>       </MaterialProducedRequirement>       <MaterialConsumedRequirement>         <MaterialDefinitionID>000000000099009904</MaterialDefinitionID>         <Description>99009904:B106</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>ULIN10</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>             <Location>               <EquipmentID>LN01</EquipmentID>               <EquipmentElementLevel>WorkCenter</EquipmentElementLevel>             </Location>           </Location>         </Location>         <Quantity>           <QuantityString>3312</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>KG</UnitOfMeasure>           <Key>MCRKey01</Key>         </Quantity>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationID</ID>           <Description />           <Value>             <ValueString>0197267116</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationSequence</ID>           <Description />           <Value>             <ValueString>0002</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>ScrapPercent</ID>           <Description />           <Value>             <ValueString>3.00</ValueString>             <DataType>float</DataType>             <UnitOfMeasure>percent</UnitOfMeasure>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroup</ID>           <Description />           <Value>             <ValueString>X206</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroupDesc</ID>           <Description />           <Value>             <ValueString>Bases</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialSequenceNumber</ID>           <Description />           <Value>             <ValueString>000020</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>       </MaterialConsumedRequirement>       <MaterialConsumedRequirement>         <MaterialDefinitionID>000000000099009907</MaterialDefinitionID>         <Description>99009907:C750</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>ULIN10</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>             <Location>               <EquipmentID>LN01</EquipmentID>               <EquipmentElementLevel>WorkCenter</EquipmentElementLevel>             </Location>           </Location>         </Location>         <Quantity>           <QuantityString>6193</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>EA</UnitOfMeasure>           <Key>MCRKey01</Key>         </Quantity>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationID</ID>           <Description />           <Value>             <ValueString>0193533257</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationSequence</ID>           <Description />           <Value>             <ValueString>0003</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>ScrapPercent</ID>           <Description />           <Value>             <ValueString>3.00</ValueString>             <DataType>float</DataType>             <UnitOfMeasure>percent</UnitOfMeasure>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroup</ID>           <Description />           <Value>             <ValueString>C750</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroupDesc</ID>           <Description />           <Value>             <ValueString>Labels</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialSequenceNumber</ID>           <Description />           <Value>             <ValueString>000030</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>       </MaterialConsumedRequirement>       <MaterialConsumedRequirement>         <MaterialDefinitionID>000000000099009913</MaterialDefinitionID>         <Description>99009913:L151</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>ULIN1A</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>             <Location>               <EquipmentID>LN01</EquipmentID>               <EquipmentElementLevel>WorkCenter</EquipmentElementLevel>             </Location>           </Location>         </Location>         <Quantity>           <QuantityString>515</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>EA</UnitOfMeasure>           <Key>MCRKey01</Key>         </Quantity>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationID</ID>           <Description />           <Value>             <ValueString>0193533257</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationSequence</ID>           <Description />           <Value>             <ValueString>0005</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>ScrapPercent</ID>           <Description />           <Value>             <ValueString>3.00</ValueString>             <DataType>float</DataType>             <UnitOfMeasure>percent</UnitOfMeasure>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroup</ID>           <Description />           <Value>             <ValueString>L151</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroupDesc</ID>           <Description />           <Value>             <ValueString>Labels</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialSequenceNumber</ID>           <Description />           <Value>             <ValueString>000050</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>       </MaterialConsumedRequirement>       <MaterialConsumedRequirement>         <MaterialDefinitionID>000000000099009916</MaterialDefinitionID>         <Description>99009916:C050</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>ULIN1A</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>             <Location>               <EquipmentID>LN01</EquipmentID>               <EquipmentElementLevel>WorkCenter</EquipmentElementLevel>             </Location>           </Location>         </Location>         <Quantity>           <QuantityString>550</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>EA</UnitOfMeasure>           <Key>MCRKey01</Key>         </Quantity>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationID</ID>           <Description />           <Value>             <ValueString>0193533257</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationSequence</ID>           <Description />           <Value>             <ValueString>0006</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>ScrapPercent</ID>           <Description />           <Value>             <ValueString>3.00</ValueString>             <DataType>float</DataType>             <UnitOfMeasure>percent</UnitOfMeasure>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroup</ID>           <Description />           <Value>             <ValueString>C050</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroupDesc</ID>           <Description />           <Value>             <ValueString>Cases</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialSequenceNumber</ID>           <Description />           <Value>             <ValueString>000060</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>       </MaterialConsumedRequirement>       <MaterialConsumedRequirement>         <MaterialDefinitionID>000000000099009917</MaterialDefinitionID>         <Description>99009917:C050</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>ULIN1A</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>             <Location />           </Location>         </Location>         <Quantity>           <QuantityString>0</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>EA</UnitOfMeasure>           <Key>MCRKey01</Key>         </Quantity>         <MaterialConsumedRequirementProperty>           <ID>Alternate</ID>           <Description />           <Value>             <ValueString>000000000099009916</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>       </MaterialConsumedRequirement>       <MaterialConsumedRequirement>         <MaterialDefinitionID>000000000089009907</MaterialDefinitionID>         <Description>89009907:C750</Description>         <Location>           <EquipmentID>XX01</EquipmentID>           <EquipmentElementLevel>Site</EquipmentElementLevel>           <Location>             <EquipmentID>ULIN10</EquipmentID>             <EquipmentElementLevel>StorageZone</EquipmentElementLevel>             <Location>               <EquipmentID>LN01</EquipmentID>               <EquipmentElementLevel>WorkCenter</EquipmentElementLevel>             </Location>           </Location>         </Location>         <Quantity>           <QuantityString>6193</QuantityString>           <DataType>float</DataType>           <UnitOfMeasure>EA</UnitOfMeasure>           <Key>MCRKey01</Key>         </Quantity>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationID</ID>           <Description />           <Value>             <ValueString>0193533257</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialReservationSequence</ID>           <Description />           <Value>             <ValueString>0003</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>ScrapPercent</ID>           <Description />           <Value>             <ValueString>3.00</ValueString>             <DataType>float</DataType>             <UnitOfMeasure>percent</UnitOfMeasure>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty />         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroup</ID>           <Description />           <Value>             <ValueString>C750</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialOriginGroupDesc</ID>           <Description />           <Value>             <ValueString>Labels</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <ID>MaterialSequenceNumber</ID>           <Description />           <Value>             <ValueString>000030</ValueString>             <DataType>string</DataType>           </Value>         </MaterialConsumedRequirementProperty>         <MaterialConsumedRequirementProperty>           <Value />         </MaterialConsumedRequirementProperty>       </MaterialConsumedRequirement>     </SegmentRequirement>   </ProductionRequest> </ProductionSchedule>'
/***********************************************************/        
/******** Copyright 2004 GE Fanuc International Inc.********/        
/****************** All Rights Reserved ********************/        
/***********************************************************/        
SET NOCOUNT ON        
DECLARE          
       @iDoc                    int,        
    @RowCount      int,        
       @KeyId       int,        
       @TableFieldId     int,        
   @TableFieldValue     varchar(255),        
       @SubscriptionTableID    int,       
       @SubscriptionGRPTableID int,       
    @PrdExecPathTableID    int,        
     @FlgCreateProduct           int,        
     @FlgCreateUOM              int,        
       @ErrMsg                    varchar(4000),        
       @ErrCode       int,        
       @RC                    int,        
       @PPId                       int,        
       @UserId                      int,        
       @ProcessOrder                varchar(100),        
       @CommentId                   int,        
       @Comment                      varchar(4000),        
       @ProdId                      int,        
       @PathId                      int,        
       @PPStatusId                  int,        
       @SPPPStatusId             int,        
       @ParentId                      int,        
       @NodeId                      int,        
       @ERNodeId                      int,        
       @SRNodeId                      int,        
       @PPSetupId                  int,        
       @PUId                    int,        
       @DebugFlag                  int,        
       @mprNoProduct                 int,        
       @mcrNoProduct                 int,        
       @mprNoPathProd               int,        
       @mprNoPath                  int,        
       @NoFormulation               int,        
       @DefaultMPRProdId               int,        
       @DefaultMCRProdId               int,        
       @DefaultBOMFamilyId           int,        
       @DefaultProdFamilyId      int,        
       @DefaultRawMaterialProdId     int,        
       @ProdCode                      varchar(100),        
       @ProdDesc                      varchar(100),        
       @DataSourceId                int,        
       @FormulationId               int,        
       @FormulationItemId           int,        
       @TableFieldDesc            varchar(255),        
       @ValueString             varchar(255),        
       @StartTime                  datetime,        
       @EndTime                      datetime,        
       @TransType                  int,        
       @TransNum                   int,        
       @Qty                    FLOAT,        
       @MaterialLotId            varchar(100),        
       @ErrTemp                   varchar(255),        
       @BOMFITableId             int,        
       @ProdUnitsTableId            int,        
       @PPTableId                  int,        
       @FlgRemoveLeadingZeros        int,        
       @PPErrorStatusID               int,        
       @OriginalProdId               int,        
       @FlgIgnoreBOMInfo               int,        
       @CreatePUAssoc               int,        
       @CreatePathAssoc               int,        
       @NoUpdatePOStatusesMask        varchar(255),        
       @Pos                    int,        
       @ParsedString             varchar(255),        
       @CurrentPPStatusId           int,        
       @FlgPrependNewProdWithDesc    int,        
       @PrependNewProdDelimiter     varchar(255),        
       @FlgUpdateMCRDesc            int,        
       @FlgUpdateMPRDesc            int,        
       @FlgUpdateDesc            int,        
       @MaterialReservationSequence  varchar(255),        
       @ScrapPercent             varchar(255),        
       @RecSPTotal             int,        
       @RecSPId                   int,        
       @RecParmTotal             int,        
       @RecParmId                  int,        
       @SQLStatement             Nvarchar(2000),        
       @Id                         int,        
       @ParmDefinition            Nvarchar(2000),        
       @SPOutputValue            int,        
       @flgCheckErrorStatus      int,        
       @PSTableId                  int,        
       @TimeModifier             int,        
       @SqlRetStat              int,        
       @PSOriginalEngUnitCodeUDP     int,        
       @UOM                    varchar(255), 
	   @SCOTableFieldid          int,
	   @ISSCOLINE				 int,
	   @PrdexecInputid			 int,
	   @OriginGroupid            int,
	   @PrdInputtableid				Int,
@isBomDownloadfieldid			Int,
@BOMMax							Int,
@BOMMin							Int,
@BOMOriginGroupid				Int,
	          
               
       --2012-06-19        
       @FlgInclProdInBOMFDesc   int,        
    @cntPR       int,        
       @loopPR       int,        
       @bmfId       int,        
       @BOMPO       varchar (50),        
       @BOMDesc       varchar (255),        
       @BOMProdDesc      varchar (255),        
  @BOMFormulationDesc    varchar (255),        
               
-- --return Variables        
     @RetProcessOrder         varchar(50),        
     @RetPathCode            varchar(50),        
     @RetPathProdCode         varchar(50),        
     @RetPathUOM               varchar(25),        
     @RetErrCode               varchar(50),        
     @RetErrMsg               varchar(4000),        
     @FlgSendRSProductionPlan   int,        
     @FlgSendRSProductionSetup   int,        
     @FlagCreate               int,        
       @OECommonSubscription   int,        
@OEDownloadSubscription   int,        
               
-- Variables added for MOT        
    @ERPOrderStatus     varchar(255),        
    @BOMFormulationItemTableId  int,        
    @ExpirationDate     varchar(50),        
    @CountOfDescription    int,        
    @DescriptionText     varchar(255),        
    @DescriptionTextAll    varchar(1000) ,
	
	@count					Int,
	
	@MinCount				Int,
	@value					Varchar(10)
         
            
-- Task 7 - Variables added for MOT        
DECLARE        
 @FlgPPExisted      int,        
 @FlgDataChanged      int,        
 @FlgPPChanged      int,        
 @FlgPPUDPChanged     int,        
 @FlgERPOrderStatus     int,        
 @OldPPPathCode      varchar(50),        
 @OldPPProdCode      varchar(50),        
 @OldPPMaterialLotId     varchar(50),        
 @OldPPExpirationDate    varchar(50),        
 @OldPPDeliveredQty     varchar(50),         
 @OldPPFormulationDesc    varchar(50),        
 @OldPPForecastStartDate    datetime,        
 @OldPPForecastEndDate    datetime,        
 @OldPPPlannedQty     FLOAT,        
 @OldPPComment      varchar(1000),        
 @NewPPPathCode      varchar(50),        
 @NewPPProdCode      varchar(50),        
 @NewPPMaterialLotId     varchar(50),        
 @NewPPExpirationDate    varchar(50),        
 @NewPPDeliveredQty     varchar(50),         
 @NewPPFormulationDesc    varchar(50),        
 @NewPPForecastStartDate    datetime,        
 @NewPPForecastEndDate    datetime,        
 @NewPPPlannedQty     FLOAT,        
 @NewPPComment      varchar(1000)        
        
-- Task 7.03        
DECLARE @LoopCount      int,        
  @LoopIndex      int        
        
        
-- Task 7.04 Compare BOM         
DECLARE @FlgBOMChanged     int,        
  @OldBOMFormulationDesc   varchar(25),        
  @OldBOMStdQty     FLOAT,        
  @OldBOMEngUnit     varchar(15),        
  @NewBOMFormulationDesc   varchar(25),        
  @NewBOMStdQty     FLOAT,        
  @NewBOMEngUnit     varchar(15)        
        
-- Task 7.05 Compare BOM Item (MCR)         
DECLARE @FlgBOMItemChanged    int        
        
-- Task 7.06 Compare BOM Item Attributes(MCRP)        
DECLARE @FlgBOMItemAttributesChanged int        
        
-- Task 7.10 Retrive the current Status of the Process Order        
DECLARE @FlgActiveBefore    int        
        
--  Task 7.12         
DECLARE @DeliveredQty     varchar(25),        
  @FlgChanged      int        
        
-- Task 8 - Get the UseCase and Action as per the state logic table        
DECLARE @UseCaseId      int,        
  @PPCreateAction     int,        
  @PPCreateStatusStr    varchar(25),        
@PPUpdateAction     int,        
  @PPUpdateStatusStr    varchar(25),        
  @FlgAllowDataChange    int,        
  @FlgAlert      int,        
  @FlgLockedData     int,        
  @FlgUnlockedData    int,        
  @PPCurrentStatusStr    varchar(50)        
        
-- Task 9 Building the ErrCode and Message        
DECLARE @ErrMessageSubject    varchar(1000),        
  @ErrMessageText     varchar(1000),        
  @ErrSeverity     int        
        
------------------------------------------------------------------------------        
--Production Plan Result Set        
------------------------------------------------------------------------------        
DECLARE     
  @ParmPPId      int,        
  @ParmPathId      int,        
  @ParmCommentId     int,        
  @ParmProdId      int,        
  @ParmImpliedSequence   int,        
  @ParmPPStatusId     int,        
  @ParmPPTypeId     int,        
  @ParmSourcePPId     int,        
  @ParmUserId      int,        
  @ParmParentPPId     int,        
  @ParmControlType    int,        
  @ParmForecastStartDate   datetime,        
  @ParmForecastEndDate   datetime,        
  @ParmForecastQuantity   FLOAT,        
  @ParmProductionRate    FLOAT,        
  @ParmAdjustedQuantity   FLOAT,        
  @ParmBlockNumber    varchar(50),        
  @ParmProcessOrder    varchar(50),        
  @ParmBOMFormulationId   Bigint,        
  @ParmUserGeneral1    varchar(255),        
@ParmUserGeneral2    varchar(255),        
  @ParmUserGeneral3    varchar(255)        
        
-- Task 10 BOM Processing for Alternate Materials        
DECLARE @AltNodeId      int,        
  @AltProdId      int,        
  @AltProdCode     varchar(25),        
  @AltEngUnitId     int,        
  @AltEngDesc      varchar(25),        
  @PrimaryNodeId     int,        
  @PrimaryProdId     int,        
  @PrimaryProdCode    varchar(25),        
  @PrimaryEngUnitId    int,        
  @PrimaryEngDesc     varchar(25),        
  @ConversionFactor    FLOAT,        
  @Entryon      Datetime        
        
        
/*6Feb2014*/        
-- Bala created Temp table to avoid Material reservation ID & Sequence        
DECLARE @temp TABLE (        
id   int identity (1,1),        
scrap  varchar(50),        
Parent  int,        
Nodeid  int        
)        
/*6Feb2014*/        
        
/*24 Sep 2014*/        
--Bala created Temp table to add alternate material quantity to main Material        
 DECLARE @Alttemp TABLE (        
Quantity FLOAT,        
Parent int,        
Nodeid int,        
prev int)   
 DECLARE @ExistMatNewOG TABLE (        
Id			Int Identity(1,1),        
Prodcode    Varchar(50),   
puid        int      
)   
Declare @MainmaterialDetails TABLE (
OG Varchar(10),
puid int,
nodeid int,
Previd int)     
        
/*24 Sep 2014*/        
-------------------------------------------------------------------------------        
-- Error Code table        
-------------------------------------------------------------------------------        
DECLARE  @tErr              TABLE (        
       ErrorCode            int,        
       ErrorCategory   varchar(500),        
       ErrorMsg     varchar(500),        
       Severity     int,        
       ReferenceData         varchar(500))        
               
DECLARE  @tErrRef           TABLE (        
       ErrorCode            int,        
       ReferenceData         varchar(500))  
	   
Declare      @SCOPathUnits TABLE(
      id int identity(1,1),
	  Produnitid int
	  )
Declare @SCOUnitOG Table(
     id int Identity(1,1),
	 OG Varchar(5),
	 Inputid int,
	 puid int)
        
DECLARE @Prdexecpaths TABLE
(ID          Int Identity(1,1),
PUid         Int,
pathid       Int,
peiid        Int
)
        
-------------------------------------------------------------------------------        
SELECT  @DebugFlag     = 0,        
     @FlagCreate     = 1        
-------------------------------------------------------------------------------        
-- Task 1 - Initialize variables and Get parameters        
-------------------------------------------------------------------------------        
SELECT  @ErrMsg                   = '',        
     @FlgSendRSProductionPlan  = 0,        
     @FlgSendRSProductionSetup  = 0,        
  @SubscriptionTableID        = 27,         
  @PrdExecPathTableID   = 13,         
  @OECommonSubscription  = -7,        
  @OEDownloadSubscription     = -8,        
     @BOMFITableId           = 28,   -- Bill_Of_Material_Formulation_Item        
     @PPTableId               = 7,    -- Production_Plan,        
     @PSTableId               = 8,    -- Production_Setup        
     @ProdUnitsTableId        = 43,   -- Prod_Units        
  @PSOriginalEngUnitCodeUDP   = -71,   -- Production Setup (batch to produce) Original Engineering Unit         
  @BOMFormulationItemTableId = 28 ,      
  @SubscriptionGRPTableID    = 29      
  --SCO
  SET @PrdexecInputid = ( SELECT tableid FROM dbo.Tables WITH (NOLOCK) WHERE tablename like 'prdexec_inputs')
  SET @OriginGroupid  = ( SELECT Table_Field_id FROM dbo.Table_Fields WITH (NOLOCK) WHERE Table_Field_Desc like 'Origin Group' and tableid = @PrdexecInputid)
          
-- Get Common\Site Parameters        
--SELECT @LookUpValue = tfv.Value        
--  FROM dbo.Table_Field_values tfv        
--  WHERE tfv.TableId = @TableId        
--  AND tfv.KeyId = @KeyId        
--  AND tfv.Table_Field_Id = @PropertyId        
          
EXEC   dbo.spCmn_UDPLookupById         
       @DataSourceId              OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OECommonSubscription,           --@KeyId              int,        
       -3,                             -- BTSched - DataSourceId        
       '18'                            --@DefaultValue       Nvarchar(1000)        
EXEC   dbo.spCmn_UDPLookupById        
       @PPStatusID              OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OECommonSubscription,           --@KeyId              int,        
       -11,                            --BTSched - DefPPStatusId        
       '1'                            --@DefaultValue       Nvarchar(1000)        
        
-- Added in 2012-06-19        
EXEC   dbo.spCmn_UDPLookupById        
       @FlgRemoveLeadingZeros              OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       -14,                            --BTSched - FlagRemovwLeadingZeros        
       '0'                            --@DefaultValue       Nvarchar(1000)        
        
EXEC   dbo.spCmn_UDPLookupById        
       @PPErrorStatusID      OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,               --@TableId           int,        
       @OECommonSubscription,           --@KeyId              int,        
       -12,                             --BTSched - ErrPPStatusId        
       '0'                             --@DefaultValue       Nvarchar(1000)                      
EXEC   dbo.spCmn_UDPLookupById        
       @TimeModifier            OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OECommonSubscription,           --@KeyId              int,        
       -69,                            --Time Modifier        
       0                                --@DefaultValue       Nvarchar(1000)        
-- Download Subscriptions        
EXEC   dbo.spCmn_UDPLookupById        
       @DefaultBOMFamilyId       OUTPUT,  --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,               --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       -5,                             --BTSched - DefBOMFamilyId        
       '1'                             --@DefaultValue       Nvarchar(1000)        
EXEC   dbo.spCmn_UDPLookupById        
       @mprNoPath              OUTPUT,  --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,               --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       -8,                             --BTSched - NoPathOption        
       '3'                             --@DefaultValue       Nvarchar(1000)        
EXEC   dbo.spCmn_UDPLookupById        
       @FlgIgnoreBOMInfo           OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,               --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       -19,                             --BTSched - IgnoreBOMInfo        
       '0'                             --@DefaultValue       Nvarchar(1000)        
EXEC   dbo.spCmn_UDPLookupById        
       @MaterialReservationSequence   OUTPUT,  --@LookupValue      Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,                  --@TableId       int,        
       @OEDownloadSubscription,              --@KeyId           int,        
       -59,                             --'BTSched - MaterialSeqMCRPDesc',                      
       'materialreservationsequence'       --@DefaultValue       Nvarchar(1000)        
EXEC   dbo.spCmn_UDPLookupById        
       @ScrapPercent            OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       -60,                            --BTSched - ScrapPercentMCRPDesc        
       'scrappercent'                  --@DefaultValue       Nvarchar(1000)        
        
        
--2012-06-19         
EXEC dbo.spcmn_UDPLookup               
      @FlgInclProdInBOMFDesc OUTPUT,        
      @SubscriptionTableID,        
      @OEDownloadSubscription,         
      'BTSched - Include Prod in BOMF Desc',        
      0        
              
            
        
        
        
 ------------------------------------------------------------------------------              
 --Added parameters for MOT        
 ------------------------------------------------------------------------------        
DECLARE @MPRKey01      varchar(255),        
  @MPRKey02      varchar(255),        
  @TxtPlannedQty     varchar(255),        
  @TxtDeliveredQty    varchar(255),        
  @ERPOrderStatus_REL    varchar(255),        
  @ERPOrderStatus_CTECO   varchar(255),        
  @ERPOrderStatus_OTHER   varchar(255),        
  @MESOrderStatus_PENDING   varchar(255),        
  @MESOrderStatus_INITIATE  varchar(255),        
  @MESOrderStatus_READY   varchar(255),          
  @MESOrderStatus_ACTIVE   varchar(255),        
  @MESOrderStatus_COMPLETE  varchar(255),        
  @MESOrderStatus_CONFIRMTOSAP varchar(255),        
  @MESOrderStatus_SAPCOMPLETE  varchar(255),        
  @MPRPName_EXPIRATIONDATE  varchar(255),        
  @FlgRemoveLeadingZerosPO  varchar(255),        
  @MCR_Dummy      varchar(25),        
  @POComment      int        
          
EXEC   dbo.spCmn_UDPLookup        
       @MPRKey01            OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MPRKey01',              --BTSched - MRKey01        
       'Planned'                 --@DefaultValue       Nvarchar(1000)        
        
EXEC   dbo.spCmn_UDPLookup        
       @MPRKey02            OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MPRKey02',              --BTSched - MRKey02        
       'Delivered'                --@DefaultValue       Nvarchar(1000)        
        
EXEC   dbo.spCmn_UDPLookup        
       @ERPOrderStatus_REL    OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - ERPOrderStatus_REL',     --BTSched - ERPOrderStatus_REL        
       'REL'                  --@DefaultValue       Nvarchar(1000)          
           
EXEC   dbo.spCmn_UDPLookup        
       @ERPOrderStatus_CTECO    OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - ERPOrderStatus_CTECO',   --BTSched - ERPOrderStatus_CTECO        
       'C~T'                  --@DefaultValue       Nvarchar(1000)          
         
EXEC   dbo.spCmn_UDPLookup        
      @TxtPlannedQty           OUTPUT,     --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - TxtPlannedQty',      --BTSched - Planned        
       'Planned'                 --@DefaultValue       Nvarchar(1000)        
        
EXEC   dbo.spCmn_UDPLookup        
       @TxtDeliveredQty       OUTPUT,    --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - TxtDeliveredQty',       --BTSched - Delivered        
       'Delivered'                --@DefaultValue       Nvarchar(1000)        
        
EXEC   dbo.spCmn_UDPLookup        
       @ERPOrderStatus_OTHER    OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - ERPOrderStatus_OTHER',   --BTSched - ERPOrderStatus_OTHER        
       'OTHER'                 --@DefaultValue       Nvarchar(1000)          
        
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_PENDING   OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,        --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MESOrderStatus_Pending', --BTSched - MESOrderStatus_PENDING        
       'Pending'                 --@DefaultValue       Nvarchar(1000)          
        
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_INITIATE   OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MESOrderStatus_Initiate',--BTSched - MESOrderStatus_INITIATE        
       'Initiate'              --@DefaultValue       Nvarchar(1000)          
        
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_ACTIVE   OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MESOrderStatus_Active',  --BTSched - MESOrderStatus_ACTIVE        
       'Active'                 --@DefaultValue       Nvarchar(1000)          
        
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_COMPLETE   OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
      'BTSched - MESOrderStatus_Complete', --BTSched - MESOrderStatus_COMPLETE        
       'Complete'                --@DefaultValue       Nvarchar(1000)             
           
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_CONFIRMTOSAP  OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MESOrderStatus_ConfirmToSAP',  --BTSched - MESOrderStatus_CONFIRMTOSAP        
       'ConfirmToSAP'               --@DefaultValue       Nvarchar(1000)         
        
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_SAPCOMPLETE  OUTPUT,--@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MESOrderStatus_SAPComplete',                            --BTSched - MESOrderStatus_SAPCOMPLETE        
       'SAPComplete'                --@DefaultValue       Nvarchar(1000)         
        
EXEC   dbo.spCmn_UDPLookup        
       @MESOrderStatus_READY  OUTPUT,  --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MESOrderStatus_Ready',   --BTSched - MESOrderStatus_READY        
       'Ready'               --@DefaultValue       Nvarchar(1000)         
        
EXEC   dbo.spCmn_UDPLookup        
       @MPRPName_EXPIRATIONDATE  OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - MPRPName_ExpirationDate',   --BTSched - MPRPName_ExpirationDate        
       'Ready'               --@DefaultValue       Nvarchar(1000)         
        
  -- Added in 2013-02-27 MK        
EXEC   dbo.spCmn_UDPLookup        
       @FlgRemoveLeadingZerosPO OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - FlgRemoveLeadingZerosPO',   --BTSched - FlgRemoveLeadingZerosPO        
       '0'               --@DefaultValue       Nvarchar(1000)         
        
  -- Added in 2013-02-27 MK        
EXEC   dbo.spCmn_UDPLookup        
       @MCR_Dummy  OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
       @SubscriptionTableID,              --@TableId           int,        
       @OEDownloadSubscription,           --@KeyId              int,        
       'BTSched - DummyProduct',   --BTSched - 'BTSched - DummyProduct'        
       'DUMMY'               --@DefaultValue       Nvarchar(1000)         
        
        
IF @DebugFlag = 1               
 SELECT  'Task 1',        
   @MPRKey01      AS MPRKey01,        
   @MPRKey02      AS MPRKey02,        
   @TxtPlannedQty     AS TxtPlannedQty,        
   @TxtDeliveredQty    As TxtDeliveredQty,        
   @ERPOrderStatus_REL    AS ERPOrderStatus_REL,        
   @ERPOrderStatus_CTECO   AS ERPOrderStatus_CTECO,        
   @ERPOrderStatus_OTHER   AS ERPOrderStatus_OTHER,        
   @MESOrderStatus_PENDING   AS MESOrderStatus_PENDING,        
   @MESOrderStatus_INITIATE  AS MESOrderStatus_INITIATE,        
   @MESOrderStatus_READY   AS MESOrderStatus_READY,           
   @MESOrderStatus_ACTIVE   AS MESOrderStatus_ACTIVE,        
   @MESOrderStatus_COMPLETE  AS MESOrderStatus_COMPLETE,        
   @MESOrderStatus_CONFIRMTOSAP AS MESOrderStatus_CONFIRMTOSAP,        
   @MESOrderStatus_SAPCOMPLETE  AS MESOrderStatus_SAPCOMPLETE,        
   @MPRPName_EXPIRATIONDATE  AS MPRPNAME_EXPIRATIONDATE,        
   @FlgRemoveLeadingZerosPO  AS FlgRemoveLeadingZerosPO,        
   @MCR_Dummy      AS MCR_Dummy          
           
-------------------------------------------------------------------------------        
-- Configure Flag to enable/disable routine that assigns the 'Error' status        
-- to a process order if some conditions such as new MPR product happens        
-- based on the existence of this status Id.        
-------------------------------------------------------------------------------        
--UL 2.0 replace COUNT(*) > 0 by EXISTS        
SELECT  @flgCheckErrorStatus       = 0        
IF EXISTS(SELECT * FROM  dbo.Production_Plan_Statuses WITH(NOLOCK)  WHERE PP_Status_Id  = @PPErrorStatusID)        
BEGIN        
       SELECT  @flgCheckErrorStatus       = 1        
END        
-- Bala Error UDP For Produced Material        
SET @POComment = (SELECT Table_Field_Id FROM Table_Fields TF WITH (NOLOCK) WHERE Table_Field_Desc LIKE 'BTSCHED - COMMENTs')        
        
        
-------------------------------------------------------------------------------        
-- Task 2 - Parse the XML        
-------------------------------------------------------------------------------        
-- Task 2.01 Make a Table to hold the parsed xml.        
-------------------------------------------------------------------------------        
--DECLARE       @tXML       TABLE (        
CREATE TABLE #tXML (        
       Id              int,         
       ParentId             int,         
       NodeType             int,         
       LocalName            varchar(2000),         
       Prev              int,         
       Ttext             varchar(2000))        
        
CREATE CLUSTERED INDEX txml_idx4 on #tXML(parentid, id)        
-------------------------------------------------------------------------------        
-- parse the xml        
-------------------------------------------------------------------------------        
        
EXEC dbo.sp_xml_PrepareDocument         
       @Idoc                     OUTPUT,         
       @Xml,        
       '<ns0:ProductionSchedule xmlns:ns0="http://www.wbf.org/xml/B2MML-V0401"/>'        
--       '<ns0:ProcessProductionSchedule xmlns:ns0="http://www.wbf.org/xml/B2MML-V0401"/>'        
        
-------------------------------------------------------------------------------     
-- fill the TABLE with parsed xml        
-------------------------------------------------------------------------------        
-- print '--EnteringInsert: ' + convert(char(30), getdate(), 21)        
INSERT  #tXML (        
       Id,        
       ParentId,        
       NodeType,        
       LocalName,        
       Prev,        
       tText)        
       SELECT  Id,        
              ParentId,        
              NodeType,        
              SUBSTRING(LocalName, 1, 4000),        
              Prev,        
              SUBSTRING(TEXT, 1, 4000)        
              FROM  OPENXML(@idoc, '/ns0:ProductionSchedule', 2)         
-- print '--PrintInsertSelect: ' + convert(char(30), getdate(), 21)        
        
-------------------------------------------------------------------------------        
-- close the xml document        
-------------------------------------------------------------------------------        
-- print '--EnteringXMLRemoveDoc: ' + convert(char(30), getdate(), 21)        
EXEC   dbo.sp_xml_RemoveDocument         
       @Idoc        
        
IF @DebugFlag = 1        
   SELECT '2.01', * FROM #tXML ORDER BY ParentId, id        
------------------------------------------------------------------------------        
-- Task 2.02 Declare the tables fr XML Parsing        
-- Now we are ready to make something useful of the parsed xml document        
-------------------------------------------------------------------------------        
-- Production Request table        
-------------------------------------------------------------------------------        
-- print '--XML Ready: ' + convert(char(30), getdate(), 21)        
DECLARE   @tPS              TABLE (        
     Id                  int  IDENTITY(1,1),        
     NodeId               int,        
     ScheduleId         varchar(100),        
     EquipmentId            varchar(100)        
  )        
        
DECLARE   @tPR              TABLE (        
     Id                  int  IDENTITY(1,1),        
     NodeId               int,        
     ProcessOrder        varchar(100),        
     Comment               varchar(1000),        
     FormulationDesc        varchar(255),        
     BOMId              int,        
     FormulationId       int,        
     CommentId           int,        
     Status              int,        
     ERPOrderStatus     varchar(255))        
              
-------------------------------------------------------------------------------        
-- Segment Request table        
-------------------------------------------------------------------------------        
DECLARE  @tSR              TABLE (        
       ParentId             int,        
       NodeId             int,        
       EarliestStartTime  datetime,        
       LatestEndTime      datetime)        
-------------------------------------------------------------------------------        
-- Equipment Request table        
-------------------------------------------------------------------------------        
DECLARE  @tER              TABLE (        
       Id              int              IDENTITY(1,1),        
       ParentId              int,        
       NodeId              int,        
       EquipmentId        varchar(100),        
       PathId              int,        
       PPId               int,        
       CommentId             int,        
     FormulationId       int,        
       PPStatusId       int,        
       Status             int,        
       --Path specific UDPs        
       DefaultProdFamilyId     int   ,        
       UserId       int   ,        
       mprNoPathProd     int   ,        
       mprNoProduct     int   ,        
       mcrNoProduct     int   ,        
       NoFormulation     int   ,        
       DefaultMPRProdId    int   ,        
       DefaultMCRProdId    int   ,        
       DefaultRawMaterialProdId  int   ,        
       NoUpdatePOStatusesMask   varchar(255)   ,        
       FlgPrependNewProdWithDesc   int   ,        
       PrependNewProdDelimiter   varchar(255)   ,        
       FlgUpdateMPRDesc    int   ,        
       FlgUpdateMCRDesc    int   ,        
       FlgCreateProduct    int   ,        
       FlgRemoveLeadingZeroes  int)    -- AJ150423        
               
-------------------------------------------------------------------------------        
-- Material Produced Requirement table        
-------------------------------------------------------------------------------        
DECLARE  @tMPR              TABLE (        
       Id               int              IDENTITY(1,1),        
       ParentId               int,        
       NodeId               int,        
       ProdCode               varchar(100),        
       ProdDesc               varchar(100),        
       ProdId               int,        
       MaterialLotID        varchar(100),        
       EquipmentId         varchar(100),        
       QuantityString        varchar(100),              
       UOM                   varchar(100),        
       PUId                   int,        
       PathUoM               varchar(100),        
       Qty                   FLOAT,        
       DeliveredQuantityString varchar(100),        
       DeliveredUOM      varchar(100),        
       DeliveredQty      Float,        
       FlgNewProduct           int,        
       PathId              int,        
       CreatePUAssoc           int,        
       CreatePathAssoc       int,        
       Status              int,        
       PPSetupId              int)        
               
-------------------------------------------------------------------------------        
-- Material Produced Requirement Property table        
-------------------------------------------------------------------------------        
DECLARE  @tMPRP              TABLE (        
       ParentId               int,        
       NodeId               int,        
       Id                   varchar(100),        
       ValueString       varchar(100))        
-------------------------------------------------------------------------------        
-- Material Consumed Requirement table        
-- 01/09/2015 BalaMurugan Rajendran Added MaterialOriginGroup Logic for Comparison for calling PE user activity for PO validation.        
-------------------------------------------------------------------------------        
DECLARE  @tMCR              TABLE (        
       Id                  int              IDENTITY(1,1),        
       ParentId               int,        
       NodeId               int,        
       ProdCode               varchar(100),        
       ProdDesc               varchar(100),        
       ProdId               int,        
       MaterialLotId        varchar(100),        
       EquipmentId         varchar(100),        
       QuantityString        varchar(100),        
       UOM                   varchar(100),        
       PUId                   int,        
       FormulationUoM        varchar(100),        
       FormulationId        int,        
       FormulationItemId       int,        
       FlgNewProduct           int,        
       Status              int,        
         FlgAlternate      int,        
       MaterialOriginGroup     Varchar(10))        
-------------------------------------------------------------------------------        
-- Material Consumed Requirement Property table        
-------------------------------------------------------------------------------        
DECLARE  @tMCRP              TABLE (        
       ParentId               int,        
       NodeId               int,        
       Id                   varchar(100),        
       ValueString         varchar(100))        
-------------------------------------------------------------------------------        
-- Location table        
-------------------------------------------------------------------------------        
DECLARE  @tLocation        TABLE (        
       ParentId               int,        
       NodeId               int,        
       EquipmentId            varchar(100),        
       EquipmentElementLevel   varchar(100))        
-------------------------------------------------------------------------------        
-- Quantity table        
-------------------------------------------------------------------------------        
DECLARE  @tQty              TABLE (        
       ParentId   int,        
       NodeId               int,        
       QuantityString        varchar(100),        
       UOM                   varchar(100),        
       KeyString      varchar(100),        
       KeyParameter      varchar(100))      -- SP 20120210        
-------------------------------------------------------------------------------        
-- <Any> UDPS table for ProductionRequest element (ProductionPlan)         
-------------------------------------------------------------------------------        
DECLARE  @tAnyUDP       TABLE (        
       ParentId               int,        
       NodeId               int,        
       TableId              int,        
       KeyId                  int,        
       tText                  varchar(255),        
       ElementName           varchar(255),        
       UDPElementId            int)        
-------------------------------------------------------------------------------        
-- <Any> Custom Stored Procedures elements        
-------------------------------------------------------------------------------        
DECLARE  @tAnySP              TABLE (        
       Id                  int       IDENTITY(1,1),               
       ParentId               int,        
       ElementName           varchar(255),        
       NodeId               int,        
       tText                  varchar(255),        
       Status              int)        
-------------------------------------------------------------------------------        
-- <Any> UDPS table for MaterialProducedRequirement element (ProductionSetup)        
-------------------------------------------------------------------------------        
DECLARE  @tAnyMPRUDP       TABLE (        
       ParentId               int,        
       NodeId               int,        
       TableId              int,        
       KeyId                  int,        
       tText      varchar(255),        
       ElementName           varchar(255),        
       UDPElementId            int)        
-------------------------------------------------------------------------------        
-- Non Update Statuses table        
-- print '--Non Update Statuses table: ' + convert(char(30), getdate(), 21)        
-- ???? Ask Alex what's that        
-------------------------------------------------------------------------------        
DECLARE @tPPStatus TABLE (        
       PPStatusId       int              NULL)        
               
SELECT  @NoUpdatePOStatusesMask = @NoUpdatePOStatusesMask +','        
SELECT  @Pos =CharIndex(',', @NoUpdatePOStatusesMask)        
WHILE @Pos > 1         
BEGIN        
       SELECT @ParsedString       = SubString(@NoUpdatePOStatusesMask, 1, @Pos -1)        
       IF  ISNumeric(@ParsedString) = 1        
              INSERT  @tPPStatus (PPStatusId)        
                     VALUES   (Convert(int,@ParsedString))        
       SELECT   @NoUpdatePOStatusesMask       = Right(@NoUpdatePOStatusesMask, Len(@NoUpdatePOStatusesMask) - @Pos)        
       SELECT   @Pos =CharIndex(',', @NoUpdatePOStatusesMask)        
END        
        
IF @DebugFlag = 1        
   SELECT @NoUpdatePOStatusesMask AS NoUpdatePOStatusesMask,        
    @ParsedString AS ParsedString,        
    @Pos AS Pos        
         
-------------------------------------------------------------------------------        
-- Task 2.0x - Production Schedule               
-- print '--ps: ' + convert(char(30), getdate(), 21)        
-------------------------------------------------------------------------------        
INSERT  @tPS (        
       NodeId )         
SELECT  Id         
       FROM       #tXML         
       WHERE       LocalName = 'ProductionSchedule'        
            
UPDATE  ps        
       SET     ScheduleId = xIc.tText         
       FROM  @tPS ps        
       LEFT  JOIN   #tXML xI ON ps.NodeId = xI.ParentId AND xI.LocalName = 'Id'        
       LEFT  JOIN   #tXML xIc ON xI.Id = xIc.ParentId        
        
 IF @DebugFlag = 1        
   SELECT '2.0x Production Schedule', * FROM @tPS        
          
-------------------------------------------------------------------------------        
-- Task 2.03 - Production Request         
-- print '--pr: ' + convert(char(30), getdate(), 21)        
-- 2012-06-19 Add @FlgRemoveLeadingZeros Logic        
-- 2013-02-27 MK, leadingzeros for PO and product are different        
-------------------------------------------------------------------------------        
DECLARE @tblDescription TABLE        
  ( Id    int  IDENTITY,        
   xdId   int,        
   xdParentId  int,        
   DescriptionText varchar(255)        
  )        
          
INSERT  @tPR (        
       NodeId )         
       SELECT  Id         
              FROM       #tXML         
              WHERE       LocalName = 'ProductionRequest'        
       UPDATE  pr        
       --SET     ProcessOrder = xIc.tText,        
       SET      ProcessOrder = CASE    Convert(int, @FlgRemoveLeadingZerosPO)         
                                WHEN        0 THEN      xIc.tText        
                                WHEN        1 THEN      CASE        IsNumeric(xIc.tText)        
                                                  WHEN 1 THEN Convert(varchar(50),convert(decimal(20,0), xIc.tText))        
                                                  WHEN 0 THEN xIc.tText        
                                            END                 
        END,        
              Comment = xDc.tText,        
              FormulationDesc = xPDRIc.tText,        
              ERPOrderStatus = xRsOvStat.tText       -- SimonP--20120210        
       FROM  @tPR pr        
       LEFT  JOIN   #tXML xI ON pr.NodeId = xI.ParentId AND xI.LocalName = 'Id'        
       LEFT  JOIN   #tXML xIc ON xI.Id = xIc.ParentId        
       LEFT  JOIN   #tXML xD ON pr.NodeId = xD.ParentId AND xD.LocalName = 'Description'        
       LEFT  JOIN   #tXML xDc ON xD.Id = xDc.ParentId        
       LEFT  JOIN   #tXML xPDRI ON pr.NodeId = xPDRI.ParentId AND xPDRI.LocalName = 'ProductProductionRuleId'        
       JOIN   #tXML xPDRIc ON xPDRI.Id = xPDRIc.ParentId        
     LEFT  JOIN   #tXML xRs ON pr.NodeId = xRs.ParentId AND xRs.LocalName = 'RequestState'          
    LEFT  JOIN   #tXML xRsOv ON xRs.Id = xRsOv.ParentId AND xRsOv.LocalName = 'Othervalue'        
    LEFT  JOIN   #tXML xRsOvStat ON xRsOv.Id = xRsOvStat.ParentId           
             
SELECT @CountOfDescription = Count(*)        
 FROM @tPR pr        
 LEFT JOIN #tXML xD ON (pr.NodeId = xd.ParentId) AND xD.LocalName = 'Description'        
 LEFT JOIN #tXML xDc ON (xD.Id = xDC.ParentId)        
         
IF  @CountOfDescription > 1        
BEGIN        
 INSERT INTO @tblDescription (xdId, xdParentId, DescriptionText)        
  SELECT xd.Id, xd.ParentId, xDc.Ttext        
   FROM @tPR pr        
   LEFT JOIN #tXML xD ON (pr.NodeId = xd.ParentId) AND xD.LocalName = 'Description'        
   LEFT JOIN #tXML xDc ON (xD.Id = xDC.ParentId)        
        
 SELECT @LoopCount = MAX(Id) FROM @tblDescription        
 SELECT @LoopIndex = MIN(Id) FROM @tblDescription        
        
 SET @DescriptionText = ''        
 SET @DescriptionTextAll = ''        
 WHILE @LoopIndex <= @LoopCount        
  BEGIN        
   SELECT @DescriptionText = COALESCE(DescriptionText, '')        
    FROM @tblDescription        
    WHERE Id = @LoopIndex        
            
   --SELECT @DescriptionTextAll = @DescriptionTextAll + ' ' + @DescriptionText        
   SELECT @DescriptionTextAll = @DescriptionTextAll + CHAR(13) + @DescriptionText  --v1.19        
        
   SELECT @LoopIndex = @LoopIndex + 1        
  END         
                  
 UPDATE @tPR SET Comment = @DescriptionTextAll        
END        
        
 -- Added for MOT        
 --IF @DebugFlag = 1        
 -- SELECT 'Check_C_TECO', pr.NodeId AS PrNodeId, xRs.Id AS RsNodeId, xRsOv.Id AS RsOvNodeId, xRsOv.tText As RsOvText, xRsOvStat.Id as xRsOvStatNOdeId, xRsOvStat.Ttext AS xRsOvStatTtext        
 --  FROM @tPR pr        
 --  LEFT  JOIN   #tXML xRs ON pr.NodeId = xRs.ParentId AND xRs.LocalName = 'RequestState'  -- prNodeId = rs.ParentId --> 16        
 --  LEFT  JOIN   #tXML xRsOv ON xRs.Id = xRsOv.ParentId AND xRsOv.LocalName = 'Othervalue'        
 --  LEFT  JOIN   #tXML xRsOvStat ON xRsOv.Id = xRsOvStat.ParentId        
              
UPDATE  pr  --BOM        
SET   BOMId = bom.BOM_Id     
FROM  @tPR pr        
JOIN  dbo.Bill_Of_Material bom WITH(NOLOCK) ON pr.FormulationDesc = bom.BOM_Desc        
        
IF @DebugFlag = 1        
BEGIN        
  SELECT '2.03a Description', * FROM @tblDescription        
  SELECT '2.03b', @DescriptionTextAll AS DescriptionTextAll        
   SELECT '2.03c Production Request', * FROM @tPR        
END           
-------------------------------------------------------------------------------        
-- Task 2.04 - Segment Requirement               
-- print '--sr: ' + convert(char(30), getdate(), 21)         
-------------------------------------------------------------------------------        
INSERT @tSR (        
       ParentId,        
       NodeId )        
       SELECT  x1.ParentId,        
              x1.Id         
       FROM       #tXML x1         
       WHERE       x1.LocalName = 'SegmentRequirement'        
               
UPDATE  sr        
--     SET     EarliestStartTime = dbo.fnS95OE_ConvertDate(xESTc.tText),        
--            LatestEndTime = dbo.fnS95OE_ConvertDate(xLETc.tText)        
SET  EarliestStartTime = xESTc.tText,        
  LatestEndTime = xLETc.tText        
FROM @tSR sr        
LEFT JOIN  #tXML xEST ON sr.NodeId = xEST.ParentId        
         AND   xEST.LocalName = 'EarliestStartTime'        
LEFT JOIN  #tXML xESTc ON xEST.Id = xESTc.ParentId        
LEFT JOIN  #tXML xLET ON sr.NodeId = xLET.ParentId        
         AND   xLET.LocalName = 'LatestEndTime'        
LEFT JOIN  #tXML xLETc ON xLET.Id = xLETc.ParentId        
               
IF EXISTS (SELECT 1 FROM @tSR WHERE EarliestStartTime IS NULL OR LatestEndTime IS NULL)        
 BEGIN        
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -0, 0, 'EarliestStartTime/LatestEndTime is set to null for Parent/Node:' + CAST(ParentId AS varchar(10)) + '/' + CAST(NodeId AS varchar(10)), 0, NULL        
    FROM @tSR        
    WHERE EarliestStartTime IS NULL        
 END        
          
IF   @TimeModifier <> 0        
 BEGIN        
 UPDATE  @tSR        
 SET  EarliestStartTime = DateAdd(mi, @TimeModifier, EarliestStartTime),        
     LatestEndTime  = DateAdd(mi, @TimeModifier, LatestEndTime)        
 END        
        
IF @DebugFlag = 1        
   SELECT '2.04 Segment Req', * FROM @tSR        
-------------------------------------------------------------------------------        
-- Task 2.05 - Equipment Requirement        
-- print '--er: ' + convert(char(30), getdate(), 21)        
-------------------------------------------------------------------------------        
-- Each of these records will correspond to a Production_Plan record.        
-------------------------------------------------------------------------------        
INSERT @tER (        
       ParentId,        
       NodeId,        
       EquipmentId)        
       SELECT  x1.ParentId,        
              x1.Id,        
              x3.tText        
      FROM       #tXML x1        
      JOIN       #tXML x2 ON x2.ParentId = x1.Id        
      AND       x2.LocalName = 'EquipmentId'        
      JOIN       #tXML x3 ON x3.ParentId = x2.Id         
      WHERE       x1.LocalName = 'EquipmentRequirement'        
              
--Try 3 ways to set the PathId                      
UPDATE   er        
       SET   PathId = dsx.Actual_Id        
       FROM  @tER er        
       JOIN  dbo.Data_Source_XRef dsx WITH(NOLOCK) ON er.EquipmentId = dsx.Foreign_Key        
                      AND  dsx.DS_Id = @DataSourceId        
                      AND  dsx.Table_Id = 13        
UPDATE  er        
 SET   PathId = pep.Path_Id        
 FROM  @tER er        
 JOIN  dbo.PrdExec_Paths pep WITH(NOLOCK) ON er.EquipmentId = pep.Path_Code        
             AND pep.PL_Id  <> 0        
 WHERE  er.PathId IS NULL        
         
UPDATE  er        
 SET   PathId = pep.Path_Id        
 FROM  @tER er        
 JOIN  dbo.PrdExec_Paths pep WITH(NOLOCK) ON  er.EquipmentId = pep.Path_Desc        
             AND   pep.PL_Id       <> 0        
 WHERE  er.PathId IS NULL        
  -------------------------------------------------------------------------------        
-- TEMPORARY FIX : 23-Apr-2015 -- AJ150423        
-------------------------------------------------------------------------------        
--        
-- Find the UDP value for the execution path each Process Order is bound to.         
-- This UDP should be configured only for Line 71 with value =0        
--        
-- Please note the original SAP ProcessOrder resides on the @tpr and the looked        
-- up PA path Id resides on the @er table        
-------------------------------------------------------------------------------        
/*        
insert @tPR (NodeId,ProcessOrder) values (1,'000123456781')        
insert @tSR (NodeId, parentId) values (1, 1)        
insert @tER (ParentId, pathId) values (1, 9)        
        
insert @tPR (NodeId,ProcessOrder) values (2,'000123456782')        
insert @tSR (NodeId, parentId) values (2, 2)        
insert @tER (ParentId, pathId) values (2, 8)        
        
        
insert @tPR (NodeId,ProcessOrder) values (3,'000123456783')        
insert @tSR (NodeId, parentId) values (3, 3)        
insert @tER (ParentId, pathId) values (3, 8)        
        
        
select * from @tEr        
select * from @tpr        
*/        
        
 UPDATE  er         
  SET     FlgRemoveLeadingZeroes = TFV.Value        
  FROM    @tER er        
  JOIN    @tSR sr         
  ON  er.ParentId = sr.NodeId        
  JOIN    @tPR pr         
  ON  sr.ParentId = pr.NodeId        
  JOIN dbo.Table_Fields_Values TFV  WITH (NOLOCK)        
  ON  TFV.KeyId    = er.Pathid        
  JOIN dbo.Table_Fields TF    WITH (NOLOCK)        
  ON  TFV.Table_Field_Id  = TF.Table_Field_Id        
  AND  TF.TableId    = 13        
  AND  TF.Table_Field_Desc = 'BTSched - RemoveLeadingZeroesfPONumber'        
-------------------------------------------------------------------------------        
-- By default, the POs for all execution paths with exception of LIne 71 should        
-- have the 3 leading zeroes stripped.         
-------------------------------------------------------------------------------           
UPDATE @tER        
  SET FlgRemoveLeadingZeroes = 1        
  WHERE FlgRemoveLeadingZeroes IS NULL        
------------------------------------------------------------------------------        
-- Strip leading zeroes of process orders bound to execution paths configured         
-- for doing that. At EUS only line 71 does not have the zeroes stripped        
-------------------------------------------------------------------------------           
UPDATE  pr         
  SET     ProcessOrder = RIGHT(ProcessOrder, LEN(ProcessOrder) - 3)        
  FROM    @tER er        
  JOIN    @tSR sr ON er.ParentId = sr.NodeId        
  AND  er.FlgRemoveLeadingZeroes = 1        
  JOIN    @tPR pr ON sr.ParentId = pr.NodeId        
/*         
 select * from @tEr        
 select * from @tpr        
--return          
*/        
-- For BOUND POs, Set Path Defined UDPs, default where not set        
-- For UNBOUND POs, Set UDPs based on the Download Subscription, default where not set        
-------------------------------------------------------------------------------        
-- Set the path based parms first by subscription/default then by path in mass         
-- to catch all paths that don't have UDPs and catch the unbound equipment.        
-- Then loop through each @tER setting an specific PathUDP Values        
-------------------------------------------------------------------------------        
BEGIN        
 EXEC       dbo.spCmn_UDPLookupById        
        @DefaultProdFamilyId       OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,              --@TableId           int,        
        @OEDownloadSubscription,           --@KeyId              int,        
        -4,                            --BTSched - DefProductFamilyId        
        '1'                            --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById         
        @UserId              OUTPUT,     --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,              --@TableId           int,        
        @OEDownloadSubscription,           --@KeyId              int,        
        -6,                             -- BTSched - DataSourceId        
        '1'                           --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @mprNoPathProd       OUTPUT,    --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,               --@TableId          int,        
        @OEDownloadSubscription,           --@KeyId              int,        
        -7,                             --BTSched - NoProdOnPathOption        
        '2'                             --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @mprNoProduct              OUTPUT,  --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,               --@TableId          int,        
        @OEDownloadSubscription,           --@KeyId              int,        
        -9,                             --BTSched - NoMprProductOption        
        '1'                             --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById          @mcrNoProduct              OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,              --@TableId              int,        
        @OEDownloadSubscription,           --@KeyId              int,        
        -10,                            --BTSched - NoMcrProductOption        
        '1'                            --@DefaultValue       Nvarchar(1000)        
                      
 EXEC       dbo.spCmn_UDPLookupById        
        @NoFormulation         OUTPUT, --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,               --@TableId          int,        
        @OEDownloadSubscription,           --@KeyId              int,        
        -13,                          --BTSched - NoBOMFormulationOption        
        '1'                             --@DefaultValue       Nvarchar(1000)  
 EXEC       dbo.spCmn_UDPLookupById        
        @DefaultMPRProdId       OUTPUT,     --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                --@TableId              int,        
        @OEDownloadSubscription,            --@KeyId              int,        
        -15,                              --BTSched - DefMPRProdId        
        '1'                              --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @DefaultMCRProdId       OUTPUT,     --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,    --@TableId              int,        
        @OEDownloadSubscription,            --@KeyId              int,        
        -16,                              --BTSched - DefMCRProdId        
        '1'                              --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @DefaultRawMaterialProdId       OUTPUT,--@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -20,                               --BTSched - DefRawMatProdFamId        
        '1'                               --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @NoUpdatePOStatusesMask       OUTPUT,--@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -25,                               --BTSched - NoUpdateProcessOrderStatuses        
        ''                               --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @FlgPrependNewProdWithDesc    OUTPUT,  --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -26,                            --BTSched - ProdCodeInDescription        
        0                                  --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @PrependNewProdDelimiter        OUTPUT,--@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -27,                            --BTSched - DelimiterProdCode        
        ':'                               --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @FlgUpdateMPRDesc          OUTPUT,   --@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -28,                               --BTSched - UpdateMPRDescription        
        0                                  --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @FlgUpdateMCRDesc               OUTPUT,--@LookupValue       Nvarchar(1000)       OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -29,                               --BTSched - UpdateMCRDescription        
        0                                  --@DefaultValue       Nvarchar(1000)        
 EXEC       dbo.spCmn_UDPLookupById        
        @FlgCreateProduct            OUTPUT,  --@LookupValue       Nvarchar(1000)   OUTPUT,        
        @SubscriptionTableID,                 --@TableId              int,        
        @OEDownloadSubscription,             --@KeyId              int,        
        -82,                            --Create product on the fly        
        '1'                       --@DefaultValue       Nvarchar(1000)        
        
              
                
END               
               
-- Set all records to the download subscription/default obtained from the previous queries        
-- this will set the default for both bound and unbound         
UPDATE       er           
SET DefaultProdFamilyId   = @DefaultProdFamilyId     ,        
 UserId = @UserId     ,        
 mprNoPathProd = @mprNoPathProd     ,        
 mprNoProduct = @mprNoProduct     ,        
 mcrNoProduct = @mcrNoProduct     ,        
 NoFormulation = @NoFormulation     ,        
 DefaultMPRProdId = @DefaultMPRProdId     ,        
 DefaultMCRProdId = @DefaultMCRProdId     ,        
 DefaultRawMaterialProdId = @DefaultRawMaterialProdId     ,        
 NoUpdatePOStatusesMask = @NoUpdatePOStatusesMask     ,        
 FlgPrependNewProdWithDesc  = @FlgPrependNewProdWithDesc      ,        
 PrependNewProdDelimiter  = @PrependNewProdDelimiter      ,        
 FlgUpdateMPRDesc = @FlgUpdateMPRDesc     ,        
 FlgUpdateMCRDesc = @FlgUpdateMCRDesc     ,        
 FlgCreateProduct = @FlgCreateProduct           
FROM @tER er          
        
        
        
--UL V2.0 Remove to Replace Cursor by While LOOP        
/*            
-- Now Update any Paths that have specific UDPs        
DECLARE       TFVCursor INSENSITIVE CURSOR          
   For (SELECT tfv.KeyId, tfv.Table_Field_Id, tfv.Value        
           FROM Table_Fields_Values tfv        
           JOIN @tER er on tfv.KeyId = er.PathId and tfv.TableId = @PrdExecPathTableID        
           )        
            For Read Only         
OPEN       TFVCursor        
FETCH       NEXT FROM TFVCursor intO @KeyId, @TableFieldId, @TableFieldValue        
WHILE       @@Fetch_Status = 0        
BEGIN        
    IF @TableFieldId = -4 UPDATE @tER SET DefaultProdFamilyId   = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -5 UPDATE @tER SET DefaultBOMFamilyId = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -6 UPDATE @tER SET UserId = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -7 UPDATE @tER SET mprNoPathProd = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -8 UPDATE @tER SET mprNoPath = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -9 UPDATE @tER SET mprNoProduct = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -10 UPDATE @tER SET mcrNoProduct = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -13 UPDATE @tER SET NoFormulation = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -15 UPDATE @tER SET DefaultMPRProdId = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -16 UPDATE @tER SET DefaultMCRProdId = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -19 UPDATE @tER SET FlgIgnoreBOMInfo = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -20 UPDATE @tER SET DefaultRawMaterialProdId = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -25 UPDATE @tER SET NoUpdatePOStatusesMask = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -26 UPDATE @tER SET FlgPrependNewProdWithDesc  = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -27 UPDATE @tER SET PrependNewProdDelimiter  = @TableFieldValue WHERE PathId = @KeyId    
    ELSE IF @TableFieldId = -28 UPDATE @tER SET FlgUpdateMPRDesc = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -29 UPDATE @tER SET FlgUpdateMCRDesc = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -59 UPDATE @tER SET MaterialReservationSequence = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -60 UPDATE @tER SET ScrapPercent = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -82 UPDATE @tER SET FlgCreateProduct = @TableFieldValue WHERE PathId = @KeyId        
     FETCH       NEXT FROM TFVCursor intO @KeyId, @TableFieldId, @TableFieldValue        
END        
CLOSE              TFVCursor        
DEALLOCATE       TFVCursor        
        
*/        
/*---------------------------------------------        
UL V2.0 Added to Replace Cursor by While LOOP        
-----------------------------------------------*/        
        
DECLARE @MyTable TABLE (         
 RowId    int IDENTITY,        
 KeyId    int,        
 Table_Field_Id  int,        
 Value    varchar(7000)        
 )        
        
DECLARE @Rows int,        
  @Row int        
        
--Insert data in the Looping table        
INSERT intO @MyTable (KeyId,Table_Field_Id,Value)        
SELECT tfv.KeyId, tfv.Table_Field_Id, tfv.Value        
FROM Table_Fields_Values tfv WITH(NOLOCK)        
JOIN @tER er ON tfv.KeyId = er.PathId         
    AND tfv.TableId = @PrdExecPathTableID        
        
        
-- Get the total number of rows        
SELECT @Rows = @@ROWCOUNT,        
  @Row = 0        
        
-- Loop through the rows in the table        
WHILE @Row < @Rows        
 BEGIN        
 SELECT @Row = @Row + 1        
        
 SELECT @KeyId    = KeyId,         
   @TableFieldId  = Table_Field_Id,        
   @TableFieldValue = Value        
 FROM @MyTable        
 WHERE RowId = @Row         
        
        
 IF @TableFieldId = -4  UPDATE @tER SET DefaultProdFamilyId   = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -5 UPDATE @tER SET DefaultBOMFamilyId = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -6 UPDATE @tER SET UserId = @TableFieldValue     WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -7 UPDATE @tER SET mprNoPathProd = @TableFieldValue   WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -8 UPDATE @tER SET mprNoPath = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -9 UPDATE @tER SET mprNoProduct = @TableFieldValue    WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -10 UPDATE @tER SET mcrNoProduct = @TableFieldValue    WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -13 UPDATE @tER SET NoFormulation = @TableFieldValue   WHERE PathId = @KeyId        
   ELSE IF @TableFieldId = -15 UPDATE @tER SET DefaultMPRProdId = @TableFieldValue   WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -16 UPDATE @tER SET DefaultMCRProdId = @TableFieldValue   WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -19 UPDATE @tER SET FlgIgnoreBOMInfo = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -20 UPDATE @tER SET DefaultRawMaterialProdId = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -25 UPDATE @tER SET NoUpdatePOStatusesMask = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -26 UPDATE @tER SET FlgPrependNewProdWithDesc  = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -27 UPDATE @tER SET PrependNewProdDelimiter  = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -28 UPDATE @tER SET FlgUpdateMPRDesc = @TableFieldValue   WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -29 UPDATE @tER SET FlgUpdateMCRDesc = @TableFieldValue   WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -59 UPDATE @tER SET MaterialReservationSequence = @TableFieldValue WHERE PathId = @KeyId        
    -- SITE UDP    ELSE IF @TableFieldId = -60 UPDATE @tER SET ScrapPercent = @TableFieldValue WHERE PathId = @KeyId        
    ELSE IF @TableFieldId = -82 UPDATE @tER SET FlgCreateProduct = @TableFieldValue   WHERE PathId = @KeyId        
        
 -- Process your data        
 END        
/*---------------------------------------        
--End of new while loop to replace cursor        
-----------------------------------------*/        
        
        
        
        
-- Update for MOT        
-- If there is a Processor ORder, we only care about the ProcessOrder, not the path        
-- because SAP may want to chaneg the path  --UPDATE       er -- Bound Process Orders        
--       SET     PPId               = pp.PP_Id,        
--              FormulationId       = pp.BOM_Formulation_Id,        
--              PPStatusId       = pp.PP_Status_Id        
--       FROM       @tER er        
--       JOIN       @tSR sr ON er.ParentId = sr.NodeId        
--       JOIN       @tPR pr ON sr.ParentId = pr.NodeId        
--       JOIN       dbo.Production_Plan pp         
--       ON        er.PathId = pp.Path_Id        
--       AND       pr.ProcessOrder = pp.Process_Order        
--       WHERE       er.PathId       Is Not Null        
               
UPDATE  er -- Bound Process Orders        
SET     PPId         = pp.PP_Id,        
    FormulationId   = pp.BOM_Formulation_Id,        
    PPStatusId    = pp.PP_Status_Id        
FROM    @tER er        
JOIN    @tSR sr ON er.ParentId = sr.NodeId        
JOIN    @tPR pr ON sr.ParentId = pr.NodeId        
JOIN    dbo.Production_Plan pp WITH(NOLOCK) ON pr.ProcessOrder = pp.Process_Order        
WHERE er.PathId  IS NOT NULL        
           
               
UPDATE  er -- Unbound Process Orders        
SET     PPId         = pp.PP_Id,        
 FormulationId   = pp.BOM_Formulation_Id,        
    PPStatusId    = pp.PP_Status_Id        
FROM    @tER er        
JOIN    @tSR sr ON er.ParentId = sr.NodeId        
JOIN    @tPR pr ON sr.ParentId = pr.NodeId        
JOIN    dbo.Production_Plan pp WITH(NOLOCK) ON pp.Path_Id IS NULL        
            AND pr.ProcessOrder = pp.Process_Order        
WHERE er.PathId IS NULL        
           
               
UPDATE er        
SET    CommentId = cc.Comment_Id        
FROM    @tER er        
JOIN    dbo.Production_Plan pp WITH(NOLOCK) ON er.PPId = pp.PP_Id        
JOIN    dbo.Comments cc     WITH(NOLOCK) ON (pp.Comment_Id = cc.TopOfChain_Id        
                   OR pp.Comment_Id = cc.Comment_Id)        
              AND cc.User_Id = @UserId        
         
                      
IF @DebugFlag = 1        
   SELECT '2.05 Equipment Req', * FROM @tER        
           
-------------------------------------------------------------------------------        
-- Task 2.06 - Locations        
-- print '--loc: ' + convert(char(30), getdate(), 21)        
-------------------------------------------------------------------------------        
INSERT       @tLocation (        
       NodeId,        
       ParentId,        
       EquipmentId,        
       EquipmentElementLevel )        
       SELECT  xL.Id,        
              xL.ParentId,        
              xEIc.tText,        
              xEELc.tText        
      FROM     #tXML xL        
      LEFT JOIN #tXML xEI ON xL.Id = xEI.ParentId        
                     AND xEI.LocalName = 'EquipmentId'        
      LEFT JOIN #tXML xEIc ON xEI.Id = xEIc.ParentId        
      LEFT JOIN #tXML xEEL ON xL.Id = xEEL.ParentId        
                     AND  xEEL.LocalName = 'EquipmentElementLevel'        
      LEFT JOIN #tXML xEELc ON xEEL.Id = xEELc.ParentId        
      WHERE  xL.LocalName = 'Location'        
                      
                      
-- Added for MOT        
UPDATE  ps        
SET  EquipmentId = L.EquipmentId        
FROM    @tPS ps        
JOIN  @tLocation L ON ps.NodeId = L.ParentId         
      AND L.EquipmentElementLevel = 'Site'        
                      
/*        
UPDATE       mprp        
       SET       ValueString = xVSc.tText        
       FROM       @tMPRP mprp        
       JOIN       #tXML xV ON mprp.NodeId = xV.ParentId        
              AND       xV.LocalName = 'Value'        
       JOIN       #tXML xVS ON xV.Id = xVS.ParentId        
              AND       xVS.LocalName = 'ValueString'        
       JOIN       #tXML xVSc ON xVS.Id = xVSc.ParentId  */        
                      
IF @DebugFlag = 1        
BEGIN        
     SELECT '2.06 Location', * FROM @tLocation        
     SELECT '2.06 ProdSch',  * FROM @tPS        
END             
        
-------------------------------------------------------------------------------        
-- Task 2.07 - Quantities                
-- print '--q: ' + convert(char(30), getdate(), 21)        
-------------------------------------------------------------------------------        
INSERT @tQty (        
     NodeId,        
     ParentId,        
     QuantityString,        
     UOM,        
     KeyString)        
SELECT xQ.Id,        
    xQ.ParentId,        
    xQSc.tText,        
    xUOMc.tText,        
    xKSc.tText        
FROM     #tXML xQ        
LEFT JOIN   #tXML xQS ON xQ.Id = xQS.ParentId         
       AND xQS.LocalName = 'QuantityString'                    
LEFT JOIN   #tXML xQSc ON xQS.Id = xQSc.ParentId        
        
LEFT JOIN   #tXML xUOM ON xQ.Id = xUOM.ParentId          AND xUOM.LocalName = 'UnitOfMeasure'        
LEFT JOIN   #tXML xUOMc ON xUOM.Id = xUOMc.ParentId        
LEFT JOIN   #tXML xKS ON xQ.Id  = xKS.ParentId         
       AND  xKS.LocalName = 'Key'        
LEFT JOIN   #tXML xKSc ON xKs.Id = xKSc.ParentId                 
WHERE xQ.LocalName = 'Quantity'        
          
          
-------------------------------------------------------------------------------                    
-- FOR P&G MOT Project, there are 2 instances of the Qty at the MPR        
-- Instanced can be increase by additional coding        
-------------------------------------------------------------------------------                    
UPDATE @tQty        
SET  KeyParameter = @MPRKey01        
WHERE KeyString = 'MPRKey01'        
          
UPDATE @tQty        
SET  KeyParameter = @MPRKey02        
WHERE KeyString = 'MPRKey02'        
               
-------------------------------------------------------------------------------        
-- Simon Poon        
-- To accommodate the multiple quantities at the MPR        
-- We do not delete the quantiy instance        
-------------------------------------------------------------------------------                    
--DELETE q1        
--       FROM       @tQty q1        
--       JOIN       @tQty q2 ON q1.ParentId = q2.ParentId        
--              AND       q1.NodeId > q2.NodeId        
IF @DebugFlag = 1        
     SELECT '2.07 Quantities', * FROM @tQty        
             
-------------------------------------------------------------------------------        
-- Task 2.08 - Material Produced Requiremnt        
-- print '--Entering MPR: ' + convert(char(30), getdate(), 21)        
-- 2012-06-19 Add FlgRemoveLeadingZeros Logic        
-------------------------------------------------------------------------------        
INSERT       @tMPR (        
     NodeId,        
     ParentId,        
     ProdCode,        
     ProdDesc,        
     MaterialLotId,        
     FlgNewProduct,        
     CreatePUAssoc,        
     CreatePathAssoc,        
     Status)        
SELECT  xMPR.Id,        
    xMPR.ParentId,        
    --xPC.tText,        
       CASE       @FlgRemoveLeadingZeros        
              WHEN       0 THEN       xPC.tText        
              WHEN        1 THEN       CASE       IsNumeric(xPC.tText)        
                      WHEN 1 THEN Convert(varchar(50),convert(decimal(20,0), xPC.tText))        
                                   WHEN 0 THEN xPC.tText        
                            END               
       END,        
    xPD.tText,        
    xSPC.tText,        
    0,        
    0,        
    0,        
    0        
FROM       #tXML xMPR        
LEFT JOIN  #tXML xMDI ON xMPR.Id = xMDI.ParentId        
              AND xMDI.LocalName = 'MaterialDefinitionID'        
LEFT JOIN  #tXML xPC ON xMDI.Id = xPC.ParentId        
LEFT JOIN  #tXML xD  ON xMPR.Id = xD.ParentId        
              AND xD.LocalName = 'Description'        
LEFT JOIN  #tXML xPD ON xD.Id = xPD.ParentId         
LEFT JOIN  #tXML xMLI ON xMPR.Id = xMLI.ParentId        
              AND xMLI.LocalName = 'MaterialLotID'        
LEFT JOIN  #tXML xSPC ON xMLI.Id = xSPC.ParentId        
WHERE   xMPR.LocalName = 'MaterialProducedRequirement'        
        
--IF @DebugFlag = 1        
--BEGIN        
-- SELECT 'XML', * FROM #tXML WHERE (Id = 28 and ParentId = 22) OR ParentId = 28        
-- SELECT '@tMPR', * FROM @tMPR        
--END        
        
        
/*------------------------------------------------        
UL V2.0  Change Select count by EXISTS        
--------------------------------------------------*/        
/*        
IF  (SELECT       COUNT(*) FROM @tMPR) = 0         
BEGIN        
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
      SELECT -300, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
        FROM dbo.email_message_data emd         
        WHERE emd.Message_Id = -300        
     GOTo ErrCode        
       ----return       (0)        
END        
*/        
IF NOT EXISTS(SELECT * FROM @tMPR)        
 BEGIN        
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -300, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
 FROM dbo.email_message_data emd WITH(NOLOCK)         
 WHERE emd.Message_Id = -300        
 GOTO ErrCode        
 ----return       (0)        
 END        
/*------------------------------------------------        
UL V2.0  END OF Change Select count by EXISTS        
--------------------------------------------------*/        
        
        
        
        
        
-------------------------------------------------------------------------------        
-- print '--EXIT MPR, Entering LookUP: ' + convert(char(30), getdate(), 21)        
-- Look up product         
-------------------------------------------------------------------------------        
-- For products that could not be found based on the product code, the SP tries        
-- to search based on the description. If configured so, it will compare the         
-- XML value with the concatenation of the ProductCode+delimiter+ProdDescription        
-------------------------------------------------------------------------------        
IF @DebugFlag = 1        
   SELECT 'ER TO MPR', er.parentid,er.FlgPrependNewProdWithDesc, er.PrependNewProdDelimiter,mpr.proddesc, mpr.prodcode         
   FROM @tMPR mpr         
   JOIN @tER er ON mpr.parentid = er.parentid        
-- Adjust product desc based on UPDs         
        
        
        
UPDATE  mpr        
SET   mpr.prodDesc = COALESCE(mpr.ProdCode,'') +  COALESCE(er.PrependNewProdDelimiter,'') + COALESCE(mpr.ProdDesc,'')         
FROM  @tMPR mpr        
JOIN  @tER er ON er.ParentId = mpr.ParentId         
      AND er.FlgPrependNewProdWithDesc = 1        
        
--IF       @FlgPrependNewProdWithDesc = 1        
--BEGIN        
--   UPDATE  @tMPR        
--         SET       prodDesc = COALESCE(ProdCode,'') +  COALESCE(@PrependNewProdDelimiter,'') + COALESCE(ProdDesc,'')                
--END        
        
UPDATE  mpr        
SET     ProdId = dsx.Actual_Id        
FROM  @tMPR mpr        
JOIN     dbo.Data_Source_XRef dsx WITH(NOLOCK) ON mpr.ProdCode = dsx.Foreign_Key        
                AND dsx.DS_Id = @DataSourceId        
JOIN     dbo.Tables tt    WITH(NOLOCK) ON dsx.Table_Id = tt.TableId        
                AND tt.TableName = 'Products'        
                       
UPDATE  mpr        
SET     ProdId = p.Prod_Id        
FROM     @tMPR mpr        
JOIN     dbo.Products p   WITH(NOLOCK) ON mpr.ProdCode = p.Prod_Code        
WHERE  mpr.ProdId IS NULL        
        
        
UPDATE  mpr        
SET     ProdId = p.Prod_Id        
FROM     @tMPR mpr        
JOIN     dbo.Products p   WITH(NOLOCK) ON mpr.ProdDesc = p.Prod_Desc        
WHERE  mpr.ProdId IS NULL        
        
        
UPDATE  mpr        
SET   QuantityString = q.QuantityString,        
     UoM = q.Uom        
FROM     @tMPR mpr        
LEFT JOIN @tQty q  ON mpr.NodeId = q.ParentId        
WHERE  q.KeyParameter = @TxtPlannedQty        
        
        
             
UPDATE  mpr        
SET     PUId = dsx.Actual_Id        
FROM     @tMPR mpr        
JOIN  dbo.Data_Source_XRef dsx WITH(NOLOCK) ON mpr.EquipmentId = dsx.Foreign_Key        
                AND dsx.DS_Id = @DataSourceId        
                AND dsx.Table_Id = @ProdUnitsTableId        
        
--- Added for MOT        
UPDATE  mpr        
SET   EquipmentId = lstorage.EquipmentId        
FROM     @tMPR mpr        
LEFT JOIN @tLocation lsite ON mpr.NodeId = lsite.ParentId        
LEFT JOIN @tLocation lstorage ON lsite.NodeId = lstorage.ParentId        
WHERE  lstorage.EquipmentElementLevel = 'StorageZone'        
               
               
UPDATE  mpr        
SET   DeliveredQuantityString = q.QuantityString,        
     DeliveredUoM = q.Uom        
FROM     @tMPR mpr        
LEFT JOIN @tQty q ON mpr.NodeId = q.ParentId        
WHERE  q.KeyParameter = @TxtDeliveredQty        
        
        
-------------------------------------------------------------------------------        
-- Get PUId for MPR by looking for the IsProductionPOint PU for the Path        
--        
-- Get First MPR record to process        
-------------------------------------------------------------------------------        
SELECT     @Id  = NULL        
SELECT  @Id  = MIN(Id)        
FROM     @tMPR        
WHERE    PUID IS NULL        
   AND Status = 0        
           
-------------------------------------------------------------------------------        
-- Loop all MPR records with PuId is Null        
-------------------------------------------------------------------------------        
WHILE  (@Id IS NOT NULL)        
 BEGIN        
   -------------------------------------------------------------------------------        
   -- Mark this MPR as processed        
   -------------------------------------------------------------------------------        
 UPDATE @tMPR        
 SET   Status = 1        
 WHERE Id = @Id        
   -------------------------------------------------------------------------------        
   -- Retrieve some MPR attributes        
   -------------------------------------------------------------------------------        
 SELECT  @NodeId    = NodeId,        
   @ParentId = ParentId,        
   @PUId    = PUId        
 FROM    @tMPR        
 WHERE Id = @Id        
         
 -------------------------------------------------------------------------------        
 -- Get Path from the EquipmentRequirement (Assume a single ER for a given SR.         
 -- If wrong, we need an inner loop)        
 -------------------------------------------------------------------------------        
 SELECT  @PathId  = Null,        
     @PUId  = Null        
             
 SELECT TOP 1 @PathId = PathId        
 FROM   @tER        
 WHERE  ParentId  = @ParentId        
         
         
 -------------------------------------------------------------------------------      
 -- Get IsPOroductionPoint PUId for this path        
 -------------------------------------------------------------------------------        
 IF @PathId IS NOT NULL        
  BEGIN        
  SELECT  @PUId = PU_Id        
  FROM    dbo.PrdExec_Path_Units WITH(NOLOCK)        
  WHERE Path_Id = @PathId        
    AND Is_Production_Point = 1        
  IF  @PUId IS NOT NULL        
   BEGIN        
   UPDATE  @tMPR        
   SET    PUId = @PUId        
   WHERE   NodeId = @NodeId        
   END        
  END        
          
          
       -------------------------------------------------------------------------------        
       -- Get Next MPR record        
       -------------------------------------------------------------------------------        
 SELECT  @Id  = NULL        
 SELECT  @Id  = MIN(Id)        
 FROM @tMPR        
 WHERE PUID IS NULL        
   AND Status = 0        
           
 END        
         
         
UPDATE  mpr        
SET    PathUoM = EU.Eng_Unit_Code -- es.Dimension_X_Eng_Units        
FROM    @tMPR mpr        
JOIN    @tER er          ON mpr.ParentId = er.ParentId        
JOIN    dbo.PrdExec_Path_Units pepu WITH(NOLOCK) ON er.PathId = pepu.Path_Id        
                AND pepu.Is_Production_Point = 1        
JOIN    dbo.Event_Configuration ec WITH(NOLOCK) ON pepu.PU_Id = ec.PU_Id        
                AND ec.ET_Id = 1        
JOIN    dbo.Event_SubTypes es  WITH(NOLOCK) ON ec.Event_SubType_Id = es.Event_SubType_Id        
JOIN    dbo.Engineering_Unit EU  WITH(NOLOCK) ON ES.dimension_x_eng_unit_id = EU.Eng_Unit_Id        
        
        
        
IF @DebugFlag = 1        
   SELECT '2.08 Material Produce Req-2.08', * FROM @tMPR        
        
           
-------------------------------------------------------------------------------        
-- Task 2.09 - Material Produced Requirement Properties        
-- print '--Entering MPRP' + convert(char(30), getdate(), 21)        
-------------------------------------------------------------------------------        
INSERT     @tMPRP (        
     NodeId,        
     ParentId,        
     Id)        
SELECT  xMPRP.Id,        
    xMPRP.ParentId,        
    xIDc.tText        
FROM    #tXML xMPRP        
JOIN    #tXML xID ON xMPRP.Id = xID.ParentId        
        AND xID.LocalName = 'ID'        
JOIN    #tXML xIDc ON xID.Id = xIDc.ParentId        
WHERE xMPRP.LocalName = 'MaterialProducedRequirementProperty'        
        
        
UPDATE  mprp        
SET    ValueString = xVSc.tText        
FROM    @tMPRP mprp        
JOIN #tXML xV ON mprp.NodeId = xV.ParentId        
        AND xV.LocalName = 'Value'        
JOIN    #tXML xVS ON xV.Id = xVS.ParentId        
        AND xVS.LocalName = 'ValueString'        
JOIN    #tXML xVSc ON xVS.Id = xVSc.ParentId        
        
        
               
-- Added for MOT        
-- Add Delivered Qty as Production UDP        
-- 2012-03-28 - Decided not to put it in the MPRP        
--INSERT @tMPRP (        
--       NodeId,        
--       ParentId,        
--       Id,        
--       ValueString)        
--       SELECT NodeId,        
--       ParentId,        
--       KeyParameter,        
--       QuantityString        
--       FROM @tQty        
--       WHERE KeyParameter = @TxtDeliveredQty        
        
               
-- Add Site Name as Production UDP;        
INSERT @tMPRP (        
     NodeId,        
     ParentId,        
     Id,        
     ValueString)          
SELECT l.NodeId,        
  l.ParentId,        
  'EquipmentIdSite',        
  l.EquipmentId        
FROM @tMPR mpr        
JOIN @tLocation l ON mpr.NodeId = l.ParentId         
       AND l.EquipmentElementLevel = 'Site'        
               
               
        
-- Add MPR Storage Zone as Production UDP        
-- NOTE - in theory, this is 2 level lower then MPR        
--  - we just assign it to be 1 level below the MPR        
-- so that all the MPRP has the same parent Ids          
INSERT @tMPRP (        
     NodeId,        
     ParentId,        
     Id,        
     ValueString)          
SELECT lstorage.NodeId,        
  lsite.ParentId,        
  'EquipmentIdStorageZone',        
  lstorage.EquipmentId        
FROM @tMPR mpr        
JOIN @tLocation lsite ON mpr.NodeId = lsite.ParentId         
JOIN @tLocation lstorage ON lsite.NodeId = lstorage.ParentId        
WHERE lstorage.EquipmentElementLevel = 'StorageZone'          
        
        
IF @DebugFlag = 1        
   SELECT '2.09 @tMPRP', * FROM @tMPRP        
        
-------------------------------------------------------------------------------        
-- Task 2.10- Material Consumed Requirement        
-- print '--Entering MCR: ' + convert(char(30), getdate(), 21)        
-- 2012-05-31 Add @FlgRemoveLeadingZeros Logic        
-------------------------------------------------------------------------------        
INSERT   @tMCR (        
     NodeId,        
     ParentId,        
     Status,        
     FlgAlternate)        
SELECT  x1.Id,        
    x1.ParentId,        
    0,        
    0        
FROM    #tXML x1        
WHERE x1.LocalName = 'MaterialConsumedRequirement'        
        
                      
                      
UPDATE  mcr        
-- SET  ProdCode = xMDIc.tText,        
 SET   ProdCode =        CASE        @FlgRemoveLeadingZeros        
                                WHEN        0 THEN      xMDIc.tText        
                                WHEN        1 THEN      CASE        IsNumeric(xMDIc.tText)        
                                      WHEN 1 THEN Convert(varchar(50),convert(decimal(20,0), xMDIc.tText))        
                                      WHEN 0 THEN xMDIc.tText        
                                END        
        END,        
     MaterialLotId = xMLIc.tText,        
     ProdDesc = xDc.tText,        
     QuantityString = q.QuantityString,        
     UoM = q.UoM,        
     EquipmentId = lSZ.EquipmentId        
 FROM     @tMCR mcr        
 LEFT JOIN #tXML xMDI  ON mcr.NodeId = xMDI.ParentId        
           AND xMDI.LocalName = 'MaterialDefinitionId'        
 LEFT JOIN #tXML xMDIc  ON xMDI.Id = xMDIc.ParentId        
 LEFT JOIN #tXML xMLI  ON mcr.NodeId = xMLI.ParentId        
           AND xMLI.LocalName = 'MaterialLotId'        
 LEFT JOIN #tXML xMLIc  ON xMLI.Id = xMLIc.ParentId        
 LEFT JOIN #tXML xD  ON mcr.NodeId = xD.ParentId        
           AND xD.LocalName = 'Description'        
 LEFT JOIN #tXML xDc  ON xD.Id = xDc.ParentId        
 LEFT JOIN @tQty q   ON mcr.NodeId = q.ParentId        
 LEFT JOIN @tLocation lS ON mcr.NodeId = lS.ParentId        
 LEFT JOIN   @tLocation lSZ ON lS.NodeId = lSZ.ParentId        
        
        
        
        
        
--return        
        
-- 2013-02-27 MK. Remove Dummy product        
Delete FROM @tMCR        
WHERE ProdCode LIKE ('%' + LTRIM(RTRIM(@MCR_Dummy)) + '%')        
        
        
-------------------------------------------------------------------------------        
-- Search MCR Product        
-------------------------------------------------------------------------------        
UPDATE  mcr        
SET  ProdId  = dsx.Actual_Id,        
  FlgNewProduct  = 0        
FROM    @tMCR mcr        
JOIN    dbo.Data_Source_XRef dsx WITH(NOLOCK) ON mcr.ProdCode = dsx.Foreign_Key        
              AND dsx.DS_Id = @DataSourceId        
JOIN    dbo.Tables tt    WITH(NOLOCK) ON dsx.Table_Id = tt.TableId        
              AND tt.TableName = 'Products'        
        
                      
UPDATE  mcr        
SET  ProdId  = p.Prod_Id,        
  FlgNewProduct  = 0        
FROM    @tMCR mcr        
JOIN    dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code        
WHERE   mcr.ProdId IS NULL        
        
         
-------------------------------------------------------------------------------        
-- For products that could not be found based on the product code, the SP tries        
-- to search based on the description. If configured so, it will compare the         
-- XML value with the concatenation of the ProductCode+delimiter+ProdDescription        
-------------------------------------------------------------------------------        
-- Adjust product desc based on UPDs         
UPDATE  mcr        
SET  mcr.prodDesc = COALESCE(mcr.ProdCode,'') +  COALESCE(er.PrependNewProdDelimiter,'') + COALESCE(mcr.ProdDesc,'')         
FROM @tMCR mcr        
JOIN @tER er ON er.ParentId = mcr.ParentId         
     AND er.FlgPrependNewProdWithDesc = 1        
             
             
--IF       @FlgPrependNewProdWithDesc = 1        
--BEGIN        
--UPDATE       @tMCR        
--       SET       prodDesc = COALESCE(ProdCode,'') +  COALESCE(@PrependNewProdDelimiter,'') + COALESCE(ProdDesc,'')         
--END        
    
                     
UPDATE  mcr        
SET    ProdId = p.Prod_Id,        
    FlgNewProduct  = 0        
FROM   @tMCR mcr        
JOIN   dbo.Products p WITH(NOLOCK) ON  mcr.ProdDesc = p.Prod_Desc        
WHERE  mcr.ProdId IS NULL        
         
               
IF @DebugFlag = 1        
   SELECT '2.10 @tMCR', * FROM @tMCR        
           
-------------------------------------------------------------------------------        
-- Task 2.11 - Material Consumed Requirement Properties        
-------------------------------------------------------------------------------        
INSERT  @tMCRP (        
  NodeId,        
  ParentId,        
  Id)        
SELECT  xMCRP.Id,        
    xMCRP.ParentId,        
    xIDc.tText        
FROM    #tXML xMCRP        
JOIN    #tXML xID ON xMCRP.Id = xID.ParentId        
        AND xID.LocalName = 'ID'        
JOIN    #tXML xIDc ON xID.Id = xIDc.ParentId        
WHERE   xMCRP.LocalName = 'MaterialConsumedRequirementProperty'        
               
                      
                      
UPDATE   mcrp        
SET     ValueString = xVSc.tText        
FROM     @tMCRP mcrp        
JOIN     #tXML xV ON mcrp.NodeId = xV.ParentId        
        AND xV.LocalName = 'Value'        
JOIN     #tXML xVS ON xV.Id = xVS.ParentId        
        AND xVS.LocalName = 'ValueString'        
JOIN     #tXML xVSc ON xVS.Id = xVSc.ParentId        
        
        
-- Set the Flg to indicate the materials to be ALTERNATE        
UPDATE @tMCR        
SET   FlgAlternate = 1        
FROM  @tMCR mcr        
LEFT JOIN @tMCRP mcrp ON (mcrp.ParentId = mcr.NodeId)        
WHERE  mcrp.Id = 'ALTERNATE'        
        
        
--01/09/2015 BalaMurugan Rajendran Added MaterialOriginGroup Logic for Comparison for calling PE user activity for PO validation.        
-- Set the Flg to Indicate the Material Origin group.        
UPDATE @tMCR        
SET   MaterialOriginGroup = mcrp.ValueString        
FROM  @tMCR mcr        
LEFT JOIN @tMCRP mcrp ON (mcrp.ParentId = mcr.NodeId)        
WHERE  mcrp.Id = 'MaterialOriginGroup'     
        
        
SET @SCOTableFieldid =  (SELECT TABLE_FIELD_ID FROM dbo.Table_Fields WITH (NOLOCK) WHERE Table_Field_Desc like 'PE_General_IsSCOLine')
IF EXISTS ( SELECT Value From dbo.Table_Fields tf With (Nolock)
					JOIN Table_fields_VAlues tfv on tfv.Table_Field_Id = tf.Table_Field_Id
					WHERE tf.Table_Field_Id = @SCOTableFieldid and Keyid = @PathID)
BEGIN
SET @ISSCOLINE = (SELECT coalesce(Convert(int,Value),0) From dbo.Table_Fields tf With (Nolock)
					JOIN Table_fields_VAlues tfv on tfv.Table_Field_Id = tf.Table_Field_Id
					WHERE tf.Table_Field_Id = @SCOTableFieldid and Keyid = @PathID)
END
ELSE
BEGIN
SET @ISSCOLINE = 0
END
IF @ISSCOLINE = 0
BEGIN
        
UPDATE   mcr        
SET     PUId = dsx.Actual_Id         
FROM     @tMCR mcr        
JOIN     dbo.Data_Source_Xref dsx WITH(NOLOCK) ON mcr.EquipmentId = dsx.Foreign_Key        
             AND dsx.DS_Id = @DataSourceId        
             AND dsx.Table_Id = @ProdUnitsTableId        
       
UPDATE   mcr        
SET     PUId = PU.PU_Id        
FROM     @tMCR mcr        
JOIN     dbo.Prod_Units PU WITH(NOLOCK) ON mcr.EquipmentId = PU.PU_Desc        
           AND mcr.PUId IS Null   
		   
END

ELSE

BEGIN


INSERT @SCOPathUnits ( Produnitid)
(Select PU_ID from dbo.Prdexec_path_units  ppu WITH (NOLOCK)
JOIN @ter ter ON ppu.path_id = ter.pathid)

INSERT @SCOUnitOG (OG,Inputid,puid)
(SELECT distinct tfv.Value,tfv.Keyid,pri.pu_id FROM dbo.Table_fields tf WITH (NOLOCK)
JOIN Table_Fields_values tfv on tfv.table_Field_id = @OriginGroupid  and tfv.tableid = @PrdexecInputid
JOIN dbo.prdexec_Inputs Pri on pri.PEI_id = tfv.keyid 
JOIN @SCOPathUnits sp on sp.produnitid = pri.pu_id)



SET @pathid =  ( SELECT Path_id FROM dbo.Prdexec_Paths PP 
					JOIN @tER ter ON ter.EquipmentId = PP.Path_Code)
SET @PrdInputtableid = (	SELECT tableid			FROM dbo.tables WITH (NOLOCK) 		WHERE tablename = 'prdexec_Inputs')

SET @isBomDownloadfieldid = (	SELECT table_field_id	FROM dbo.table_fields WITH (NOLOCK) 	WHERE tableid = @PrdInputtableid AND table_field_desc = 'IsBomPLCDownload')
SET @BOMOriginGroupid = (	SELECT table_field_id	FROM dbo.table_fields WITH (NOLOCK) 	WHERE tableid = @PrdInputtableid AND table_field_desc = 'Origin Group')
SET @ProcessOrder = ( SELECT Process_Order FROM dbo.Production_Plan WITH (NOLOCK) WHERE PP_Id = @PPID)

INSERT @Prdexecpaths ( pathid,PUid,peiid)
(SELECT path_id,pei.pu_id,pei.Pei_Id FROM dbo.PrdExec_Path_Units ppu WITH (NOLOCK) 
JOIN dbo.prdexec_Inputs pei WITH (NOLOCK) ON Pei.pu_id = ppu.pu_id
WHERE Path_Id = @pathid)

UPDATE   mcr        
SET     PUId = su.puid         
FROM     @tMCR mcr        
JOIN     @SCOUnitOG su ON su.OG = mcr.MaterialOriginGroup


             
INSERT @ExistMatNewOG (Prodcode, puid)
(SELECT Prodcode,PUid from @tMCR WHERE puid is NULL)

SET @count = (SELECT COUNT(*) FROM @ExistMatNewOG)

SET @MinCount = 1
WHILE ( @MinCount <= @count)
BEGIN
SELECT @value = ( Select Convert(Varchar,VALUE) from dbo.Property_MaterialDefinition_MaterialClass PMM 
JOIN MaterialDefinition MD ON MD.MaterialDefinitionId = PMM.MaterialDefinitionId 
JOIN @ExistMatNewOG EMO on MD.S95Id LIKE '%'+EMO.prodCode+'%'
AND EMO.ID = @MinCount 
WHERE Name LIKE 'ORIGIN GROUP')


SELECT @PUid = (SELECT p.PU_ID FROM PROD_UNITS p
				JOIN dbo.PrdExec_Path_Units ppu WITH (NOLOCK) ON ppu.path_id = @PathId AND ppu.pu_id = p.pu_id
				JOIN PRDEXEC_INPUTS PEI WITH (NOLOCK) ON P.pu_id = PEI.pu_id
				JOIN Table_Fields_Values tfv WITH (NOLOCK) ON pEI.pei_id = tfv.keyid
				WHERE tfv.table_Field_id  = @BOMOriginGroupid and tfv.tableid = @PrdInputtableid
				AND tfv.Value = @value)
			
UPDATE @TMCR 
SET PUid = @PUId
FROM @tMCR tmcr
JOIN @ExistMatNewOG EMO ON tmcr.prodcode = Emo.Prodcode 
AND Emo.id = @MinCount
JOIN @Prdexecpaths PP ON PP.PUid = @PUId
SET @MinCount = @MinCount + 1
END

Update @tmcr 
SET PUid = pu_id 
FROM @tmcr tmcr
JOIN dbo.Data_Source_XRef dsf ON dsf.Actual_Id = tmcr.puid
JOIN Prod_units p WITH (NOLOCK) ON p.pu_Desc = dsf.Foreign_Key




END
		    
         
IF @DebugFlag = 1        
   SELECT '2.11 tMCRP', * FROM @tMCRP        
          
-------------------------------------------------------------------------------        
--**** FINSIHED POPULATING THE TABLES FROM THE xml        
-------------------------------------------------------------------------------        
        
-------------------------------------------------------------------------------        
-- Task 3 - Error Checks        
-------------------------------------------------------------------------------        
-- Task 3.01        
-- If the MPR product doesn't exist, then quit.        
-------------------------------------------------------------------------------        
SELECT @RowCount = 0        
SELECT @RowCount = COUNT(*)        
FROM  @tMPR mpr        
JOIN  @tER er      ON er.ParentId = mpr.ParentId and er.mprNoProduct = 3        
LEFT JOIN dbo.Products p WITH(NOLOCK) ON mpr.ProdCode = p.Prod_Code        
WHERE  mpr.ProdId IS NULL          
   AND p.Prod_Id IS NULL        
                 
                 
IF @RowCount > 0         
 BEGIN        
    DELETE FROM @tErrRef        
    SELECT @ErrCode = -161        
            
    INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Product: ' + mpr.ProdCode + ' on Path:' + CONVERT(varchar(10),er.PathId)        
 FROM  @tMPR mpr        
 JOIN  @tER er ON er.ParentId = mpr.ParentId and er.mprNoProduct = 3        
 LEFT JOIN dbo.Products p WITH(NOLOCK) ON mpr.ProdCode = p.Prod_Code        
 WHERE mpr.ProdId IS NULL          
    AND p.Prod_Id IS NULL        
            
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
--IF       @mprNoProduct = 3        
--       AND       (SELECT  COUNT(*)        
--              FROM  @tMPR mpr        
--                     LEFT  JOIN       dbo.Products p         
--                     ON mpr.ProdCode = p.Prod_Code        
--                     WHERE  mpr.ProdId IS NULL        
--                     AND       p.Prod_Id IS NULL) > 0        
--BEGIN        
--    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
--      SELECT -161, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
--        FROM dbo.email_message_data emd         
--        WHERE emd.Message_Id = -161        
--     GOTo ErrCode        
--       ----return       (0)        
--END        
        
-------------------------------------------------------------------------------        
-- Task 3.02     
-- If the MCR product doesn't exist, then quit.        
-------------------------------------------------------------------------------        
SELECT @RowCount = 0        
        
SELECT @RowCount = COUNT(*)        
FROM  @tMCR mcr        
JOIN  @tER er on er.ParentId = mcr.ParentId and er.mcrNoProduct = 3        
LEFT JOIN dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code        
WHERE mcr.ProdId IS NULL          
  AND p.Prod_Id IS NULL        
          
IF @RowCount > 0         
 BEGIN        
 DELETE FROM @tErrRef        
         
 SELECT @ErrCode = -168        
         
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Product: ' + mcr.ProdCode + ' on Path:' + CONVERT(varchar(10),er.PathId)        
 FROM  @tMCR mcr        
 JOIN  @tER er ON er.ParentId = mcr.ParentId and er.mcrNoProduct = 3        
 LEFT JOIN dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code        
 WHERE mcr.ProdId IS NULL          
   AND p.Prod_Id IS NULL        
            
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
--IF       @mcrNoProduct = 3        
--       AND       (SELECT   COUNT(*)        
--                     FROM  @tMCR mcr        
--                     LEFT  JOIN       dbo.Products p ON mcr.ProdCode = p.Prod_Code        
--                     WHERE mcr.ProdId IS NULL        
--                     AND       p.Prod_Id IS NULL) > 0        
--BEGIN        
--    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
--      SELECT -168, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
--        FROM dbo.email_message_data emd         
--        WHERE emd.Message_Id = -168        
--     GOTo ErrCode        
--       ----return       (0)        
--END        
        
        
        
-------------------------------------------------------------------------------        
-- Task 3.03        
-- If the MPR product doesn't exist, but the description has already been used,         
-- then quit.        
-------------------------------------------------------------------------------        
SELECT @RowCount = 0        
        
SELECT @RowCount = COUNT(*)        
FROM  @tMPR mpr        
JOIN  Products p WITH(NOLOCK) ON mpr.ProdDesc = p.Prod_Desc        
WHERE  mpr.ProdId IS NULL        
                 
IF @RowCount > 0         
 BEGIN        
 DELETE FROM @tErrRef        
         
 SELECT @ErrCode = -168        
         
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Product: ' + mpr.ProdDesc + ' on Path:' + CONVERT(varchar(10),er.PathId)        
 FROM @tMPR mpr        
 JOIN Products p WITH(NOLOCK) ON mpr.ProdDesc = p.Prod_Desc        
 JOIN @tER er ON er.ParentId = mpr.ParentId         
 WHERE  mpr.ProdId IS NULL        
         
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE  emd.Message_Id = @ErrCode        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
         
--IF       (SELECT       COUNT(*)        
--              FROM  @tMPR mpr        
--              JOIN  Products p ON mpr.ProdDesc = p.Prod_Desc        
--          WHERE  mpr.ProdId IS NULL) > 0        
--BEGIN        
--    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
--      SELECT -162, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
--        FROM dbo.email_message_data emd         
--        WHERE emd.Message_Id = -162        
--     GOTo ErrCode        
--       ----return       (0)        
--END        
        
        
-------------------------------------------------------------------------------        
-- Task 3.04         
-- If the MPR product isn't associated to the path, then quit.        
-------------------------------------------------------------------------------        
--Select @mprNoPathProd as mprNoPathProd        
SELECT @RowCount = 0        
        
SELECT @RowCount = COUNT(*)        
FROM  @tER er        
JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId        
LEFT JOIN   dbo.PrdExec_Path_Products pepp WITH(NOLOCK) ON er.PathId = pepp.Path_Id        
                      AND  mpr.ProdId = pepp.Prod_Id        
WHERE pepp.PEPP_Id IS NULL         
  AND er.mprNoPathProd = 3        
                 
                 
IF @RowCount > 0         
 BEGIN        
 DELETE FROM @tErrRef        
         
 SELECT @ErrCode = -164        
         
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Product: ' + mpr.ProdCode + ' on Path:' + CONVERT(varchar(10),er.PathId)        
 FROM  @tER er        
 JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId        
 LEFT JOIN   dbo.PrdExec_Path_Products pepp WITH(NOLOCK) ON er.PathId = pepp.Path_Id        
                       AND mpr.ProdId = pepp.Prod_Id        
 WHERE pepp.PEPP_Id IS NULL         
   AND er.mprNoPathProd = 3        
         
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
--IF       @mprNoPathProd = 3        
--       AND       (SELECT  COUNT(*)        
--                     FROM  @tER er        
--                     JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId        
--                     LEFT  JOIN       dbo.PrdExec_Path_Products pepp ON er.PathId = pepp.Path_Id        
--                                   AND       mpr.ProdId = pepp.Prod_Id        
--                     WHERE       pepp.PEPP_Id IS NULL) > 0        
--BEGIN        
--       SELECT       TOP 1  @ErrMsg = @ErrMsg + '|-164:Path product does not exist: ' + pep.Path_Desc + ', '        
--                            + mpr.ProdCode + '  '        
--              FROM              @tMPR mpr        
--              JOIN              @tER er ON mpr.ParentId = er.ParentId        
--              JOIN              dbo.PrdExec_Paths pep ON er.PathId = pep.Path_Id        
--              LEFT       JOIN       dbo.PrdExec_Path_Products pepp ON pep.Path_Id = pepp.Path_Id       
--                            AND       mpr.ProdId = pepp.Prod_Id        
--              WHERE       pepp.PEPP_Id IS NULL        
--       PRint       @ErrMsg        
--    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
--      SELECT -164, emd.Message_Subject, emd.Message_Text, emd.Severity, @ErrMsg        
--        FROM dbo.email_message_data emd         
--        WHERE emd.Message_Id = -164        
--     GOTo ErrCode        
--       ----return       (0)        
--END        
        
        
        
-------------------------------------------------------------------------------        
-- Task 3.05        
-- If the required path isn't configured in Plant Applications, then quit.        
-------------------------------------------------------------------------------        
--SELECT @mprNoPath AS mprNoPath        
-- JG: I'm not sure how this works. Leaving it for now - ask Simon.         
--     regardless, use the subscription based global parameter since there's no way to look it up for a Path        
        
/*------------------------------------------------        
UL V 2.0 Use IF EXISTS instead of COUNT        
--------------------------------------------------*/        
IF    @mprNoPath = 3  AND   ((SELECT  COUNT(*)        
                     FROM   @tER        
                      WHERE  PathId IS NULL) > 0 OR        
                       (SELECT COUNT(*)         
                      FROM @tER) = 0)        
 BEGIN        
  DELETE FROM @tErrRef        
  SELECT @ErrCode = -142        
          
  INSERT intO @tErrRef (ErrorCode, ReferenceData)        
  SELECT @ErrCode, 'Path does not exist: ' + EquipmentId        
  FROM  @tER er        
  WHERE PathId IS NULL        
          
  IF (SELECT COUNT(*) FROM @tER) = 0        
   BEGIN        
    INSERT into @tErrRef(ErrorCode, ReferenceData)        
    SELECT @ErrCode, 'Path does not exist:'        
   END        
          
  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
  SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
  FROM dbo.email_message_data emd WITH(NOLOCK)        
  JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
  WHERE emd.Message_Id = @ErrCode        
          
  GOTO ErrCode        
  ----return       (0)        
 END        
        
-------------------------------------------------------------------------------        
-- Task 3.06        
-- If the associated path has no UoM, then quit.        
-------------------------------------------------------------------------------        
/*------------------------------------------------        
UL V 2.0 Use IF EXISTS instead of COUNT        
--------------------------------------------------*/        
/*        
IF       (SELECT       COUNT(*)        
              FROM       @tMPR MPR        
              JOIN       @tER ER        
              ON       MPR.ParentId       = ER.ParentId        
              WHERE       MPR.PathUoM IS NULL        
              AND       ER.PathId   IS NOT NULL) > 0 -- do not check for unbound POs        
*/        
IF EXISTS(SELECT *        
          FROM @tMPR MPR        
          JOIN @tER ER ON MPR.ParentId = ER.ParentId        
          WHERE MPR.PathUoM IS NULL            
               AND ER.PathId IS NOT NULL        
          )        
 BEGIN        
 DELETE FROM @tErrRef        
         
 SELECT @ErrCode = -143        
         
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'No UoM on Path: ' + er.EquipmentId        
 FROM   @tER er        
 JOIN   @tMPR mpr ON er.ParentId = mpr.ParentId        
        AND mpr.PathUoM IS NULL        
                
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)         
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
         
         
-------------------------------------------------------------------------------        
-- Task 3.07        
-- If there is no conversion factor between the MPR UoM and the Path UoM,         
-- then quit.        
-------------------------------------------------------------------------------        
/*------------------------------------------------        
UL V 2.0 Use IF EXISTS instead of COUNT        
--------------------------------------------------*/        
/*        
IF       (SELECT  COUNT(*)        
              FROM   @tMPR mpr        
              LEFT       JOIN       Engineering_Unit eu1 ON mpr.UoM = eu1.Eng_Unit_Code        
              LEFT       JOIN       Engineering_Unit eu2 ON mpr.PathUoM = eu2.Eng_Unit_Code        
              LEFT       JOIN       Engineering_Unit_Conversion euc ON eu2.Eng_Unit_Id = euc.From_Eng_Unit_Id        
                            AND       eu1.Eng_Unit_Id = euc.To_Eng_Unit_Id        
              WHERE       euc.Eng_Unit_Conv_Id IS NULL        
              AND       mpr.UoM <> mpr.PathUoM) > 0        
*/        
IF EXISTS( SELECT *         
   FROM   @tMPR mpr        
           LEFT JOIN dbo.Engineering_Unit eu1    WITH(NOLOCK) ON mpr.UoM = eu1.Eng_Unit_Code        
           LEFT JOIN dbo.Engineering_Unit eu2    WITH(NOLOCK) ON mpr.PathUoM = eu2.Eng_Unit_Code        
           LEFT JOIN dbo.Engineering_Unit_Conversion euc WITH(NOLOCK) ON eu2.Eng_Unit_Id = euc.From_Eng_Unit_Id        
                                     AND eu1.Eng_Unit_Id = euc.To_Eng_Unit_Id        
    WHERE euc.Eng_Unit_Conv_Id IS NULL        
             AND mpr.UoM <> mpr.PathUoM        
  )        
 BEGIN        
 DELETE FROM @tErrRef        
         
 SELECT @ErrCode = -165        
         
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'No Conversion Factor for UoM on Path: ' + er.EquipmentId        
 FROM  @tER er        
 JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId        
 LEFT JOIN dbo.Engineering_Unit eu1 WITH(NOLOCK) ON mpr.UoM = eu1.Eng_Unit_Code        
 LEFT JOIN dbo.Engineering_Unit eu2 WITH(NOLOCK) ON mpr.PathUoM = eu2.Eng_Unit_Code        
 LEFT JOIN dbo.Engineering_Unit_Conversion euc WITH(NOLOCK) ON eu2.Eng_Unit_Id = euc.From_Eng_Unit_Id        
              AND       eu1.Eng_Unit_Id = euc.To_Eng_Unit_Id        
 WHERE euc.Eng_Unit_Conv_Id IS NULL        
   AND mpr.UoM <> mpr.PathUoM        
           
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
         
         
-------------------------------------------------------------------------------        
-- Task 3.08        
-- If the provided BOM is not configured in Plant Applications, then quit.        
-------------------------------------------------------------------------------        
SELECT @RowCount = 0        
SELECT @RowCount = COUNT(*)        
     FROM @tPR pr        
     JOIN @tSR sr ON pr.Id = sr.ParentId        
     JOIN @tER er ON er.ParentId = sr.NodeId AND er.NoFormulation = 2 AND @FlgIgnoreBOMInfo = 0        
     WHERE  pr.BOMId IS NULL        
             
IF @RowCount > 0         
 BEGIN        
 DELETE FROM @tErrRef        
         
 SELECT @ErrCode = -121        
         
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Process Order: ' + pr.ProcessOrder + ' on Path:' + CONVERT(varchar(10),er.PathId)        
 FROM    @tPR pr        
 JOIN @tSR sr ON pr.Id = sr.ParentId        
 JOIN @tER er ON er.ParentId = sr.NodeId         
      AND er.NoFormulation = 2         
      AND @FlgIgnoreBOMInfo = 0        
 WHERE   pr.BOMId IS NULL       
         
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 GOTo ErrCode        
 ----return       (0)        
 END        
--IF       @NoFormulation = 2           
--       AND       @FlgIgnoreBOMInfo = 0               -- ***        
--       AND (SELECT       COUNT(*)        
--                     FROM       @tPR        
--                     WHERE       BOMId IS NULL) > 0        
--BEGIN        
--       SELECT       TOP 1       @ErrMsg = @ErrMsg + '|-121:No BoM configured: ' + FormulationDesc        
--              FROM       @tPR        
--              WHERE       BOMId IS NULL        
--       PRint       @ErrMsg        
--      INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
--        SELECT -121, emd.Message_Subject, emd.Message_Text, emd.Severity, @errmsg        
--          FROM dbo.email_message_data emd         
--          WHERE emd.Message_Id = -121        
--       GOTo ErrCode        
--       ----return       (0)        
--END        
        
        
           
        
        
        
-------------------------------------------------------------------------------        
-- Task 3.09        
-- If the passed process order has already been active, then quit.        
-------------------------------------------------------------------------------        
IF EXISTS(SELECT pp.Process_Order        
   FROM @tPR pr        
   JOIN dbo.Production_Plan pp ON (pp.Process_Order = pr.ProcessOrder)        
   JOIN @tER er ON (er.PathId = pp.Path_Id) )        
 SELECT @FlgPPExisted = 1       
 
 -- Check for Family care, we wont filter by path id since we have to check for Parent/Child paths.
 IF EXISTS( SELECT ds_id FROM dbo.Data_Source with(nolock) WHERE ds_Desc = 'SView'  )
BEGIN    
IF EXISTS(SELECT pp.Process_Order        
   FROM @tPR pr        
   JOIN dbo.Production_Plan pp WITH (NOLOCK) ON (pp.Process_Order = pr.ProcessOrder)   )
   BEGIN
    SELECT @FlgPPExisted = 1  
	SELECT  @PPId = pp.PP_Id,        
   @ProcessOrder = pp.Process_Order        
 FROM @tPR pr        
 JOIN dbo.Production_Plan pp WITH(NOLOCK) ON (pp.Process_Order = pr.ProcessOrder)  
	END
END 
   
IF @FlgPPExisted = 1        
 BEGIN        
 SELECT  @PPId = pp.PP_Id,        
   @ProcessOrder = pp.Process_Order        
 FROM @tPR pr        
 JOIN dbo.Production_Plan pp WITH(NOLOCK) ON (pp.Process_Order = pr.ProcessOrder)         
 JOIN @tER er ON (er.PathId = pp.Path_Id)        
        
        
 SELECT @PPCurrentStatusStr = pps.PP_Status_Desc        
 FROM dbo.Production_Plan pp WITH(NOLOCK)        
 JOIN dbo.Production_Plan_Statuses pps WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)        
 WHERE pp.PP_Id = @PPId        
          
 SELECT @ERPOrderStatus = ERPOrderStatus        
 FROM @tPR        
         
 /*------------------------------------------------        
 UL V 2.0 Use IF EXISTS instead of COUNT        
 --------------------------------------------------*/        
 /*        
 IF  (SELECT COUNT(*)        
               FROM    @tER er           
               JOIN       dbo.Production_Plan_Starts pps ON er.PPId = pps.PP_Id) > 0        
     AND @PPCurrentStatusStr = @MESOrderStatus_PENDING        
     AND CHARINDEX(@ERPOrderStatus, @ERPOrderStatus_CTECO) = 0        
    */        
    IF EXISTS( SELECT *        
    FROM @tER er        
    JOIN dbo.Production_Plan_Starts pps ON er.PPId = pps.PP_Id        
        )         
     AND @PPCurrentStatusStr = @MESOrderStatus_PENDING        
     AND CHARINDEX(@ERPOrderStatus, @ERPOrderStatus_CTECO) = 0        
  BEGIN        
  DELETE FROM @tErrRef        
          
  SELECT @ErrCode = -101        
          
  INSERT intO @tErrRef (ErrorCode, ReferenceData)        
  SELECT @ErrCode, 'Process Order: ' + pp.Process_Order         
  FROM   @tER er        
  JOIN   dbo.Production_Plan_Starts pps WITH(NOLOCK) ON er.PPId = pps.PP_Id        
  JOIN   dbo.Production_Plan pp   WITH(NOLOCK) ON pp.PP_Id = er.PPId        
          
  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
  SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
  FROM dbo.email_message_data emd WITH(NOLOCK)        
  JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
  WHERE emd.Message_Id = @ErrCode        
          
 --       SELECT       @ErrTemp       =         
 --       CASE       @RepeatedPO        
 --              WHEN       1       THEN       '-101'        
 --              WHEN       2       THEN       '-102'        
 --              WHEN       3       THEN       '-103'        
 --              WHEN       4       THEN       '-104'        
 --              WHEN       5       THEN       '-105'        
 --       END        
 --       IF       @RepeatedPO       <> 6          
 --       BEGIN        
 --              IF       @ErrCode IS NULL        
 --                     SELECT       @ErrCode = @ErrTemp        
 --              ELSE        
 --                     SELECT       @ErrCode = @ErrCode + '|' + @ErrTemp        
 --       END        
 --       --return       (0)        
  GOTO ErrCode        
        ----return       (0)        
  END        
 END        
         
         
        
-------------------------------------------------------------------------------        
-- Task 3.10        
-- If the passed process order already exists and its status matches one of the        
-- passed non-update status parameter, then quits        
-------------------------------------------------------------------------------        
/*------------------------------------------------        
UL V 2.0 Use IF EXISTS instead of COUNT        
--------------------------------------------------*/        
/*        
IF       (SELECT       COUNT(*)        
              FROM       @tER er        
              JOIN       dbo.Production_Plan PP        
              ON       er.PPId              = PP.PP_Id        
              JOIN       @tPPStatus t        
              ON       t.PPStatusId       = PP.PP_Status_Id) > 0        
*/        
IF EXISTS ( SELECT *         
   FROM @tER er        
           JOIN dbo.Production_Plan PP WITH(NOLOCK) ON  er.PPId   = PP.PP_Id        
           JOIN @tPPStatus t       ON  t.PPStatusId = PP.PP_Status_Id        
   )        
 BEGIN        
--       SELECT       @ErrTemp       =         
--       CASE       @RepeatedPO        
--              WHEN       1       THEN       '-108'        
--              WHEN       2       THEN       '-109'        
--              WHEN       3       THEN       '-110'        
--              WHEN       4       THEN       '-111'        
--              WHEN       5       THEN       '-112'        
--       END        
--       IF       @RepeatedPO       <> 6          
--       BEGIN        
--              IF       @ErrCode IS NULL        
--             SELECT       @ErrCode = @ErrTemp        
--              ELSE        
--                     SELECT       @ErrCode = @ErrCode + '|' + @ErrTemp        
--       END        
--       --return       (0)        
--TODO: ADD ERR REFERENCE CODE        
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -108, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 WHERE emd.Message_Id = -108        
         
 GOTO ErrCode        
 ----return       (0)        
 END        
         
         
         
-------------------------------------------------------------------------------        
-- If the MCR location isn't configured, then quit.        
-------------------------------------------------------------------------------        
-- DISABLED because the MCR.PUId is an optional field        
--IF       (SELECT       COUNT(*)        
--              FROM       @tMCR        
--              WHERE       PUId IS NULL) > 0        
--BEGIN        
--       SELECT       TOP 1       @ErrMsg = @ErrMsg + 'MCR location not configured: ' + EquipmentId        
--              FROM       @tMCR        
--              WHERE       PUId IS NULL        
--       PRint       @ErrMsg        
--       IF       @ErrCode IS NULL        
--              SELECT       @ErrCode = '-180'        
--       ELSE        
--              SELECT       @ErrCode = @ErrCode + '|-180'        
--       --return       (0)        
--END        
-------------------------------------------------------------------------------        
-- End of Fatal Error Checks         
-------------------------------------------------------------------------------        
        
        
        
        
-----------------------------------------------------------------------------        
-- Task 3.11        
-- If the MPR product doesn't exist, use the default product.        
-------------------------------------------------------------------------------        
SELECT @RowCount = 0        
        
SELECT @RowCount = COUNT(*)        
FROM  @tMPR mpr        
JOIN  @tER er ON er.ParentId = mpr.ParentId         
      AND er.mprNoProduct = 2        
LEFT JOIN  dbo.Products p WITH(NOLOCK) ON mpr.ProdCode = p.Prod_Code        
WHERE mpr.ProdId IS NULL          
  AND p.Prod_Id IS NULL        
          
IF @RowCount > 0         
 BEGIN        
 --IF       @mprNoProduct = 2        
 --       AND       (SELECT       COUNT(*)        
 --                     FROM       @tMPR mpr        
 ----                     LEFT       JOIN       dbo.Products p ON mpr.ProdDesc = p.Prod_Desc        
 --                     LEFT       JOIN       dbo.Products p ON mpr.ProdCode = p.Prod_Code        
 --                     WHERE       mpr.ProdId IS NULL        
 --                     AND       p.Prod_Id IS NULL) > 0        
 UPDATE  mpr        
 SET   ProdId = @DefaultMPRProdId        
 FROM  @tMPR mpr        
 JOIN  @tER er ON er.ParentId = mpr.ParentId         
       AND er.mprNoProduct = 2        
 LEFT JOIN dbo.Products p WITH(NOLOCK) ON mpr.ProdCode = p.Prod_Code        
 WHERE mpr.ProdId IS NULL        
   AND p.Prod_Id IS NULL        
           
--TODO: ADD ERR REFERENCE CODE        
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -160, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 WHERE emd.Message_Id = -160        
         
 END        
        
        
         
         
-------------------------------------------------------------------------------        
-- Task 3.12        
-- If the MCR product doesn't exist, use the default product.        
-------------------------------------------------------------------------------        
--IF       @mcrNoProduct = 2        
--       AND       (SELECT       COUNT(*)        
--                     FROM       @tMCR mcr        
----                     LEFT       JOIN       dbo.Products p ON mcr.ProdDesc = p.Prod_Desc        
--                     LEFT       JOIN       dbo.Products p ON mcr.ProdCode = p.Prod_Code        
--                     WHERE       mcr.ProdId IS NULL        
--                     AND       p.Prod_Id IS NULL) > 0        
SELECT @RowCount = 0        
        
SELECT @RowCount = COUNT(*)        
FROM  @tMCR mcr        
JOIN  @tER er on er.ParentId = mcr.ParentId and er.mcrNoProduct = 2        
LEFT JOIN dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code         
WHERE  mcr.ProdId IS NULL          
   AND p.Prod_Id IS NULL        
           
IF @RowCount > 0         
 BEGIN        
 UPDATE mcr        
 SET   ProdId = @DefaultMCRProdId        
 FROM  @tMCR mcr        
 JOIN  @tER er ON er.ParentId = mcr.ParentId         
       AND er.mcrNoProduct = 2        
 LEFT JOIN   dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code        
 WHERE  mcr.ProdId IS NULL        
   AND p.Prod_Id IS NULL        
           
--TODO: ADD ERR REFERENCE CODE  
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -167, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 WHERE emd.Message_Id = -167        
         
 END        
        
        
        
        
        
-------------------------------------------------------------------------------        
-- Task 3.13        
-- If the required path isn't configured in Plant Applications, then exit with         
-- fatal error        
-------------------------------------------------------------------------------        
-- This must use the global Download subscription since there is no path to tie it to        
        
/*IF  @mprNoPath = 1        
       AND  (SELECT  COUNT(*)        
                     FROM       @tER        
                     WHERE       PathId IS NULL) > 0        
*/        
IF EXISTS(SELECT * FROM @tER WHERE PathId IS NULL)        
 BEGIN        
 --TODO: ADD ERR REFERENCE CODE        
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -142, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 WHERE emd.Message_Id = -142        
 GOTo ErrCode        
 ----return       (0)        
 END        
         
        
-------------------------------------------------------------------------------        
-- Task 3.14        
-- If the required path isn't configured in Plant Applications, then the         
-- schedule will be unbound.        
-------------------------------------------------------------------------------        
-- This must use the global Download subscription since there is no path to tie it to        
/*        
IF       @mprNoPath = 2        
       AND       (SELECT       COUNT(*)        
                     FROM       @tER        
                     WHERE       PathId IS NULL) > 0        
*/        
IF EXISTS(SELECT * FROM @tER WHERE PathId IS NULL ) AND @mprNoPath = 2        
 BEGIN        
 SELECT TOP 1 @ErrMsg = 'Path does not exist: ' + EquipmentId        
 FROM   @tER        
 WHERE  PathId IS NULL        
         
--TODO: ADD ERR REFERENCE CODE        
        
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT -141, emd.Message_Subject, emd.Message_Text, emd.Severity, @errmsg        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 WHERE emd.Message_Id = -141        
         
 END        
        
        
        
        
        
        
        
-------------------------------------------------------------------------------        
-- Task 3.15        
-- If the MPR product isn't associated to the path, then the schedule will be         
-- unbound.        
-------------------------------------------------------------------------------        
--IF       @mprNoPathProd = 2        
--       AND       (SELECT       COUNT(*)        
--                     FROM              @tER er        
--                     JOIN              @tMPR mpr ON er.ParentId = mpr.ParentId        
--                     LEFT       JOIN       dbo.PrdExec_Path_Products pepp ON er.PathId = pepp.Path_Id        
--                                   AND       mpr.ProdId = pepp.Prod_Id        
--                     WHERE       pepp.PEPP_Id IS NULL) > 0        
SELECT @RowCount = 0        
SELECT @RowCount = COUNT(*)        
FROM  @tER er        
JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId        
LEFT JOIN dbo.PrdExec_Path_Products pepp WITH(NOLOCK) ON er.PathId = pepp.Path_Id        
                 AND mpr.ProdId = pepp.Prod_Id        
WHERE pepp.PEPP_Id IS NULL         
  AND er.mprNoPathProd = 2        
          
IF @RowCount > 0         
 BEGIN        
    DELETE FROM @tErrRef        
            
    SELECT @ErrCode = -163        
            
    INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Path product does not exist: ' + pep.Path_Desc + ', ' + mpr.ProdCode + '  '        
 FROM     @tMPR mpr        
 JOIN     @tER er ON mpr.ParentId = er.ParentId AND er.mprNoPathProd = 2        
 JOIN     dbo.PrdExec_Paths pep WITH(NOLOCK)   ON er.PathId = pep.Path_Id        
 LEFT JOIN dbo.PrdExec_Path_Products pepp WITH(NOLOCK) ON pep.Path_Id = pepp.Path_Id        
                  AND mpr.ProdId = pepp.Prod_Id        
 WHERE   pepp.PEPP_Id IS NULL         
         
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 UPDATE  er        
 SET    PathId = NULL        
 FROM     @tMPR mpr        
 JOIN     @tER er ON mpr.ParentId = er.ParentId        
 JOIN     dbo.PrdExec_Paths pep WITH(NOLOCK)   ON er.PathId = pep.Path_Id        
 LEFT JOIN dbo.PrdExec_Path_Products pepp WITH(NOLOCK) ON pep.Path_Id = pepp.Path_Id        
                       AND mpr.ProdId = pepp.Prod_Id        
 WHERE       pepp.PEPP_Id IS NULL        
         
 END        
         
         
         
         
         
-------------------------------------------------------------------------------        
-- Task 3.16        
-- If the process order is unbound, then don't convert the engineering units.        
-------------------------------------------------------------------------------        
/*        
IF       (SELECT       COUNT(*)        
              FROM       @tER        
              WHERE       PathId IS NULL) > 0        
*/        
IF EXISTS(SELECT * FROM @tER WHERE PathId IS NULL)        
 BEGIN        
    DELETE FROM @tErrRef        
            
    SELECT @ErrCode = -166        
            
    INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, '-166:Engineering Unit not converted for: ' + EquipmentId        
 FROM @tER        
 WHERE PathId IS NULL        
         
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 UPDATE  mpr        
 SET    Qty = mpr.QuantityString        
 FROM    @tMPR mpr        
 JOIN    @tER er ON mpr.ParentId = er.ParentId        
 WHERE   er.PathId IS NULL        
         
 END        
        
-------------------------------------------------------------------------------        
-- End of Warning Error Checks         
-------------------------------------------------------------------------------        
        
        
        
        
-------------------------------------------------------------------------------        
-- Task 4 - Processing the MPR        
-------------------------------------------------------------------------------        
-- Loop through each MPR. even for existing products, to check if they are         
-- associated with the pu and path        
--        
-- Mark all MPR records as unprocessed        
-------------------------------------------------------------------------------        
UPDATE  @tMPR  SET Status = 0        
-------------------------------------------------------------------------------        
-- Get first MPR to be processed        
-------------------------------------------------------------------------------        
SELECT @Id = NULL        
        
SELECT @Id = MIN(Id)        
FROM   @tMPR        
WHERE  Status = 0        
            
-------------------------------------------------------------------------------        
-- Loop through each MPR        
-------------------------------------------------------------------------------        
WHILE   (@Id Is Not NULL)        
 BEGIN        
       -------------------------------------------------------------------------------        
       -- Mark this MPR as processed        
       -------------------------------------------------------------------------------        
 UPDATE  @tMPR        
 SET    Status   = 1        
 WHERE   Id  = @Id        
       -------------------------------------------------------------------------------        
       -- Retrieve some MPR attributes        
       -------------------------------------------------------------------------------        
 SELECT  @ParentId   = ParentId,        
   @ProdCode   = ProdCode,        
   @ProdDesc   = ProdDesc,        
   @PUId    = PUId,        
   @ProdId  = ProdId,      
   @NodeId    = NodeId        
 FROM    @tMPR        
 WHERE Id = @Id        
       -------------------------------------------------------------------------------        
       -- Get Path from the EquipmentRequirement (Assume a single ER for a given SR.         
       -- If wrong, we need an inner loop)        
       -------------------------------------------------------------------------------        
               
 SELECT  @PathId      = Null,        
   @FlgCreateProduct = NULL,        
   @OriginalProdId    = @ProdId        
           
 SELECT  TOP 1 @PathId = PathId,         
   @FlgCreateProduct = FlgCreateProduct,         
   @DefaultPRODFamilyId = DefaultPRODFamilyId,        
   @UserId = UserId,        
   @FlgUpdateMPRDesc = FlgUpdateMPRDesc        
 FROM    @tER        
 WHERE   ParentId  = @ParentId        
        
 IF @FlgCreateProduct = 1        
  EXEC   spS95_ScheduleProdCreate        
        @ProdId                     OUTPUT,     --  @OutputValue  varchar(25) OUTPUT,        
        @CreatePUAssoc              OUTPUT,    --        
        @CreatePathAssoc               OUTPUT,     --        
        @ProdCode,                               --  @PssblNewProdDesc       varchar(255),        
        @ProdDesc,                               --  @NoProductId            int = Null,        
        @DefaultPRODFamilyId,                    --  @FamilyId               int,        
        @UserId,                               --  @UserId                 int,        
        @PUId,                                 --  @PUId                int,        
        @PathId,                                --  @PathId                 int,        
        @FlgUpdateMPRDesc                        --  @FlgUpdateDesc         int        
                         
                    
 IF  @OriginalProdId  IS NULL        
   -------------------------------------------------------------------------------        
   -- For new products: if can not be created, then exits with fatal error        
   -------------------------------------------------------------------------------        
  BEGIN        
  IF @ProdID  IS NULL        
   BEGIN        
   INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
   SELECT -169, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Product: ' + Coalesce(Convert(varchar(25), @ProdCode), 'No ProdCode') + ' on PathID:' + Coalesce(Convert(varchar(25), @PathId), 'No PathId')        
   FROM dbo.email_message_data emd WITH(NOLOCK)        
   WHERE emd.Message_Id = -169        
           
   GOTo ErrCode        
   ----return       (0)        
        
   END        
  -------------------------------------------------------------------------------        
  -- For new products: update the MPR record with the new product id        
  -------------------------------------------------------------------------------        
  UPDATE @tMPR        
  SET  ProdId   = @ProdId,        
    FlgNewProduct   = 1         
  WHERE    NodeId  = @NodeId        
          
  END        
          
          
 -------------------------------------------------------------------------------        
 -- Update pathId for new and old products        
 -------------------------------------------------------------------------------        
 UPDATE       @tMPR        
 SET   PathId              = @PathId,        
     CreatePUAssoc       = @CreatePUAssoc,        
     CreatePathAssoc       = @CreatePathAssoc         
 WHERE       NodeId       = @NodeId        
        
       -------------------------------------------------------------------------------        
       -- Move to next MPR        
       -------------------------------------------------------------------------------        
 SELECT  @Id  = NULL        
 SELECT  @Id  = MIN(Id)        
 FROM    @tMPR        
 WHERE   Status = 0        
         
 END        
         
        
-------------------------------------------------------------------------------        
-- Task 5 - Processing the MCR        
-------------------------------------------------------------------------------        
-- If the MCR product doesn't exist, make a new product under the Default         
-- Product Family.        
-- If the MCR product exists and the PU Id was passed, then associates PU to         
-- ProdId, if necessary        
-------------------------------------------------------------------------------        
-- Loop through each MCR        
        
-------------------------------------------------------------------------------        
SELECT   @PathId       = Null,        
        @ProdId       = Null         
-------------------------------------------------------------------------------        
-- Get first MCR to be processed        
-------------------------------------------------------------------------------        
SELECT  @Id  = NULL        
        
SELECT  @Id  = MIN(Id)        
FROM    @tMCR        
WHERE Status = 0        
        
-------------------------------------------------------------------------------        
-- Loop through each MCR        
-------------------------------------------------------------------------------        
WHILE   (@Id IS NOT NULL)        
 BEGIN        
 -------------------------------------------------------------------------------        
 -- Mark this MCR as processed        
 -------------------------------------------------------------------------------        
 UPDATE  @tMCR        
 SET    Status  = 1        
 WHERE   Id   = @Id        
         
 -------------------------------------------------------------------------------        
 -- Retrieve some MCR attributes        
 -------------------------------------------------------------------------------        
 SELECT  @PUId      = mcr.PUId,        
     @ProdCode     = mcr.ProdCode,        
     @ProdDesc     = mcr.ProdDesc,        
     @NodeId      = mcr.NodeId,        
     @ProdId      = mcr.ProdId,        
     @FlgCreateProduct = er.FlgCreateProduct        
 FROM    @tMCR mcr        
 JOIN @tER er ON mcr.ParentId = er.ParentId        
 WHERE   mcr.Id = @Id        
                                        
 IF  @FlgIgnoreBOMInfo = 0  AND @FlgCreateProduct = 1  -- if site processes BOM info        
  BEGIN               
  -------------------------------------------------------------------------------        
  -- create the product. If PUId is passed, associate with PU. If Path is passed,         
  -- associated with path        
  -------------------------------------------------------------------------------        
  SELECT   @OriginalProdId = @ProdId        
          
  EXEC   spS95_ScheduleProdCreate        
    @ProdId       OUTPUT,     --  @OutputValue        varchar(25) OUTPUT,        
    @CreatePUAssoc     OUTPUT,      --        
    @CreatePathAssoc    OUTPUT,      --        
    @ProdCode,                        --  @PossiblNewProdDesc   varchar(255),        
    @ProdDesc,                        --  @NoProductId          int = Null,        
    @DefaultRawMaterialProdId,       --  @FamilyId             int,        
    @UserId,                       --  @UserId               int,        
    @PUId,                           --  @PUId              int,        
    @PathId,                        --  @PathId               int        
    @FlgUpdateMCRDesc                --  @FlgUpdateDesc       int        
       -------------------------------------------------------------------------------        
       -- If a product could not be created, then exit with an error        
       -------------------------------------------------------------------------------        
  IF  @OriginalProdId IS NULL        
   BEGIN        
   IF  @ProdID IS NULL        
    BEGIN        
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
    SELECT -170, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Product: ' + @ProdCode + ' on Path:' + Coalesce(Convert(varchar(25), @PathId), 'NoPathId')        
     FROM dbo.email_message_data emd WITH(NOLOCK)       
    WHERE emd.Message_Id = -170        
            
    GOTO ErrCode        
    ----return       (0)        
    END        
   ELSE        
    BEGIN        
    UPDATE  @tMCR        
    SET    ProdId = @ProdId,        
      FlgNewProduct  = 1        
    WHERE   NodeId       = @NodeId        
    END        
   END        
  END        
          
 -------------------------------------------------------------------------------        
 -- Get next MCR to be processed        
 -------------------------------------------------------------------------------        
 SELECT   @Id       = NULL        
 SELECT   @Id       = MIN(Id)        
 FROM     @tMCR        
 WHERE Status = 0        
         
 END        
         
         
         
-------------------------------------------------------------------------------        
-- Task 6         
-- Task 6.01        
-- Create Engineering Units As Needed        
-------------------------------------------------------------------------------        
INSERT  Engineering_Unit (        
       Eng_Unit_Desc,         
       Eng_Unit_Code)        
SELECT  DISTINCT UOM, UOM        
FROM @tMCR       M        
LEFT JOIN Engineering_Unit EU WITH(NOLOCK) ON  M.UOM = EU.Eng_Unit_Code        
WHERE EU.Eng_Unit_Id  IS NULL        
        
        
-------------------------------------------------------------------------------        
-- Task 6.02        
-- Handle UOM conversion        
-------------------------------------------------------------------------------        
/*        
IF (SELECT COUNT(*)         
       FROM       @tMPR        
       WHERE       PathUoM is null)>0        
*/        
IF EXISTS(SELECT * FROM @tMPR WHERE PathUoM IS NULL)        
 BEGIN        
    DELETE FROM @tErrRef        
            
    SELECT @ErrCode = -166        
            
 INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'PathUOM missing for ' + Coalesce(Convert(varchar(25), er.PathId), 'NoPathId') + ' Product ' + mpr.ProdCode        
 FROM @tMPR mpr        
 JOIN    @tER er ON er.ParentId = mpr.ParentId        
 WHERE    mpr.PathUoM IS NULL        
         
 INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)     
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
 END        
         
         
UPDATE @tMPR         
SET    PathUoM = UoM        
WHERE  PathUoM IS NULL        
        
UPDATE  MPR        
SET QTY  =  Convert(Float, MPR.QuantityString) * Coalesce(EUC.Slope, 1) + Coalesce(EUC.intercept, 0)        
FROM  @tMPR MPR         
JOIN  dbo.Engineering_Unit E1    WITH(NOLOCK) ON MPR.UOM  = E1.Eng_Unit_Code        
JOIN  dbo.Engineering_Unit E2    WITH(NOLOCK) ON MPR.PathUOM = E2.Eng_unit_Code        
JOIN  dbo.Engineering_Unit_Conversion EUC WITH(NOLOCK) ON EUC.From_Eng_Unit_Id = E1.Eng_Unit_Id        
               AND EUC.To_Eng_Unit_Id = E2.Eng_Unit_Id        
                 
UPDATE @tMPR        
SET   QTY = QuantityString        
WHERE  QTY Is Null         
        
        
-- Added for MOT        
UPDATE   @tMPR        
SET     DeliveredQTY   = DeliveredQuantityString        
WHERE    DeliveredQTY  IS NULL         
        
                   
IF @DebugFlag = 1        
 SELECT 'Material Produce Req-6.02', * FROM @tMPR        
        
        
        
-------------------------------------------------------------------------------        
--Task 7        
-- Additional Logic for MOT        
-- Get the ERPOrderStatus, Order Existed Detection, Data Change Detection,         
-- Has PO ever Changed to 'Active'          
-------------------------------------------------------------------------------        
        
-------------------------------------------------------------------------------         
-- Task 7.01 Get the ERP Order Status        
-------------------------------------------------------------------------------    
SELECT @ERPOrderStatus = ERPOrderStatus FROM @tPR        
         
IF CHARINDEX(@ERPOrderStatus, @ERPOrderStatus_REL) > 0 OR @ERPOrderStatus IS NULL        
 SELECT @FlgERPOrderStatus = 1        
ELSE IF CHARINDEX(@ERPOrderStatus, @ERPOrderStatus_CTECO) > 0        
 SELECT @FlgERPOrderStatus = 2        
ELSE         
 SELECT @FlgERPOrderStatus = 3        
        
-------------------------------------------------------------------------------         
-- Task 7.02 Verify the PO existed or MOT        
-------------------------------------------------------------------------------        
SELECT @FlgPPExisted = 0        
IF EXISTS(SELECT pp.Process_Order        
   FROM @tPR pr        
   JOIN dbo.Production_Plan pp ON (pp.Process_Order = pr.ProcessOrder)        
   JOIN @tER er ON (er.PathId = pp.Path_Id) )        
 SELECT @FlgPPExisted = 1        
-- Check for Family care, we wont filter by path id since we have to check for Parent/Child paths.
 IF EXISTS( SELECT ds_id FROM dbo.Data_Source with(nolock) WHERE ds_Desc = 'SView'  )
BEGIN    
IF EXISTS(SELECT pp.Process_Order        
   FROM @tPR pr        
   JOIN dbo.Production_Plan pp ON (pp.Process_Order = pr.ProcessOrder)   ) 
   BEGIN
    SELECT @FlgPPExisted = 1  
	END
	END
         
If @DebugFlag = 1        
 SELECT 'Task 7.02',        
   @FlgERPOrderStatus  AS FlgERPOrderStatus,        
   @FlgPPExisted AS FlgPPExisted        
         
-------------------------------------------------------------------------------         
-- Task 7.03 Verify the Data Change ?        
-- Compare Production Plan MPR        
-- Compare Production Setup (nothing to compare)        
-- Compare Production Setup Detail (MaterialLotId)        
-------------------------------------------------------------------------------         
IF @FlgPPExisted = 0        
 BEGIN        
 SELECT @ProcessOrder = pr.ProcessOrder FROM @tPR pr        
                 
 ------------------------------------------------------------------------------        
 -- Check the BOM Product is missing        
 ------------------------------------------------------------------------------        
 DECLARE @FlgBOMMissing int        
        
    SELECT @RowCount = 0        
            
 SELECT @RowCount = COUNT(*)        
 FROM  @tMCR mcr        
 JOIN @tER er ON er.ParentId = mcr.ParentId AND er.mcrNoProduct = 2        
 LEFT JOIN  dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code        
 WHERE mcr.ProdId IS NULL          
   AND p.Prod_Id IS NULL        
        
 SELECT @FlgBOMMissing = 0        
 IF @RowCount > 0         
  SELECT @FlgBOMMissing = 1        
          
 END        
        
        
IF @FlgPPExisted = 1        
 BEGIN        
 SELECT  @PPId = pp.PP_Id,        
   @ProcessOrder = pp.Process_Order        
 FROM @tPR pr        
 JOIN dbo.Production_Plan pp WITH(NOLOCK) ON (pp.Process_Order = pr.ProcessOrder)         
 JOIN @tER er ON (er.PathId = pp.Path_Id)        
        
 DECLARE @tblPPChanges TABLE        
  ( Id    int  IDENTITY,        
   ItemName  varchar(50),        
   OldItemValue varchar(1000),        
   NewItemValue varchar(1000),        
   FlgChanged  int        
  )        
         
 SELECT @ProcessOrder = pp.Process_Order,         
   @OldPPPathCode = prp.Path_Code,         
   @OldPPProdCode = p.Prod_Code,         
   @OldPPPlannedQty = pp.Forecast_Quantity,        
   @OldPPMaterialLotId = pp.User_General_1,         
   @OldPPExpirationDate = pp.User_General_2,        
   @OldPPDeliveredQty = CONVERT(varchar(25), pp.Adjusted_Quantity),        
   @OldPPFormulationDesc = bomf.BOM_Formulation_Desc,         
   @OldPPForecastStartDate = pp.Forecast_Start_Date,         
   @OldPPForecastEndDate = pp.Forecast_End_Date,         
   @OldPPComment = c.Comment        
 FROM dbo.Production_Plan pp     WITH(NOLOCK)        
 JOIN dbo.Products p       WITH(NOLOCK) ON (p.Prod_Id = pp.Prod_Id)        
 JOIN dbo.Prdexec_Paths prp     WITH(NOLOCK) ON (prp.Path_Id = pp.Path_Id)        
 LEFT JOIN dbo.Production_Setup psu   WITH(NOLOCK) ON ( psu.PP_Id = pp.PP_Id)        
 --LEFT JOIN dbo.Production_Setup_Detail psd WITH(NOLOCK) ON (psd.PP_Setup_Id = psu.PP_Setup_Id)        
 JOIN dbo.Bill_Of_Material_Formulation bomf WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = pp.BOM_Formulation_Id)        
 LEFT JOIN Comments c      WITH(NOLOCK) ON (c.Comment_Id = pp.Comment_Id)        
 WHERE pp.PP_Id = @PPId         
          
 SELECT @NewPPComment = pr.Comment,        
 @NewPPFormulationDesc = pr.FormulationDesc + ':' + @ProcessOrder         
 FROM @tPR pr        
         
 SELECT @NewPPPathCode = er.EquipmentId        
 FROM @tER er        
         
 SELECT @NewPPPlannedQty = mpr.Qty,        
   @NewPPProdCode = mpr.ProdCode,        
   @NewPPMaterialLotId = mpr.MaterialLotID        
 FROM @tMPR mpr        
        
 SELECT @NewPPForecastStartDate = sr.EarliestStartTime,        
   @NewPPForecastEndDate = sr.LatestEndTime        
 FROM @tSR sr        
          
 SELECT @NewPPExpirationDate = mprp.ValueString        
 FROM @tMPRP mprp        
 WHERE Id = @MPRPName_EXPIRATIONDATE        
        
 /*UL expiration date set to 0 if 00000000 or 000-00-00*/        
 SET @NewPPExpirationDate = (SELECT REPLACE(@NewPPExpirationDate,'-',''))        
 IF ISNUMERIC(@NewPPExpirationDate) = 1        
 BEGIN        
  IF CONVERT(INT,@NewPPExpirationDate) = 0        
   SET @NewPPExpirationDate = '0'        
 END        
        
        
        
        
         
 SELECT @NewPPDeliveredQty = DeliveredQuantityString        
 FROM @tMPR        
          
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-Path Code', @OldPPPathCode, @NewPPPathCode, 0)         
          
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-Prod Code', @OldPPProdCode, @NewPPProdCode, 0)          
          
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-Planned Qty', CONVERT(varchar(25), @OldPPPlannedQty), CONVERT(varchar(25), @NewPPPlannedQty), 0)          
        
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-Material Lot Id', @OldPPMaterialLotId, @NewPPMaterialLotId, 0)          
        
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
  VALUES ('PP-Expiration Date', @OldPPExpirationDate, @NewPPExpirationDate, 0)          
          
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-DeliveredQty', CONVERT(varchar(25), CONVERT(int, CONVERT(FLOAT, @OldPPDeliveredQty))),         
           CONVERT(varchar(25), CONVERT(int, CONVERT(FLOAT, @NewPPDeliveredQty))) , 0)            
          
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-Formulation Desc', @OldPPFormulationDesc, @NewPPFormulationDesc, 0)          
          
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-ForecastStartDate', @OldPPForecastStartDate, @NewPPForecastStartDate, 0)          
        
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-ForecastEndDate', @OldPPForecastEndDate, @NewPPForecastEndDate, 0)          
        
 --SELECT @OldPPComment AS OldComment, @NewPPComment as NewPPComment        
 INSERT intO @tblPPChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('PP-Comment', @OldPPComment, @NewPPComment, 0)          
          
 UPDATE  @tblPPChanges        
 SET FlgChanged = 1        
 WHERE ( OldItemValue <> NewItemValue         
    OR OldItemValue IS NULL AND NewItemValue IS NOT NULL         
    OR OldItemValue IS NOT NULL AND NewItemValue IS NULL        
   )        
           
         
 SELECT @FlgPPChanged = 0         
         
 IF  (SELECT COUNT(*) FROM @tblPPChanges WHERE FlgChanged = 1) > 0        
  SELECT @FlgPPChanged = 1        
            
 IF @DebugFlag = 1        
  SELECT 'tblPPChanges', * FROM @tblPPChanges         
           
------------------------------------------------------------------------------           
-- Compare Production Plan UDP (MPRP           
------------------------------------------------------------------------------        
 DECLARE @tblPPUDPChanges TABLE        
 ( Id    int  IDENTITY,        
  ItemName  varchar(50),        
  OldItemValue varchar(50),        
  NewItemValue varchar(50),        
  FlgChanged  int        
 )          
 DECLARE  @tbltmpMPRP TABLE (        
     Id    int IDENTITY,        
     ItemName     varchar(100),        
     NewItemValue    varchar(100))         
         
         
 INSERT intO @tblPPUDPChanges(ItemName, OldItemValue, FlgChanged)          
 SELECT tf.Table_Field_Desc, tfv.Value, 0        
 FROM Table_Fields_Values tfv WITH(NOLOCK)        
 JOIN Table_Fields tf   WITH(NOLOCK) ON (tf.Table_Field_Id = tfv.Table_Field_Id)        
 JOIN Tables t     WITH(NOLOCK) ON (t.TableId = tf.TableId)        
 WHERE tfv.KeyId = @PPId and tf.TableId = @PPTableId         
          
        
 INSERT intO @tbltmpMPRP (ItemName, NewItemValue)        
 SELECT Id, ValueString        
 FROM @tMPRP        
        
        
 -- Simulated Changes        
 --INSERT intO @tbltmpMPRP(ItemName, NewItemValue)        
 -- VALUES ('xxx', 'yyy')        
 --UPdate @tbltmpMPRP SET NewItemValue = '25.000' WHERE ItemName = 'DeliveredQty'        
        
        
 MERGE @tblPPUDPChanges AS Target        
 USING (SELECT ItemName, NewItemvalue FROM @tbltmpMPRP) AS Source        
 ON (Target.ItemName = Source.ItemName)        
 WHEN MATCHED THEN        
  UPDATE SET Target.NewItemValue = Source.NewItemValue        
 WHEN NOT MATCHED BY TARGET THEN        
  INSERT(ItemName, NewItemValue)        
  VALUES(Source.ItemName, Source.NewItemValue);         
         
 UPDATE  @tblPPUDPChanges        
 SET FlgChanged = 1        
 WHERE ( OldItemValue <> NewItemValue         
   OR OldItemValue IS NULL         
   AND NewItemValue IS NOT NULL         
   OR OldItemValue IS NOT NULL         
   AND NewItemValue IS NULL        
   )        
        
 SELECT @FlgPPUDPChanged = 0        
 IF  (SELECT COUNT(*) FROM @tblPPUDPChanges WHERE FlgChanged = 1) > 0        
  SELECT @FlgPPUDPChanged = 1        
        
 IF @DebugFlag = 1        
   SELECT 'tblPPUDPChanges', * FROM @tblPPUDPChanges         
           
------------------------------------------------------------------------------        
-- Task 7.04 Compare BOM         
------------------------------------------------------------------------------         
 DECLARE @tblBOMChanges TABLE        
 ( Id    int  IDENTITY,        
  ItemName  varchar(50),        
  OldItemValue varchar(50),        
  NewItemValue varchar(50),        
  FlgChanged  int        
 )         
         
        
 SELECT @OldBOMFormulationDesc = bomf.BOM_Formulation_Desc,        
   @OldBOMStdQty = bomf.Standard_Quantity,        
   @OldBOMEngUnit = eu.Eng_Unit_Desc        
 FROM dbo.Bill_Of_Material_Formulation bomf WITH(NOLOCK)        
 JOIN dbo.Production_Plan pp     WITH(NOLOCK) ON (pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id)        
 JOIN Engineering_Unit eu      WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomf.Eng_Unit_Id)        
 WHERE pp.PP_Id = @PPId        
         
        
    SELECT @NewBOMFormulationDesc =  pr.FormulationDesc + ':' + LTRIM(@ProcessOrder),         
           @NewBOMStdQty =  1,        
           @NewBOMEngUnit = eu.Eng_Unit_Desc        
 FROM    @tPR PR        
 JOIN    dbo.Bill_Of_Material BOM WITH(NOLOCK) ON  pr.FormulationDesc = BOM.Bom_Desc        
 JOIN    @tSR SR          ON SR.ParentId = PR.NodeId        
 JOIN    @tMPR MPR         ON MPR.ParentId = SR.NodeId        
 JOIN dbo.Engineering_Unit EU  WITH(NOLOCK) ON EU.Eng_Unit_Code = mpr.uom        
 WHERE   PR.FormulationId IS NULL        
        
 INSERT intO @tblBOMChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('BOM-Formulation Desc', @OldBOMFormulationDesc, @NewBOMFormulationDesc, 0)        
        
 INSERT intO @tblBOMChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('BOM-Std Qty', @OldBOMFormulationDesc, @NewBOMFormulationDesc, 0)        
        
 INSERT intO @tblBOMChanges(ItemName, OldItemValue, NewItemValue, FlgChanged)        
 VALUES ('BOM-BOM Eng Unit', @OldBOMFormulationDesc, @NewBOMFormulationDesc, 0)        
        
 UPDATE  @tblBOMChanges        
 SET FlgChanged = 1        
 WHERE ( OldItemValue <> NewItemValue         
   OR OldItemValue IS NULL         
   AND NewItemValue IS NOT NULL         
   OR OldItemValue IS NOT NULL        
   AND NewItemValue IS NULL        
   )        
        
        
 SELECT @FlgBOMChanged = 0        
 --IF  (SELECT COUNT(*) FROM @tblBOMChanges WHERE FlgChanged = 1) > 0        
 IF EXISTS(SELECT * FROM @tblBOMChanges WHERE FlgChanged = 1)        
  SELECT @FlgBOMChanged = 1        
        
 IF @DebugFlag = 1        
  SELECT 'tblBOMChanges', * FROM @tblBOMChanges        
          
        
------------------------------------------------------------------------------        
-- Task 7.05 Compare BOM Item (MCR)         
--  No detected changes on Alternates        
--  01/09/2015 BalaMurugan Rajendran Added MaterialOriginGroup Logic for Comparison for calling PE user activity for PO validation.        
------------------------------------------------------------------------------        
 DECLARE @tblBOMItemChangesOld TABLE        
 ( Id    int  IDENTITY,        
  ProdCode  varchar(50),        
  Quantity  varchar(50),        
  EngUnitDesc  varchar(50),        
  EventNumber  varchar(50),        
  PUDesc   varchar(50),        
  MaterialOrigingroup varchar(50)        
 )         
        
 DECLARE @tblBOMItemChangesNew TABLE        
 ( Id    int  IDENTITY,        
  ProdCode  varchar(50),        
  Quantity  varchar(50),        
  EngUnitDesc  varchar(50),        
  EventNumber  varchar(50),        
  PUDesc   varchar(50),        
  MaterialOrigingroup varchar(50)        
 )         
        
 DECLARE @tblBOMItemChanges TABLE 
 ( Id    int  IDENTITY,        
  TableName  varchar(50),        
  ProdCode  varchar(50),        
  Quantity  varchar(50),        
  EngUnitDesc  varchar(50),        
  EventNumber  varchar(50),        
  PUDesc   varchar(50),        
  MaterialOrigingroup varchar(50)        
 )         
        
 INSERT intO @tblBOMItemChangesOld        
 ( ProdCode  ,        
  Quantity  ,        
  EngUnitDesc  ,        
  EventNumber  ,        
  PUDesc,        
  MaterialOrigingroup)        
 SELECT p.Prod_Code,         
   bomfi.Quantity,        
   eu.Eng_Unit_Desc,              
   bomfi.Lot_Desc,        
   pu.PU_Desc,        
   tfv.value        
 FROM dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)        
 JOIN dbo.Bill_Of_Material_Formulation bomf WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)        
 JOIN dbo.Production_Plan pp     WITH(NOLOCK) ON (pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id)        
 JOIN  dbo.Products p     WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id)         
 JOIN  dbo.Engineering_Unit eu   WITH(NOLOCK) ON (eu.Eng_Unit_Id = bomfi.Eng_Unit_Id)        
 LEFT JOIN dbo.Prod_Units pu    WITH(NOLOCK) ON (pu.PU_Id = bomfi.PU_Id)        
 JOIN Table_Fields tf WITH (NOLOCK) ON Table_field_Desc = 'MaterialOriginGroup'        
 JOIN Table_Fields_Values tfv WITH (NOLOCK) ON tf.table_Field_id = tfv.Table_Field_id        
 AND tfv.KeyId = bomfi.BOM_Formulation_Item_Id        
 WHERE pp.PP_Id = @PPId        
         
           
 INSERT intO @tblBOMItemChangesNew        
 ( ProdCode  ,        
  Quantity  ,        
  EngUnitDesc  ,        
  EventNumber  ,        
  PUDesc,        
  MaterialOrigingroup)        
          
 SELECT mcr.ProdCode,        
   CONVERT(FLOAT, mcr.QuantityString),        
   mcr.UOM,        
   mcr.MaterialLotId,        
   pu.PU_Desc,        
   mcr.MaterialOriginGroup        
 FROM  @tMCR mcr        
 LEFT JOIN dbo.Prod_Units pu WITH(NOLOCK) ON (pu.PU_Id = mcr.PUId)        
 WHERE FlgAlternate = 0        
           
 -- Simulated for Changes          
 --Update @tblBOMItemChangesNew SET EventNumber = 'PETest01' where Id=1        
 --Update @tblBOMItemChangesNew SET Quantity = '10.00' where Id=2        
         
 INSERT intO @tblBOMItemChanges        
 ( TableName  ,        
  ProdCode  ,        
  Quantity  ,        
  EngUnitDesc  ,        
  EventNumber  ,        
  PUDesc,        
  MaterialOrigingroup             
 )          
 SELECT MIN(ComparedTable) as ComparedTable, ProdCode, Quantity, EngUnitDesc, EventNumber, PUDesc, MaterialOriginGroup        
 FROM        
 (     
  SELECT 'OldBOMItem' as ComparedTable, a.ProdCode, a.Quantity, a.EngUnitDesc, a.EventNumber, a.PUDesc, a.MaterialOrigingroup        
  FROM @tblBOMItemChangesOld a        
  UNION ALL        
  SELECT 'NewBOMItem' as ComparedTable, b.ProdCode, b.Quantity, b.EngUnitDesc, b.EventNumber, b.PUDesc, b.MaterialOrigingroup        
  FROM @tblBOMItemChangesNew b        
 ) tmp        
 GROUP BY ProdCode, Quantity, EngUnitDesc, EventNumber, PUDesc, MaterialOrigingroup        
 HAVING COUNT(*) = 1        
 ORDER BY ProdCode        
         
         
 DELETE FROM @tblBOMItemChanges WHERE TableName = 'OldBOMItem'        
        
 SELECT @FlgBOMItemChanged = 0        
 IF (SELECT COUNT(*) FROM @tblBOMItemChanges) > 0        
  SELECT @FlgBOMItemChanged = 1        
        
 IF @DebugFlag = 1        
 BEGIN        
   SELECT 'tblBOMItemChangesOld', * FROM @tblBOMItemChangesOld        
   SELECT 'tblBOMItemChangesNew', * FROM @tblBOMItemChangesNew        
   SELECT 'tblBOMItemChanges', * FROM @tblBOMItemChanges        
 END        
        
/*        
 -- used for ALternate Later        
 SELECT bomfi.Prod_Id,         
   p.Prod_Code,         
   bomfi.Quantity,        
   bomfi.Eng_Unit_Id,        
   eu.Eng_Unit_Desc,              
   bomfi.Scrap_Factor,        
   bomfs.Prod_Id,        
p_sub.Prod_Code,        
   bomfs.Eng_Unit_Id,        
   eu_sub.Eng_Unit_Desc,        
   bomfs.Conversion_Factor        
   FROM dbo.Bill_Of_Material_Formulation_Item bomfi        
   JOIN dbo.Bill_Of_Material_Formulation bomf ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)        
   JOIN Production_Plan pp ON (pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id)        
   --JOIN Bill_Of_Material_Product bomp ON (bomp.BOM_Formulation_Id = bomf.BOM_Formulation_Id)        
   JOIN Products p ON (p.Prod_Id = bomfi.Prod_Id)         
   JOIN Engineering_Unit eu ON (eu.Eng_Unit_Id = bomfi.Eng_Unit_Id)        
   LEFT JOIN Bill_Of_Material_Substitution bomfs ON (bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id)        
   LEFT JOIN Products p_sub ON (p_sub.Prod_Id = bomfs.Prod_Id)         
   LEFT JOIN Engineering_Unit eu_sub ON (eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id)        
   WHERE pp.PP_Id = @PPId */        
        
------------------------------------------------------------------------------        
-- Task 7.06 Compare BOM Item Attributes(MCRP)        
------------------------------------------------------------------------------        
 DECLARE @tblBOMItemAttributesChanges TABLE        
 ( Id    int  IDENTITY,        
  ProdCode  varchar(25),        
  ItemName  varchar(50),       
  OldItemValue varchar(50),        
  NewItemValue varchar(50),        
  FlgChanged  int        
 )          
 DECLARE  @tbltmpMCRP TABLE (        
     Id    int IDENTITY,        
     ProdCode  varchar(25),        
     ItemName     varchar(100),        
     NewItemValue    varchar(100))         
        
 INSERT intO @tblBOMItemAttributesChanges        
 ( ProdCode  ,        
  ItemName  ,        
  OldItemValue ,        
  FlgChanged          
 )         
 SELECT p.Prod_Code,         
   tf.Table_Field_Desc,         
   tfv.Value,         
   0        
 FROM  dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK)        
 JOIN  dbo.Bill_Of_Material_Formulation bomf  WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)        
 JOIN  dbo.Production_Plan pp      WITH(NOLOCK) ON (pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id)        
 JOIN  dbo.Products p        WITH(NOLOCK) ON (p.Prod_Id = bomfi.Prod_Id)        
 LEFT JOIN dbo.Table_Fields_Values tfv     WITH(NOLOCK) ON (tfv.KeyId = bomfi.BOM_Formulation_Item_Id)        
 JOIN  dbo.Table_Fields tf       WITH(NOLOCK) ON (tf.Table_Field_Id = tfv.Table_Field_Id)        
 JOIN  dbo.Tables t        WITH(NOLOCK) ON (t.TableId = tf.TableId)           
 WHERE pp.PP_Id = @PPId         
   AND t.TableId = @BOMFormulationItemTableId         
           
        
 INSERT intO @tbltmpMCRP         
 ( ProdCode  ,        
     ItemName     ,        
     NewItemValue    )        
 SELECT mcr.ProdCode,        
   mcrp.Id,        
   mcrp.ValueString         
 FROM @tMCRP mcrp        
 LEFT JOIN @tMCR mcr ON (mcr.NodeId = mcrp.ParentId)        
 WHERE mcr.FlgAlternate = 0        
              
    -- Simulated for Changes        
 -- INSERT @tbltmpMCRP(ProdCode, ItemName, NewItemValue)        
 -- Values('New ProdCode', 'NewItemName', 'yyyy')        
           
        
 -- Disable this feature because it may crash the download if there are 2 same material items in the BOM        
 --MERGE @tblBOMItemAttributesChanges AS Target        
 --USING (SELECT ProdCode, ItemName, NewItemvalue FROM @tbltmpMCRP) AS Source        
 --ON (Target.ProdCode = Source.ProdCode) AND(Target.ItemName = Source.ItemName) AND (Target.Id = Source.Id)        
 --WHEN MATCHED THEN        
 -- UPDATE SET Target.NewItemValue = Source.NewItemValue        
 --WHEN NOT MATCHED BY TARGET THEN        
 -- INSERT(ProdCode, ItemName, NewItemValue)        
 -- VALUES(Source.ProdCode, Source.ItemName, Source.NewItemValue);         
        
 --UPDATE  @tblBOMItemAttributesChanges        
 --SET FlgChanged = 1        
 --WHERE ( OldItemValue <> NewItemValue         
 --  OR OldItemValue IS NULL        
 --  AND NewItemValue IS NOT NULL         
 --  OR OldItemValue IS NOT NULL        
 --  AND NewItemValue IS NULL        
 --  )        
        
 SELECT @FlgBOMItemAttributesChanged = 0        
 --IF  (SELECT COUNT(*) FROM @tblBOMItemAttributesChanges WHERE FlgChanged = 1) > 0        
 IF EXISTS(SELECT * FROM @tblBOMItemAttributesChanges WHERE FlgChanged = 1)        
  SELECT @FlgBOMItemAttributesChanged = 1        
        
 IF @DebugFlag = 1        
 BEGIN        
   SELECT 'tblBOMItemAttributesChanges', * FROM @tblBOMItemAttributesChanges        
   --SELECT 'tbltmpMCRP', * FROM @tbltmpMCRP        
 END         
         
 ------------------------------------------------------------------------------        
 -- 7.07 Compare Any UDP for PP (there is only 1 ANY UDP to represent the server)        
 -- 7.08 Compare Any UDP for MPR (TBD)        
 --  Not necessary to detect such changes        
 ------------------------------------------------------------------------------         
         
 ------------------------------------------------------------------------------         
 -- Task 7.09 Data Change Logic Summary        
 ------------------------------------------------------------------------------         
 SELECT @FlgDataChanged = 0        
 IF @FlgPPChanged = 1 OR @FlgPPUDPChanged = 1 OR @FlgBOMChanged = 1 OR        
  @FlgBOMItemChanged = 1 OR @FlgBOMItemAttributesChanged = 1        
  SELECT @FlgDataChanged = 1        
        
 IF @DebugFlag = 1        
  SELECT @ERPOrderStatus AS ERPOrderStatus,         
    @FlgERPOrderStatus AS FlgERPOrderStatus,        
    @FlgPPChanged AS FlgPPChanged,        
    @FlgPPUDPChanged AS FlgPPUDPChanged,        
    @FlgBOMChanged AS FlgBOMChanged,        
    @FlgBOMItemChanged AS FlgBOMItemChanged,        
    @FlgBOMItemAttributesChanged AS FlgBOMItemAttributesChanged         
        
 ------------------------------------------------------------------------------        
 -- Task 7.10 Retrive the current Status of the Process Order        
 ------------------------------------------------------------------------------        
 SELECT @FlgActiveBefore = 0        
/*        
 IF  (SELECT COUNT(*)        
              FROM       @tER er        
              JOIN       dbo.Production_Plan_Starts pps ON er.PPId = pps.PP_Id) > 0        
*/        
 IF EXISTS( SELECT *         
    FROM @tER er        
    JOIN dbo.Production_Plan_Starts pps WITH(NOLOCK) ON er.PPId = pps.PP_Id)        
         SELECT @FlgActiveBefore = 1        
                 
 ------------------------------------------------------------------------------        
 -- Task 7.11 Check the BOM Product is missing        
 ------------------------------------------------------------------------------        
    SELECT @RowCount = 0        
 SELECT @RowCount = COUNT(*)        
 FROM  @tMCR mcr        
 JOIN  @tER er      ON er.ParentId = mcr.ParentId         
            AND er.mcrNoProduct = 3        
 LEFT  JOIN  dbo.Products p WITH(NOLOCK) ON mcr.ProdCode = p.Prod_Code        
 WHERE mcr.ProdId IS NULL          
   AND p.Prod_Id IS NULL        
           
        
 SELECT @FlgBOMMissing = 0        
 IF @RowCount > 0         
  SELECT @FlgBOMMissing = 1        
        
 END        
        
        
        
------------------------------------------------------------------------------        
--Task 7.12         
-- If the Delivered Qty has been changed, no matter what, it will be changed        
-- 2012-03-28 Since the Delivered Qty is not stored as UDP, this section is changed to be         
-- change of the Production Plan Column        
------------------------------------------------------------------------------        
SELECT @FlgChanged = NULL        
SELECT @FlgChanged = FlgChanged FROM @tblPPChanges WHERE ItemName = 'PP-DeliveredQty'     
        
IF @FlgChanged = 1        
 BEGIN        
 SELECT @DeliveredQty = @NewPPDeliveredQty        
        
 IF ISNUMERIC(@DeliveredQty) = 1        
     UPDATE dbo.Production_Plan        
  SET  Adjusted_Quantity = CONVERT(FLOAT, @DeliveredQty)        
  WHERE PP_Id = @PPId        
          
 IF @DebugFlag = 1        
  SELECT 'Delivered Qty has been updated to ' + @DeliveredQty        
 END        
        
        
------------------------------------------------------------------------------        
-- Task 8 - Get the UseCase and Action as per the state logic table        
------------------------------------------------------------------------------         
SELECT @PPCurrentStatusStr = pps.PP_Status_Desc        
FROM dbo.Production_Plan pp    WITH(NOLOCK)        
JOIN dbo.Production_Plan_Statuses pps WITH(NOLOCK) ON (pps.PP_Status_Id = pp.PP_Status_Id)        
WHERE pp.PP_Id = @PPId        
        
SELECT @UseCaseId = -99           
-- Case 1, 2        
IF  @FlgERPOrderStatus = 1 AND @FlgPPExisted = 0            
 SELECT  @UseCaseId    = UseCaseId,        
   @PPCreateAction   = PPCreateAction,        
   @PPCreateStatusStr  = PPCReateStatusStr,        
   @PPUpdateAction   = PPUpdateAction,        
   @PPUpdateStatusStr  = PPUpdateStatusStr,        
   @FlgAllowDataChange  = FlgAllowDataChange,        
   @FlgAlert    = FlgAlert,        
   @ErrCode    = ErrCode,        
   @FlgLockedData   = FlgLockedData,        
   @FlgUnlockedData  = FlgUnlockedData        
 FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
 WHERE   UseCaseActive = 1        
   AND ERPOrderStatusId = @FlgERPOrderStatus        
   AND FlgMESOrderExisted = @FlgPPExisted         
   AND FlgBOMMissing = @FlgBOMMissing        
             
--Case 4        
IF (  @FlgERPOrderStatus  = 1        
  AND @FlgPPExisted   = 1        
  AND @FlgDataChanged   = 1        
  AND @FlgActiveBefore  = 1        
  AND @PPCurrentStatusStr  = @MESOrderStatus_PENDING)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,        
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
    AND FlgDataChange = @FlgDataChanged        
    AND FlgActiveBefore = @FlgActiveBefore        
    AND PPCurrentStatusStr = @PPCurrentStatusStr        
        
--Case 5, 6        
IF (  @FlgERPOrderStatus  = 1        
  AND @FlgPPExisted   = 1        
  AND @FlgDataChanged   = 1        
  AND @FlgActiveBefore  = 0        
  AND @PPCurrentStatusStr  =  @MESOrderStatus_PENDING)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,        
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
    AND FlgDataChange = @FlgDataChanged         
    AND FlgActiveBefore = @FlgActiveBefore        
    AND PPCurrentStatusStr = @PPCurrentStatusStr        
    AND FlgBOMMissing = @FlgBOMMissing        
        
--Case 8        
IF (  @FlgERPOrderStatus  = 1        
  AND @FlgPPExisted   = 1        
  AND @FlgDataChanged   = 0        
  AND @PPCurrentStatusStr  =  @MESOrderStatus_PENDING)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,        
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
    AND FlgDataChange = @FlgDataChanged         
    AND PPCurrentStatusStr = @PPCurrentStatusStr        
        
--Case 9 - 20        
IF ( @FlgERPOrderStatus  = 1         
  AND @FlgPPExisted   = 1        
  AND @PPCurrentStatusStr  <>  @MESOrderStatus_PENDING)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,        
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
    AND FlgDataChange = @FlgDataChanged         
    AND PPCurrentStatusStr = @PPCurrentStatusStr        
        
--Case 21        
IF (  @FlgERPOrderStatus  = 2        
  AND @FlgPPExisted   = 0)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,        
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
        
--Case 22-35        
IF ( @FlgERPOrderStatus  = 2        
  AND @FlgPPExisted  = 1)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,        
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
    AND FlgDataChange = @FlgDataChanged         
    AND PPCurrentStatusStr = @PPCurrentStatusStr        
        
--Case 36-37        
IF (  @FlgERPOrderStatus  = 3        
  AND @FlgPPExisted   = 1)        
  SELECT  @UseCaseId    = UseCaseId,        
    @PPCreateAction   = PPCreateAction,        
    @PPCreateStatusStr  = PPCReateStatusStr,        
    @PPUpdateAction   = PPUpdateAction,   
    @PPUpdateStatusStr  = PPUpdateStatusStr,        
    @FlgAllowDataChange  = FlgAllowDataChange,        
    @FlgAlert    = FlgAlert,        
    @ErrCode    = ErrCode,        
    @FlgLockedData   = FlgLockedData,        
    @FlgUnlockedData  = FlgUnlockedData        
  FROM dbo.Local_S95OEProductionScheduleDownloadStateLogic        
  WHERE   UseCaseActive = 1        
    AND ERPOrderStatusId = @FlgERPOrderStatus        
    AND FlgMESOrderExisted = @FlgPPExisted        
    AND FlgDataChange = @FlgDataChanged        
        
--Case Unknown        
IF @UseCaseId = -99         
 SELECT  @PPCreateAction   = 0,        
   @PPUpdateAction   = 0,        
   @FlgAllowDataChange  = 0,        
   @FlgAlert    = 1,        
   @ErrCode    = -425,        
   @FlgLockedData   = 0,        
   @FlgUnlockedData  = 0        
            
IF @DebugFlag = 1        
 SELECT @UseCaseId    AS UseCaseId,        
   @FlgERPOrderStatus  AS FlgERPOrderStatus,        
   @FlgPPExisted   AS PPExisted,        
   @FlgDataChanged   AS FlfDataChanged,        
   @FlgActiveBefore  AS FlgActiveBefore,        
   @PPCurrentStatusStr  AS PPCurrentStatusStr,        
   @FlgBOMMissing   AS FlgBOMMissing,        
   @PPCreateAction   AS PPCreateAction,        
   @PPCreateStatusStr  AS PPCReateStatusStr,        
   @PPUpdateAction   AS PPUpdateAction,        
   @PPUpdateStatusStr  AS PPUpdateStatusStr,        
   @FlgAllowDataChange  AS FlgAllowDataChange,        
   @FlgAlert    AS FlgAlert,        
   @ErrCode    AS ErrCode,        
   @FlgLockedData   AS FlgLockedData,        
   @FlgUnlockedData  AS FlgUnlockedData        
        
        
        
        
------------------------------------------------------------------------------        
-- Task 9 Building the ErrCode and Message        
-- We only report the 1st changes in the following priority        
-- tdlPPChanges, tblPPUDPCahnges, tblBOMChanges, tblBOMItmeChanges, tblBOMItemAttributeChanges        
-- Case 1 and 6 do not the errmessage        
-- Case 2, 4, 5 have their errcode        
-- Cases 3 and 7 are inactive        
------------------------------------------------------------------------------         
-- Case 21        
IF @FlgAlert = 1 AND @FlgPPExisted = 0        
 BEGIN        
 -- Retrieve the message from the Email_Message_Data        
 SELECT @ErrMessageSubject = COALESCE(Message_Subject, 'NoMessageSubject'),        
   @ErrMessageText  = COALESCE(Message_Text, 'NoMessageText'),        
   @ErrSeverity  = Severity        
 FROM dbo.Email_Message_Data WITH(NOLOCK)        
 WHERE Message_id = @ErrCode        
        
 -- Error Message to have the Process Order        
 SELECT @ErrMessageText = @ErrMessageText + ';UseCase:' + CONVERT(varchar(25), @UseCaseId) +  ';ERP Status:' + COALESCE(@ERPOrderStatus, 'REL')         
   + ';Attempt to change a Non-Existed Order:' + COALESCE(@ProcessOrder, 'NoPO')        
 END        
         
          
-- Case 9, 11, 13, 15, 17, 19, 20, 24-29, 34-37        
IF @FlgAlert = 1 AND @FlgPPExisted = 1        
 BEGIN         
 -- Retrieve the message from the Email_Message_Data        
 SELECT @ErrMessageSubject = COALESCE(Message_Subject, 'NoMessageSubject'),        
   @ErrMessageText  = COALESCE(Message_Text, 'NoMessageText'),        
   @ErrSeverity  = Severity        
 FROM dbo.Email_Message_Data WITH(NOLOCK)        
 WHERE Message_id = @ErrCode        
        
 -- Error Message to have the Process Order        
 SELECT @ErrMessageText = @ErrMessageText + ';UseCase:' + CONVERT(varchar(25), @UseCaseId) + ';ERP Status:<' + COALESCE(@ERPOrderStatus, 'REL') +         
  '>;Attempt to change Order:' + COALESCE(@ProcessOrder, 'NoPO') + ' with Status <' + COALESCE(@PPCurrentStatusStr, 'NoStatusStr') +'>'        
        
 -- Error Message to alert the status changes        
 IF @PPUpdateAction = 1        
  SELECT @ErrMessageText = @ErrMessageText + ';to status:<' + @PPUpdateStatusStr + '>'        
            
 -- Error Message to add the Changed Item           
 IF  @FlgPPChanged = 1        
  BEGIN        
  SELECT Top 1 @ErrMessageText = @ErrMessageText  + ';Changed PP Item:<' + COALESCE(ItemName, 'NoItemName') + ':' + COALESCE(NewItemValue, 'NoItemValue') + '>'        
  FROM @tblPPChanges        
  WHERE FlgChanged = 1        
          
  GOTO RegisteredChanges         
  END         
           
 IF  @FlgPPUDPChanged = 1        
  BEGIN        
  SELECT Top 1 @ErrMessageText = @ErrMessageText  + ';Changed PPUDP Item:<' + COALESCE(ItemName, 'NoItemName') + ':' + COALESCE(NewItemValue, 'NoItemValue') + '>'        
  FROM @tblPPUDPChanges        
  WHERE FlgChanged = 1         
            
  GOTO RegisteredChanges         
  END          
           
 IF  @FlgBOMChanged = 1        
  BEGIN        
  SELECT TOP 1 @ErrMessageText = @ErrMessageText  + ';Changed BOM:<' + COALESCE(ItemName, 'NoItemName') + ':' + COALESCE(NewItemValue, 'NoItemValue') + '>'        
  FROM @tblBOMChanges        
  WHERE FlgChanged = 1        
          
  GOTO RegisteredChanges         
  END         
           
 IF  @FlgBOMItemChanged = 1        
  BEGIN        
  SELECT TOP 1 @ErrMessageText  = @ErrMessageText  + ';Changed BOM Item:<' +         
           ' Prod:' + COALESCE(@ProdCode, 'NoProdCode') +        
           ' Qty:' + COALESCE(Convert(varchar(25), Quantity), 'NoQty') +        
           ' EU:' + COALESCE(EngUnitDesc, 'NoEU') +         
           ' EN:' + COALESCE(EventNumber, 'NoEN') +        
           ' PU:' + COALESCE(PUDesc, 'NoPU') + '>'        
  FROM @tblBOMItemchanges        
  GOTO RegisteredChanges         
  END         
        
 IF  @FlgBOMItemAttributesChanged = 1        
  BEGIN        
        
  SELECT Top 1 @ErrMessageText  = @ErrMessageText  + ';Changed BOM Item Attr:<' + COALESCE(ItemName, 'NoItemName') + ':' + COALESCE(NewItemValue, 'NoItemValue') + '>'        
   FROM @tblBOMItemAttributesChanges        
   WHERE FlgChanged = 1        
  GOTO RegisteredChanges         
  END         
           
 RegisteredChanges:        
 END        
        
        
        
        
-- Case 8, 10, 12, 14, 16, 18, 22, 23, 30-33        
IF @FlgAlert = 0        
 BEGIN        
 -- Retrieve the message from the Email_Message_Data        
 SELECT @ErrMessageSubject = COALESCE(Message_Subject, 'NoMessageSubject'),        
   @ErrMessageText = COALESCE(Message_Text, 'NoMessageText'),        
   @ErrSeverity = Severity        
   FROM dbo.Email_Message_Data        
   WHERE Message_id = @ErrCode        
        
 -- Error Message to have the Process Order        
 SELECT @ErrMessageText = @ErrMessageText + ';UseCase:' + CONVERT(varchar(25), @UseCaseId) +  ';ERP Status:' + COALESCE(@ERPOrderStatus, 'REL') + ' Attempt to change a Order:' + @ProcessOrder        
        
 IF @PPUpdateAction = 1        
 -- Error Message to have the Process Order        
 SELECT @ErrMessageText = @ErrMessageText + ';UseCase:' + CONVERT(varchar(25), @UseCaseId) + ';ERP Status:<' + COALESCE(@ERPOrderStatus, 'REL') + '>;Attempt to change Order:'         
 + @ProcessOrder + ' with Status <' + @PPCurrentStatusStr +'>' + ';to status:<' + @PPUpdateStatusStr + '>'        
        
 END        
        
        
INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
SELECT @ErrCode, @ErrMessageSubject, @ErrMessageText, @ErrSeverity, NULL        
        
        
IF @DebugFlag = 1        
 BEGIN         
 SELECT @ErrCode AS ErrCode,        
   @ErrMessageSubject AS ErrMessageSubject,        
   @ErrMessageText AS ErrMessageText        
 END        
    
        
IF @PPCreateAction = 0 AND @PPUpdateAction = 0 AND @FlgAllowDataChange = 0        
 BEGIN         
 IF @DebugFlag = 1        
  SELECT 'Skip Processing'        
 GOTO SKIPProcessing        
 END        
        
IF @PPCreateAction = 0 AND @PPUpdateAction = 1 AND @FlgAllowDataChange = 0        
 BEGIN       
 IF @DebugFlag = 1        
  SELECT 'Only Update the PP Status, thats all !!'        
          
 SELECT        
  @ParmPathId      = Path_Id,        
  @ParmCommentId     = Comment_Id,        
  @ParmProdId      = Prod_Id,        
  @ParmImpliedSequence   = Implied_Sequence,        
  @ParmPPStatusId     = PP_Status_Id,        
  @ParmPPTypeId     = PP_Type_Id,        
  @ParmSourcePPId     = Source_PP_Id,        
  @ParmUserId      = User_Id,        
  @ParmParentPPId     = Parent_PP_Id,        
  @ParmControlType    = Control_Type,        
  @ParmForecastStartDate   = Forecast_Start_Date,        
  @ParmForecastEndDate   = Forecast_End_Date,        
  @ParmForecastQuantity   = Forecast_Quantity,        
  @ParmProductionRate    = Production_Rate,        
  @ParmAdjustedQuantity   = Adjusted_Quantity,        
  @ParmBlockNumber    = Block_Number,        
  @ParmProcessOrder    = Process_Order,        
  @ParmBOMFormulationId   = BOM_Formulation_Id,        
  @ParmUserGeneral1    = User_General_1,        
  @ParmUserGeneral2    = User_General_2,        
  @ParmUserGeneral3    = User_General_3        
 FROM dbo.Production_Plan WITH(NOLOCK)        
 WHERE pp_Id = @PPId        
        
 SELECT @PPStatusId = PP_Status_Id        
 FROM dbo.Production_Plan_Statuses WITH(NOLOCK)        
 WHERE PP_Status_Desc = @PPUpdateStatusStr        
        
 SELECT @RC = 0          
 EXECUTE  @RC = spServer_DBMgrUpdProdPlan         
         @PPId                 OUTPUT, -- PPId            
         2,                      -- TransType        
         0,                      -- TransNum        
         @ParmPathId,                 -- PathId                              
         @ParmCommentId,              -- CommentId        
         @ParmProdId,                  -- ProdId        
         @ParmImpliedSequence,          -- Implied Sequence        
         @PPStatusId,              -- Status Id        
         @ParmPPTypeId,                   -- PP Type Id        
         @ParmSourcePPId,              -- Source PP Id        
         @UserId,               -- User Id        
         @ParmParentPPId,              -- Parent PP Id        
         @ParmControlType,             -- Control Type         
         @ParmForecastStartDate,       -- Forecast_Start_Time        
         @ParmForecastEndDate,           -- Forecast_End_Time        
         NULL,                 -- Entry_On        
         @ParmForecastQuantity,          -- Forecast_Quantity         
         @ParmProductionRate,          -- Production_Rate         
         @ParmAdjustedQuantity,          -- Adjusted Quantity         
         @ParmBlockNumber,             -- Block Number,        
         @ParmProcessOrder,             -- Process_Order        
         Null,                        -- Transaction Time               
         Null,                        -- Misc1        
         Null,                        -- Misc2        
         Null,                        -- Misc3        
         Null,                        -- Misc4        
    @ParmBOMFormulationId,     -- BOMFormulationId        
    @ParmUserGeneral1,      -- UsrGen1        
    @ParmUserGeneral2,      -- UsrGen2        
    @ParmUserGeneral3      -- UsrGen3        
        
 IF  @RC  = -100        
  BEGIN        
  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
   SELECT -106, emd.Message_Subject, emd.Message_Text, emd.Severity, 'ProcessOrder: ' + @ProcessOrder        
   FROM dbo.email_message_data emd WITH(NOLOCK)        
   WHERE emd.Message_Id = -106        
  GOTO ErrCode        
          
  END        
         
 SET @FlgSendRSProductionPlan = 1         
 GOTO SKIPProcessing        
         
 END        
        
        
     
        
------------------------------------------------------------------------------        
-- Task 10 BOM Processing        
-- If the provided BOM is not configured in Plant Applications, then make the         
-- BOM Formulation records.        
-------------------------------------------------------------------------------        
SELECT @RowCount = 0        
SELECT @RowCount = COUNT(*)        
FROM @tPR pr        
JOIN @tSR sr ON pr.Id = sr.ParentId        
JOIN @tER er ON er.ParentId = sr.NodeId         
     AND er.NoFormulation = 1         
     AND @FlgIgnoreBOMInfo = 0        
WHERE   pr.BOMId IS NULL        
        
        
IF @RowCount > 0         
 BEGIN        
    DELETE FROM @tErrRef        
            
    SELECT @ErrCode = -120        
            
    INSERT intO @tErrRef (ErrorCode, ReferenceData)        
 SELECT @ErrCode, 'Process Order: ' + pr.ProcessOrder + ' on Path:' + CONVERT(varchar(10),er.PathId)        
 FROM @tPR pr        
 JOIN @tSR sr ON pr.Id = sr.ParentId        
 JOIN @tER er ON er.ParentId = sr.NodeId AND er.NoFormulation = 2 AND @FlgIgnoreBOMInfo = 0        
 WHERE pr.BOMId IS NULL        
         
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
 FROM dbo.email_message_data emd WITH(NOLOCK)        
 JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
 WHERE emd.Message_Id = @ErrCode        
         
  GOTO ErrCode        
       ----return       (0)        
               
 END        
         
         
--IF       @NoFormulation = 1        
--       AND       @FlgIgnoreBOMInfo = 0                
--       AND       (SELECT       COUNT(*)        
--                     FROM      @tPR        
--                     WHERE       BOMId IS NULL) > 0        
--BEGIN        
--       SELECT       TOP 1       @ErrMsg = @ErrMsg + 'No BoM configured: ' + FormulationDesc        
--              FROM       @tPR        
--              WHERE       BOMId IS NULL        
--      INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
--        SELECT -120, emd.Message_Subject, emd.Message_Text, emd.Severity, @ErrMsg        
--          FROM dbo.email_message_data emd         
--          WHERE emd.Message_Id = -120        
--END        
-------------------------------------------------------------------------------        
-- Handle Bill_Of_Material, if site configured to not ignore BOM info on the        
-- XML file        
-- populate BOM        
-- Table Bill_Of_Material, Bill_Of_Material_Formulation         
-- Bill_Of_Material_Formulation_Item        
-------------------------------------------------------------------------------        
--JG: this is a site UDP as are all UDPs in this IF statement (i.e. @MaterialReservationSequence, etc).         
-- Some could be made Path specific...         
        
        
-------------------------------------------------------------------------------        
-- Retrieve the Standard Qty        
-------------------------------------------------------------------------------        
DECLARE @StandardQty Float        
SELECT @StandardQty = Qty        
FROM @tMPR        
        
IF @DebugFlag = 1        
  SELECT 'MPR Standard Qty is ' + convert(varchar(25), @StandardQty)         
        
        
--select @FlgIgnoreBOMInfo, @FlgInclProdInBOMFDesc        
----return        
        
/*6feb2014*/        
-- Bala pulled data into temp table to create # for BOm Material        
        
INSERT @temp (parent, nodeid)        
  SELECT parentid,NodeId         
  FROM @tMCR        
  WHERE Id = id        
 /*6feb2014*/          
        
        
        
        
IF   @FlgIgnoreBOMInfo = 0 AND (@FlgPPExisted = 0 OR @FlgAllowDataChange = 1)        
 BEGIN        
 --SELECT 'populate BOM'        
 -------------------------------------------------------------------------------        
 -- Handle Bill Of Material table        
 -------------------------------------------------------------------------------        
 INSERT  Bill_of_material         
  ( Bom_Desc,         
   Bom_Family_Id)         
 SELECT FormulationDesc,         
   @DefaultBomFamilyId        
 FROM  @tPR        
 WHERE BOMId IS NULL        
/* Bala Code to add Alternate Material quanity to Main Material*/        
INSERT @Alttemp        
(Quantity,Parent,Nodeid,prev)        
SELECT        
QuantityString,mcr.Parentid,Nodeid,Prev FROM @tMCR mcr        
JOIN #tXML xml1 ON xml1.id = mcr.NodeId        
WHERE FlgAlternate = 1    
INSERT @MainmaterialDetails
(OG,Puid,Nodeid,previd)
SELECT MaterialOriginGroup,PUID, a.nodeid,mcr.nodeid FROM @tMCR mcr   
JOIN #tXML xml1 ON xml1.id = mcr.NodeId   
JOIN @Alttemp a ON a.prev = mcr.nodeid
        
      UPDATE mcr        
      SET QuantityString = Convert(VARCHAR,((CONVERT(FLOAT, mcr.QuantityString)) + (CONVERT (FLOAT,alt.Quantity)))) 
      FROM @tMCR mcr        
      JOIN @Alttemp alt ON alt.prev = mcr.nodeid     
	  
		UPDATE mcr        
	    SET  Puid = md.puid,
		MaterialOrigingroup = md.OG
		FROM @tMCR mcr 
		JOIN   @MainmaterialDetails md on md.nodeid = mcr.nodeid
		
		
	
        
    
   -------------------------------------------------------------------------------        
   -- Handle Bill_Of_Material_Formulation        
   -------------------------------------------------------------------------------        
   IF @FlgInclProdInBOMFDesc = 0 -- Existing Functionality        
      BEGIN        
  UPDATE   pr        
  SET  FormulationId  = bmf.BOM_Formulation_Id        
  FROM @tPR pr        
  JOIN    dbo.Bill_Of_Material_Formulation bmf WITH(NOLOCK)         
    ON BMF.BOM_Formulation_Desc = PR.FormulationDesc + ':' + LTRIM(PR.ProcessOrder)        
         
    INSERT   Bill_Of_Material_Formulation               
           (Bom_Id,         
         Standard_Quantity,        
         Bom_Formulation_Desc,         
         Eng_Unit_Id)        
  SELECT  bom.bom_id,         
      1,         
      FormulationDesc + ':' + LTRIM(ProcessOrder),         
      eu.Eng_Unit_Id        
  FROM    @tPR PR        
  JOIN    dbo.Bill_Of_Material BOM  WITH(NOLOCK)         
    ON pr.FormulationDesc = BOM.Bom_Desc        
    JOIN    @tSR SR                 
    ON SR.ParentId = PR.NodeId        
    JOIN    @tMPR MPR                 
    ON MPR.ParentId = SR.NodeId        
    JOIN    dbo.Engineering_Unit EU   WITH(NOLOCK)         
    ON EU.Eng_Unit_Code = mpr.uom        
  WHERE   PR.FormulationId IS NULL        
               
    UPDATE  pr        
    SET       FormulationId       = bmf.BOM_Formulation_Id        
    FROM       @tPR pr        
        JOIN       dbo.Bill_Of_Material_Formulation bmf WITH(NOLOCK)         
     ON BMF.BOM_Formulation_Desc = PR.FormulationDesc + ':' + LTRIM(PR.ProcessOrder)        
     END         
               
  --2012-06-19        
       IF @FlgInclProdInBOMFDesc = 1 -- New Functionality        
       BEGIN        
                    
            SELECT      @cntPR = null,         
      @loopPR = null        
            SELECT      @cntPR = min(id),         
      @loopPR = max(id)         
      FROM @tPR        
                    
            WHILE @cntPR <= @loopPR        
            BEGIN        
                  SELECT      @BOMPO = Null,         
                        @BOMDesc = Null        
                  SELECT      @BOMPO = ProcessOrder,         
                        @BOMDesc = FormulationDesc        
                  FROM @tPR         
                  WHERE       id = @cntPR        
        
                  SELECT      @BOMProdDesc = coalesce(P.PROD_DESC_Local, P.PROD_DESC_Global,MPR.ProdDesc)        
                  FROM @tPR PR         
                        JOIN @tSR  SR on PR.NodeId = SR.ParentId        
                        JOIN @tMPR MPR on SR.NodeId = MPR.ParentId        
                        JOIN dbo.Products P WITH(NOLOCK) on MPR.ProdId = P.Prod_Id        
                  WHERE       PR.Id = @cntPR         
        
                  SELECT      @BOMFormulationDesc = NULL        
                 --2012-07-26           
                 --SELECT @BOMFormulationDesc = @BOMProdDesc --+ '-' + @BOMPO         
                 SELECT @BOMFormulationDesc = @BOMProdDesc + ':' + @BOMPO         
        
                  WHILE LEN(@BOMFormulationDesc) > 50        
                  BEGIN        
                        SELECT      @BOMProdDesc = LEFT(@BOMProdDesc, (LEN(@BOMProdDesc)-1))        
                        --SELECT @BOMFormulationDesc = @BOMProdDesc --+ ':' + @BOMPO         
                        SELECT @BOMFormulationDesc = @BOMProdDesc + ':' + @BOMPO         
                  END           
                          
                  SELECT      @bmfId = bmf.BOM_Formulation_Id        
                  FROM dbo.Bill_Of_Material_Formulation bmf WITH(NOLOCK)         
                  WHERE       BOM_Formulation_Desc like '%' + @BOMFormulationDesc + '%'        
                                                             
                  IF @bmfId is not null -- existing BOM Formulation        
                  BEGIN        
                        UPDATE @tPR set FormulationId = @bmfId where id = @cntPR        
                  END         
                  ELSE -- new BOM Formulation        
             BEGIN        
           
                        INSERT      dbo.Bill_Of_Material_Formulation (        
                        Bom_Id,         
                        Standard_Quantity,         
                        Bom_Formulation_Desc,         
                        Eng_Unit_Id)        
                        SELECT  bom.bom_id,         
                              1,         
                              @BOMFormulationDesc,        
                              eu.Eng_Unit_Id        
                        FROM        @tPR PR             
                              JOIN dbo.Bill_Of_Material BOM WITH(NOLOCK) ON PR.FormulationDesc = BOM.Bom_Desc        
                              JOIN @tSR SR ON SR.ParentId = PR.NodeId        
                              JOIN @tMPR MPR ON MPR.ParentId = SR.NodeId        
                              JOIN dbo.Engineering_Unit EU WITH(NOLOCK) ON  EU.Eng_Unit_Code = mpr.uom        
                        WHERE       PR.Id = @cntPR         
        
                        SELECT      @bmfId = @@identity        
                                
                        UPDATE      @tPR        
                        SET  FormulationId = @bmfId         
                        WHERE id = @cntPR        
                  END --New BOM Formulation        
      SELECT @cntPR= @cntPR + 1        
   END--WHILE @cntPR <= @loopPR        
  END---- New functionality               
        
   -------------------------------------------------------------------------------        
   -- Update mcr with formulationid         
   -------------------------------------------------------------------------------        
   UPDATE  @tMCR        
   SET    FormulationId  = PR.FormulationId        
   FROM    @tMCR MCR        
   JOIN     @tSR SR ON  MCR.ParentId  = SR.NodeId        
   JOIN    @tPR PR ON  SR.ParentId   = PR.NodeId        
           
        
        
 IF @DebugFlag = 1                      
  SELECT 'Task 10-mcr+formulationid', * FROM @tMCR        
                         
 -------------------------------------------------------------------------------        
 -- Handle Bill Of Material Formulation Item        
-- see if formulation item exists by looking for same product id in same place         
 -- on bill (formulation_order)        
 -------------------------------------------------------------------------------        
 --SELECT @MaterialReservationSequence AS MaterialReservationSequence        
         
/*6feb2014*/         
 UPDATE   @tMCR        
 SET    FormulationItemId = BMFI.Bom_Formulation_Item_Id        
 FROM    @tMCR MCR        
 --JOIN    @tMCRP MCRP1 ON  MCRP1.ParentId  = MCR.NodeId AND MCRP1.Id = @MaterialReservationSequence        
 JOIN @temp t             ON t.nodeid = mcr.nodeid        
 JOIN    dbo.Bill_Of_Material_Formulation_Item BMFI WITH(NOLOCK) ON BMFI.Bom_Formulation_Id = MCR.FormulationId        
                  AND BMFI.Bom_Formulation_Order = t.id --CONVERT(int, MCRP1.ValueString)        
                  AND BMFI.Prod_Id = MCR.ProdId        
                      
   IF @DebugFlag = 1        
      SELECT 'Task 10 -tMCR', * FROM @tMCR        
--        SELECT  COUNT(*) AS MCRFOrmItemIdISNULL        
--                    FROM       @tMCR mcr        
--                    JOIN       @tMCRP mcrp1 ON        mcrp1.ParentId        = mcr.NodeId         
--                              AND        mcrp1.Id       = @MaterialReservationSequence        
--                    JOIN       @tMCRP mcrp2 ON        mcrp2.ParentId        = mcr.NodeId         
--                              AND        mcrp2.id       = @ScrapPercent        
--                    JOIN       Engineering_Unit EU ON        EU.eng_unit_code = mcr.uom         
--              WHERE       MCR.FormulationItemId is NULL        
        
 INSERT   dbo.Bill_Of_Material_Formulation_Item         
       (BOM_Formulation_Id,         
       Prod_Id,         
       Bom_Formulation_Order,         
       Scrap_Factor,         
       PU_Id,        
       Quantity,        
       Eng_Unit_Id,        
       Lot_Desc)        
 SELECT  MCR.FormulationId,         
   MCR.ProdId,         
   t.id,        
   --CONVERT(int,mcrp1.VALUEString),         
   CONVERT(FLOAT,mcrp2.VALUEString),         
   MCR.PUId,        
   CONVERT(FLOAT,MCR.quantitystring),         
   EU.Eng_Unit_Id,        
   MCR.MaterialLotId        
 FROM   @tMCR mcr        
 JOIN   @tMCRP mcrp2 ON  mcrp2.ParentId  = mcr.NodeId         
             AND mcrp2.id  = @ScrapPercent        
 JOIN @temp t  on t.nodeid = mcr.nodeid -- Bala Removed the code that fetched the data for MaterialReservationSequence        
               
 JOIN   dbo.Engineering_Unit EU WITH(NOLOCK) ON  EU.eng_unit_code = mcr.uom         
 WHERE MCR.FormulationItemId IS NULL         
        
        
        
        
 /*6Feb2014        
 JOIN   @tMCRP mcrp1 ON  mcrp1.ParentId = mcr.NodeId         
             AND mcrp1.Id = @MaterialReservationSequence        
 JOIN   @tMCRP mcrp2 ON  mcrp2.ParentId  = mcr.NodeId         
             AND mcrp2.id  = @ScrapPercent        
        
 JOIN   dbo.Engineering_Unit EU WITH(NOLOCK) ON  EU.eng_unit_code = mcr.uom         
 WHERE MCR.FormulationItemId IS NULL         
 */        
           
/*6Feb2014*/            
 UPDATE   @tMCR        
 SET   FormulationItemId = BMFI.Bom_Formulation_Item_Id        
 FROM @tMCR MCR        
 --JOIN @tMCRP MCRP1 ON MCRP1.ParentId = MCR.NodeId        
 --      AND MCRP1.Id = @MaterialReservationSequence        
 JOIN @temp t             ON t.nodeid = mcr.nodeid         
 JOIN    dbo.Bill_Of_Material_Formulation_Item BMFI WITH(NOLOCK) ON BMFI.Bom_Formulation_Id = MCR.FormulationId        
                  AND BMFI.Bom_Formulation_Order = t.id --CONVERT(int, MCRP1.ValueString)        
                  AND BMFI.Prod_Id  = MCR.ProdId        
         
                
--       -------------------------------------------------------------------------------        
--       -- get uom for the Bill_Of_Material_Formulation_Item        
--       -------------------------------------------------------------------------------        
--       UPDATE       @tMCR        
--              SET       FormulationUOM              = EU.Eng_Unit_Code        
--              FROM       @tMCR MCR        
--              JOIN       Bill_Of_Material_Formulation_Item BMFI        
--              ON       BMFI.Bom_Formulation_Item_Id = MCR.FormulationItemId        
--              JOIN       Engineering_Unit EU        
--              ON       EU.Eng_Unit_Id              = BMFI.Eng_Unit_Id        
--       -------------------------------------------------------------------------------        
--       -- convert quantity if MCR UOM <> Bill_OF_material_Formulation_Item UOM        
--       -------------------------------------------------------------------------------        
--       UPDATE       MCR        
--              SET       QuantityString  =  Convert(Float, MCR.QuantityString) * Coalesce(EUC.Slope, 1) + Coalesce(EUC.intercept, 0)        
--                     FROM       @tMCR MCR        
--                     JOIN       Engineering_Unit E1        
--  ON       MCR.UOM       = E1.Eng_Unit_Code        
--                     JOIN       Engineering_Unit E2        
--                     ON       MCR.FormulationUOM = E2.Eng_unit_Code        
--                     JOIN       Engineering_Unit_Conversion EUC        
--                     ON       EUC.From_Eng_Unit_Id       = E1.Eng_Unit_Id        
--                     AND       EUC.To_Eng_Unit_Id       = E2.Eng_Unit_Id        
--                     WHERE       Coalesce(MCR.FormulationUOM,'XXX') <> Coalesce(MCR.UOM, 'YYY')        
               
       -------------------------------------------------------------------------------        
       -- if the prod_id and sequence have not changed then check for changes in         
       -- quantity, scrap factor, puid, eng_unit, lot        
       -------------------------------------------------------------------------------        
/*6feb2014        
 UPDATE  BMFI        
 SET  BMFI.Scrap_Factor   = CONVERT(FLOAT, MCRP2.ValueString),        
   BMFI.Quantity    = CONVERT(FLOAT, MCR.QuantityString),        
   BMFI.Eng_Unit_Id    = EU.Eng_Unit_Id,        
   BMFI.Lot_Desc    = MCR.MaterialLotId        
 FROM dbo.Bill_Of_Material_Formulation_Item BMFI WITH(NOLOCK)        
 JOIN    @tMCR MCR  ON MCR.FormulationItemId = BMFI.Bom_Formulation_Item_Id        
 JOIN    @tMCRP MCRP1 ON MCRP1.ParentId = MCR.NodeId        
        AND MCRP1.Id = @MaterialReservationSequence        
 JOIN    @tMCRP MCRP2 ON MCRP2.ParentId = MCR.NodeId         
        AND MCRP2.Id = @ScrapPercent        
 JOIN    dbo.Engineering_Unit eu WITH(NOLOCK) ON EU.Eng_Unit_Code = MCR.UOM        
 WHERE   BMFI.Scrap_Factor <> CONVERT(FLOAT, MCRP2.ValueString)        
   OR BMFI.Quantity    <> CONVERT(FLOAT, MCR.QuantityString)        
   OR BMFI.Eng_Unit_Id <> EU.Eng_Unit_Id        
   OR BMFI.Lot_Desc    <> MCR.MaterialLotId        
*/           
        
 UPDATE  BMFI          
 SET  BMFI.Scrap_Factor = CONVERT(FLOAT, MCRP2.ValueString),          
   BMFI.Quantity  = CONVERT(FLOAT, MCR.QuantityString),          
   BMFI.Eng_Unit_Id = EU.Eng_Unit_Id,          
   BMFI.Lot_Desc  = MCR.MaterialLotId          
 FROM dbo.Bill_Of_Material_Formulation_Item BMFI          
 JOIN       @tMCR MCR    ON  MCR.FormulationItemId = BMFI.Bom_Formulation_Item_Id          
 JOIN       @tMCRP MCRP2    ON MCRP2.ParentId        = MCR.NodeId           
          AND MCRP2.Id              = @ScrapPercent          
 JOIN       dbo.Engineering_Unit eu  ON  EU.Eng_Unit_Code      = MCR.UOM          
 WHERE       BMFI.Scrap_Factor       <> CONVERT(FLOAT, MCRP2.ValueString)          
   OR BMFI.Quantity   <> CONVERT(FLOAT, MCR.QuantityString)          
   OR BMFI.Eng_Unit_Id  <> EU.Eng_Unit_Id          
   OR BMFI.Lot_Desc   <> MCR.MaterialLotId          
        
	
           
   -------------------------------------------------------------------------------        
   -- If the old formulation has items that are not on the current SAP formulation,         
   -- delete them        
   -- Loop through each distinct MCR formulationId         
   -------------------------------------------------------------------------------        
   --        
   -- Mark all MCR records as unprocessed        
   -------------------------------------------------------------------------------        
   UPDATE  @tMCR        
   SET Status = 0        
           
   -------------------------------------------------------------------------------        
   -- Get first MCR to be processed        
   -------------------------------------------------------------------------------        
   SELECT  @Id = NULL        
   SELECT  @Id = MIN(Id)        
   FROM    @tMCR        
   WHERE    FormulationId Is Not Null        
   AND Status = 0        
        
        
           
   -------------------------------------------------------------------------------        
   -- Loop through each MCR        
   -------------------------------------------------------------------------------        
   WHILE      (@Id       Is Not NULL)        
  BEGIN        
    -------------------------------------------------------------------------------        
    -- Retrieve some MPR attributes        
    -------------------------------------------------------------------------------        
    SELECT  @FormulationId  = FormulationId        
    FROM   @tMCR        
    WHERE  Id = @Id        
            
    -------------------------------------------------------------------------------        
    -- Mark this MCR as processed       (use formulationId on the where so it works        
    -- as a select distinct)        
    -------------------------------------------------------------------------------        
    UPDATE  @tMCR        
    SET   Status  = 1        
    WHERE FormulationId = @FormulationId        
        
            
    -------------------------------------------------------------------------------        
    -- delete BMFI formulation items not existent on the MCR items for this formulation id         
    -------------------------------------------------------------------------------        
    DELETE dbo.Bill_Of_Material_Formulation_Item        
    FROM  dbo.Bill_Of_Material_Formulation_Item bmfi WITH(NOLOCK)        
    LEFT JOIN   @tMCR MCR ON BMFI.Bom_Formulation_Id = MCR.formulationid        
        AND BMFI.Bom_Formulation_Item_Id  = MCR.FormulationItemId      
    WHERE BMFI.Bom_Formulation_Id  = @FormulationId        
    AND MCR.FormulationItemId IS NULL        
            
            
    -------------------------------------------------------------------------------        
    -- Get next MCR to be processed        
    -------------------------------------------------------------------------------        
    SELECT  @Id = NULL        
    SELECT  @Id = MIN(Id)        
    FROM @tMCR        
    WHERE FormulationId Is Not Null        
    AND Status = 0        
    END        
            
            
   -------------------------------------------------------------------------------        
   -- get uom for the Bill_Of_Material_Formulation_Item        
   -------------------------------------------------------------------------------        
   UPDATE  @tMCR        
   SET   FormulationUOM  = EU.Eng_Unit_Code        
   FROM   @tMCR MCR        
   JOIN   dbo.Bill_Of_Material_Formulation_Item BMFI WITH(NOLOCK) ON BMFI.Bom_Formulation_Item_Id = MCR.FormulationItemId        
   JOIN   dbo.Engineering_Unit EU WITH(NOLOCK) ON  EU.Eng_Unit_Id  = BMFI.Eng_Unit_Id        
        
   -------------------------------------------------------------------------------     
   -- convert quantity if MCR UOM <> Bill_OF_material_Formulation_Item UOM        
   -------------------------------------------------------------------------------        
 UPDATE   MCR        
 SET       QuantityString  =  CONVERT(FLOAT, MCR.QuantityString) * COALESCE(EUC.Slope, 1) + COALESCE(EUC.intercept, 0)        
 FROM   @tMCR MCR        
 JOIN   dbo.Engineering_Unit E1    WITH(NOLOCK) ON MCR.UOM = E1.Eng_Unit_Code        
 JOIN   dbo.Engineering_Unit E2    WITH(NOLOCK) ON MCR.FormulationUOM = E2.Eng_unit_Code        
 JOIN   dbo.Engineering_Unit_Conversion EUC WITH(NOLOCK) ON EUC.From_Eng_Unit_Id  = E1.Eng_Unit_Id        
                 AND  EUC.To_Eng_Unit_Id = E2.Eng_Unit_Id        
 WHERE  COALESCE(MCR.FormulationUOM,'XXX') <> COALESCE(MCR.UOM, 'YYY')        
         
         
   -------------------------------------------------------------------------------        
   -- Update User Defined Fields for Bill_Of_Material_Formulation        
   -- Create Table Fields for  MCRP.Id        
   -------------------------------------------------------------------------------            
 INSERT Table_Fields        
  ( Ed_Field_Type_Id,        
   Table_Field_Desc,        
   TableId)        
 SELECT  Distinct 1,         
     MCRP.Id,        
     @BOMFITableId  -- new        
 FROM  @tMCR MCR        
 JOIN     @TMCRP MCRP ON  MCRP.ParentId = MCR.NodeId        
 LEFT JOIN   dbo.Table_Fields TF WITH(NOLOCK) ON  MCRP.Id  = TF.Table_Field_Desc        
 WHERE   MCRP.Id IS NOT NULL        
   AND TF.Table_Field_Id IS NULL        
                             
                             
   -------------------------------------------------------------------------------        
   -- Delete user_defined_values previously associated with the formulations        
   -------------------------------------------------------------------------------        
 DELETE   dbo.Table_Fields_Values        
 FROM    dbo.Table_Fields_Values TFV WITH(NOLOCK)        
 JOIN    dbo.Table_Fields TF   WITH(NOLOCK) ON  TF.Table_Field_Id = TFV.Table_Field_Id        
               AND @BOMFITableId = TFV.TableId                             
 JOIN    @tMCRP MCRP         ON MCRP.Id  = TF.Table_Field_Desc        
 JOIN    @tMCR MCR         ON MCRP.ParentId = MCR.NodeId        
               AND MCR.FormulationItemId  = TFV.KeyId         
        
            
   -------------------------------------------------------------------------------        
   -- create table_fields_vales for mcrp         
   -------------------------------------------------------------------------------        
 INSERT  dbo.Table_Fields_Values        
  ( KeyId,         
   TableId,         
   Table_Field_Id,         
   Value)         
 SELECT  MCR.FormulationItemId,         
   @BOMFITableId,                        
   TF.Table_Field_Id,         
   MCRP.ValueString        
 FROM    @tMCR MCR        
 JOIN    @tMCRP MCRP       ON MCR.NodeId = MCRP.ParentId         
 JOIN    dbo.TABLE_Fields TF WITH(NOLOCK) ON  TF.Table_field_desc = MCRP.Id        
 WHERE   MCRP.ValueString IS NOT NULL         
   AND  MCR.FormulationItemId IS NOT NULL        
           
               
--       -------------------------------------------------------------------------------        
--       -- routine that was used when having problems supporting multiple MCRs with same product code        
--       -- Loop through each combination.        
--       -------------------------------------------------------------------------------        
--       DECLARE       TFVCursor INSENSITIVE CURSOR          
--            For (select distinct mcr.formulationItemId, tf.table_field_Id from @tMCR MCR        
--              JOIN       @tMCRP MCRP        
--              ON       MCR.NodeId       = MCRP.ParentId         
--              JOIN       TABLE_Fields TF         
--              ON        TF.Table_field_desc = MCRP.Id      
--              WHERE       MCRP.ValueString IS NOT NULL)        
--                      Order By mcr.formulationItemId, tf.table_field_id For Read Only         
--       OPEN       TFVCursor        
--       FETCH       NEXT FROM TFVCursor intO @FormulationItemId, @TableFieldId        
--       WHILE       @@Fetch_Status = 0        
--       BEGIN        
--              -- Find TF desc to compare with MCRP.Id        
--              SELECT       @ValueString       = Null,        
--                     @TableFieldDesc       = Null        
--               
--              SELECT       @TableFieldDesc       = Table_Field_Desc        
--                     FROM       Table_Fields       
--                     WHERE       Table_Field_Id              = @TableFieldId        
--               
--              -- get first occurence for the combination        
--              SELECT       Top 1 @ValueString              = MCRP.ValueString        
--                     FROM        @tMCRP MCRP        
--                     JOIN       @tMCR  MCR        
--                     ON       MCR.NodeId              = MCRP.ParentId        
--                     WHERE       MCR.FormulationItemId       = @FormulationItemId        
--                     AND       MCRP.Id                     = @TableFieldDesc        
--                     AND       MCRP.ValueString       Is Not Null        
--               
--              IF       @ValueString        Is Not Null        
--                     AND       @FormulationItemId Is Not Null        
--                     AND       LEN(RTRIM(LTRIM(@ValueString)))>0        
--              BEGIN        
--                     IF       (SELECT       Count(*)        
--                                   FROM       Table_Fields_Values        
--                                   WHERE       KeyId              = @FormulationItemId        
--                                   AND       TableId              = @BOMFITableId       -- 28        
--                                   AND       Table_Field_Id       = @TableFieldId) = 0        
--                     BEGIN        
--                            INSERT       Table_Fields_Values        
--                                   (KeyId,         
--                                   TableId,         
--                                   Table_Field_Id,         
--                                   Value)         
--                                   VALUES       (@FormulationItemId,         
--                                      @BOMFITableId, -- 28,         
--                                          @TableFieldId,         
--                                          @ValueString)        
--                     END        
--              END        
--              FETCH       NEXT FROM TFVCursor intO @FormulationItemId, @TableFieldId        
--       END        
--       CLOSE              TFVCursor        
--       DEALLOCATE       TFVCursor        
--        
        
 -------------------------------------------------------------------------------        
 -- MOT - Populate the Alternate for MCR        
 -------------------------------------------------------------------------------        
 Declare  @EquipmentId  varchar(50)        
 --IF (SELECT COUNT(*) FROM @tMCR WHERE FlgAlternate = 1) > 0        
 IF EXISTS(SELECT * FROM @tMCR WHERE FlgAlternate = 1)        
  BEGIN        
        
  DECLARE @tMCRALT TABLE        
    ( Id     int   IDENTITY,        
     AltNodeId   int,        
     AltProdId   int,        
     AltProdCode   varchar(255),        
     AltEngUnitId  int,        
     AltEngDesc   varchar(25),        
     PrimaryNodeId  int,        
     PrimaryProdId  int,        
     PrimaryProdCode  varchar(255),        
     PrimaryEngUnitId int,        
     PrimaryEngDesc  varchar(25),            
     ConversionFactor Float,        
     FormulationId  int,        
     FormulationItemId int,        
     EquipmentId   varchar(50)        
     )        
          
  DELETE bomsi        
  FROM dbo.Bill_Of_Material_Substitution bomsi  WITH(NOLOCK)        
  JOIN dbo.Bill_Of_Material_Formulation_Item bomfi WITH(NOLOCK) ON (bomfi.BOM_Formulation_Item_Id = bomsi.BOM_Formulation_Item_Id)        
  JOIN dbo.Bill_Of_Material_Formulation bomf   WITH(NOLOCK) ON (bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id)        
  JOIN dbo.Production_Plan pp       WITH(NOLOCK) ON (pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id)        
  WHERE pp.PP_Id = @PPId        
        
        
           
  INSERT intO @tMCRALT (AltNodeId, AltProdId, AltProdCode, AltEngDesc, FormulationId, EquipmentId)        
  SELECT  NodeId, ProdId, ProdCode, UOM, FormulationId, EquipmentId        
  FROM @tMCR        
  WHERE FlgAlternate = 1        
          
  --select * from @tMCRALT        
  ----return        
          
  SELECT @LoopCount = MAX(Id) FROM @tMCRALT        
  SELECT @LoopIndex = MIN(Id) FROM @tMCRALT        
        
  WHILE @LoopIndex <= @LoopCount        
   BEGIN        
           
   SELECT @AltNodeId  = NULL,        
     @AltProdId  = NULL,        
     @AltProdCode = NULL,         
     @AltEngDesc  = NULL,         
     @FormulationId = NULL,        
     @EquipmentId = NULL        
           
   SELECT @AltNodeId  = AltNodeId,        
     @AltProdId  = AltProdId,        
     @AltProdCode = AltProdCode,         
     @AltEngDesc  = AltEngDesc,         
     @FormulationId = FormulationId,        
     @EquipmentId = EquipmentId        
   FROM @tMCRALT mcralt        
   WHERE Id = @loopIndex        
        
   UPDATE @tMCRALT        
   SET AltEngUnitId = eu1.Eng_Unit_Id        
   FROM @tMCRALT mcralt        
   JOIN dbo.Engineering_Unit eu1 WITH(NOLOCK) ON (eu1.Eng_Unit_Code = mcralt.AltEngDesc)        
   WHERE mcralt.Id = @LoopIndex        
             
   SELECT @AltEngUnitId =  AltEngUnitId        
   FROM @tMCRALT        
   WHERE Id = @LoopIndex        
        
   SELECT @PrimaryProdCode = mcrp.ValueString        
   FROM @tMCR mcr        
   JOIN @tMCRP mcrp ON (mcrp.ParentId = mcr.NodeId)        
   WHERE mcrp.Id = 'ALTERNATE'        
     AND mcrp.ParentId = @AltNodeId        
        
   --Remove all leading 0 from the prodcode, keep last 8 digits        
   --UL 16-Jun-2014        
   SET @PrimaryProdCode = RIGHT(@PrimaryProdCode,8)        
        
        
   SELECT @PrimaryNodeId = mcr.NodeId,        
     @PrimaryProdId = mcr.ProdId,        
     @PrimaryEngUnitId = eu1.Eng_Unit_Id,        
     @PrimaryEngDesc = mcr.UOM,        
     @FormulationId = mcr.FormulationId,        
     @FormulationItemId = mcr.FormulationItemId        
   FROM @tMCR mcr        
   JOIN dbo.Engineering_Unit eu1 WITH(NOLOCK) ON (eu1.Eng_Unit_Code = mcr.UOM)        
   WHERE mcr.ProdCode = @PrimaryProdCode        
    AND mcr.EquipmentId = @EquipmentId        
        
        
             
   SELECT @ConversionFactor = 1          
   IF @PrimaryEngUnitId <> @AltEngUnitId        
    BEGIN        
    SELECT  @ConversionFactor = NULL         
    SELECT  @ConversionFactor = Slope        
    FROM dbo.Engineering_Unit_Conversion WITH(NOLOCK)        
    WHERE From_Eng_Unit_Id = @AltEngUnitId         
      AND To_Eng_Unit_Id = @PrimaryEngUnitId        
                
    IF @ConversionFactor IS NULL        
     BEGIN        
     SELECT @ErrCode = -430        
        
     SELECT @ErrMessageSubject = NULL,        
       @ErrMessageText = NULL,        
       @ErrSeverity = NULL        
        
     -- Retrieve the message from the Email_Message_Data        
     SELECT @ErrMessageSubject = COALESCE(Message_Subject, 'NoMessageSubject'),        
       @ErrMessageText = COALESCE(Message_Text, 'NoMessageText'),        
       @ErrSeverity = Severity        
     FROM dbo.Email_Message_Data WITH(NOLOCK)        
     WHERE Message_id = @ErrCode        
        
     -- Error Message to have the Process Order        
     SELECT @ErrMessageText = @ErrMessageText + ';ERP Status:' + @ERPOrderStatus + ';Order:' + @ProcessOrder +         
           ';No UOM Conversion for ' + @AltProdCode        
        
     INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
     SELECT @ErrCode, @ErrMessageSubject, @ErrMessageText, @ErrSeverity, NULL        
        
     GOTO ErrCode        
     END        
    END        
            
        
            
        
   UPDATE @tMCRALT        
   SET PrimaryNodeId  = @PrimaryNodeId,        
    PrimaryProdId  = @PrimaryProdId,        
    PrimaryProdCode  = @PrimaryProdCode,        
    PrimaryEngUnitId = @PrimaryEngUnitId,        
    PrimaryEngDesc  = @PrimaryEngDesc,        
    ConversionFactor = @ConversionFactor,        
    FormulationId  = @FormulationId,        
    FormulationItemId = @FormulationItemId        
   WHERE Id = @LoopIndex        
        
        
   IF NOT EXISTS( SELECT BOM_Substitution_Id         
       FROM dbo.Bill_Of_Material_Substitution WITH(NOLOCK)        
       WHERE BOM_Formulation_Item_Id = @FormulationItemId        
         AND Prod_Id = @AltProdId )        
    INSERT intO dbo.Bill_Of_Material_Substitution        
     (BOM_Formulation_Item_Id, Prod_Id, Eng_Unit_Id, Conversion_Factor, BOM_Substitution_Order)        
    SELECT FormulationItemId,        
      AltProdId,        
      AltEngUnitId,        
      COnversionFactor,        
      @LoopIndex        
    FROM @tMCRALT        
    WHERE Id = @LoopIndex             
        
   SELECT @LoopIndex = @LoopIndex + 1        
   END -- Loopindex        
          
  IF @DebugFlag = 1        
   SELECT '10-tMCRALT', * FROM @tMCRALT        
          
  END -- SELECT COUNT(*) FROM @tMCR WHERE FlgAlternate = 1        
           
 END -- IF       @FlgIgnoreBOMInfo = 0          
        
        
-------------------------------------------------------------------------------        
-- Task 11 -         
-- Handle Production_Plan        
-------------------------------------------------------------------------------        
/*---------------------------------------------        
UL V2.0 Added to Replace Cursor by While LOOP        
-----------------------------------------------*/        
/*        
DECLARE       PPXCursor INSENSITIVE CURSOR                
       FOR (SELECT     ER.PPId,         
                     PR.ProcessOrder,         
                     PR.CommentId,         
                     PR.Comment,         
                     ER.PathId,         
                     SR.EarliestStartTime,         
                     SR.LatestEndTime,        
                     ER.NodeId,        
                     SR.NodeId,        
                     ER.PPStatusId,        
                     ER.UserId,        
                     PR.ERPOrderStatus        
                     FROM       @tPR PR        
                     JOIN       @tSR SR        
                     ON       SR.ParentId       = PR.NodeId        
                     JOIN       @tER ER        
                     ON       ER.ParentId       = SR.NodeId)        
                      ORDER       By PR.ProcessOrder For Read Only         
OPEN       PPXCursor        
FETCH  NEXT FROM PPXCursor intO  @PPId, @ProcessOrder, @CommentId, @Comment,  @PathId, @StartTime, @EndTime, @ERNodeId, @SRNodeId,         
                              @CurrentPPStatusId, @UserId, @ERPOrderStatus        
WHILE       @@Fetch_Status = 0        
*/        
        
DECLARE @MyTable2 TABLE (         
 RowId    int IDENTITY,        
 PPId    int,         
    ProcessOrder  varchar(50),         
    CommentId   int,         
    Comment    Nvarchar(4000),         
    PathId    int,         
  EarliestStartTime datetime,         
    LatestEndTime  datetime,        
    ERNodeId   int,        
    SRNodeId   int,        
    PPStatusId   int,        
    UserId    int,        
    ERPOrderStatus  varchar(255)        
 )        
        
SELECT  @Rows = 0,        
  @Row = 0         
          
   --2014-11-21 Bala Added the code to update @tpr commentid to commentid for Existing POs.        
          
  UPDATE @tPR         
  SET Commentid = p.Comment_id,        
  Comment = Comment_Text from dbo.Production_Plan p WITH (NOLOCK)        
  JOIN dbo.Comments c  WITH (NOLOCK)on c.comment_id = p.comment_id        
  JOIN @tpr t ON t.ProcessOrder = p.Process_order        
  WHERE p.Process_order like  t.ProcessOrder        
        
--Insert data in the Looping table        
INSERT intO @MyTable2 (        
 PPId,         
    ProcessOrder,         
    CommentId,         
    Comment,         
    PathId,         
    EarliestStartTime,         
    LatestEndTime,        
    ERNodeId,        
    SRNodeId,        
    PPStatusId,        
    UserId,        
    ERPOrderStatus)        
SELECT     ER.PPId,         
          PR.ProcessOrder,         
          PR.CommentId,         
          PR.Comment,         
          ER.PathId,         
          SR.EarliestStartTime,         
          SR.LatestEndTime,        
          ER.NodeId,        
          SR.NodeId,        
          ER.PPStatusId,        
          ER.UserId,        
          PR.ERPOrderStatus        
FROM   @tPR PR        
JOIN   @tSR SR ON  SR.ParentId  = PR.NodeId        
JOIN   @tER ER ON  ER.ParentId  = SR.NodeId        
ORDER  BY PR.ProcessOrder        
        
-- Get the total number of rows        
SELECT @Rows = @@ROWCOUNT,        
  @Row = 0        
        
        
-- Loop through the rows in the table        
WHILE @Row < @Rows        
 BEGIN        
 SELECT @Row = @Row + 1        
         
         
         
 SELECT @PPId = PPId,         
   @ProcessOrder = ProcessOrder,         
   @CommentId = CommentId,         
   @Comment = Comment,          
   @PathId = PathId,         
   @StartTime = EarliestStartTime,         
   @EndTime = LatestEndTime,     
   @ERNodeId = ERNodeId,         
   @SRNodeId = SRNodeId,         
           @CurrentPPStatusId =PPStatusId,         
           @UserId = UserId,         
           @ERPOrderStatus = ERPOrderStatus        
 FROM @MyTable2        
 WHERE RowId = @Row        
   -------------------------------------------------------------------------------        
   -- Get Product (can not join to tMPR on the cursor definition, because it might         
   -- have multiple MPRs)        
   -- All the MPRs for a given SR are for the same product        
   -------------------------------------------------------------------------------        
   SELECT  @ProdId   = Null,        
          @QTy     = Null        
                  
   SELECT TOP 1 @ProdId = ProdId        
   FROM    @tMPR        
   WHERE    ParentId = @SRNodeId           
                      
   -------------------------------------------------------------------------------        
   -- Add all MPR.Qty (already UOM converted) to get the PP.Forecast_Quantity        
   -- All the MPRs for a given SR are for the same product        
   -------------------------------------------------------------------------------        
 SELECT  @Qty  = Sum(Qty)        
 FROM  @tMPR        
 WHERE  ParentId = @SRNodeId            
                   
   -------------------------------------------------------------------------------        
   -- Figure out the PP Status        
   -------------------------------------------------------------------------------        
   SELECT  @SPPPStatusId  = @PPStatusId        
   -------------------------------------------------------------------------------        
   -- If the UDP for PP Error Status was configured and the PP Status exists, then        
   -- the value for the flag will be 1 and the interface will check if any condition        
   -- to set the PP Status to error happened.        
   -------------------------------------------------------------------------------        
           
 IF  @flgCheckErrorStatus  = 1         
     BEGIN        
      -------------------------------------------------------------------------------        
      -- Task 11.01        
      -- Step1:If there is any new MPR product then set PP status to error        
      -- and --return a warning message.        
 -------------------------------------------------------------------------------        
      /*        
      IF (SELECT COUNT(*)        
          FROM       @tMPR        
          WHERE       ParentId       = @SRNodeId        
          AND       FlgNewProduct       = 1) > 0   */        
  IF EXISTS(SELECT * FROM  @tMPR  WHERE  ParentId = @SRNodeId AND FlgNewProduct = 1)        
       BEGIN        
          SELECT  @SPPPStatusId  = @PPErrorStatusId        
                  
            DELETE FROM @tErrRef        
                    
            SELECT @ErrCode = -171        
                    
            INSERT intO @tErrRef (ErrorCode, ReferenceData)        
   SELECT @ErrCode, 'Product: ' + mpr.ProdCode + ' Process Order: ' + @ProcessOrder        
   FROM    @tMPR mpr        
   WHERE   ParentId  = @SRNodeId        
     AND FlgNewProduct = 1       
       
  
             
            INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
   SELECT @ErrCode, emd.Message_Subject, tfv.Value, emd.Severity, er.ReferenceData        
   FROM dbo.email_message_data emd WITH(NOLOCK)        
   JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
   JOIN Table_Fields_Values tfv WITH (NOLOCK)  ON tfv.keyid = @ErrCode      
   AND tfv.Table_Field_Id = @POComment AND tfv.TableId =  @SubscriptionGRPTableID      -- Bala Fetch value from UDP
   WHERE emd.Message_Id = @ErrCode        
       END        
        ELSE         
   -------------------------------------------------------------------------------        
   -- Task 11.02        
   -- Step 2:If there is any MPR product (will apply to only existing products, since an        
   -- error message will be generated above for the new products) that the interface        
   -- found the PUId (production point for the path) and associated with the product,        
   -- it will set the PP status to error and --return a warning message.        
   -------------------------------------------------------------------------------        
   /*        
              IF       (SELECT       COUNT(*)        
                            FROM       @tMPR        
                            WHERE       ParentId       = @SRNodeId        
                            AND       FlgNewProduct       <> 1  -- doesn't really matter        
                            AND       CreatePUAssoc       = 1        
                            AND       PUId       Is NOT NULL) > 0        
           */        
   IF EXISTS(SELECT * FROM @tMPR WHERE ParentId  = @SRNodeId AND FlgNewProduct <> 1 AND CreatePUAssoc = 1 AND PUId IS NOT NULL)        
            BEGIN        
    SELECT @SPPPStatusId  = @PPErrorStatusId        
            
    DELETE FROM @tErrRef        
            
    SELECT @ErrCode = -175        
            
    INSERT intO @tErrRef (ErrorCode, ReferenceData)               
    SELECT @ErrCode, 'PUId: ' + Coalesce(Convert(varchar(25), mpr.PUId), 'NoPUId') + ' Process Order: ' + @ProcessOrder        
    FROM  @tMPR mpr        
    WHERE ParentId = @SRNodeId        
      AND FlgNewProduct <> 1          
      AND CreatePUAssoc  = 1        
      AND PUId IS NOT NULL        
              
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
    SELECT @ErrCode, emd.Message_Subject, tfv.Value, emd.Severity, er.ReferenceData        
    FROM dbo.email_message_data emd WITH(NOLOCK)        
    JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
      JOIN Table_Fields_Values tfv WITH (NOLOCK)  ON tfv.keyid = @ErrCode      
   AND tfv.Table_Field_Id = @POComment AND tfv.TableId =  @SubscriptionGRPTableID     -- Bala Fetch value from UDP 
    WHERE emd.Message_Id = @ErrCode        
            
              END        
      ELSE        
              -------------------------------------------------------------------------------        
              -- Task 11.03        
              -- Step 3:If there is any MPR product (will apply to only existing products, since an        
              -- error message will be generated above for the new products) that the interface        
              -- found the PathId (bound PO) and associated with the path,        
              -- it will set the PP status to error and --return a warning message.        
              -------------------------------------------------------------------------------        
              /*        
              IF       (SELECT       COUNT(*)        
                            FROM       @tMPR        
                            WHERE       ParentId       = @SRNodeId        
                            AND       FlgNewProduct       <> 1  -- doesn't really matter        
                            AND       CreatePathAssoc       = 1        
                            AND       PathId       Is NOT NULL) > 0        
                    */        
       IF EXISTS(SELECT * FROM @tMPR WHERE ParentId = @SRNodeId AND FlgNewProduct <> 1 AND  CreatePathAssoc = 1 AND PathId Is NOT NULL)        
         BEGIN        
     SELECT @SPPPStatusId = @PPErrorStatusId        
        
     DELETE FROM @tErrRef        
        
     SELECT @ErrCode = -176        
                
     INSERT intO @tErrRef (ErrorCode, ReferenceData)        
     SELECT @ErrCode, 'PathId: ' + Coalesce(Convert(varchar(25), mpr.PathId), 'NoPathId') + ' Process Order: ' + @ProcessOrder        
     FROM       @tMPR mpr        
     WHERE   ParentId  = @SRNodeId        
       AND  FlgNewProduct  <> 1  -- doesn't really matter        
       AND  CreatePathAssoc  = 1        
       AND  PathId   IS NOT NULL        
               
     INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
     SELECT @ErrCode, emd.Message_Subject, tfv.Value, emd.Severity, er.ReferenceData        
     FROM dbo.email_message_data emd WITH(NOLOCK)        
     JOIN @tErrRef er ON er.ErrorCode = @ErrCode        
       JOIN Table_Fields_Values tfv WITH (NOLOCK)  ON tfv.keyid = @ErrCode      
   AND tfv.Table_Field_Id = @POComment AND tfv.TableId =  @SubscriptionGRPTableID     -- Bala Fetch value from UDP  
     WHERE emd.Message_Id = @ErrCode        
             
           END        
       ELSE        
    -------------------------------------------------------------------------------        
    -- Task 11.04        
    -- Step4:If there is any MPR product (will apply to only existing products, since an        
    -- error message will be generated above for the new products) that the interface        
    -- could not find a PUId (production point for the path) to associate the         
    -- product with, then set the PP status to error and --return a warning message.        
    -------------------------------------------------------------------------------        
              /*        
              IF       (SELECT       COUNT(*)        
           FROM       @tMPR        
                            WHERE       ParentId       = @SRNodeId        
                            AND       FlgNewProduct       <> 1  -- doesn't really matter        
                            AND       PUId       Is NULL) > 0        
               */    
             IF EXISTS(SELECT * FROM @tMPR WHERE ParentId = @SRNodeId AND FlgNewProduct <> 1 AND PUId IS NULL)          
      BEGIN        
      SELECT @SPPPStatusId = @PPErrorStatusId        
              
      DELETE FROM @tErrRef        
              
      SELECT @ErrCode = -172        
              
      INSERT intO @tErrRef (ErrorCode, ReferenceData)        
      SELECT @ErrCode, 'ProdCode: ' + mpr.ProdCode + ' Process Order: ' + @ProcessOrder        
      FROM  @tMPR mpr        
      WHERE   ParentId = @SRNodeId        
        AND  FlgNewProduct <> 1  -- doesn't really matter        
        AND  PUId IS NULL            
                                
      INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
      FROM dbo.email_message_data emd WITH(NOLOCK)        
      JOIN @tErrRef er on er.ErrorCode = @ErrCode        
      WHERE emd.Message_Id = @ErrCode        
              
      END        
             ELSE        
               -------------------------------------------------------------------------------        
               -- Task 11.05        
               -- Step5:If there is any MPR product (will apply to only existing products, since an        
               -- error message will be generated above for the new products) that the interface        
               -- could not find a Path (unbound PO) to associate the         
               -- product with, then set the PP status to error and --return a warning message.        
               -------------------------------------------------------------------------------        
               /*        
      IF       (SELECT       COUNT(*)        
      FROM       @tMPR        
      WHERE       ParentId       = @SRNodeId        
      AND       FlgNewProduct       <> 1   -- doesn't really matter        
      AND       PathId       Is NULL) > 0        
     */        
      IF EXISTS(SELECT * FROM @tMPR WHERE ParentId  = @SRNodeId AND FlgNewProduct <> 1 AND PathId IS NULL)        
       BEGIN        
       SELECT  @SPPPStatusId = @PPErrorStatusId        
        
       DELETE FROM @tErrRef        
        
       SELECT @ErrCode = -173        
        
       INSERT intO @tErrRef (ErrorCode, ReferenceData)        
       SELECT @ErrCode, 'ProdCode: ' + mpr.ProdCode + ' Process Order: ' + @ProcessOrder        
       FROM  @tMPR mpr        
       WHERE   ParentId  = @SRNodeId        
         AND FlgNewProduct <> 1   -- doesn't really matter        
         AND PathId IS NULL        
                 
       INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
       SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
       FROM dbo.email_message_data emd WITH(NOLOCK)        
       JOIN @tErrRef er on er.ErrorCode = @ErrCode        
       WHERE emd.Message_Id = @ErrCode        
               
       END        
  /* 2014-11-10 Bala commented out the part where consumed material creation creates the PO in error status */        
              --ELSE        
       -------------------------------------------------------------------------------        
       -- If there is any new MCR product that the interface didn't get a PU id to        
       -- associate with, set the PP status.        
       -------------------------------------------------------------------------------        
       /*        
       IF       (SELECT       COUNT(*)        
             FROM       @tMCR        
             WHERE       ParentId       = @SRNodeId        
             AND       PUId              Is Null        
             AND       FlgNewProduct       = 1) > 0        
         */        
       --  IF EXISTS(SELECT * FROM @tMCR WHERE ParentId = @SRNodeId AND PUId Is Null AND FlgNewProduct  = 1)        
       -- BEGIN        
       --    SELECT  @SPPPStatusId = @PPErrorStatusId        
       -- END        
       --ELSE        
              -------------------------------------------------------------------------------        
              -- If there is any new MCR product (associated or not associated to a PU) and         
              -- the PP is unbound, then set the PP status to error (because the new product         
              -- could not be associated with any path)        
              -------------------------------------------------------------------------------        
                 /*        
                 IF       @PathId       Is Null        
                        AND       (SELECT       COUNT(*)        
                                      FROM       @tMCR        
                               WHERE       ParentId       = @SRNodeId        
                               AND       FlgNewProduct       = 1) > 0        
                          */          
        --IF EXISTS(SELECT * FROM @tMCR WHERE ParentId = @SRNodeId AND FlgNewProduct = 1) AND @PathId IS NULL                                                  
        -- BEGIN        
        --    SELECT @SPPPStatusId = @PPErrorStatusId        
        -- END          
                
               
                      
  END        

---  Bala Get the comment text from WF         
 -- --Bala Added Error Msg to comment so that site knows why the PO went to Error Status.        
          
 -- IF EXISTS ( SELECT ErrorMsg FROM @tErr)        
 -- BEGIN        
        
 -- Update @MyTable2        
 -- SET comment = coalesce(Comment,'') +  CHAR(13) + Errormsg        
 -- FROM @MyTable2 MT        
 -- JOIN @TERR T ON T.Referencedata LIKE '%'+MT.ProcessOrder+'%'        
 -- Where t.ErrorCode  IS NOT NULL        
          
 -- SET @comment = (SELECT Comment FROM @MyTable2)        
          
 -- END        
        
          
 ----Update @tMPRP        
 ----SET ValueString = ''        
 ----FROM @tMPRP tmrp        
 ----JOIN @tMPR mpr ON mpr.NodeId = tmrp.ParentId        
 ----WHERE tmrp.id = 'Origin GroupID'        
 ----and mpr.FlgNewProduct = 1         
          
        
          
 -- -------------------------------------------------------------------------------        
 -- -- Task 11.06 Production Plan Comment        
 -- --  First, make changes to Comments TABLE        
 -- -------------------------------------------------------------------------------        
 --IF  @CommentId IS NOT NULL        
 -- BEGIN        
 -- UPDATE dbo.Comments         
 -- SET  Comment_Text = @Comment,         
 --   Comment      = @Comment         
 -- WHERE   Comment_Id  = @CommentId        
 -- END        
 --ELSE        
 -- BEGIN        
 -- -------------------------------------------------------------------------------        
 -- -- Add Comment WHERE Comment_text = Comment + Process_Order to make it unique        
 -- -------------------------------------------------------------------------------        
 -- IF @Comment IS NOT NULL        
 --  BEGIN        
 --  INSERT dbo.Comments           
 --  ( Comment_Text,         
 --   Comment,         
 --   User_Id,         
 --   CS_Id,         
 --   Modified_On        
 --   )         
 --  VALUES (@Comment+ LTRIM(@ProcessOrder),         
 --    @Comment,         
 --    @UserId,         
 --    3,         
 --    GetDate()        
 --    )        
             
 --  SELECT @CommentId = @@Identity        
        
 --  UPDATE  @tPR         
 --  SET  CommentId = @CommentID         
 --  WHERE ProcessOrder = @ProcessOrder        
           
 --  -------------------------------------------------------------------------------        
 --  -- now UPDATE the unique Comment.  Now It may NOT be unique        
 --  -- I don't know why he does that, since the table does not have any unique         
 --  -- constraint for the commenttext column        
 --  -------------------------------------------------------------------------------        
 --  UPDATE dbo.Comments         
 --  SET Comment_text  = Comment,         
 --   TopOfChain_id = Comment_Id         
 --  WHERE  Comment_Id = @CommentId        
           
 --  END        
 -- END        
              
 -------------------------------------------------------------------------------        
 -- Task 11.07        
 -- Retrieve the BatchId, ExpirationDate and the DeliveredQty        
 -------------------------------------------------------------------------------        
 SELECT @MaterialLotId = mpr.MaterialLotId        
 FROM @tMPR mpr        
 JOIN @tSR sr ON (sr.NodeId = mpr.ParentId)        
          
 SELECT @ExpirationDate = mprp.ValueString        
 FROM @tMPRP mprp        
 JOIN @tMPR mpr ON (mpr.NodeId = mprp.ParentId)        
 JOIN @tSR sr ON (sr.NodeId = mpr.ParentId)        
 WHERE sr.NodeId = @SRNodeId        
   AND mprp.Id = @MPRPName_EXPIRATIONDATE        
         
 /*UL expiration date set to 0 if 00000000 or 000-00-00*/        
 SET @ExpirationDate = (SELECT REPLACE(@ExpirationDate,'-',''))        
 IF ISNUMERIC(@ExpirationDate) = 1        
 BEGIN        
  IF CONVERT(INT,@ExpirationDate) = 0        
   SET @ExpirationDate = '0'        
 END        
         
        
          
 SELECT @DeliveredQty = DeliveredQty        
 FROM @tMPR        
               
 IF @DebugFlag = 1        
  SELECT 'Task 11.07',         
    @SRNodeId     AS SRNodeId,        
    @MPRPName_EXPIRATIONDATE AS ExpirationDateStr,        
    @MaterialLotId    AS MaterialLotId,        
    @ExpirationDate    AS ExpirationDate,        
    @DeliveredQty    As DeliveredQty        
               
   -------------------------------------------------------------------------------        
   -- Task 11.08        
   -- now add / change production plan        
   -------------------------------------------------------------------------------        
 IF   @PPId  IS NULL AND @PPCreateAction = 1        
  BEGIN        
  SELECT  @TransType  = 1,        
@TransNum   = 0         
  END        
           
 IF @PPId IS NOT NULL AND @PPUpdateAction = 1        
  BEGIN        
  SELECT  @TransType  = 2,        
    @TransNum   = 0        
                  
  -- Added for MOT - Do not change the MaterialLotId (BatchId)        
  -- Use the BatchId from the existing production plan        
  SELECT @MaterialLotId = User_General_1        
  FROM dbo.Production_Plan WITH(NOLOCK)        
  WHERE pp_Id = @PPId        
  END        
          
          
  /*         
  1/5/2015 Set Process order status to Error when the resource path is not present for component materials    
  Bala 3/24/2016 Only keep PO in Error status for PE line or else dont execute below script.    
  */        
 IF EXISTS ( SELECT * FROM @tER WHERE FlgRemoveLeadingZeroes = 0)
 BEGIN
		  IF EXISTS ( SELECT * FROM @tMCR WHERE EquipmentId IS NULL)        
				  BEGIN        
				  SELECT @SPPPStatusId = @PPErrorStatusID        
				  SELECT @ErrCode = -401        
				  INSERT intO @tErrRef (ErrorCode, ReferenceData)        
				  (SELECT @ErrCode, 'Product Desc: ' + Coalesce(Convert(varchar(25), MCR.Proddesc), 'Proddesc')          
				  FROM       @tMCR MCR        
				  WHERE MCR.EquipmentId IS NULL)        
             
				  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
				  SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData        
				  FROM dbo.email_message_data emd WITH(NOLOCK)        
				  JOIN @tErrRef er on er.ErrorCode = @ErrCode        
				  WHERE emd.Message_Id = @ErrCode        
			      END        
END
  /*         
  1/5/2015 Set Process order status to Error when the resource path is not present for component materials    
  3/24/2016 Only keep PO in Error status for PE line  
  */        
               
   --SELECT @PPId as PPId, @TransType AS TransType        
        
   -------------------------------------------------------------------------------        
   -- For existing Process orders which new status was not set to 'error' (due        
   -- some MPR/MCR situation), set it to the current status        
   -------------------------------------------------------------------------------        
 IF  @SPPPStatusId  = @PPStatusId        
  BEGIN        
  IF  @PPId  Is Null AND @PPCreateAction = 1        
   SELECT @SPPPStatusId = PP_Status_Id        
   FROM dbo.Production_Plan_Statuses WITH(NOLOCK)        
   WHERE PP_Status_Desc = @PPCreateStatusStr        
        
  IF  @PPId  IS NOT NULL AND @PPUpdateAction = 0        
   SELECT @SPPPStatusId = @CurrentPPStatusId        
        
  IF  @PPId  IS NOT NULL AND @PPUpdateAction = 1        
   SELECT @SPPPStatusId = PP_Status_Id        
   FROM dbo.Production_Plan_Statuses WITH(NOLOCK)        
   WHERE PP_Status_Desc = @PPUpdateStatusStr           
                    
  END        
--      SELECT        
--              @PPId               AS PPId,                           
--              @TransType            AS TransType,        
--              @TransNum            As TransNum,        
--              @PathId            AS PathId,                            
--              @CommentId          AS CommentId,        
--              @ProdId             AS ProdId,        
--            @SPPPStatusId         AS SPPPStatusId,        
--              @UserId            AS USerId,        
--              @StartTime          As StartTime,        
--              @EndTime             AS EndTime,        
--              @Qty                AS Qty,        
--              @ProcessOrder         AS ProcessOrder        
   --SELECT @SPPPStatusId AS SPPPStatusId        
--SELECT '-----',   @ProcessOrder AS PO         
 IF @FlagCreate = 1        
       EXECUTE  @RC = spServer_DBMgrUpdProdPlan         
     @PPId                     OUTPUT, -- PPId                             
     @TransType,                     -- TransType        
     @TransNum,                     -- TransNum        
     @PathId,                         -- PathId                              
     @CommentId,                      -- CommentId        
     @ProdId,                          -- ProdId        
     NULL,                            -- Implied Sequence        
     @SPPPStatusId,                  -- Status Id        
     1,                               -- PP Type Id        
     NULL,                          -- Source PP Id        
     @UserId,                         -- User Id        
     NULL,                          -- Parent PP Id        
     2,                            -- Control Type         
     @StartTime,                 -- Forecast_Start_Time        
     @EndTime,                      -- Forecast_End_Time        
     NULL,                          -- Entry_On        
     @Qty,                            -- Forecast_Quantity         
     0,                            -- Production_Rate         
     @DeliveredQty,                  -- Adjusted Quantity         
     NULL,                            -- Block Number,         
     @ProcessOrder,                  -- Process_Order        
     NULL,                         -- Transaction Time               
     NULL,                         -- Misc1        
     NULL,                            -- Misc2        
     NULL,                            -- Misc3        
     NULL,                            -- Misc4        
     NULL,          -- BOMFormulationId        
     @MaterialLotId,           -- UsrGen1        
     @ExpirationDate,           -- UsrGen2        
     @ERPOrderStatus           -- UsrGen3        
                           
                    
                           
                           
 IF  @RC = -100        
  BEGIN        
       --CLOSE PPXCursor        
       --DEALLOCATE       PPXCursor        
  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
  SELECT -106, emd.Message_Subject, emd.Message_Text, emd.Severity, 'ProcessOrder: ' + @ProcessOrder        
  FROM dbo.email_message_data emd  WITH(NOLOCK)        
  WHERE emd.Message_Id = -106        
             
  GOTO ErrCode        
  ----return       (0)        
          
  END        
               
       -- Added for MOT (has been moved to the resultset)        
      -- UPDATE dbo.Production_Plan        
      --SET User_General_1 = @MaterialLotId,        
      -- User_General_2 = @ExpirationDate,        
      -- User_General_3 = @ERPOrderStatus        
      --WHERE PP_Id = @PPId        
        
 SELECT @FlgSendRSProductionPlan   = 1        
     --INSERT Local_Update_ScheduleView(PPId, ProcessOrder, EntryOn, Processed)        
     --   VALUES (@PPId, @ProcessOrder, GetDate(), 0)        
       -- Update ER with newly created PPId        
    /*           
       IF       (SELECT       Count(*)        
                     FROM       @tER        
                     WHERE       NodeId       = @ERNodeId        
                     AND       PPId       Is Null) > 0        
     */                       
 IF EXISTS(SELECT * FROM @tER WHERE NodeId  = @ERNodeId AND PPId IS NULL)        
  BEGIN        
   UPDATE  @tER        
   SET   PPId = @PPId        
   WHERE NodeId = @ERNodeId        
  END        
       --FETCH   NEXT FROM PPXCursor intO  @PPId, @ProcessOrder, @CommentId, @Comment,  @PathId, @StartTime, @EndTime, @ERNodeId, @SRNodeId,        
       --                              @CurrentPPStatusId, @UserId, @ERPOrderStatus        
END         
--CLOSE              PPXCursor        
--DEALLOCATE       PPXCursor        
        
        
        
        
-------------------------------------------------------------------------------        
-- Task 12        
-- Handle PP fields not supported by resultset        
--        
-- TODO: Incorporate the BOM_Formulation_Id column to the spServer        
-- need to further investifgate         
-------------------------------------------------------------------------------        
IF (SELECT FormulationId FROM @tPR)  IS NOT NULL        
 UPDATE PP         
 SET    BOM_Formulation_Id   = PR.FormulationId        
 FROM   dbo.production_plan PP WITH(NOLOCK)        
 JOIN   @tER ER ON    ER.PPId  = PP.PP_Id        
 JOIN   @tSR SR ON    ER.ParentId  = SR.NodeId        
 JOIN   @tPR PR ON    PR.NodeId    = SR.ParentId        
        
IF (SELECT FormulationId FROM @tER)  IS NOT NULL               
 UPDATE PP         
 SET    BOM_Formulation_Id    = ER.FormulationId        
 FROM   dbo.production_plan PP WITH(NOLOCK)        
 JOIN   @tER ER ON    ER.PPId  = PP.PP_Id        
 JOIN   @tSR SR ON    ER.ParentId  = SR.NodeId        
 JOIN   @tPR PR ON    PR.NodeId    = SR.ParentId        
         
         
          
         
-------------------------------------------------------------------------------        
-- Task 13        
-- Handle PP UDPs        
--        
-- Create Table Fields for  MPRP.Id        
-------------------------------------------------------------------------------        
INSERT Table_Fields (        
       Ed_Field_Type_Id,        
       Table_Field_Desc,        
       TableId  )        
SELECT Distinct 1,         
  MPRP.Id,        
  @PPTableId        
FROM  @tMPR MPR        
JOIN     @tMPRP MPRP ON  MPRP.ParentId  = MPR.NodeId         
LEFT JOIN dbo.Table_Fields TF WITH(NOLOCK) ON MPRP.Id = TF.Table_Field_Desc        
WHERE MPRP.Id IS NOT NULL        
  AND TF.Table_Field_Id IS NULL        
        
        
                      
-------------------------------------------------------------------------------        
-- delete table_fields_values pointing to ppids AND table_fields_ids        
-------------------------------------------------------------------------------        
-- Updated for MOT        
--DELETE       Table_Fields_Values        
--       FROM       Table_Fields_Values TFV        
--       JOIN       Table_Fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id        
--       AND       @PPTableId  = TFV.TableId        
--       JOIN       @tMPRP MPRP ON  MPRP.Id = TF.Table_Field_Desc        
--       JOIN       @tMPR MPR ON ( MPRP.ParentId  = MPR.NodeId  OR MPRP.NodeId = MPR.NodeId)        
--       JOIN       @tER ER ON  MPR.ParentId = ER.ParentId        
--       AND       ER.PPId  = TFV.KeyId        
        
DELETE   dbo.Table_Fields_Values        
FROM       dbo.Table_Fields_Values TFV        
JOIN       dbo.Table_Fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id        
         AND @PPTableId = TFV.TableId        
JOIN       @tMPRP MPRP ON MPRP.Id = TF.Table_Field_Desc        
JOIN       @tMPR MPR ON MPRP.ParentId = MPR.NodeId        
JOIN       @tER ER  ON MPR.ParentId = ER.ParentId        
       AND ER.PPId = TFV.KeyId        
       AND (TF.Table_Field_Desc <> 'EquipmentIdSite')        
       AND (TF.Table_Field_Desc <> 'EquipmentIdStorageZone')        
               
        
-- The functionality below is now handled by the ANy Element on the ProductionRequest        
-- XML element. This logic is to be moved to the Custom Orchestration        
-------------------------------------------------------------------------------        
-- create table_fields_values for mpr associated with a ppid (StorageZone)        
-------------------------------------------------------------------------------        
--DELETE       Table_Fields_Values        
--       FROM       Table_Fields_Values TFV        
--       JOIN       Table_Fields TF        
--       ON       TF.Table_Field_Id       = TFV.Table_Field_Id        
--       AND       @PPTableId              = TFV.TableId        
--       AND       TF.Table_Field_Desc       = 'PS StorageZone'        
--       JOIN       @tER ER        
--       ON       ER.PPId                     = TFV.KeyId        
--INSERT        Table_Fields_Values         
--       (KeyId,         
--       TableId,         
--       Table_Field_Id,         
--       Value)         
--       SELECT        DISTINCT ER.PPId,         
--              @PPTableId,         
--              TF.Table_Field_Id,         
--              L1.EquipmentId        
--              FROM       @tLocation L1        
--              JOIN       @tLocation L2        
--              ON       L1.ParentId       = L2.NodeId        
--              JOIN       @tMPR MPR        
--              ON       MPR.NodeId       = L2.ParentId        
--              JOIN       Table_Fields TF        
--              ON       TF.Table_Field_Desc              = 'PS StorageZone'        
--              JOIN       @tER ER        
--           ON       MPR.ParentId                   = ER.ParentId        
--              WHERE       L1.EquipmentElementLevel       = 'StorageZone'               
--              AND       ER.PPId                            IS Not Null        
        
        
        
-------------------------------------------------------------------------------        
-- create table_fields_values for mprp associated with a ppid        
-------------------------------------------------------------------------------        
IF @FlgPPExisted = 0        
 INSERT  Table_Fields_Values         
     (KeyId,         
        TableId,         
        Table_Field_Id,         
        Value)         
 SELECT  DISTINCT ER.PPId,         
     @PPTableId,         
     TF.Table_Field_Id,         
     MPRP.ValueString        
 FROM       @tMPRP MPRP        
 JOIN       @tMPR MPR ON MPRP.ParentId  = MPR.NodeId        
 JOIN       @tER ER ON MPR.ParentId  = ER.ParentId AND ER.PPId  Is Not Null        
 JOIN       dbo.Table_Fields TF WITH(NOLOCK) ON TF.Table_Field_Desc  = MPRP.Id        
 WHERE  ER.PPId IS NOT NULL        
   
 IF @FlgPPExisted = 1        
  INSERT  Table_Fields_Values         
        (KeyId,         
        TableId,         
        Table_Field_Id,         
        Value)         
 SELECT  DISTINCT ER.PPId,         
     @PPTableId,         
     TF.Table_Field_Id,         
     MPRP.ValueString        
 FROM       @tMPRP MPRP        
 JOIN       @tMPR MPR ON MPRP.ParentId  = MPR.NodeId        
 JOIN       @tER ER ON MPR.ParentId  = ER.ParentId AND ER.PPId  Is Not Null        
 JOIN       dbo.Table_Fields TF WITH(NOLOCK) ON TF.Table_Field_Desc  = MPRP.Id        
 WHERE  ER.PPId IS NOT NULL        
   AND (MPRP.Id <> 'EquipmentIdSite')        
    AND (MPRP.Id <> 'EquipmentIdStorageZone')        
        
-------------------------------------------------------------------------------        
-- Task 14        
-- Handle <Any> UDPs for the PPId        
--        
-- Extract the UDPS from the ProductionRequest XML element        
-------------------------------------------------------------------------------        
INSERT @tAnyUDP (        
       ParentId,     -- PR.Id        
       NodeId,     -- ANY.Id        
       tText,        
       ElementName,        
       UDPElementId)        
SELECT  x0.Id,        
    x1.Id,        
    x4.tText,        
    x3.LocalName,        
    x3.ParentId        
FROM       #tXML x0        
JOIN       #tXML x1    ON  x1.ParentId  = x0.Id        
         AND x0.LocalName  = 'ProductionRequest'        
JOIN       #tXML x2   ON  x2.ParentId = x1.Id                      
         AND x1.LocalName = 'Any'        
         AND x2.LocalName = 'UDP'        
JOIN       #tXML x3  ON  x2.Id = x3.Parentid            
JOIN       #tXML x4  ON  x3.Id = x4.Parentid        
         AND x4.LocalName = '#Text'        
        
              
IF @DebugFlag = 1        
 SELECT 'Task 14.01'               
              
-------------------------------------------------------------------------------        
-- Get PPId and TableId        
-------------------------------------------------------------------------------        
UPDATE AN        
SET  KeyId   = ER.PPId,        
    TableId = @PPTableId        
FROM @tAnyUDP AN        
JOIN @tSR SR  ON SR.ParentId  = AN.ParentId        
JOIN    @tER ER  ON ER.ParentId  = SR.NodeId         
        
              
        
--select '@tAnyUDP', * from @tAnyUDP        
-------------------------------------------------------------------------------        
-- Create Table Fields for the <ANY> elements        
-------------------------------------------------------------------------------        
INSERT  Table_Fields        
       (Ed_Field_Type_Id,        
       Table_Field_Desc)        
SELECT Distinct 1,         
  tText        
FROM  @tAnyUDP AN        
LEFT JOIN   dbo.Table_Fields TF WITH(NOLOCK) ON AN.tText = TF.Table_Field_Desc        
WHERE   AN.ElementName ='NAME'        
  AND AN.tText IS NOT NULL        
  AND TF.Table_Field_Id IS NULL        
          
          
          
          
-------------------------------------------------------------------------------        
-- Task 14.01        
-- create table_fields_values for the <Any> UDP elements for PPId        
-------------------------------------------------------------------------------        
INSERT Table_Fields_Values         
       (KeyId,         
       TableId,         
       Table_Field_Id,         
       Value)         
SELECT  DISTINCT AN.KeyId,        
  AN.TableId,        
  TF.Table_Field_Id,        
  AN.tText        
FROM       @tAnyUDP AN        
JOIN       @tAnyUDP AN1 ON  AN.UDPElementId  = AN1.UDPElementId        
       AND AN1.ElementName  = 'NAME'        
JOIN       dbo.Table_Fields TF   WITH(NOLOCK) ON  AN1.tText = TF.Table_Field_Desc        
LEFT JOIN  dbo.Table_Fields_Values TFV WITH(NOLOCK) ON TFV.KeyId = AN.KeyId         
              AND TFV.TableId  = AN.TableId        
              AND TFV.Table_Field_Id = TF.Table_Field_Id        
WHERE AN.ElementName = 'VALUE'        
  AND TFV.KeyId IS NULL        
          
          
          
-------------------------------------------------------------------------------        
-- UPDATE existing <Any> UDP elements for PPId        
-------------------------------------------------------------------------------        
UPDATE TFV        
SET       TFV.Value = AN1.tText        
FROM       Table_Fields_Values TFV        
JOIN       @tAnyUDP AN ON AN.KeyId = TFV.KeyId        
       AND AN.ElementName = 'Name'        
JOIN dbo.Table_Fields TF WITH(NOLOCK) ON TFV.Table_Field_Id = TF.Table_Field_Id        
            AND TF.Table_Field_Desc = AN.tText        
JOIN @tAnyUDP AN1 ON AN.UDPElementId = AN1.UDPElementId        
       AND AN1.ElementName = 'Value'        
               
               
               
-------------------------------------------------------------------------------        
-- Task 15        
-- Handle Production_Setup        
-------------------------------------------------------------------------------        
/*---------------------------------------------        
UL V2.0 Added to Replace Cursor by While LOOP        
-----------------------------------------------*/        
/*        
DECLARE       PSXCursor INSENSITIVE CURSOR                
       For (SELECT     ER.PPId,         
                     MPR.Qty,        
                     MPR.MaterialLotId,        
                     MPR.PUId,        
                     PP.Path_Id,        
                     MPR.Id,        
                     MPR.UOM        
                     FROM       @tER ER        
                     JOIN       @tMPR MPR        
                     ON       MPR.ParentId       = ER.ParentId        
                     JOIN       Production_Plan PP        
                     ON       ER.PPId           = PP.PP_Id)        
                      ORDER       By ER.PPId For Read Only         
                              
OPEN       PSXCursor        
FETCH       NEXT FROM PSXCursor intO  @PPId, @Qty, @MaterialLotId, @PUId, @PathId, @Id         
*/        
        
DECLARE @MyTable3 TABLE (         
 RowId    int IDENTITY,        
 PPId    int,         
 Qty     FLOAT,        
 MaterialLotId  varchar(100),        
 PUId    int,        
 Path_Id    int,        
 Id     int,        
 UOM     varchar(25)        
 )        
        
SELECT  @Rows = 0,        
  @Row = 0         
        
INSERT @MyTable3 (        
 PPId,         
 Qty,        
 MaterialLotId,        
 PUId,        
 Path_Id,        
 Id,        
 UOM )        
SELECT     ER.PPId,         
          MPR.Qty,        
          MPR.MaterialLotId,        
          MPR.PUId,        
          PP.Path_Id,        
          MPR.Id,        
          MPR.UOM        
FROM @tER ER        
JOIN    @tMPR MPR ON MPR.ParentId = ER.ParentId        
JOIN    dbo.Production_Plan PP WITH(NOLOCK) ON ER.PPId = PP.PP_Id        
ORDER BY ER.PPId        
        
-- Get the total number of rows        
SELECT @Rows = @@ROWCOUNT,        
  @Row = 0        
        
-- Loop through the rows in the table        
WHILE @Row < @Rows        
 BEGIN        
 SELECT @Row = @Row + 1        
         
         
 SELECT @PPId = PPId,         
   @Qty = Qty,         
   @MaterialLotId = MaterialLotId,         
   @PUId = PUId,         
   @PathId = Path_Id,         
   @Id = Id,        
   @UOM = UOM        
 FROM @MyTable3        
 WHERE RowId = @Row        
         
 SELECT  @PPSetupId = Null        
         
 SELECT  @PPSetupId = PP_Setup_Id        
 FROM    dbo.Production_Setup WITH(NOLOCK)        
 WHERE PP_Id = @PPId        
 --AND       Pattern_Code       = @MaterialLotId  -- Removed for MOT        
            
 IF  @PPSetupId IS NULL AND @PPCreateAction = 1        
  BEGIN        
  SELECT  @TransType  = 1,        
    @TransNum   = 0        
  END        
        
 IF  @PPSetupId  IS NOT NULL AND @PPUpdateAction = 1        
  BEGIN        
  SELECT @TransType   = 2,        
        @TransNum    = 0        
  END        
          
 IF @FlagCreate = 1        
  EXECUTE    @RC = SpServer_DBMgrUpdProdSetup        
       @PPSetupId       OUTPUT,     -- SetupID        
       @TransType,                  -- Action        
       @TransNum,                   -- TransNum        
       @UserId,                    -- UserId        
       @PPId,                     -- PPId        
       NULL,                      -- ImpliedSequence        
       @PPStatusId,                  -- PPStatusId        
       NULL,                       -- PatternRepetitions        
       NULL,                       -- CommentId        
       @Qty,                      -- ForecastQuantity        
      NULL,                      -- BaseDimX        
       NULL,                      -- BaseDimY        
       NULL,                      -- BaseDimZ        
       NULL,                      -- BaseDimA        
       NULL,                      -- BaseGeneral1        
       NULL,                      -- BaseGeneral2        
       NULL,                      -- BaseGeneral3        
       NULL,                      -- BaseGeneral4        
       NULL,                      -- Shrinkage        
       NULL,                 -- PatternCode        
       @PathID,                    -- PathId        
       NULL,                      -- EntryOn        
       NULL,                         -- TransactionTime        
       NULL                         -- ParentPPSetupId        
              
                      
 IF @RC = -100        
     BEGIN        
              --CLOSE              PSXCursor        
              --DEALLOCATE       PSXCursor        
  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
  SELECT -107, emd.Message_Subject, emd.Message_Text, emd.Severity, 'PPSetupId: '+ @PPSetupId + ' @PPId: ' + @PPId        
  FROM dbo.email_message_data emd WITH(NOLOCK)        
  WHERE emd.Message_Id = -107        
          
  GOTo ErrCode        
  ----return       (0)        
     END        
             
 SELECT @FlgSendRSProductionSetup = 1        
         
 -------------------------------------------------------------------------------        
 -- Update MPR with the PPSetupId        
 -------------------------------------------------------------------------------        
 UPDATE @tMPR        
 SET  PPSetupId = @PPSetupId        
 WHERE   Id = @Id        
         
         
 -------------------------------------------------------------------------------        
 -- Handle UDPs for PPSetupId        
 -------------------------------------------------------------------------------        
 /*        
 IF       (SELECT       COUNT(Table_Field_Id)        
              FROM       Table_Fields        
              WHERE       Table_Field_Id       = @PSOriginalEngUnitCodeUDP) > 0        
   */        
 IF EXISTS(SELECT Table_Field_Id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Id = @PSOriginalEngUnitCodeUDP )        
  BEGIN        
  -------------------------------------------------------------------------------        
  -- Store the original UOM for this PPSetup (Batch)        
  -------------------------------------------------------------------------------        
  /*        
  IF       (SELECT       COUNT(KeyId)        
             FROM       Table_Fields_Values        
             WHERE       KeyId               = @PPSetupId        
             AND       Table_Field_Id       = @PSOriginalEngUnitCodeUDP        
             AND       TableId              = @PSTableId) > 0        
  */        
       IF EXISTS( SELECT Keyid         
          FROM dbo.Table_Fields_Values WITH(NOLOCK)         
          WHERE KeyId = @PPSetupId AND Table_Field_Id = @PSOriginalEngUnitCodeUDP AND TableId = @PSTableId)        
   BEGIN        
   UPDATE dbo.Table_Fields_Values        
   SET  Value  = @UOM        
   WHERE   KeyId = @PPSetupId        
     AND Table_Field_Id = @PSOriginalEngUnitCodeUDP        
     AND TableId  = @PSTableId        
   END        
  ELSE        
   BEGIN        
    INSERT Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)        
         VALUES (@PPSetupId, @PSOriginalEngUnitCodeUDP, @PSTableId, @UOM)        
   END        
  END        
               
    -------------------------------------------------------------------------------               
       -- Populate the Production_Setup_Detail - BatchId        
       -- MaterialLotId (BatchId) is populated to User_General_1 Instead        
      -------------------------------------------------------------------------------           
      -- DECLARE @PPsetupDetailId  int        
            
      -- SELECT  @PPSetupDetailId       = Null        
      -- SELECT  @PPSetupDetailId       = PP_SetUp_Detail_Id        
      --        FROM  dbo.Production_Setup_Detail        
      --        WHERE  PP_Setup_Id   = @PPSetUpId        
      --        --AND User_General_1 = @MaterialLotId -- no need to match because it may be an update        
                           
      -- IF   @PPSetupDetailId IS NULL        
      --INSERT  dbo.Production_Setup_Detail   (        
      --Comment_Id,         
      --Element_Number,         
      --Element_Status,         
      --Extended_info,        
      --Order_Line_Id,         
      --PP_Setup_Id,         
      --Prod_Id,        
      --Target_Dimension_X,        
      --Target_Dimension_Y,         
      --Target_Dimension_Z,         
      --Target_Dimension_A,         
      --User_General_1,        
      --User_General_2,         
      --User_General_3,         
      --User_Id)        
      --SELECT  NULL,         
      --  0,         
      --  @PPStatusId,        
      --  NULL,         
      --  NULL,          
      --  @PPSetUpId,         
      --  @ProdId,          
      --  NULL,         
      --  NULL,          
      --  NULL,          
      --  NULL,        
      --  @MaterialLotId,         
      --  NULL,          
      --  NULL,         
      --  @UserId        
                
  -- Do not Update the BatchNumber        
     --   IF   @PPSetupDetailId IS NOT NULL              
     --UPDATE dbo.Production_Setup_Detail        
     -- SET User_General_1 = @MaterialLotId        
     -- WHERE PP_Setup_Detail_Id = @PPsetupDetailId            
               
       --FETCH       NEXT FROM PSXCursor intO  @PPId, @Qty, @MaterialLotId, @PUId, @PathId, @Id, @UOM        
END        
--CLOSE              PSXCursor        
--DEALLOCATE       PSXCursor        
-------------------------------------------------------------------------------        
-- Task 16        
-- Handle <Any> UDPs for the PPId        
--        
-- Extract the UDPS from the ProductionRequest-MPR XML element        
-------------------------------------------------------------------------------        
INSERT        @tAnyMPRUDP (        
       ParentId,     -- PR.Id        
       NodeId,     -- ANY.Id        
       tText,        
       ElementName,        
       UDPElementId)        
SELECT  x0.Id,        
      x1.Id,        
      x4.tText,        
      x3.LocalName,        
      x3.ParentId        
FROM       #tXML x0        
JOIN       #tXML x1 ON  x1.ParentId = x0.Id        
      AND  x0.LocalName = 'MaterialProducedRequirement'        
JOIN       #tXML x2 ON  x2.ParentId = x1.Id         
      AND x1.LocalName = 'Any'        
      AND x2.LocalName = 'UDP'        
JOIN       #tXML x3 ON  x2.Id = x3.Parentid       
JOIN       #tXML x4 ON  x3.Id = x4.Parentid        
      AND x4.LocalName = '#Text'        
              
              
-------------------------------------------------------------------------------        
-- Get PSId and TableId        
-------------------------------------------------------------------------------        
UPDATE  AN        
SET  KeyId    = MPR.PPSetupId,        
    TableId    = @PSTableId        
FROM  @tAnyMPRUDP AN        
JOIN  @tMPR MPR ON  MPR.NodeId  = AN.ParentId        
        
               
               
-------------------------------------------------------------------------------        
-- Create Table Fields for the <ANY> elements for MPR         
-------------------------------------------------------------------------------        
INSERT  dbo.Table_Fields        
       (Ed_Field_Type_Id,        
       Table_Field_Desc)        
SELECT  Distinct 1,         
     tText        
FROM       @tAnyMPRUDP AN        
LEFT JOIN  dbo.Table_Fields TF WITH(NOLOCK) ON  AN.tText = TF.Table_Field_Desc        
WHERE   AN.ElementName  ='NAME'        
  AND AN.tText IS NOT Null        
  AND TF.Table_Field_Id IS NULL        
          
            
          
-------------------------------------------------------------------------------        
-- create table_fields_values for the <Any> UDP elements for MPR        
-------------------------------------------------------------------------------        
INSERT  dbo.Table_Fields_Values         
       (KeyId,         
       TableId,         
       Table_Field_Id,         
Value)         
SELECT  DISTINCT AN.KeyId,        
  AN.TableId,        
  TF.Table_Field_Id,        
  AN.tText        
FROM       @tAnyMPRUDP AN        
JOIN       @tAnyMPRUDP AN1 ON AN.UDPElementId  = AN1.UDPElementId        
        AND AN1.ElementName = 'NAME'        
JOIN       dbo.Table_Fields TF   WITH(NOLOCK) ON AN1.tText = TF.Table_Field_Desc        
LEFT JOIN  dbo.Table_Fields_Values TFV WITH(NOLOCK) ON TFV.KeyId = AN.KeyId        
              AND TFV.TableId = AN.TableId        
              AND TFV.Table_Field_Id = TF.Table_Field_Id        
WHERE AN.ElementName  = 'VALUE'        
  AND TFV.KeyId IS NULL        
          
          
-------------------------------------------------------------------------------        
-- UPDATE existing <Any> UDP elements for MPR        
-------------------------------------------------------------------------------        
UPDATE   TFV        
SET       TFV.Value = AN1.tText        
FROM       dbo.Table_Fields_Values TFV WITH(NOLOCK)        
JOIN       @tAnyMPRUDP AN    ON AN.KeyId = TFV.KeyId        
           AND AN.ElementName = 'Name'        
JOIN dbo.Table_Fields TF WITH(NOLOCK) ON TFV.Table_Field_Id = TF.Table_Field_Id        
           AND TF.Table_Field_Desc = AN.tText        
JOIN @tAnyMPRUDP AN1     ON AN.UDPElementId = AN1.UDPElementId        
           AND AN1.ElementName  = 'Value'        
                   
                   
        
-------------------------------------------------------------------------------        
-- Task 17        
-- Handle <Any> SPs        
--        
-- Extract the <Any> Sps from the entire XML document        
-------------------------------------------------------------------------------        
INSERT @tAnySP (        
       ParentId,        
       ElementName,        
       NodeId,                                    
       tText,        
       Status)        
SELECT  x2.ParentId,         
    x2.LocalName,         
    x3.id,         
    x3.tText,        
    0        
FROM       #tXML x0        
JOIN       #tXML x1 ON x1.ParentId = x0.Id        
      AND x0.LocalName = 'Any'        
      AND x1.LocalName = 'SP'        
JOIN       #tXML x2 ON  x2.ParentId = x1.Id        
JOIN       #tXML x3 ON  x3.ParentId = X2.Id        
      AND x3.LocalName = '#Text'           
        
                         
-------------------------------------------------------------------------------        
-- Find first Stored Procedure name        
-------------------------------------------------------------------------------        
SELECT  @RecSPId  = NULL        
        
SELECT       @RecSPId              = MIN(Id)        
FROM    @tAnySP        
WHERE   ElementName = 'Name'        
  AND Status  = 0        
          
          
-------------------------------------------------------------------------------        
-- Loop through the tAnySP table for all SP elements (elementName=Name)        
-------------------------------------------------------------------------------        
WHILE   (@RecSPId Is NOT NULL)        
 BEGIN        
 -------------------------------------------------------------------------------        
 -- Retrieve ELementId for this SP        
 -------------------------------------------------------------------------------        
 SELECT  @ParentId    = ParentId,        
   @SQLStatement   = tText    
 FROM    @tAnySP        
 WHERE   Id = @RecSPId        
         
         
 -------------------------------------------------------------------------------        
 -- Mark SP as 'processed'        
 -------------------------------------------------------------------------------        
 UPDATE   @tAnySP        
 SET    Status = 1        
 WHERE   Id = @RecSPId        
         
         
 -------------------------------------------------------------------------------        
 -- Check if SP exists        
 -------------------------------------------------------------------------------        
 /*        
 IF       (SELECT   COUNT(Id)        
    FROM    SysObjects        
    WHERE   xType='P'        
    AND    name = @SQLStatement) = 0        
 */        
 IF NOT EXISTS(SELECT Id FROM SysObjects WHERE xType='P' AND name = @SQLStatement)        
  BEGIN        
  INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
  SELECT -999, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
  FROM dbo.email_message_data emd WITH(NOLOCK)        
  WHERE emd.Message_Id = -999        
  END        
          
 ELSE        
  BEGIN        
  -------------------------------------------------------------------------------        
  -- Search first parameter for this SP        
  -------------------------------------------------------------------------------        
  SELECT       @SQLStatement       = 'EXEC ' + @SQLStatement        
          
  SELECT       @RecParmId       = NULL        
          
  SELECT   @RecParmId = MIN(Id)        
  FROM     @tAnySP        
  WHERE   ParentId  = @ParentId        
    AND ElementName = 'Parm'        
    AND Status = 0        
           
            
  -------------------------------------------------------------------------------        
  -- Loop through all other parameters for this SP        
  -------------------------------------------------------------------------------        
  WHILE (@RecParmId IS NOT NULL)        
   BEGIN        
   -------------------------------------------------------------------------------        
   -- Build SQL Statement and mark the parameter record as processed        
   -------------------------------------------------------------------------------        
   SELECT   @SPOutputValue = NULL        
   SELECT   @SQLStatement  = @SQLStatement + ' ' +tText + ','        
   FROM     @tAnySP        
   WHERE  Id  = @RecParmId             
   UPDATE   @tAnySP        
   SET     Status = 1        
   WHERE    Id = @RecParmId        
           
   -------------------------------------------------------------------------------        
   -- Move to the next parameter        
   -------------------------------------------------------------------------------        
   SELECT   @RecParmId = NULL        
           
   SELECT   @RecParmId = MIN(Id)        
   FROM     @tAnySP        
   WHERE   ParentId  = @ParentId        
     AND ElementName = 'Parm'        
     AND Status = 0        
           END        
                   
  -------------------------------------------------------------------------------        
  -- Remove the last extra comma, if exists and then run the sql statement        
  --        
  -- The only way to get the exec to run with SPs with parameter was to encapsulate        
  -- the sqlstatement between (). But I can not get the SP status to be set to a               
  -- variable. ex: EXEC @RC=@SQLStatement, it only works without parameters        
  --        
  -------------------------------------------------------------------------------        
  --IF       CHARINDEX(',', @SQLStatement) > 0        
  --       SELECT       @SQLStatement       = LEFT(@SQLStatement,LEN(@SqlStatement) - 1)        
  --EXEC  (@SQLStatement)        
  -------------------------------------------------------------------------------        
  -- Replaced exc with sp_executeSQL because it is more efficient and allows to        
  -- capture the ouput parameter of the SP.        
  --         
-- Please note the called SP must have an output parameter with datatype int        
  -- as the LAST parameter on the SP definition.       This output parameter can be        
  -- set to null on the called SP, if un-necessary.  ALso, the output from the        
  -- called SP is appended to the errCode string (as a warning error). MOre info        
  -- MS KB Article Id #262499. Example of a called SP:        
  -- CREATE PROCEDURE dbo.spS95OE_Test6        
  --       @Parm1 varchar(255) = NULL,        
  --       ..        
  --       @outputvalue int output        
  --         
  -------------------------------------------------------------------------------        
  SELECT       @SQLStatement    = @SQLStatement + N' @OutputValue OUTPUT'        
  SELECT       @ParmDefinition  = N'@OutputValue int OUTPUT'        
          
  EXECUTE @SQLRetStat = sp_executeSQL        
    @SQLStatement,        
    @ParmDefinition,        
    @SPOutputValue       OUTPUT        
            
  -------------------------------------------------------------------------------        
  -- output a hardcoded error code if the called custom stored procedure --returns        
  -- an error. Please be aware the --return code is different than when --returning        
  -- a value within the sp.        
  -------------------------------------------------------------------------------        
  IF @SQLRetStat <> 0        
   BEGIN        
   INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
   SELECT -998, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL        
   FROM dbo.email_message_data emd WITH(NOLOCK)        
   WHERE emd.Message_Id = -998        
   END        
  ELSE        
   BEGIN        
   IF  @SPOutputValue Is NOT NULL        
    BEGIN        
    INSERT intO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)        
    SELECT @SPOutputValue, 'Schedule Download Error', 'SP call --returned bad --return code', 0, @SQLStatement + ' Parms: ' + @ParmDefinition        
    END        
   END        
     END        
 -------------------------------------------------------------------------------        
 -- Move to the next Stored Procedure        
 -------------------------------------------------------------------------------        
 SELECT  @RecSPId = NULL        
         
 SELECT  @RecSPId = MIN(Id)        
 FROM    @tAnySP        
 WHERE   ElementName = 'Name'        
   AND Status = 0        
         
 END        
         
         
         
-------------------------------------------------------------------------------        
-- Task 18        
-- Update LastProcessedDateDownload for each Path processed        
-------------------------------------------------------------------------------        
-- Add a record for each path in the system        
INSERT intO dbo.Table_Fields_Values (KeyId,Table_Field_id,TableId, Value)         
SELECT p.Path_Id, -78, @PrdExecPathTableID, '1970-01-01 00:00:00.000'         
FROM dbo.table_fields_values  v   WITH(NOLOCK)        
RIGHT OUTER JOIN dbo.prdexec_paths p WITH(NOLOCK) ON p.path_id = v.KeyId         
              AND v.TableId = @PrdExecPathTableID         
              AND Table_field_id = -78        
WHERE v.KeyId IS NULL         
        
        
UPDATE tfv        
SET Value = CONVERT(varchar(25), GETDATE())        
FROM dbo.Table_Fields_Values tfv        
JOIN @tER er ON er.PathId = tfv.KeyId        
WHERE Table_Field_id = -78         
  AND TableId = @PrdExecPathTableID        
          
          
--IF (@Comment IS NOT NULL)        
--BEGIN        
        
--  IF EXISTS (SELECT KEYID FROM Table_Fields_Values tfv WITH (NOLOCK)         
--  JOIN Production_Plan P WITH (NOLOCK) ON p.PP_Id = tfv.keyid        
--  JOIN @tPR tpr on tpr.ProcessOrder = p.Process_Order        
--  WHERE Table_Field_Id = @POcomment and TableId = @PPTableId )        
          
--  BEGIN        
          
--  UPDATE Table_Fields_Values        
--  SET Value = @Comment         
--  WHERE Table_Field_Id = @POcomment    
--  and TableId = 7        
          
--  END        
          
--  ELSE        
          
--  BEGIN        
           
--  INSERT  Table_Fields_Values        
--  (KeyId,        
--  Table_Field_Id,        
--  TableId,        
--  Value)        
--  SELECT p.pp_id,        
--  @POcomment,        
--  @PPTableId,        
--  @comment FROM dbo.Production_plan p WITH (NOLOCK)         
--  JOIN @tPR t ON t.ProcessOrder = p.Process_Order         
          
--  END        
          
--END        
          
--select 'LO', * from @tLocation        
--select 'PR', * from @tPR        
--select 'SR', * from @tSR        
--select 'ER', * from @tER        
--select 'MPR', * from @tMPR        
--select 'MPRP', * from @tMPRP        
--select 'MCR', * from @tMCR order by proddesc        
--select 'MCRP', * from @tMCRP        
--select 'ANYUDP',  * from @tAnyUDP        
--select 'ANYSP',  * from @tAnySP        
        
SKIPProcessing:        
ErrCode:        
--IF   @ErrCode = '-000'        
--   SELECT @ErrCode AS ErrCode        
        
        
-------------------------------------------------------------------------------        
-- Task 19        
-- Send Dummy Result Sets back        
-------------------------------------------------------------------------------        
IF @FlgSendRSProductionPlan   = 0        
      -- Send dummy Production Plan ResultSet        
      SELECT        
         NULL   AS      Result,        
         NULL   AS      PreDB,        
         NULL   AS      TransType,        
         NULL   AS      TransNum,        
         NULL   AS      PathId,        
         NULL   AS      PPId,        
         NULL   AS      CommentId,        
         NULL   AS      ProdId,        
         NULL   AS      ImpliedSequence,        
         NULL   AS      PPStatusId,        
         NULL   AS      PPTYpeId,        
         NULL   AS      SourcePPId,        
         NULL   AS      UserId,        
         NULL   AS      ParentPPId,        
         NULL AS      ControlType,        
         NULL   AS      ForecastStartTime,        
         NULL   AS      ForecastEndTime,        
         NULL   AS      EntryOn,        
         NULL   AS      ForecastQuantity,        
         NULL   AS      ProductionRate,        
         NULL   AS      AdjustedQuantity,        
         NULL   AS      BlockNumber,        
         NULL   AS      ProcessOrder,        
         NULL   AS      TransactionTime,        
         NULL   AS      BOMFormulationId        
   WHERE NULL IS NOT NULL -- for empty result set        
         
IF @FlgSendRSProductionSetup = 0        
      -- Send dummy Production Setup ResultSet           
      SELECT        
         NULL AS   Result,        
         NULL AS   PreDB,        
         NULL AS   TransType,        
         NULL AS   TransNum,        
         NULL AS   PathId,        
         NULL AS   PPSetupId,        
         NULL AS   PPId,        
         NULL AS   ImpliedSequence,        
         NULL AS   PPStatusId,        
         NULL AS   PatternReptition,        
         NULL AS   CommentId,        
         NULL AS   ForecastQuantity,        
         NULL AS   BaseDimensionX,        
         NULL AS   BaseDimensionY,        
         NULL AS   BaseDimensionZ,        
         NULL AS   BaseDimensionA,        
         NULL AS   BaseGeneral1,        
         NULL AS   BaseGeneral2,        
         NULL AS   BaseGeneral3,        
         NULL AS   BaseGeneral4,        
         NULL AS   Shrinkage,        
         NULL AS   PatternCode,        
         NULL AS   UserId,        
         NULL AS   EntryOn,        
         NULL AS   TransactionTime,        
         NULL AS   ParentPPSetupId        
   WHERE NULL IS NOT NULL -- for empty result set        
        
-------------------------------------------------------------------------------        
-- Task 20        
-- Send Result Sets back        
-------------------------------------------------------------------------------           
SELECT @RetProcessOrder = ProcessOrder FROM @tPR        
        
SELECT @RetPathCode = EquipmentId FROM @tER        
        
SELECT   @RetPathProdCode = ProdCode,        
      @RetPathUOM = UOM        
FROM @tMPR        
              
        
DELETE FROM @tERR WHERE ErrorCode IS NULL        
        
SELECT         
        ErrorCode     AS Code        ,        
        ErrorCategory    AS Category       ,        
        ErrorMsg      AS Message       ,        
        Severity      AS Severity       ,        
       Coalesce(ReferenceData, '') AS Reference                
FROM @tERR        
        
             
SELECT  @RetProcessOrder         AS ProcessOrder,        
     @RetPathCode            AS PathCode,        
     @RetPathProdCode         AS PathProdCode,        
     @RetPathUOM            AS PathUOM,        
     ISNULL(@FlgBOMItemChanged,0)        AS BOMChanged        
             
             
-- print '--EXIT: ' + convert(char(30), getdate(), 21)        
--drop table #tXML        
SET NOCOUNT OFF        
        
     
        