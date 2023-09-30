/*
-------------------------------------------------------------------------------
-- SP returns resultsets for ProductionPerformance, ConsumptionPerformance and
-- OrderCOnfirmation for a give Process Order. PP and CP includes MPAPs and 
-- MCAPs
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
Options:
ReportCorrections 	 - True/False (1/0) 	 - Report a negative amount for a product 
that was changed to something else.
ReportDeletions 	  	 - True/False (1/0) 	 - Report a negative amount for data that 
was removed due to deleted events or Production_Plan_Starts changes.
AutoConfirmation 	 - True/False (1/0) 	 - Confirm the ERP_Production and E
RP_Consumption records at the end of this sp.  This means that Biztalk doesn't need
to confirm them separately.
EventIdentification 	 - 1,2,3 	  	  	 
 	 - 1) Use both Production_Plan_Starts and Event_Details.PP_Id
 	   2) Use just Event_Details.PP_Id
 	   3) Use just Production_Plan_Starts
ReportByModifiedOn 	 - True/False (1/0) 	 - Record all records in the ERP tables
 but only send MPA/MCA records where the ModifiedOn field > Subscription.LastProcessedDate
-------------------------------------------------------------------------------
DATE 	  	  	  	 BY 	  	  	  	  	  	 DESCRIPTION
2009-08-18 001 001 	 Alex.Judkowicz@GE.com 	 Rewrite for WF demo
2009-08-31 	  	  	 S.Poon 	  	  	  	  	 Changes adapted to NLINK
-- 	  	  	  	  	 Production Performance Production ->PI_PROD
-- 	  	  	  	  	 Site number to '1100'
-- 	  	  	  	  	 Stoage number to '0001'
-- 	  	  	  	  	 wrong assignment - swap the MCP Datatype and UnitOfMeasure
--
2009-09-03 	  	  	 MCA simulated data use ProcessOrder
--
2009-10-08 	  	  	 CC Description Production Performance Consumption ->PI_CONS
2009-12-02  J.Gerstl    Changes to adapt to OpenEnterprise project
-------------------------------------------------------------------------------
spLocal_ProductionPerformanceUploadNewFull 90
*/
CREATE PROCEDURE [dbo].[spS95OE_ProductionPerformanceUpload]
 	 @PPID 	 INT,  	 -- The PPID of the Process Order
 	 @UploadType   	 INT  	 -- 1 = Full: Sends PP, CP, and OC
                      -- 2 = Incremental PP: Sends PP, Null(CP,OC)
                      -- 3 = Incremental CP: Sends CP, Null(PP,OC)
AS
/*
spS95OE_ProductionPerformanceUpload 1959,1
--select * from erp_production where pp_id = 
*/
-------------------------------------------------------------------------------
-- @UploadType (Time-based (incremental) or Full)
--  This parm indicates which data tables to return and which routines should be executed. 
-- NULL means that the table is returned but empty.
--                                Upload Type 	  	 
-- 	                               1 	 2 	 3
--MaterialProducedActual 	         Y 	 Y 	 NULL
--MaterialProducedActualProperty 	 Y 	 Y 	 NULL
--MaterialConsumedActual 	         Y 	 NULL 	 Y
--MaterialConsumedActualProperty 	 Y 	 NULL 	 Y
--OrderConfirmation 	               Y 	 Y Y
--Update ERP_Production 	           Y 	 Y 	 N
--Update ERP_Consumption 	         Y 	 N 	 Y
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SECTION 0: INITIALIZATION
-------------------------------------------------------------------------------
SET ARITHIGNORE ON 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Variable Declarations
-------------------------------------------------------------------------------
DECLARE 	 @EventsTableId  	    	    	    	  	  	 INT,
    @Debug      INT,
    @AutoConfirm      INT,
    @cVarId                         INT,
    @cResultOn                      DATETIME,
    @cResult                        VARCHAR(25),
    @cPPId                          INT,
    @cmpaStorageZone                VARCHAR(255),
    @cPUId                          INT,
    @SubscriptionTableID            INT,
 	  	 @ProductionPlanTableId  	    	  	  	 INT,
    @PrdExecPathTableID INT,
 	  	 @ProductionSetupTableId  	    	  	 INT,
 	  	 @ProductionPlanStatusesTableId 	  	 INT,
 	  	 @VariablesTableId  	    	    	  	  	 INT,
 	  	 @ProductionPerformanceGroupId  	    	 INT,
 	  	 @ConsumptionPerformanceGroupId  	  	 INT,
 	  	 @TestConformanceGroupId  	    	    	 INT,
 	  	 @OrderConfirmationGroupId  	    	  	 INT,
 	  	 @NullTimeStamp  	    	    	    	  	  	 DATETIME,
 	  	 @TimeStamp  	    	    	    	  	  	  	 DATETIME,
    @KeyId    INT,
    @TableFieldId   INT,
    @TableFieldValue VARCHAR(255),
    @Status0  	    	    	    	  	  	  	 INT,
 	  	 @Status1  	    	    	    	  	  	  	 INT,
 	  	 @Status2  	    	    	    	  	  	  	 INT,
 	  	 @Status3  	    	    	    	  	  	  	 INT,
 	  	 @Status4  	    	    	    	  	  	  	 INT,
 	  	 @Status5  	    	    	    	  	  	  	 INT,
 	  	 @Status6  	    	    	    	  	  	  	 INT,
 	  	 @Status7  	    	    	    	  	  	  	 INT,
 	  	 @MPAStorageZone  	    	    	    	  	 VARCHAR(100),
 	  	 @PPWarningCommentAlias  	    	    	  	 VARCHAR(100),
 	  	 @ProdProcSegmentId  	    	    	  	  	 VARCHAR(100),
 	  	 @ConsProcSegmentId  	    	    	  	  	 VARCHAR(100),
 	  	 @ConfProcSegmentId  	    	    	  	  	 VARCHAR(100),
 	  	 @DataSourceId  	    	    	    	  	  	 INT,
 	  	 @TPSegmentName  	    	    	    	  	  	 VARCHAR(100),
 	  	 @TPTestName  	    	    	    	  	  	 VARCHAR(100),
 	  	 @FlgPadZeros  	    	    	    	  	  	 INT,
 	  	 @DSEventNumId  	    	    	    	  	  	 INT,
 	  	 @ReportCorrections  	    	    	  	  	 SMALLINT,
 	  	 @ReportDeletions  	    	    	  	  	 SMALLINT,
 	  	 @EventIdentification  	    	    	  	 SMALLINT,
 	  	 @ReportByModifiedOn  	    	    	  	 SMALLINT,
 	  	 @TECOFieldId  	    	    	    	  	  	 VARCHAR(255),
 	  	 @CompleteFieldId  	    	    	  	  	 VARCHAR(255),
 	  	 @ConfirmFieldId  	    	    	    	  	 VARCHAR(255),
 	  	 @Cnt   	    	    	    	    	  	  	  	 INT,
 	  	 @LoopPPId 	  	  	  	  	  	  	 INT,
 	  	 @LoopCount  	    	    	    	  	  	  	 INT,
 	  	 @LoopIndex  	    	    	    	  	  	  	 INT,
 	  	 @ECDimXOP  	    	    	    	  	  	  	 SMALLINT,
 	  	 @WEDAmountOP  	    	    	    	  	  	 SMALLINT,
 	  	 @EDDimXOP  	    	    	    	  	  	  	 SMALLINT,
 	  	 @EAppProdOP  	    	    	    	  	  	 SMALLINT,
 	  	 @PSStartOP  	    	    	    	  	  	  	 SMALLINT,
 	  	 @PSEndOP  	    	    	    	  	  	  	 SMALLINT,
 	  	 @PSProdIdOP  	    	    	    	  	  	 SMALLINT,
 	  	 --@LastProcessedDate  	    	    	  	  	 DATETIME,
 	  	 @CurrentStatusId  	    	    	  	  	 INT, 
 	  	 @PrevStatusId  	     	    	    	  	  	 INT,
 	  	 @FromValue  	    	    	    	  	  	  	 INT, 
 	  	 @ToValue  	    	    	    	  	  	  	 INT, 
 	  	 @ColumnName  	    	    	    	  	  	 VARCHAR(255),
 	  	 @EntryOn  	    	    	    	  	  	  	 DATETIME,
 	  	 @ActualId  	    	    	    	  	  	  	 INT,
 	  	 @SubscriptionTriggerId  	    	    	  	 INT,
 	  	 @SubscriptionGroupId  	    	    	  	 INT,
 	  	 @SubscriptionGroupDesc  	    	    	  	 VARCHAR(255),
 	  	 @TransId  	    	    	    	  	  	  	 INT,
 	  	 @ConfirmTOSAPId  	    	    	    	  	 INT,
 	  	 @TimeTriggerINTerval  	    	    	  	 INT,
 	  	 @TableId  	    	    	    	  	  	  	 INT,
 	  	 @PathId  	    	    	    	    	  	  	 INT,
 	  	 @PUId  	    	    	    	    	  	  	  	 INT,
 	  	 @SentTOSAP  	    	    	    	  	  	  	 VARCHAR(255),
 	  	 @SentToSAPFlagFieldId  	    	    	  	 INT,
 	  	 @Id  	    	    	    	    	  	  	  	 INT,
 	  	 @TestPerformanceHeader  	    	    	  	  	 VARCHAR(255),
 	  	 @MaterialProducedActualPropertyHeader  	 VARCHAR(255),
 	  	 @MaterialConsumedActualPropertyHeader  	 VARCHAR(255),
 	  	 @TimeModifier  	    	    	    	  	  	 INT,
 	  	 @FlgConvertMCAUOMToBOMUOM  	    	  	 INT,
 	  	 @FlgConvertMPAUOMToPSUOM  	    	  	 INT,
 	  	 @PSOriginalEngUnitCodeUDP  	    	  	 INT,
 	  	 @MPAQuantityDataType  	    	    	  	 VARCHAR(255),
 	  	 @MCAQuantityDataType  	    	    	  	 VARCHAR(255),
 	  	 @ProductsTableId  	    	    	  	  	 INT,
 	  	 @ProdLinesTableId  	    	    	  	  	 INT,
 	  	 @ProdUnitsTableId 	  	  	  	  	 INT, 	 
 	  	 @FlgPAS88InterfaceImplemented  	    	 INT,
 	  	 @PPErrorStatusID  	    	    	  	  	 INT,
 	  	 @PPStatusID  	    	    	   	  	  	 INT,
 	  	 @FlgSendDispositionTests  	    	  	 INT,
 	  	 @FlgGroupMPAForOCMessage 	  	  	 INT,
 	  	 @UDPId 	  	  	  	  	  	  	  	 INT, 	 
 	  	 @FlgMakePPLookLikeOC 	  	  	  	 INT, 	 
 	  	 @FlgTPFlagToLinkBatchToPO 	  	  	 INT, 	 
 	  	 @tRows  	  	  	  	  	  	  	  	 INT,
 	  	 @OECommonSubscription INT,
    @OEUploadSubscription INT, 
    @FlgFixedOutput INT,
    @MPADefaultSiteId 	  	 VARCHAR(255),
    @MCADefaultSiteId 	  	 VARCHAR(255),
 	  	 @DefaultStorageZoneMCA 	 VARCHAR(255)
 	  	 
-------------------------------------------------------------------------------
-- TABLE DECLARATIONS  	    	    	    	    	    	    	    	    	    	    	    	    
-------------------------------------------------------------------------------
DECLARE @tTransactions 	 TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
 	  	 SubscriptionTriggerId  	 INT,
 	  	 SubscriptionId  	    	  	 INT,
 	  	 SubscriptionGroupId  	 INT,
 	  	 EntryOn  	    	    	  	 DATETIME, 
 	  	 ActualId  	    	  	  	 INT,
 	  	 RecordType  	    	  	  	 INT,
 	  	 PPId  	    	    	  	  	 INT,
 	  	 PrevStatusId  	    	  	 INT,   	   
 	  	 CurrentStatusId  	    	 INT 	  	 
)    	    	  
DECLARE 	 @tPaths   	  	 TABLE 
(  	  
 	  	 PathId  	    	    	  	  	 INT
)
DECLARE @tPUs   	    	  	 TABLE 
(  	  
 	  	 PUId  	    	    	  	  	 INT
)
--DECLARE @tPOs 	   	    	  TABLE 
--(  	  	 
-- 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
--  	    	 PPId  	    	    	  	  	 INT,
--  	    	 SentTOSAP  	    	  	  	 VARCHAR(255))
DECLARE 	 @tEmpty  	    	  TABLE 
(  	  	 
 	  	 Id  	    	    	  	  	  	 INT 
)
DECLARE 	 @tStatus   	  	 TABLE 
( 
 	  	 StatusId  	  	  	   	 INT PRIMARY KEY,
 	  	 Confirm  	    	    	  	 INT,
 	  	 Complete  	    	  	  	 INT,
 	  	 TECO  	    	    	  	  	 INT 
)
DECLARE 	 @tProcessOrder  TABLE 
(  	  
 	  	 Id  	  	  	  	  	  	 INT IDENTITY(1,1),
 	  	 PPId  	    	    	  	  	 INT PRIMARY KEY,
 	  	 ProcessOrder  	    	  	 VARCHAR(100),
 	  	 ParentPPId  	    	  	  	 INT,
 	  	 PathId  	    	    	  	  	 INT,
 	  	 PPStatusId  	    	  	  	 INT,
 	  	 StartTime  	    	  	  	 DATETIME,
 	  	 EndTime  	    	    	  	 DATETIME,
 	  	 ProcessSegmentId  	  	 VARCHAR(100),
 	  	 Confirm  	    	    	  	 INT,
 	  	 Complete  	    	  	  	 INT,
 	  	 TECO  	    	    	  	  	 INT,
 	  	 PPTId  	    	    	  	  	 INT,
 	  	 PPTStartTime  	    	  	 DATETIME,
 	  	 PPTEndTime  	    	  	  	 DATETIME,
 	  	 KeepFlag  	    	  	  	 INT,
    --Path Based UDPs 	  	 
    ReportCorrections 	 INT 	 ,
    --SITE AutoConfirm 	 INT 	 ,
    ReportDeletions 	 INT 	 ,
    ReportByModifiedOn 	 VARCHAR(255) 	 ,
    TPSegmentName 	 VARCHAR(255) 	 ,
    TPTestName 	 VARCHAR(255) 	 ,
    TestPerformanceHeader 	 VARCHAR(255) 	 ,
    MaterialProducedActualPropertyHeader 	 VARCHAR(255) 	 ,
    MaterialConsumedActualPropertyHeader 	 VARCHAR(255) 	 ,
    MPAStorageZone 	 VARCHAR(255) 	 ,
    PPWarningCommentAlias 	 VARCHAR(255) 	 ,
    ConfProcSegmentId 	 VARCHAR(255) 	 ,
    ProdProcSegmentId 	 VARCHAR(255) 	 ,
    ConsProcSegmentId 	 VARCHAR(255) 	 ,
    FlgPadZeros 	 INT 	 ,
    EventIdentification 	 INT 	 ,
    DSEventNumId 	 INT 	 ,
    FlgConvertMCAUOMToBOMUOM 	 INT 	 ,
    FlgConvertMPAUOMToPSUOM 	 INT 	 ,
    FlgSendDispositionTests 	 INT 	 ,
    FlgGroupMPAForOCMessage 	 INT 	 ,
    LastProcessedTimestampUploadIncrementalPP 	 datetime 	 ,
    LastProcessedTimestampUploadIncrementalCP 	 datetime 	 ,
    MPADefaultSiteId 	 VARCHAR(255) 	 ,
    MCADefaultSiteId 	 VARCHAR(255) 	 
 	  	 )
DECLARE @tEvents   	  	 TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1) PRIMARY KEY,
 	  	 PPId  	    	    	  	  	 INT,
 	  	 PUId  	    	    	  	  	 INT,
 	  	 EventId   	    	  	  	 INT, 
 	  	 EventNum  	    	  	  	 VARCHAR(100),
 	  	 StartTime  	    	  	  	 DATETIME,
 	  	 EndTime  	    	    	  	 DATETIME,
 	  	 StartId  	    	    	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL DEFAULT 0,
 	  	 ModifiedOn  	    	  	  	 DATETIME
)
DECLARE 	 @tVariables   	  TABLE 
(  	  
 	  	 Id  	  	  	  	  	  	 INT IDENTITY(1,1) PRIMARY KEY,
 	  	 PPId  	    	    	  	  	 INT,
 	  	 VarId  	    	    	  	  	 INT, 
 	  	 StartTime  	    	  	  	 DATETIME,
 	  	 EndTime  	    	    	  	 DATETIME,
 	  	 StartId  	    	    	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL 	  	  	  	 DEFAULT 0,
 	  	 ModifiedOn  	    	  	  	 DATETIME
)
DECLARE @tProductionHistory TABLE 
(
 	  	 Id  	  	  	    	    	  	 INT IDENTITY(1,1),
 	  	 PPId  	    	    	  	  	 INT,
 	  	 ProductionType  	    	  	 TINYINT,
 	  	 KeyId  	    	    	  	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL,
 	  	 PRIMARY KEY 	  	  	  	 (PPId, ProductionType, KeyId, Id)
)  	  
DECLARE @tProduction   	  TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
 	  	 PPId  	    	    	  	  	 INT,
 	  	 ProductionType  	    	  	 TINYINT,
 	  	 KeyId  	    	    	  	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL DEFAULT 0,
 	  	 ModifiedOn  	    	  	  	 DATETIME,
 	  	 PRIMARY KEY (PPId, ProductionType, KeyId, Id))  	  
DECLARE 	 @tMPA   	    	  	 TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1) PRIMARY KEY,
 	  	 ProcessOrder  	    	  	 VARCHAR(100),
 	  	 PPId  	    	    	  	  	 INT,
 	  	 PathId  	    	    	  	  	 INT,
 	  	 EventId   	    	  	  	 INT, 
 	  	 StartTime  	    	  	  	 DATETIME,
 	  	 EndTime  	   	    	  	 DATETIME,
 	  	 PUId  	    	    	  	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Product  	    	    	  	 VARCHAR(100),
 	  	 SAPProduct  	    	  	  	 VARCHAR(100),
 	  	 EventNum  	    	  	  	 VARCHAR(100),
 	  	 Batch  	    	    	  	  	 VARCHAR(100),
 	  	 Quantity  	    	  	  	 REAL, 
 	  	 EngUnitId  	    	  	  	 INT,
 	  	 UoM  	    	    	  	  	 VARCHAR(100),
 	  	 ProcessSegmentId  	  	 VARCHAR(100),
 	  	 StorageZone  	    	  	 VARCHAR(100),
 	  	 PSEngUnitId  	    	  	 INT,
 	  	 PSUoM  	    	    	  	  	 VARCHAR(100),
 	  	 ConvertedQuantity  	  	 REAL,
 	  	 EngUnitConvId  	    	  	 INT
)
DECLARE 	  @tMPAP  	    	  TABLE 
(  	  
 	  	 Id 	  	  	  	  	  	 INT 	  	  	  	 IDENTITY(1,1), 	  
 	  	 EventId   	    	  	  	 INT, 
 	  	 PropertyName  	    	  	 VARCHAR(100),
 	  	 Value  	    	    	  	  	 VARCHAR(100),
 	  	 DataType  	    	  	  	 VARCHAR(100),
 	  	 UoM  	    	    	  	  	 VARCHAR(100),
 	  	 TestId  	    	    	  	  	 BigInt,
 	  	 ParentMPAId 	  	  	  	 INT 	  	  	  	  	  	  	  	  
)
DECLARE @tComponents   	  TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY,
 	  	 PPId  	    	    	  	  	 INT,
 	  	 CompId  	    	    	  	  	 INT,
 	  	 SourceEventId  	    	  	 INT,
 	  	 EventId  	    	    	  	 INT,
 	  	 RAC  	    	    	  	  	 INT 	  	 DEFAULT 0,
 	  	 Quantity  	    	  	  	 REAL 	 DEFAULT 0,
 	  	 Ratio  	    	    	  	  	 REAL 	 DEFAULT 100,
 	  	 StartId  	    	    	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 ModifiedOn  	    	  	  	 DATETIME,
 	  	 PRIMARY KEY 	  	  	  	 (RAC, Id)
)
DECLARE @tConsumptionTotal TABLE 
(
 	  	 PPId  	    	    	  	  	 INT,
 	  	 EventId  	    	    	  	 INT,
 	  	 CompId  	    	    	  	  	 INT,
 	  	 SourceEventId  	    	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL DEFAULT 0,
 	  	 Ratio  	    	    	  	  	 REAL DEFAULT 100,
 	  	 ModifiedOn  	    	  	  	 DATETIME,
 	  	 PRIMARY KEY 	  	  	  	 (PPId, EventId, CompId)
)
DECLARE @tConsumptionHistory TABLE 
(
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
 	  	 PPId  	    	    	  	  	 INT,
 	  	 EventId  	    	    	  	 INT,
 	  	 CompId  	    	    	  	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL,
 	  	 PRIMARY KEY 	  	  	  	 (PPId, EventId, CompId, Id)
)  	  
DECLARE @tConsumption   	  TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
 	  	 PPId  	    	    	  	  	 INT,
 	  	 EventId  	    	    	  	 INT,
 	  	 CompId  	    	    	  	  	 INT,
 	  	 SourceEventId  	    	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL DEFAULT 0,
 	  	 Ratio  	    	    	  	  	 REAL DEFAULT 100,
 	  	 ModifiedOn  	    	  	  	 DATETIME,
 	  	 PRIMARY KEY 	  	  	  	 (PPId, EventId, CompId, Id)
)  	  
DECLARE @tWaste   	  	 TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
 	  	 EventId   	    	  	  	 INT,
 	  	 Quantity  	    	  	  	 REAL,
 	  	 PRIMARY KEY 	  	  	  	 (EventId, Id)
)  	    	    	  
DECLARE @tMCA  	    	  	 TABLE 
(  	  
 	  	 Id  	    	    	  	  	  	 INT IDENTITY(1,1),
 	  	 ProcessOrder  	    	  	 VARCHAR(100),
 	  	 EventId  	    	    	  	 INT,
 	  	 EventCompId   	    	  	 INT,
 	  	 VarId  	    	    	  	  	 INT,
 	  	 SourceEventId  	    	  	 INT,
 	  	 SourceEventNum  	    	  	 VARCHAR(100),
 	  	 StartTime  	    	  	  	 DATETIME,
 	  	 EndTime  	    	    	  	 DATETIME,
 	  	 PUId  	    	    	  	  	 INT,
 	  	 RAC  	    	    	  	  	 INT,
 	  	 ProdId  	    	    	  	  	 INT,
 	  	 Product  	    	    	  	 VARCHAR(100),
 	  	 SAPProduct  	  	  	   	 VARCHAR(100),
 	  	 Quantity  	    	  	  	 REAL,
 	  	 EngUnitId  	    	  	  	 INT,
 	  	 UoM  	    	    	  	  	 VARCHAR(100),
 	  	 ProcessSegmentId  	  	 VARCHAR(100),
 	  	 StorageZone  	    	  	 VARCHAR(100),
 	  	 Ratio  	    	    	  	  	 REAL,
 	  	 PPId  	    	    	  	  	 INT,
 	  	 PathId  	    	    	  	  	 INT,
 	  	 BOMFId  	    	    	  	  	 INT,
 	  	 BOMEngUnitId  	    	  	 INT,
 	  	 BOMUoM  	    	    	  	  	 VARCHAR(100),
 	  	 ConvertedQuantity  	  	 REAL,
 	  	 EngUnitConvId  	    	  	 INT
)  	  
DECLARE 	 @tMCAP  	    	  TABLE 
(  	  
 	  	 Id 	  	  	  	  	  	 INT 	  	  	  	 IDENTITY(1,1), 	  
 	  	 EventCompId  	    	  	 INT,
 	  	 EventId  	    	    	  	 INT,
 	  	 PropertyName  	    	  	 VARCHAR(100),
 	  	 Value  	    	    	  	  	 VARCHAR(100),
 	  	 DataType  	    	  	  	 VARCHAR(100),
 	  	 UoM  	    	    	  	  	 VARCHAR(100),
 	  	 VarId  	    	    	  	  	 INT,
 	  	 TestId  	    	    	  	  	 BigInt,
 	  	 ParentMCAId 	  	  	  	 INT 	  	  	  	  
)
DECLARE 	 @tQHdr  	    	  TABLE 
(  	  
 	  	 QHdrId  	    	    	  	  	 INT IDENTITY,
 	  	 ProcessOrder  	    	  	 VARCHAR(100),
 	  	 PUId  	    	    	  	  	 INT,
 	  	 EventNum  	    	  	  	 VARCHAR(100),
 	  	 EventId  	    	    	  	 INT,
 	  	 TimeStamp  	    	  	  	 DATETIME,
 	  	 POStartTime  	    	  	 DATETIME,
 	  	 POEndTime  	    	  	  	 DATETIME,
 	  	 Batch  	    	    	  	  	 VARCHAR(100),
 	  	 TestSegmentID  	    	  	 VARCHAR(100),
 	  	 TestName  	    	  	  	 VARCHAR(100),
 	  	 PPId  	    	    	  	  	 INT,
 	  	 PathId  	    	    	  	  	 INT
 )
DECLARE  @tQTest  	  TABLE 
(  	  
 	  	 Id  	  	  	  	   	    	 INT IDENTITY(1,1),
 	  	 QHdrId  	    	    	  	  	 INT,
 	  	 TestDesc  	    	  	  	 VARCHAR(100),
 	  	 EntryOn  	    	    	  	 DATETIME,
 	  	 Result  	    	    	  	  	 VARCHAR(100),
 	  	 DataType  	    	  	  	 VARCHAR(100),
 	  	 UOM  	    	    	  	  	 VARCHAR(100),
 	  	 Comment  	    	    	  	 VARCHAR(1000),
 	  	 NextCommentId  	  	  	 INT,
 	  	 Disposition  	    	  	 VARCHAR(100),
 	  	 EndTime  	    	    	  	 DATETIME,
 	  	 TestID  	    	    	  	  	 BigInt,
 	  	 VarId  	    	    	  	  	 INT 
)
DECLARE @tXRefVars   TABLE 
(  	  
 	  	 Id  	  	  	  	  	    	 INT IDENTITY(1,1) PRIMARY KEY,
  	    	  VarId  	    	    	  	  	 INT
)
DECLARE @tQuaVars  	  TABLE 
(  	  
 	  	 PUId  	    	    	  INT,
  	    	 VarId  	    	    	  INT
)
DECLARE @tProductionPlanPaths TABLE 
(  	  
 	  	 tId  	    	  	 INT IDENTITY,
   	    	  PPId   	    	  	 INT,
   	    	  PathId  	    	 INT,
   	    	  StartTime  	  	 DATETIME,
   	    	  EndTime  	    	 DATETIME 
)
-- Declare Output tables
DECLARE 	 @oMPA 	 TABLE
(
 	 [Description] 	  	  	 VARCHAR(255),
 	 PublishedDate 	  	  	 VARCHAR(255),
 	 ProductionResponseId 	 VARCHAR(255),
 	 ProductionRequestId 	  	 VARCHAR(255),
 	 SegmentResponseId 	  	 VARCHAR(255),
 	 ProcessSegmentId 	  	 VARCHAR(255),
 	 ActualStartTime 	  	  	 VARCHAR(255),
 	 ActualEndTime 	  	  	 VARCHAR(255),
 	 MaterialDefinitionId 	 VARCHAR(255),
 	 MaterialLotId 	  	  	 VARCHAR(255),
 	 EquipmentId1 	  	  	 VARCHAR(255),
 	 EquipmentElementLevel1 	 VARCHAR(255), 	 
 	 EquipmentId2 	  	  	 VARCHAR(255),
 	 EquipmentElementLevel2 	 VARCHAR(255), 	 
 	 Quantity 	  	  	  	 VARCHAR(255),
 	 DataType 	  	  	  	 VARCHAR(255),
 	 UnitOfMeasure 	  	  	 VARCHAR(255),
 	 EventId 	  	  	  	  	 INT,
 	 Sequence  	    	  	  	 INT 	  	  	  	 IDENTITY(1,1)
)
DECLARE 	 @oMPAP 	 TABLE
(
 	 Id 	  	  	  	  	  	 VARCHAR(255),
 	 [Description] 	  	  	 VARCHAR(255),
 	 [Value] 	  	  	  	  	 VARCHAR(255),
 	 DataType 	  	  	  	 VARCHAR(255),
 	 UnitOfMeasure 	  	  	 VARCHAR(255),
 	 EventId 	  	  	  	  	 INT,
 	 TestId 	  	  	  	  	 BigInt,
 	 ParentMPAId 	  	  	  	 INT,
 	 Sequence  	    	  	  	 INT 	  	  	  	 IDENTITY(1,1)
)
DECLARE 	 @oMCA 	 TABLE
(
 	 [Description] 	  	  	 VARCHAR(255),
 	 PublishedDate 	  	  	 VARCHAR(255),
 	 ProductionResponseId 	 VARCHAR(255),
 	 ProductionRequestId 	  	 VARCHAR(255),
 	 SegmentResponseId 	  	 VARCHAR(255),
 	 ProcessSegmentId 	  	 VARCHAR(255),
 	 ActualStartTime 	  	  	 VARCHAR(255),
 	 ActualEndTime 	  	  	 VARCHAR(255),
 	 MaterialDefinitionId 	 VARCHAR(255),
 	 MaterialLotId 	  	  	 VARCHAR(255),
 	 EquipmentId1 	  	  	 VARCHAR(255),
 	 EquipmentElementLevel1 	 VARCHAR(255), 	 
 	 EquipmentId2 	  	  	 VARCHAR(255),
 	 EquipmentElementLevel2 	 VARCHAR(255), 	 
 	 Quantity 	  	  	  	 VARCHAR(255),
 	 DataType 	  	  	  	 VARCHAR(255),
 	 UnitOfMeasure 	  	  	 VARCHAR(255),
 	 ChildEventId 	  	  	 INT,
 	 Sequence  	    	  	  	 INT 	  	  	  	 IDENTITY(1,1)
)
DECLARE 	 @oMCAP 	 TABLE
(
 	 Id 	  	  	  	  	  	 VARCHAR(255),
 	 [Description] 	  	  	 VARCHAR(255),
 	 [Value] 	  	  	  	  	 VARCHAR(255),
 	 DataType 	  	  	  	 VARCHAR(255),
 	 UnitOfMeasure 	  	  	 VARCHAR(255),
 	 EventId 	  	  	  	  	 INT,
 	 TestId 	  	  	  	  	 BigInt,
 	 ParentMCAId 	  	  	  	 INT,
 	 Sequence  	    	  	  	 INT 	  	  	  	 IDENTITY(1,1)
)
DECLARE 	 @oOC 	 TABLE
(
 	 [Description] 	  	  	 VARCHAR(255),
 	 PublishedDate 	  	  	 VARCHAR(255),
 	 ProductionResponseId 	 VARCHAR(255),
 	 ProductionRequestId 	  	 VARCHAR(255),
 	 SegmentResponseId 	  	 VARCHAR(255),
 	 ProcessSegmentId 	  	 VARCHAR(255),
 	 ActualStartTime 	  	  	 VARCHAR(255),
 	 ActualEndTime 	  	  	 VARCHAR(255),
 	 MaterialDefinitionId 	 VARCHAR(255),
 	 MaterialLotId 	  	  	 VARCHAR(255),
 	 Quantity 	  	  	  	 VARCHAR(255),
 	 DataType 	  	  	  	 VARCHAR(255),
 	 UnitOfMeasure 	  	  	 VARCHAR(255),
 	 PPId 	  	  	  	  	 INT,
 	 Sequence  	    	  	  	 INT 	  	  	  	 IDENTITY(1,1)
)
-------------------------------------------------------------------------------
-- Initialize Constants
-------------------------------------------------------------------------------
SELECT 	 @Debug = 0, 
    @EventsTableId  	    	    	    	  	 = 1,
    @SubscriptionTableID          = 27, 
    @OECommonSubscription     = -7,
    @OEUploadSubscription     = -9,
 	  	 @ProductionPlanTableId  	    	    	 = 7,
 	  	 @ProductionSetupTableId  	    	 = 8,
 	  	 @ProductionPlanStatusesTableId  	 = 34,
    @PrdExecPathTableID       = 13, 
 	  	 @VariablesTableId  	    	    	   	 = 20,
 	  	 @ProductsTableId  	    	    	   	 = 23,
 	  	 @ProdLinesTableId  	    	    	   	 = 18,
 	  	 @ProdUnitsTableId 	  	  	   	 = 43, 	  	 
 	  	 @ProductionPerformanceGroupId  	 = -3,
 	  	 @ConsumptionPerformanceGroupId  	 = -4,
 	  	 @TestConformanceGroupId  	    	 = -5,
 	  	 @OrderConfirmationGroupId  	    	 = -6,
 	  	 @NullTimeStamp  	  	    	    	    	 = '1970-01-01 00:00:00',
 	  	 @TimeStamp  	    	    	    	  	  	 = GETDATE(),
 	  	 @MPAQuantityDataType  	    	    	 = 'float',
 	  	 @MCAQuantityDataType  	    	    	 = 'float',
 	  	 @PSOriginalEngUnitCodeUDP  	    	 = -71, 	   
    @SentToSAPFlagFieldId  	  = -68,
 	  	 @TECOFieldId  	  	  	  	  	 = -56,
 	  	 @ConfirmFieldId 	  	  	  	  	 = -58,
 	  	 @CompleteFieldId 	  	  	  	 = -57,
 	  	 @FlgFixedOutput 	  	  	  	  	 = 0
        -- Possible Values:
        -- 0: Real time: It accesses the database to return MPA, MPAP, MCA, MCAP and OC
        -- 1: Simulated: It returns harcoded resultsets for MPA, MPAP, MCA, MCPA and OC
        -- 2: Demo: It accesses the database to return MPA and OC. 
        --    It returns harcoded resultsets for MPAP, MCA and MCAP
-------------------------------------------------------------------------------
-- if this PPid is SentToSAP = Y then bail, regardless of the upload type
-------------------------------------------------------------------------------
IF (SELECT Value
    FROM Table_Fields_Values v  	 WITH 	 (NOLOCK)
    WHERE   KeyId  	    	  = @PPId
    AND  	   TableId  	    	  = @ProductionPlanTableId
    AND  	   Table_Field_Id  	  = @SentToSAPFlagFieldId) = 'Y'
BEGIN
  GOTO OUTPUTRESULTS
  IF @Debug = 1 SELECT @PPId, 'already sent to SAP'
END
--ELSE
--BEGIN
--  INSERT 	 @tPOs (PPId, SentToSAP)
-- 	  	   VALUES 	 (@PPId, 'N')
--END
-------------------------------------------------------------------------------
-- Get the production statuses and their associated UDPs.
-------------------------------------------------------------------------------
INSERT  	  @tStatus (StatusId,
  	    	  	  	  TECO,
  	    	  	  	  Confirm,
  	    	  	  	  Complete)
 	  	 SELECT  	  PP_Status_Id,
  	  	  	  	  isnull(tcv.Value, 0),
  	  	  	  	  isnull(cnv.Value, 0),
  	  	  	  	  isnull(cmv.Value, 0)
 	  	  	  	 FROM 	 Production_Plan_Statuses pps 	  	 WITH 	 (NOLOCK)
  	  	  	  	 LEFT 
 	  	  	  	 JOIN 	 dbo.Table_Fields_Values tcv 	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON  	  	 tcv.TableId 	  	  	  	 = @ProductionPlanStatusesTableId
 	  	  	  	 AND 	  	 tcv.KeyId 	  	  	  	 = pps.PP_Status_Id
 	  	  	  	 AND 	  	 tcv.Table_Field_Id 	  	 = @TECOFieldId
  	  	  	  	 LEFT 
 	  	  	  	 JOIN 	 dbo.Table_Fields_Values 	 cnv 	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON  	  	 cnv.TableId 	  	  	  	 = @ProductionPlanStatusesTableId
 	  	  	  	 AND 	  	 cnv.KeyId 	  	  	  	 = pps.PP_Status_Id
 	  	  	  	 AND 	  	 cnv.Table_Field_Id 	  	 = @ConfirmFieldId
 	  	  	  	 LEFT 
 	  	  	  	 JOIN 	 dbo.Table_Fields_Values cmv 	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON  	  	 cmv.TableId 	  	  	  	 = @ProductionPlanStatusesTableId
 	  	  	  	 AND 	  	 cmv.KeyId 	  	  	  	 = pps.PP_Status_Id
 	  	  	  	 AND 	  	 cmv.Table_Field_Id 	  	 = @CompleteFieldId
-------------------------------------------------------------------------------
-- History Bit Masks
-------------------------------------------------------------------------------
SELECT 	 @ECDimxOP 	 = ORDINAL_POSITION
 	  	 FROM 	 INFORMATION_SCHEMA.COLUMNS 	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME 	 = 'Event_Components'
 	  	 AND 	  	 COLUMN_NAME = 'Dimension_X'
SELECT 	 @WEDAmountOP  = ORDINAL_POSITION
 	  	 FROM 	 INFORMATION_SCHEMA.COLUMNS 	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME  = 'Waste_Event_Details'
 	  	 AND 	  	 COLUMN_NAME = 'Amount'
SELECT 	 @EAppProdOP = ORDINAL_POSITION
 	  	 FROM 	 INFORMATION_SCHEMA.COLUMNS 	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME = 'Events'
 	  	 AND 	  	 COLUMN_NAME = 'Applied_Product'
SELECT 	 @PSStartOP = ORDINAL_POSITION
 	  	 FROM INFORMATION_SCHEMA.COLUMNS 	  	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME = 'Production_Starts' 
 	  	 AND COLUMN_NAME 	    = 'Start_Time'
SELECT 	 @PSEndOP = ORDINAL_POSITION 	  	  	  	 
 	  	 FROM 	 INFORMATION_SCHEMA.COLUMNS 	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME = 'Production_Starts'
 	  	 AND 	  	 COLUMN_NAME = 'End_Time'
SELECT 	 @PSProdIdOP = ORDINAL_POSITION 	  	  	  	 
 	  	 FROM 	 INFORMATION_SCHEMA.COLUMNS 	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME 	 = 'Production_Starts'
 	  	 AND 	  	 COLUMN_NAME = 'Prod_Id'
SELECT 	 @EDDimXOP 	 = ORDINAL_POSITION 	  	  	 
 	  	 FROM 	 INFORMATION_SCHEMA.COLUMNS 	  	 WITH 	 (NOLOCK)
 	  	 WHERE 	 TABLE_NAME 	 = 'Event_Details'
 	  	 AND 	  	 COLUMN_NAME = 'Initial_Dimension_X'
-------------------------------------------------------------------------------
-- Get Common\Site User Defined Parameters
-------------------------------------------------------------------------------
EXEC dbo.spCmn_UDPLookupById  	  @DataSourceId OUTPUT,  	    	  --@LookupValue  	  NVARCHAR(1000) OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  	 --@TableId  	    	  INT,
   	  @OECommonSubscription,  	    	 --@KeyId  	    	  INT,
   	  -3,  	    	    	    	  	 --@PropertyName  	  NVARCHAR(255),
   	  '18'  	    	    	    	 --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	   @PPStatusID   	      	   OUTPUT,   	      	   --@LookupValue   	   NVARCHAR(1000)   	   OUTPUT,
    	   @SubscriptionTableID,   	      	      	  --@TableId   	      	   INT,
    	   @OECommonSubscription,   	  --@KeyId   	   	   INT,
    	   -11,   	      	      --BTSched - DefPPStatusId
  	   '1'   	      	      	  --@DefaultValue   	   NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById   	   @PPErrorStatusID   	      	   OUTPUT,   	   --@LookupValue   	   NVARCHAR(1000)   	   OUTPUT,
    	   @SubscriptionTableID,   	      	      	  --@TableId   	      	   INT,
    	   @OECommonSubscription,   	  --@KeyId   	      	   INT,
    	   -12,   	      	      --BTSched - ErrPPStatusId
    	   0   	      	      	  --@DefaultValue   	   NVARCHAR(1000)   	  
    /*
    We have a <TimeModifier> UDP to be used for either Uploads or Downloads.
    If the <TimeModifier> :=  -X,  then we subtract X mins for all timestamps in the download message, and
                                                              add X mins for all timestamps in the upload message.
    If the <TimeModifier> :=  +X, then we subtract X mins for all timestamps in the upload message, and
  	    	                                        add X mins for all timestamps in the download message.
    */
EXEC dbo.spCmn_UDPLookupById  	  @TimeModifier  	    	     	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	   --@TableId  	    	  INT,
   	  @OECommonSubscription,  	   --@KeyId  	    	  INT,
   	  -69,  	    	    	    	   --Time Modifier
   	  0  	    	    	    	    	   --@DefaultValue  	  NVARCHAR(1000)
IF  	  ISNUMERIC(@TimeModifier) =0 
  	  SELECT  	  @TimeModifier = 0
SELECT  	  @TimeModifier  	  = @TimeModifier * -1
EXEC dbo.spCmn_UDPLookupById  	  @FlgPAS88InterfaceImplemented   	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	    	  --@TableId  	    	  INT,
   	  @OECommonSubscription,  	    	  --@KeyId  	    	  INT,
   	  -73,  	    	    	    	    	  --FlgPAS88InterfaceImplemented  	    	    	    	    	  
 	    0  	    	    	    	    	  	  --@DefaultValue  	  NVARCHAR(1000)
 	 
-------------------------------------------------------------------------------
-- UDP by Subscription/Defaults: Get Upload Parameters based on OE Upload Subscription - these will be used as the defaults if no Path based UDP exists
-------------------------------------------------------------------------------
EXEC dbo.spCmn_UDPLookupById  	  @ReportCorrections  	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
 	     @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
 	     @OEUploadSubscription,  	  --@KeyId  	    	  INT,
 	     -21,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
 	     '1'  	    	    	    	  --@DefaultValue  	  NVARCHAR(1000) 	  	  	 -- AJ:23-Jul-09:CHANGED DEFAULT
EXEC dbo.spCmn_UDPLookupById   	   @AutoConfirm    	      	   OUTPUT,   	   --@LookupValue   	   NVARCHAR(1000)   	   OUTPUT,
    	   @SubscriptionTableID,   	      	      	  --@TableId   	      	   INT,
    	   @OEUploadSubscription,   	  --@KeyId   	      	   INT,
    	   -22,   	      	      --BTSched - ErrPPStatusId
    	   0   	      	      	  --@DefaultValue   	   NVARCHAR(1000)   	  
EXEC dbo.spCmn_UDPLookupById  	  @ReportDeletions  	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	  --@KeyId  	    	  INT,
   	  -23,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
   	  '1'  	    	    	    	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @ReportByModifiedOn  	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	  --@KeyId  	    	  INT,
   	  -24,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
   	  '1'  	    	    	    	  --@DefaultValue  	  NVARCHAR(1000) 	  	  	 -- AJ:23-Jul-09:CHANGED DEFAULT
EXEC dbo.spCmn_UDPLookupById  	  @TPSegmentName  	  OUTPUT,  	    	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	  	   	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -30,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
   	  'End of Batch'  	    	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @TPTestName  	    	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -31,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
   	  'Lot Release'  	    	    	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @TestPerformanceHeader  	    	   OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000) OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	  --@KeyId  	    	  INT,
   	  -32,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
   	  '<TestPerformance>' --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @MaterialProducedActualPropertyHeader OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000) OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	  --@KeyId  	    	  INT,
   	  -33,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
   	  '<MaterialProducedActualProperty>'  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @MaterialConsumedActualPropertyHeader OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000) OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	  --@KeyId  	    	  INT,
   	  -34,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
   	  '<MaterialConsumedActualProperty>'  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @MPAStorageZone  	  OUTPUT,  	    	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -43,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
   	  'PP MPA StorageZone'  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @PPWarningCommentAlias OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
 	  @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
 	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
 	  -44,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
 	  'PP TEST Warning Comment'  	 --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @ConfProcSegmentId  	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -45,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
   	  'ORDER CONFIRMATION'  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @ProdProcSegmentId  	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -46,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
   	  'MAKE'  	    	    	    	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @ConsProcSegmentId  	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -47,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
   	  'MAKE'  	    	    	    	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @FlgPadZeros  	    	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
 	 @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
 	 @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
 	 -48,  	    	  	  	  	  --@PropertyName  	  NVARCHAR(255),
 	 '0'  	    	    	    	  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @EventIdentification OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	  --@KeyId  	    	  INT,
   	  -49,  	    	    	    	  --@PropertyName  	  NVARCHAR(255),
   	  '1'  	    	    	    	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @DSEventNumId  	    	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	 @SubscriptionTableID,  	    	    	    	  	  --@TableId  	    	  INT,
   	 @OEUploadSubscription,  	    	  --@KeyId  	    	  INT, 
   	 -67,  	    	    	    	  	  --@PropertyName  	  NVARCHAR(255),
 	   0  	    	    	    	  	  	  --@DefaultValue  	  NVARCHAR(1000) '50003'
EXEC dbo.spCmn_UDPLookupById  	  @FlgConvertMCAUOMToBOMUOM   	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -70,  	    	    	    	    	  --Time Modifier
   	  0  	    	    	    	    	  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @FlgConvertMPAUOMToPSUOM   	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -72,  	    	    	    	    	  --Time Modifier
   	  0  	    	    	    	    	  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @FlgSendDispositionTests   	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -75,  	    	    	    	    	  --Time Modifier
   	  0  	    	    	    	    	      --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById   	   @FlgGroupMPAForOCMessage 	 OUTPUT,  
 	  	 @SubscriptionTableID,   	      	      	      	      	  
 	  	 @OEUploadSubscription,   	      	      	  
 	  	 -83, 	  	  	      	  
 	  	 1 
EXEC dbo.spCmn_UDPLookupById  	  @MPADefaultSiteId   	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -84,  	    	    	    	    	  --Time Modifier  	    	    	    	    	  
 	    '1100'  	    	    	    	    	  	  --@DefaultValue  	  NVARCHAR(1000)
EXEC dbo.spCmn_UDPLookupById  	  @MCADefaultSiteId   	  OUTPUT,  	  --@LookupValue  	  NVARCHAR(1000)  	  OUTPUT,
   	  @SubscriptionTableID,  	    	    	    	    	  --@TableId  	    	  INT,
   	  @OEUploadSubscription,  	    	  --@KeyId  	    	  INT,
   	  -86,  	    	    	    	    	  --Time Modifier  	    	    	    	    	  
 	    '9999'  	    	    	    	    	  	  --@DefaultValue  	  NVARCHAR(1000)
-- Not doing TP in OE
--SELECT 	 @UDPId 	 = NULL
--SELECT 	 @UDPId 	 = Table_Field_Id
-- 	  	 FROM 	 dbo.Table_Fields 	 WITH 	 (NOLOCK) 	 
-- 	  	 WHERE 	 Table_Field_Desc 	 = 'TP Flag To Link Batches to Process Order'
--IF 	 @UDPId 	 IS NULL
-- 	 SELECT 	 @FlgTPFlagToLinkBatchToPO 	 = 0
--ELSE
--BEGIN
-- 	  	 EXEC dbo.spCmn_UDPLookupById   	   @FlgTPFlagToLinkBatchToPO 	 OUTPUT, 
-- 	  	  	 @SubscriptionTableID,   	      	      	      	      	 
-- 	  	  	 @SubscriptionId,   	      	      	 
-- 	  	  	 @UDPId, 	      	    	  	 
-- 	  	  	 0 
--END
-- Not implemented in OE v1.0
--SELECT 	 @UDPId 	 = NULL
--SELECT 	 @UDPId 	 = Table_Field_Id
-- 	  	 FROM 	 dbo.Table_Fields 	 WITH 	 (NOLOCK) 	 
-- 	  	 WHERE 	 Table_Field_Desc 	 = 'Prod Perf Subscr Generates OrderConfirmation XML'
--IF 	 @UDPId 	 IS NULL
-- 	 SELECT 	 @FlgMakePPLookLikeOC 	 = 0
--ELSE
--BEGIN
-- 	  	 EXEC dbo.spCmn_UDPLookupById   	   @FlgMakePPLookLikeOC 	 OUTPUT, 
-- 	  	  	 @SubscriptionTableID,   	      	      	      	 
-- 	  	  	 @SubscriptionId,   	      	 
-- 	  	  	 @UDPId, 	      	    	 
-- 	  	  	 0 
--END
-------------------------------------------------------------------------------
-- SECTION 2: GET PROCESS ORDERS  	    	    	     	    	    	    	    	    	    	    	  
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- 2.1  	  Get POs   	    	    	    	    	    	    	    	    	    	    	    	    	    	    	   
------------------------------------------------------------------------------
INSERT  	 @tProcessOrder (
 	  	 PPId,
 	  	 ProcessOrder,
 	  	 ParentPPId,
 	  	 StartTime,
 	  	 EndTime,
 	  	 PathId,
 	  	 PPStatusId)
SELECT  	  	 DISTINCT  	  pp.PP_Id,
 	  	  	 pp.Process_Order,
 	  	  	 pp.PP_Id,
 	  	  	 COALESCE(MIN(pps.Start_Time), pp.Actual_Start_Time),
 	  	  	 COALESCE(pp.Actual_End_Time, @TimeStamp),
 	  	  	 pp.Path_Id,
 	  	  	 pp.PP_Status_Id
 	  	   	 FROM 	 dbo.Production_Plan pp 	  	  	 WITH 	 (NOLOCK)
  	  	 -- 	 JOIN 	 @tPOs spp 
 	  	  	 --ON  	  	 pp.PP_Id = spp.PPId
  	  	  	 LEFT 
 	  	  	 JOIN 	 dbo.Production_Plan_Starts pps 	 WITH 	 (NOLOCK) 
 	  	  	 ON 	  	 pps.PP_Id = pp.PP_Id
 	  	  	 WHERE pp.PP_Id = @PPId
  	  	  	 GROUP 
 	  	  	 BY  	  	 pp.PP_Id,
 	  	  	  	  	 pp.Process_Order,
 	  	  	  	  	 pp.Actual_Start_Time,
 	  	  	  	  	 pp.Actual_End_Time,
 	  	  	  	  	 pp.Path_Id,
 	  	  	  	  	 pp.PP_Status_Id
-------------------------------------------------------------------------------
-- 2.2  	  Add child POs   	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	     
-------------------------------------------------------------------------------
INSERT  	  @tProcessOrder (PPId,
 	  	 ProcessOrder,
 	  	 ParentPPId,
 	  	 StartTime,
 	  	 EndTime,
 	  	 PathId,
 	  	 PPStatusId)
SELECT  	  DISTINCT  	  pp.PP_Id,
   	    	  po.ProcessOrder,
   	    	  pp.Parent_PP_Id,
   	    	  COALESCE(MIN(pps.Start_Time), pp.Actual_Start_Time),
   	    	  COALESCE(pp.Actual_End_Time, @TimeStamp),
   	    	  pp.Path_Id,
   	    	  pp.PP_Status_Id
 	  	 FROM 	 dbo.Production_Plan pp 	  	  	  	 WITH 	 (NOLOCK)
  	  	 JOIN 	 @tProcessOrder po 
 	  	 ON 	  	 po.PPId 	  	  	 = pp.Parent_PP_Id
  	  	 LEFT 
 	  	 JOIN 	 dbo.Production_Plan_Starts pps 	  	 WITH 	 (NOLOCK)
 	  	 ON 	  	 pps.PP_Id = pp.PP_Id
  	  	 GROUP 
 	  	 BY  	  pp.PP_Id,
  	    	    	  po.ProcessOrder,
  	    	    	  pp.Parent_PP_Id,
  	    	    	  pp.Actual_Start_Time,
  	    	    	  pp.Actual_End_Time,
  	    	    	  pp.Path_Id,
  	    	    	  pp.PP_Status_Id
  	    	    	  
-------------------------------------------------------------------------------
-- 2.25 UDP by Path: Get Upload Parameters based on the path of the passed in process order(s)
-------------------------------------------------------------------------------
UPDATE   	 po  --Set the defaults for each path (bound and unbound) 	 
  SET 	 ReportCorrections = @ReportCorrections 	 ,
 	     -- SITE UDPAutoConfirm  = @AutoConfirm  	 ,
 	 ReportDeletions = @ReportDeletions 	 ,
 	 ReportByModifiedOn = @ReportByModifiedOn 	 ,
 	 TPSegmentName = @TPSegmentName 	 ,
 	 TPTestName = @TPTestName 	 ,
 	 TestPerformanceHeader = @TestPerformanceHeader 	 ,
 	 MaterialProducedActualPropertyHeader = @MaterialProducedActualPropertyHeader 	 ,
 	 MaterialConsumedActualPropertyHeader = @MaterialConsumedActualPropertyHeader 	 ,
 	 MPAStorageZone = @MPAStorageZone 	 ,
 	 PPWarningCommentAlias = @PPWarningCommentAlias 	 ,
 	 ConfProcSegmentId = @ConfProcSegmentId 	 ,
 	 ProdProcSegmentId = @ProdProcSegmentId 	 ,
 	 ConsProcSegmentId = @ConsProcSegmentId 	 ,
 	 FlgPadZeros = @FlgPadZeros 	 ,
 	 EventIdentification = @EventIdentification 	 ,
 	 DSEventNumId = @DSEventNumId 	 ,
 	 FlgConvertMCAUOMToBOMUOM = @FlgConvertMCAUOMToBOMUOM 	 ,
 	 FlgConvertMPAUOMToPSUOM = @FlgConvertMPAUOMToPSUOM 	 ,
 	 FlgSendDispositionTests = @FlgSendDispositionTests 	 ,
 	 FlgGroupMPAForOCMessage = @FlgGroupMPAForOCMessage 	 ,
--Treat Last Processed Timestamps special; there's no default for the subscription
  LastProcessedTimestampUploadIncrementalPP = '1970-01-01 00:00:00.000' ,
  LastProcessedTimestampUploadIncrementalCP = '1970-01-01 00:00:00.000' ,
 	 MPADefaultSiteId = @MPADefaultSiteId 	 ,
 	 MCADefaultSiteId = @MCADefaultSiteId 
 	 FROM @tProcessOrder po 	 
-- Now Update any Paths that have specific UDPs
DECLARE   	   TFVCursor INSENSITIVE CURSOR  
 	 For (SELECT tfv.KeyId, tfv.Table_Field_Id, tfv.Value
 	         FROM Table_Fields_Values tfv
 	         JOIN @tProcessOrder po on tfv.KeyId = po.PathId and tfv.TableId = @PrdExecPathTableID
 	         )
   	      	    For Read Only 
OPEN   	   TFVCursor
FETCH   	   NEXT FROM TFVCursor INTO @KeyId, @TableFieldId, @TableFieldValue
WHILE   	   @@Fetch_Status = 0
BEGIN
    IF @TableFieldId = -21 UPDATE @tProcessOrder SET ReportCorrections = @TableFieldValue WHERE PathId = @KeyId
    -- SITE UDP    IF @TableFieldId = -22 UPDATE @tProcessOrder SET   --SITE AutoConfirm = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -23 UPDATE @tProcessOrder SET ReportDeletions = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -24 UPDATE @tProcessOrder SET ReportByModifiedOn = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -30 UPDATE @tProcessOrder SET TPSegmentName = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -31 UPDATE @tProcessOrder SET TPTestName = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -32 UPDATE @tProcessOrder SET TestPerformanceHeader = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -33 UPDATE @tProcessOrder SET MaterialProducedActualPropertyHeader = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -34 UPDATE @tProcessOrder SET MaterialConsumedActualPropertyHeader = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -43 UPDATE @tProcessOrder SET MPAStorageZone = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -44 UPDATE @tProcessOrder SET PPWarningCommentAlias = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -45 UPDATE @tProcessOrder SET ConfProcSegmentId = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -46 UPDATE @tProcessOrder SET ProdProcSegmentId = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -47 UPDATE @tProcessOrder SET ConsProcSegmentId = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -48 UPDATE @tProcessOrder SET FlgPadZeros = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -49 UPDATE @tProcessOrder SET EventIdentification = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -67 UPDATE @tProcessOrder SET DSEventNumId = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -70 UPDATE @tProcessOrder SET FlgConvertMCAUOMToBOMUOM = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -72 UPDATE @tProcessOrder SET FlgConvertMPAUOMToPSUOM = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -75 UPDATE @tProcessOrder SET FlgSendDispositionTests = @TableFieldValue WHERE PathId = @KeyId
--Treat Last Processed Timestamps special; they will be defaulted to 1/1/1970 if not processed for this path yet
    ELSE IF @TableFieldId = -80 UPDATE @tProcessOrder SET LastProcessedTimestampUploadIncrementalPP = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -81 UPDATE @tProcessOrder SET LastProcessedTimestampUploadIncrementalCP = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -83 UPDATE @tProcessOrder SET FlgGroupMPAForOCMessage = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -84 UPDATE @tProcessOrder SET MPADefaultSiteId = @TableFieldValue WHERE PathId = @KeyId
    ELSE IF @TableFieldId = -85 UPDATE @tProcessOrder SET MCADefaultSiteId = @TableFieldValue WHERE PathId = @KeyId
 	   FETCH   	   NEXT FROM TFVCursor INTO @KeyId, @TableFieldId, @TableFieldValue
END
CLOSE   	      	   TFVCursor
DEALLOCATE   	   TFVCursor
-------------------------------------------------------------------------------
-- 2.3  	  Get run times and the relevant path for the POs   	    	    	    	    	    
-- *** WE ARE IGNORING THIS FOR RIGHT NOW - ASSUME CURRENT PATH IS VALID *** 
-------------------------------------------------------------------------------
-- Get the production plan history so we know which Path was assigned to a PO at a given time
-- Get all the production plan history records
INSERT @tProductionPlanPaths (  	  
 	  	 PPId,
 	  	 PathId,
 	  	 StartTime)
SELECT  	  pph.PP_Id,
  	  	  pph.Path_Id,
  	  	 MIN(pph.Modified_On)
 	 FROM 	 dbo.Production_Plan_History pph 	  	  	  	 WITH 	 (NOLOCK)
  	 JOIN 	 @tProcessOrder po 
 	 ON 	  	 pph.PP_Id = po.PPId
 	 GROUP 
 	 BY 	  	 pph.PP_Id, pph.Path_Id
 	 ORDER 
 	 BY 	  	 pph.PP_Id, MIN(pph.Modified_On)
SELECT @tRows = @@ROWCOUNT
UPDATE 	 pph1
 	  	 SET 	 StartTime   	  = CASE  	  WHEN   	  pph1.tId = 1  	    	    	    	    	  
  	    	    	    	  	    	    	    	    	  OR pph1.PPId <> pph3.PPId  	    	  	  	  
  	    	    	    	    	  	  	   	    	  THEN '1900-01-01 00:00:00'  	    	    	  
  	    	    	    	    	    	  	 END,
  	  	  	 EndTime   	  = CASE   	  WHEN pph1.PPId = pph2.PPId 
  	    	    	    	    	    	    	  	  	 THEN pph2.StartTime
  	    	    	    	    	    	  	 ELSE 	 NULL
  	    	    	    	    	    	  	 END
 	  	 FROM @tProductionPlanPaths pph1
  	  	 LEFT 
 	  	 JOIN @tProductionPlanPaths pph2 
 	  	 ON 	 pph2.tId = pph1.tId + 1
  	    	 AND pph1.tId < @tRows
  	  	 LEFT 
 	  	 JOIN @tProductionPlanPaths pph3 
 	  	 ON 	 pph3.tId = pph1.tId - 1
  	    	 AND pph1.tId > 1
-----------------------------------------------------------------------------------------------------
-- 2.4  	  Fill in some of the fields needed for the OrderConfirmation resultset
-----------------------------------------------------------------------------------------------------
UPDATE  	  PO
 	  	 SET  	 ProcessSegmentId = PO.ConfProcSegmentId,
 	  	  	  	 Confirm  	    	  = SS.Confirm,
 	  	  	  	 Complete  	    	  = SS.Complete,
 	  	  	  	 TECO  	    	    	  = SS.TECO
  	  	  	  	 FROM 	 @tProcessOrder PO
  	  	  	  	 LEFT  	  
 	  	  	  	 JOIN  	 @tStatus SS  	  
 	  	  	  	 ON 	  	 PO.PPStatusId  	  = SS.StatusId
-----------------------------------------------------------------------------------------------------
-- SECTION 3: GET TOTAL PRODUCTION  	    	    	     	    	    	    	    	    	    	    	  
-----------------------------------------------------------------------------------------------------
-- 3.1  	  Get ALL production events based on the production_plan_starts.  We need to get all of   	     
--  	  the events b/c at this poINT we don't know which components or source events have been  	     
--  	  modified.  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	     --
-----------------------------------------------------------------------------------------------------
--IF @EventIdentification IN (1, 3)
--BEGIN
  	  INSERT @tEvents (PPId,
  	    	    	  PUId,
  	    	    	  EventId,
  	    	    	  EventNum,
  	    	    	  StartTime,
  	    	    	  EndTime,
  	    	    	  Quantity,
  	    	    	  StartId,
  	    	    	  ProdId)
  	  SELECT  po.PPId,
  	    	    	  ee.PU_Id,
  	    	    	  ee.Event_Id,
  	    	    	  ee.Event_Num,
  	    	    	  ee.Start_Time,
  	    	    	  ee.Timestamp,
  	    	    	  ed.Initial_Dimension_X,
  	    	    	  ps.Start_Id,
  	    	    	  COALESCE(ee.applied_product, ps.Prod_Id) 	  	  
  	    	  	 FROM  	 @tProcessOrder po
  	    	  	 JOIN 	 dbo.Production_Plan_Starts pps 	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON 	  	 po.PPId 	  	 = pps.PP_Id
  	    	  	 JOIN 	 dbo.Prod_Units pu 	  	  	  	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON   	 pps.PU_Id 	 = pu.PU_Id
  	    	    	 AND 	  	 (Production_Type IS NULL
  	    	    	    	    	    	  OR Production_Type = 0)
  	    	  	 JOIN 	 dbo.Prdexec_Path_Units ppu 	  	  	  	 WITH 	 (NOLOCK) 	 
 	  	  	 ON  	  	 ppu.PU_Id = pu.PU_Id
  	    	    	 AND 	  	 ppu.Is_Production_PoINT = 1
  	    	  	 JOIN 	 @tProductionPlanPaths ppp 	  	  	  	 
 	  	  	 ON  	  	 ppu.Path_Id = ppp.PathId
   	  	  	 AND 	  	 pps.PP_Id = ppp.PPId
   	  	  	 AND 	  	 ppp.StartTime <= pps.Start_Time
   	  	  	 AND 	  	 (ppp.EndTime > pps.Start_Time
   	    	  	  	  	  	  OR ppp.EndTime IS NULL)
  	    	  	 JOIN 	 dbo.Events ee 	  	  	  	  	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON 	  	 ee.PU_Id = pps.PU_Id 	 
   	    	  	  AND 	 ee.TimeStamp >= pps.Start_Time
   	    	  	  AND 	 (ee.TimeStamp < pps.End_Time  	    	    	    	    	    	  
 	  	  	  	  	 OR 	 pps.End_Time IS NULL)
  	    	  	 JOIN 	 dbo.Event_Details ed 	  	  	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON 	  	 ee.Event_Id = ed.Event_Id
 	  	  	     AND  ed.PP_Id  	  IS NULL  	 
  	    	  	 LEFT 
 	  	  	 JOIN 	 dbo.Production_Starts ps 	  	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON   	  ee.PU_Id = ps.PU_Id
   	    	    	  AND 	 ee.TimeStamp >= ps.Start_Time
   	    	    	  AND 	 (ee.TimeStamp < ps.End_Time  	    	    	    	    	    	    	  
 	  	  	  	  	 OR 	 ps.End_Time IS NULL)
  	    	  	 WHERE po.EventIdentification IN (1, 3)
--END
-------------------------------------------------------------------------------
-- 3.2  	  Pull ALL records where Event_Details.PP_Id is set   	    	    	    	   
-------------------------------------------------------------------------------
--IF @EventIdentification IN (1,2)
--BEGIN
  	  INSERT @tEvents (PPId,
  	    	    	  PUId,
  	    	    	  EventId,
  	    	    	  EventNum,
  	    	    	  StartTime,
  	    	    	  EndTime,
  	    	    	  Quantity,
  	    	    	  StartId,
  	    	    	  ProdId)
  	  SELECT  po.PPId,
  	    	    	  ee.PU_Id,
  	    	    	  ee.Event_Id,
  	    	    	  ee.Event_Num,
  	    	    	  ee.Start_Time,
  	    	    	  ee.Timestamp,
  	    	    	  ed.Initial_Dimension_X,
  	    	    	  ps.Start_Id,
  	    	    	  COALESCE(ee.applied_product, ps.Prod_Id) 	  	  
--  	    	    	  ps.Prod_Id
  	    	  	 FROM  	  @tProcessOrder po
  	    	  	 JOIN   	  dbo.Event_Details ed 	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON 	  	 ed.PP_Id = po.PPId
  	    	  	 LEFT 
 	  	  	 JOIN 	 @tEvents te 
 	  	  	 ON 	  	 ed.Event_Id = te.EventId
 	  	  	   AND te.EventId IS NULL 
  	    	  	 JOIN  	 dbo.Events ee 	  	  	  	  	 WITH 	 (NOLOCK)
 	  	  	 ON 	  	 ee.Event_Id = ed.Event_Id
  	    	  JOIN 	  	 dbo.Prdexec_Path_Units ppu 	  	 WITH 	 (NOLOCK)
 	  	  ON  	  	 po.PathId = ppu.Path_Id  	    	  	  	  
   	  	  AND 	  	 ppu.PU_Id = ee.PU_Id  	    	    	  	  	  
   	  	  AND  	  	 ppu.is_Production_PoINT = 1  	    	  	  
  	    	  LEFT 
 	  	 JOIN 	  	 dbo.Production_Starts ps 	  	 WITH 	 (NOLOCK)
 	  	 ON   	  	 ee.PU_Id = ps.PU_Id
   	    	 AND 	  	  	 ee.TimeStamp >= ps.Start_Time
   	    	 AND 	  	  	 (ee.TimeStamp < ps.End_Time
   	    	  	  	   	  	  OR ps.End_Time IS NULL)
  	  	 WHERE po.EventIdentification IN (1,2)
--END
-------------------------------------------------------------------------------
-- 3.3  	  Get most recent modified on and update records  	     	    	    	    	   
-------------------------------------------------------------------------------
UPDATE 	 te
 	  	 SET  	  ModifiedOn = tem.ModifiedOn
 	  	 FROM 	 @tEvents te
  	  	 JOIN 	 (SELECT  	  Id  	  = te.Id,
  	    	  	  	  	  	    	  ModifiedOn  	  = CASE  	  
 	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN  	  MAX(eh.Modified_On) > MAX(edh.Modified_On)
 	  	  	  	  	  	   	    	    	    	    	    	    	 AND MAX(eh.Modified_On) > MAX(psh.Modified_On)
  	    	    	    	    	    	  	  	  	  	  	  	    	  	  	 THEN MAX(eh.Modified_On)
  	    	    	    	    	    	  	  	  	  	  	  	  	 WHEN  	  MAX(edh.Modified_On) > MAX(psh.Modified_On)
  	    	    	    	    	    	    	  	  	  	  	  	  	  	  	 THEN MAX(edh.Modified_On)
  	    	    	    	    	    	  	  	  	  	  	  	  	 ELSE MAX(psh.Modified_On)
 	  	  	  	  	  	   	    	    	    	    	  END
  	    	    	  	  	  	  	 FROM 	 @tEvents te
 	  	  	  	  	  	  	 LEFT
 	  	  	  	  	  	  	 JOIN 	 dbo.Event_History eh 	  	  	  	 WITH 	 (NOLOCK)
 	  	  	  	  	  	  	 ON 	  	 te.EventId = eh.Event_Id
 	  	  	  	  	  	  	 LEFT 
 	  	  	  	  	  	  	 JOIN 	 dbo.Event_Detail_History edh 	  	 WITH 	 (NOLOCK) 	 
 	  	  	  	  	  	  	 ON 	  	 te.EventId = edh.Event_Id
 	  	  	  	  	  	  	 LEFT 
 	  	  	  	  	  	  	 JOIN 	 dbo.Production_Starts_History psh 	 WITH 	 (NOLOCK)
 	  	  	  	  	  	  	 ON 	  	 te.StartId = psh.Start_Id
 	  	  	  	  	  	  	 GROUP 
 	  	  	  	  	  	  	 BY 	  	 te.Id) tem 
 	  	  	  	  	  	  	 ON 	  	 te.Id = tem.Id
-------------------------------------------------------------------------------
-- 3.4  	  Get test data based on production_plan_starts  	    	    	    	    	    	   
-------------------------------------------------------------------------------
INSERT @tVariables (  	  PPId,
   	    	  StartTime,
   	    	  EndTime,
   	    	  VarId,
   	    	  StartId,
   	    	  ProdId,
   	    	  Quantity)
 	  	 SELECT   po.PPId,
   	  	  	  	  pps.Start_Time,
   	  	  	  	  pps.End_Time,
   	  	  	  	  t.Var_Id,
   	  	  	  	  ps.Start_Id,
   	  	  	  	  ps.Prod_Id,
   	  	  	  	  SUM(isnull(convert(REAL, t.Result), 0))
 	  	  	  	 FROM  	  @tProcessOrder po
 	  	  	  	 JOIN 	 dbo.Production_Plan_Starts pps 	  	  	 WITH 	 (NOLOCK) 	 
 	  	  	  	 ON 	  	 po.PPId = pps.PP_Id
 	  	  	  	 JOIN 	 dbo.Prod_Units pu 	  	  	  	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON   	 pps.PU_Id = pu.PU_Id
   	    	    	    	 AND 	  	 Production_Type = 1
 	  	  	  	 JOIN 	 dbo.Prdexec_Path_Units ppu 	  	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON  	  	 ppu.PU_Id = pu.PU_Id
   	    	    	    	 AND  	 ppu.Is_Production_PoINT = 1
   	  	  	  	 JOIN 	 @tProductionPlanPaths ppp 	  	  	  	 
 	  	  	  	 ON  	  	 ppu.Path_Id = ppp.PathId
 	  	  	  	 AND 	  	 pps.PP_Id = ppp.PPId
 	  	  	  	 AND 	  	 ppp.StartTime <= pps.Start_Time
 	  	  	  	 AND 	  	 (ppp.EndTime > pps.Start_Time
 	  	  	  	  	  	  OR ppp.EndTime IS NULL)
 	  	  	  	 JOIN 	 dbo.Tests t 	  	  	  	  	  	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON 	  	 t.Var_Id = pu.Production_Variable
 	  	  	  	 AND 	  	 t.Result_On >= pps.Start_Time
 	  	  	  	 AND 	  	 (t.Result_On < pps.End_Time
 	  	  	  	  	  	 OR pps.End_Time IS NULL)
 	  	  	  	 LEFT 
 	  	  	  	 JOIN 	 dbo.Production_Starts ps 	  	  	  	 WITH 	 (NOLOCK)
 	  	  	  	 ON   	 pu.PU_Id = ps.PU_Id
 	  	  	  	 AND  	 t.Result_On >= ps.Start_Time
 	  	  	  	 AND  	 (t.Result_On < ps.End_Time
 	  	  	  	  	  	 OR  	  	 ps.End_Time IS NULL)
 	  	  	  	 GROUP 
 	  	  	  	 BY  	  po.PPId,
 	  	  	  	  	 pps.Start_Time,
 	  	  	  	  	 pps.End_Time,
 	  	  	  	  	 t.Var_Id,
 	  	  	  	  	 ps.Start_Id,
 	  	  	  	  	 ps.Prod_Id
-------------------------------------------------------------------------------
-- 3.5  	  Get the most recent Modified_On  	 
-- THIS performs poorly - improve as required - per an execution plan display, this took 36% of the time to run 	    	    	    	    	    	    	    	    	    	    	    	    	    	     
-------------------------------------------------------------------------------
UPDATE tv
 	 SET 	  	 tv.ModifiedOn = tvm.ModifiedOn
 	 FROM 	 @tVariables tv
  	 JOIN 	 (SELECT 	 Id  	    	    	  = tv.Id,
  	    	    	    	    	 ModifiedOn  	  = CASE  	  
 	  	  	  	  	  	  	  	  	  	 WHEN MAX(th.Modified_On) > MAX(psh.Modified_On)
  	    	    	    	    	    	    	    	    	    	    	  THEN MAX(th.Modified_On)
  	    	    	    	    	    	    	    	    	    	  	  ELSE MAX(psh.Modified_On)
  	    	    	    	    	    	    	    	    	 END
  	    	    	  	  	 FROM 	 @tVariables tv
  	    	    	 JOIN 	 dbo.Tests t 	  	 WITH 	 (NOLOCK)
 	  	  	  	  	 ON 	  	 tv.VarId = t.Var_Id
   	    	    	    	  	 AND 	  	 tv.StartTime <= t.Result_On
   	    	    	    	  	 AND 	  	 (tv.EndTime > t.Result_On
   	    	    	    	    	  	    	  	  OR tv.EndTime IS NULL)
  	    	    	 JOIN 	 dbo.Test_History th 
 	  	  	  	  	 ON 	  	 t.Test_Id = th.Test_Id
  	    	    	 JOIN 	 dbo.Production_Starts_History psh 
 	  	  	  	  	 ON 	  	 psh.Start_Id = tv.StartId
  	    	    	  	  	 GROUP 
 	  	  	  	  	 BY tv.Id) tvm 
 	  	  	  	  	 ON 	  	 tv.Id = tvm.Id
-------------------------------------------------------------------------------
-- SECTION 4: PRODUCTION PEFORMANCE  	    	     	    	    	    	    	    	    	    	  
-------------------------------------------------------------------------------
--IF @SubscriptionGroupId = @ProductionPerformanceGroupId 	  	 -- AJ:23-Jul-2009:Disabled
--BEGIN
IF @UploadType in (1,2)
BEGIN --@UploadType in (1,2)
 -------------------------------------------------------------------------------
 -- 4.1  	  Validate production event reports and calculate incremental quantity  	    	    	   
 -------------------------------------------------------------------------------
 -- Get previously reported consumption records
INSERT @tProductionHistory (  	  PPId,
   	    	  ProductionType,
   	    	  KeyId,
   	    	  ProdId,
   	    	  Quantity)
 	  SELECT  ec.PP_Id,
 	    	  	  	  ec.Production_Type,
 	    	  	  	  ec.Key_Id,
 	    	  	  	  ec.Prod_Id,
 	    	  	  	  SUM(ec.Quantity)
 	  	  	  FROM 	  dbo.ERP_Production ec 	  	  	 WITH 	 (NOLOCK)
 	  	  	  WHERE  	  ec.PP_Id = @PPId
 	    	  	  	  AND 	  ec.Confirmed = 1
 	  	  	 GROUP 
 	  	  	 BY  	  ec.PP_Id,
 	    	    	  	  	  ec.Production_Type,
 	    	    	  	  	  ec.Key_Id,
 	    	    	  	  	  ec.Prod_Id
-- Report new production, quantity changes and product changes
INSERT @tProduction (  	  PPId,
   	    	  ProductionType,
   	    	  KeyId,
   	    	  ProdId,
   	    	  Quantity,
   	    	  ModifiedOn)
 	  SELECT  te.PPId,
 	    	  	  	  0,
 	    	  	  	  te.EventId,
 	    	  	  	  te.ProdId,
 	    	  	  	  te.Quantity - isnull(tph.Quantity,0),
 	    	  	  	  te.ModifiedOn
  	  	  	 FROM @tEvents te
 	  	  	  	 LEFT 
 	  	  	 JOIN @tProductionHistory tph 
 	  	  	 ON  	  tph.ProductionType = 0
   	    	    	    	 AND te.PPId = tph.PPId
   	    	    	    	 AND te.EventId = tph.KeyId
   	    	    	    	 AND te.ProdId = tph.ProdId
 	  	  	 WHERE (te.Quantity - isnull(tph.Quantity, 0)) <> 0
-- Report product corrections
--IF @ReportCorrections = 1
--BEGIN
 	  INSERT @tProduction (  	  PPId,
 	    	    	    	    	    	    	  ProductionType,
 	    	    	    	    	    	    	  KeyId,
 	    	    	    	    	    	    	  ProdId,
 	    	    	    	    	    	    	  Quantity,
 	    	    	    	    	    	    	  ModifiedOn)
 	  SELECT  	  tph.PPId,
 	    	    	  	  tph.ProductionType,
 	    	    	  	  tph.KeyId,
 	    	    	  	  tph.ProdId,
 	    	    	  	  tph.Quantity * -1,
 	    	    	  	  te.ModifiedOn
 	  	 FROM 	 @tProductionHistory tph
 	  	    JOIN @tProcessOrder po on po.PPId = tph.PPId and po.ReportCorrections = 1
 	    	  JOIN 	 @tEvents te 
 	  ON  	 te.PPId = tph.PPId
   	  	  AND 	 te.EventId = tph.KeyId
   	  	  AND 	 te.ProdId <> tph.ProdId
 	  	  WHERE  	 tph.ProductionType = 0
 	    	  AND 	 tph.Quantity <> 0
--END
-- Report deleted events and process order changes
--IF @ReportDeletions = 1
--BEGIN
 	  INSERT @tProduction (  	  
 	  	 PPId,
   	    	    	 ProductionType,
   	    	    	 KeyId,
   	    	    	 ProdId,
   	    	    	 Quantity,
   	    	    	 ModifiedOn)
 	  SELECT  	 tph.PPId,
 	    	  	  	 tph.ProductionType,
 	    	  	  	 tph.KeyId,
 	    	  	  	 tph.ProdId,
 	    	  	  	 tph.Quantity * -1,
 	    	  	  	 @TimeStamp
 	  	  	  	 FROM 	 @tProductionHistory tph
 	  	  	  	 JOIN  @tProcessOrder po on tph.PPId = po.PPId and po.ReportDeletions = 1
 	    	  	  	 LEFT 
 	  	  	 JOIN 	 @tEvents te 
 	  	  	 ON  	  	 te.PPId = tph.PPId
 	    	    	  	 AND 	  	 te.EventId = tph.KeyId
 	  	  	  	 WHERE  	 tph.ProductionType = 0
 	    	    	  	 AND 	  	 te.EventId IS NULL
 	    	    	  	 AND 	  	 tph.quantity <> 0   	  -- filters out deleted events so they are not continuously reported
--END
-------------------------------------------------------------------------------
-- 4.2 Create production event MPA records  	    	    	    	    	    	    	    	    	    	    	    	    	    	     
-------------------------------------------------------------------------------
INSERT @tMPA (  	  EventId,
 	    	  StartTime,
 	    	  EndTime,
 	    	  PUId,
 	    	  ProdId,
 	    	  ProcessOrder,
 	    	  PPId,
 	    	  PathId,
 	    	  Quantity,
 	    	  EventNum,
 	    	  Batch,  	    	    	    	    	  
 	    	  EngUnitId,
 	    	  UoM,
 	    	  ProcessSegmentId)
SELECT   	  tp.KeyId,
 	  te.StartTime,
 	  te.EndTime,
 	  te.PUId,
 	  tp.ProdId,
 	  po.ProcessOrder,
 	  po.PPId,
 	  po.PathId,
 	  tp.Quantity,
 	  te.EventNum, 
 	  te.EventNum, 
 	  es.Dimension_X_Eng_Unit_Id,
 	  EU.Eng_Unit_Code,
 	  po.ProdProcSegmentId
FROM @tProduction tp
 	  JOIN @tEvents te 
 	 ON tp.KeyId = te.EventId
 	  JOIN @tProcessOrder po ON tp.PPId = po.PPId
 	   	    	  AND (  	  (po.ReportByModifiedOn = 1 AND tp.ModifiedOn > po.LastProcessedTimestampUploadIncrementalPP)
 	    	    	    	  OR po.ReportByModifiedOn = 0)
 	  JOIN dbo.Event_Configuration ec 	 WITH 	 (NOLOCK) ON   	  ec.PU_Id = te.PUId
 	    	    	    	    	  AND ec.ET_Id = 1
 	  JOIN dbo.Event_Subtypes es 	  	  	 WITH 	 (NOLOCK) ON 	  	 es.Event_Subtype_Id = ec.Event_Subtype_Id
 	  LEFT
 	  JOIN dbo.Engineering_Unit EU 	  	 WITH 	 (NOLOCK) ON es.Dimension_X_Eng_Unit_Id = EU.Eng_Unit_Id
WHERE  	  tp.ProductionType = 0
-- Report deleted records
--IF @ReportDeletions = 1
--BEGIN
 	  INSERT @tMPA (  	  EventId,
 	    	  StartTime,
 	    	  EndTime,
 	    	  PUId,
 	    	  ProdId,
 	    	  ProcessOrder,
 	    	  PPId,
 	    	  PathId,
 	    	  Quantity,
 	    	  EventNum,
 	    	  Batch,  	    	    	    	    	  
 	    	  EngUnitId,
 	    	  UoM,
 	    	  ProcessSegmentId)
 	  SELECT   	  tp.KeyId,
 	    	  eh.Start_Time,
 	    	  eh.TimeStamp,
 	    	  eh.PU_Id,
 	    	  tp.ProdId,
 	    	  po.ProcessOrder,
 	    	  po.PPId,
 	    	  po.PathId,
 	    	  tp.Quantity,
 	    	  eh.event_num,
 	    	  eh.event_num,
 	    	  es.Dimension_X_Eng_Unit_Id,
 	    	  EU.Eng_Unit_Code,
 	    	  po.ProdProcSegmentId
 	  FROM @tProduction tp
 	    	  JOIN @tProcessOrder po ON tp.PPId = po.PPId 
 	    	             AND po.ReportDeletions = 1
 	    	    	         AND (  	  (po.ReportByModifiedOn = 1 AND tp.ModifiedOn > po.LastProcessedTimestampUploadIncrementalPP)
 	    	    	    	    	          OR po.ReportByModifiedOn = 0)
 	    	  JOIN dbo.Event_History eh WITH 	 (NOLOCK) ON tp.KeyId = eh.Event_Id
 	    	    	    	    	    	  AND eh.dbtt_id = 4
 	    	  JOIN dbo.Event_Configuration ec WITH 	 (NOLOCK)  ON   	  ec.PU_Id = eh.PU_Id
 	    	    	    	    	    	  AND ec.ET_Id = 1
 	    	  JOIN dbo.Event_Subtypes es WITH 	 (NOLOCK) ON es.Event_Subtype_Id = ec.Event_Subtype_Id
 	    	  LEFT
 	    	  JOIN dbo.Engineering_Unit EU  WITH 	 (NOLOCK) ON es.Dimension_X_Eng_Unit_Id = EU.Eng_Unit_Id
 	  WHERE  	  tp.ProductionType = 0
--END
-------------------------------------------------------------------------------
-- 4.3  	  Validate variable test reports and calculate incremental quantity  	    	 
-------------------------------------------------------------------------------
-- Report incremental quantity consumption if the quantity has changed
INSERT @tProduction (  	  PPId,
 	    	    	    	    	    	  ProductionType,
 	    	    	    	    	    	  KeyId,
 	    	    	    	    	    	  ProdId,
 	    	    	    	    	    	  Quantity,
 	    	    	    	    	    	  ModifiedOn)
SELECT  	  tvt.PPId,
 	    	  1,
 	    	  tvt.VarId,
 	    	  tvt.ProdId,
 	    	  tvt.Quantity - isnull(tph.Quantity,0),
 	    	  tvt.ModifiedOn
FROM (  	  SELECT  	  PPId  	    	  = tv.PPId,
 	    	    	    	  	  	  VarId  	    	  = tv.VarId,
 	    	    	    	  	  	  ProdId  	    	  = tv.ProdId,
 	    	    	    	  	  	  Quantity  	  = SUM(tv.Quantity),
 	    	    	    	  	  	  ModifiedOn  	  = MAX(tv.ModifiedOn)
 	    	  FROM @tVariables tv
 	    	  GROUP BY  	  tv.PPId,
 	    	    	    	    	  tv.VarId,
 	    	    	    	    	  tv.ProdId ) tvt
 	  LEFT JOIN @tProductionHistory tph ON  	  tph.ProductionType = 1
 	    	    	    	    	    	    	    	    	    	    	  AND tvt.PPId = tph.PPId
 	    	    	    	    	    	    	    	    	    	    	  AND tvt.VarId = tph.KeyId
 	    	    	    	    	    	    	    	    	    	    	  AND tvt.ProdId = tph.ProdId
WHERE  	  (tvt.Quantity - isnull(tph.Quantity, 0)) <> 0
--IF @ReportCorrections = 1
--BEGIN
 	  -- Report product corrections
 	  INSERT @tProduction (  	  PPId,
 	    	    	    	   	    	    	  ProductionType,
 	    	    	    	    	    	    	  KeyId,
 	    	    	    	    	    	    	  ProdId,
 	    	    	    	    	    	    	  Quantity,
 	    	    	    	    	    	    	  ModifiedOn)
 	  SELECT  	  tph.PPId,
 	    	    	  tph.ProductionType,
 	    	    	  tph.KeyId,
 	    	    	  tph.ProdId,
 	    	    	  tph.Quantity * -1,
 	    	    	  tvt.ModifiedOn
 	  FROM @tProductionHistory tph
 	      JOIN @tProcessOrder po on tph.PPId = po.PPId and po.ReportCorrections = 1
 	    	  JOIN (  	  SELECT  	  PPId  	    	  = tv.PPId,
 	    	    	    	    	    	  VarId  	    	  = tv.VarId,
 	    	    	    	    	    	  ProdId  	    	  = tv.ProdId,
 	    	    	    	    	    	  Quantity  	  = SUM(tv.Quantity),
 	    	    	    	    	    	  ModifiedOn  	  = MAX(ModifiedOn)
 	    	    	    	  FROM @tVariables tv
 	    	    	    	  GROUP BY  	  tv.PPId,
 	    	    	    	    	    	    	  tv.VarId,
 	    	    	    	    	    	    	  tv.ProdId ) tvt ON  	  tvt.PPId = tph.PPId
 	    	    	    	    	    	    	    	    	    	    	    	  AND tvt.VarId = tph.KeyId
 	    	    	    	    	    	    	    	    	    	    	    	  AND tvt.ProdId <> tph.ProdId
 	  WHERE  	  tph.ProductionType = 1
 	    	    	  AND tph.Quantity <> 0
--END
-- Report process order changes
--IF @ReportDeletions = 1
--BEGIN
 	  INSERT @tProduction (  	  PPId,
 	    	    	    	    	    	    	  ProductionType,
 	    	    	    	    	    	    	  KeyId,
 	    	    	    	    	    	    	  ProdId,
 	    	    	    	    	    	    	  Quantity,  	    	    	    	    	    	    	    	  
 	  	  	  	  	  	  ModifiedOn)
 	  SELECT  tph.PPId,
 	    	    	  tph.ProductionType,
 	    	    	  tph.KeyId,
 	    	    	  tph.ProdId,
 	    	    	  tph.Quantity * -1,
 	    	    	  @TimeStamp
 	  FROM @tProductionHistory tph
 	      JOIN @tProcessOrder po on tph.PPId = po.PPId and po.ReportDeletions = 1
 	    	  JOIN (  	  SELECT  	  PPId  	    	  = tv.PPId,
 	    	    	    	    	    	  VarId  	    	  = tv.VarId,
 	    	    	    	    	    	  ProdId  	    	  = tv.ProdId,
 	    	    	    	    	    	  Quantity  	  = SUM(tv.Quantity)
 	    	    	    	  FROM @tVariables tv
 	    	    	    	  GROUP BY  	  tv.PPId,
 	    	    	    	    	    	    	  tv.VarId,
 	    	    	    	    	    	    	  tv.ProdId ) tvt ON  	  tvt.PPId = tph.PPId
 	    	    	    	    	    	    	    	    	    	    	    	  AND tvt.VarId = tph.KeyId
 	  WHERE  	  tph.ProductionType = 1
 	    	    	  AND tvt.VarId IS NULL
--END
-------------------------------------------------------------------------------
-- 4.4 Insert tests INTo MPA  	    	    	    	    	    	    	    	    	    	    	    	 
-------------------------------------------------------------------------------
INSERT @tMPA (  	  StartTime,
 	  EndTime,
 	  PUId,
 	  ProdId,
 	  ProcessOrder,
 	  PPId,
 	  PathId,
 	  Quantity,
 	  EngUnitId,
 	  UoM,
 	  ProcessSegmentId)
SELECT   	  po.StartTime,
 	  po.EndTime,
 	  v.PU_Id,
 	  tp.ProdId,
 	  po.ProcessOrder,
 	  po.PPId,
 	  po.PathId,
 	  tp.Quantity,
 	  EU.Eng_Unit_Id,
 	  v.Eng_Units,
 	  po.ProdProcSegmentId
FROM @tProduction tp
 	  JOIN @tProcessOrder po ON tp.PPId = po.PPId
 	    	  AND (  	  (po.ReportByModifiedOn = 1 AND tp.ModifiedOn > po.LastProcessedTimestampUploadIncrementalPP)
 	    	    	    	  OR po.ReportByModifiedOn = 0)
 	  JOIN dbo.Variables v  WITH 	 (NOLOCK) ON v.Var_Id = tp.KeyId
 	  LEFT
 	  JOIN dbo.Engineering_Unit EU  WITH (NOLOCK) ON v.Eng_Units = EU.Eng_Unit_Code
WHERE  	  tp.ProductionType = 1
----------------------------------------------------------------------------
-- 4.5  	  Retrieve the Product Code for the mpa records  	    	    	     	    	    	    	    	    	    	    	  
----------------------------------------------------------------------------
UPDATE  mpa
 	 SET 	  	 Product  	  = COALESCE(dsx.Foreign_Key, p.Prod_Code),
 	  	  	  	 SAPProduct  	  = COALESCE(dsx.Foreign_Key, p.Prod_Code)
 	 FROM 	 @tMPA mpa
 	  	 JOIN 	 dbo.Products p WITH (NOLOCK) ON mpa.ProdId = p.Prod_Id
 	  	 LEFT 
 	 JOIN 	 dbo.Data_Source_XRef dsx WITH (NOLOCK) ON   	  mpa.ProdId = dsx.Actual_Id
   	  	  AND  	  dsx.Table_Id = @ProductsTableId
   	  	  AND  	  dsx.DS_Id = @DataSourceId
----------------------------------------------------------------------------
-- 4.6  	  Retrieve the Storage Zone for the mpa records  	    	    	    	     	    	    	    	    	    	   	   
-- If it could not find from the variable, then use the PP.UDP
----------------------------------------------------------------------------
DECLARE   	   mpaCursor INSENSITIVE CURSOR   
  For (SELECT DISTINCT mpa.PPId, vv.Var_Id, mpa.EndTime, po.MPAStorageZone, mpa.PUId
 	       FROM  	  @tMPA mpa
 	         JOIN  @tProcessOrder po on po.PPId = mpa.PPId
 	  	       JOIN 	 dbo.Prod_Units pu WITH (NOLOCK) ON   	  mpa.PUId = pu.PU_Id
 	    	    	    	       OR  	  mpa.PUId = pu.Master_Unit
   	       JOIN 	 dbo.Variables vv WITH (NOLOCK) ON   	  pu.PU_Id = vv.PU_Id
   	    	    	       AND  vv.Test_Name = po.MPAStorageZone 
   	    	    	       AND  vv.Event_Type = 1
          )
 	      	      For Read Only 
OPEN   	   mpaCursor
FETCH   	   NEXT FROM mpaCursor INTO @cPPId ,@cVarId,@cResultOn,@cmpaStorageZone,@cPUId
WHILE   	   @@Fetch_Status = 0
BEGIN
  SELECT @cResult = ISNULL(Result,@cmpaStorageZone)
    FROM Tests t
    WHERE t.Var_Id = @cVarId AND t.Result_On = @cResultOn
  -- If it could not find from the variable and PP.UDP, then use the PU.UDP  
  IF @@ROWCOUNT = 0 OR @cResult IS NULL 
    BEGIN
      SELECT @cResult = TFV.value
        FROM dbo.Table_Fields_Values 	 TFV 	 WITH (NOLOCK)
        WHERE TFV.KeyId = @cPUId
          AND tfv.Table_Field_Id = -43
          AND 	 TFV.TableId 	  	  	 = @ProdUnitsTableId
    END
  UPDATE mpa
 	   SET  	  StorageZone = @cResult
    WHERE PPId = @cPPId
  FETCH   	   NEXT FROM mpaCursor INTO @cPPId ,@cVarId,@cResultOn,@cmpaStorageZone,@cPUId
END
CLOSE   	      	   mpaCursor
DEALLOCATE   	   mpaCursor
----------------------------------------------------------------------------
-- 4.7A. For sites where the S88 interface is implemented, the SP should 
-- report the virtual batch 
-- event Num instead the UP (unit procedure) event num.
----------------------------------------------------------------------------
IF  	  @FlgPAS88InterfaceImplemented = 1
BEGIN
 	  UPDATE  mpa
 	  	  	 SET  	  Batch = ee.Event_Num
 	  	  	 FROM  	  @tMPA mpa
 	    	  	 JOIN 	  dbo.Event_Components ec WITH 	 (NOLOCK) ON mpa.EventId = ec.Event_Id
 	    	    	 JOIN 	  dbo.Events ee 	  	  	 WITH (NOLOCK) ON ec.Source_Event_Id = ee.Event_Id
 	    	    	 JOIN 	  dbo.Prod_Units pu 	  	 WITH (NOLOCK) ON  	  ee.PU_Id = pu.PU_Id
 	    	    	    	    	  AND  	  pu.Extended_Info LIKE '%BATCH:%'
END
----------------------------------------------------------------------------
-- Update event numbers from the xref table
----------------------------------------------------------------------------
UPDATE 	  mpa
 	 SET  	  EventNum = COALESCE(dsx.Foreign_Key, mpa.EventNum)
 	 FROM  	  @tMPA mpa
 	   JOIN @tProcessOrder po on po.PPId = mpa.PPId
 	  	 JOIN  	  dbo.Data_Source_XRef dsx WITH 	 (NOLOCK)
 	 ON  	  mpa.EventId = dsx.Actual_Id
   	  	  AND  	  dsx.Table_Id = @EventsTableId
   	  	  AND  	  dsx.DS_Id = po.DSEventNumId
----------------------------------------------------------------------------
-- 4.8  	  Retrieve the MPAP  	    	    	    	     	    	    	    	    	    	    	    	  
----------------------------------------------------------------------------
INSERT  	  @tMPAP (EventId,
 	    	  PropertyName,
 	    	  Value,  	    	    	  DataType,
 	    	  UoM,
 	    	  TestId,
 	  ParentMPAId)
SELECT   	  mpa.EventId,
 	    	    	  X.Foreign_Key,
 	    	  tt.Result,
 	    	  CASE  	  WHEN vv.Data_Type_Id IN (1, 2) THEN 'float'
 	    	    	    	  ELSE 'string'
 	    	    	    	  END,
 	    	  vv.Eng_Units,
 	    	  tt.Test_Id,
 	  mpa.id
FROM  	  @tMPA mpa
JOIN @tProcessOrder po on po.PPId = mpa.PPId
JOIN   	  dbo.Data_Source_Xref X   	 WITH 	 (NOLOCK) ON   	  X.DS_Id   	    	  = @DataSourceId
 	    	    	    	  AND  	  X.Table_Id   	    	  = @VariablesTableId
 	    	    	    	  AND  	  X.Subscription_Id  	  = @OEUploadSubscription --was @SubscriptionId 
   	    	    	  AND  	  X.XML_Header  	    	  = po.MaterialProducedActualPropertyHeader
JOIN   	  dbo.Variables vv   	  	  	 WITH 	 (NOLOCK) ON   	  mpa.PUId  	  = vv.pu_id
 	    	    	    	  AND  	  VV.Var_id  	  = X.Actual_Id  	    	    	    	  
JOIN 	 dbo.Tests tt 	  	  	  	 WITH 	 (NOLOCK) ON  	  tt.Var_Id = vv.Var_Id
 	    	    	    	    	    	    	    	  	  	  	  	  	 AND  	  tt.Result_On = mpa.EndTime
UPDATE  	  @tMPAP
SET  	  PropertyName = LEFT(PropertyName, CHARINDEX(';', PropertyName) - 1)
WHERE  	  CHARINDEX(';', PropertyName) > 1
--END
END --@UploadType in (1,2)
-------------------------------------------------------------------------------  	    
-- SECTION 5: CONSUMPTION PERFORMANCE  	    	     	    	    	    	    	    	    	    	  
-------------------------------------------------------------------------------  	    
-- IF @SubscriptionGroupId = @ConsumptionPerformanceGroupId 	  	 -- AJ:23-Jul-2009:Disabled
IF @UploadType in (1,3)
BEGIN --IF @UploadType in (1,3)
  	  -------------------------------------------------------------------------------  	    
  	  -- 5.1  	  Retrieve the first level of the genealogy tree  	    	    	    	    	    	    	    	    	    	    	     
  	  -------------------------------------------------------------------------------  	    
  	  -- Retrieve the 1st level
  	  INSERT  	  @tComponents (  	  PPId,
  	    	    	    	  CompId,
  	    	    	    	  SourceEventId,
  	    	    	    	  EventId,
  	    	    	    	  RAC,
  	    	    	    	  Quantity)
  	  SELECT  te.PPId,
  	    	  ec.Component_Id,
  	    	  ec.Source_Event_Id,
  	    	  ec.Event_Id,
  	    	  COALESCE(ec.Report_As_Consumption, 0),
  	    	  COALESCE(ec.Dimension_X, 0)
  	    	  FROM @tEvents te 	 
  	    	  JOIN dbo.Event_Components ec  WITH 	 (NOLOCK) ON ec.Event_Id = te.EventId
  	 -------------------------------------------------------------------------------  	     	 
  	  -- 5.2  	  Calculate the ratio if we're moving up the tree  	  (i.e. RAC = 0)  	    	    	    	   	    	    	     
  	  -------------------------------------------------------------------------------  	    
  	  -- Get the associated waste events
  	  INSERT  	  @tWaste (  	  EventId,
  	    	    	    	    	    	  Quantity)
  	  SELECT  wed.Event_Id,
  	    	    	  SUM(wed.Amount)
  	  FROM dbo.Waste_Event_Details wed WITH 	 (NOLOCK)
  	    	  JOIN (  	  SELECT DISTINCT  	  SourceEventId  	  = tc.SourceEventId
  	    	    	    	  FROM @tComponents tc 
  	    	    	    	  WHERE tc.RAC = 0) tc ON tc.SourceEventId = wed.Event_Id
  	  GROUP BY  	  wed.Event_Id,
  	    	    	    	  wed.Amount
  	  UPDATE tc
  	  SET  	  Ratio   	    	  = CASE
  	    	  WHEN  	  ped.Initial_Dimension_X IS NOT NULL
  	    	    	  AND ped.Initial_Dimension_X > 0
  	    	    	  AND (ped.Initial_Dimension_X - COALESCE(tw.Quantity, 0)) <> 0 
 	    	    	  THEN  	  COALESCE(tc.Quantity, 0)/(ped.Initial_Dimension_X - COALESCE(tw.Quantity, 0))
  	    	    	  ELSE 1 	 
  	    	  END
  	  FROM @tComponents tc
  	    	  LEFT JOIN dbo.Event_Details ped  WITH 	 (NOLOCK) ON ped.Event_Id = tc.SourceEventId
  	    	  LEFT JOIN @tWaste tw ON tw.EventId = tc.SourceEventId
  	  WHERE tc.RAC = 0
 	 ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  -- 5.3  	  Retrieve the last modification time  	    	 
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  UPDATE tc
  	  SET ModifiedOn = tch.ModifiedOn
  	  FROM @tComponents tc
  	    	  JOIN (  	  SELECT  	  Id  	    	    	  = tc.Id,
  	    	    	    	    	    	  ModifiedOn  	  = MAX(ech.Modified_On)
  	    	    	    	  FROM @tComponents tc
  	    	    	    	    	  LEFT JOIN Event_Component_History ech WITH 	 (NOLOCK) ON  	  ech.Component_Id = tc.CompId
  	    	    	    	  WHERE dbo.fnS95_ColumnUpdated(convert(binary(8), ech.Column_Updated_Bitmask), @ECDimXOP) = 1
  	    	    	    	  GROUP BY tc.Id) tch ON tc.Id = tch.Id
  	  -- Waste Events
  	  UPDATE tc
  	  SET ModifiedOn = CASE   	  WHEN wdh.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	  THEN wdh.ModifiedOn
  	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	   	    	  END
  	  FROM @tComponents tc
  	    	  JOIN (  	  SELECT  EventId  	    	  = wed.Event_Id,
  	    	    	    	    	    	  ModifiedOn  	  = MAX(wedh.Modified_On)
  	    	    	    	  FROM dbo.Waste_Event_Details wed 	 WITH 	 (NOLOCK)
  	    	    	    	    	  JOIN (  	  SELECT DISTINCT  	  SourceEventId  	  = tc.SourceEventId
  	    	    	    	    	    	    	  FROM @tComponents tc 
  	    	    	    	    	    	    	  WHERE tc.RAC = 0) tc ON tc.SourceEventId = wed.Event_Id
  	    	    	    	    	  LEFT JOIN Waste_Event_Detail_History wedh  WITH (NOLOCK) ON wed.WED_Id = wedh.WED_Id
  	    	    	    	  WHERE dbo.fnS95_ColumnUpdated(convert(binary(8), wedh.Column_Updated_Bitmask), @WEDAmountOP) = 1
  	    	    	    	  GROUP BY wed.Event_Id) wdh ON tc.SourceEventId = wdh.EventId
  	  WHERE tc.RAC = 0
  	  -- Event Details
  	  UPDATE tc
  	  SET ModifiedOn = CASE   	  WHEN edh.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	  THEN edh.ModifiedOn
  	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	    	    	  END
  	  FROM @tComponents tc
  	    	  JOIN (  	  SELECT  EventId  	    	  = edh.Event_Id,
  	    	    	    	    	    	  ModifiedOn  	  = MAX(edh.Modified_On)
  	    	    	    	  FROM @tComponents tc
  	    	    	    	    	  LEFT JOIN dbo.Event_Detail_History edh WITH (NOLOCK) ON edh.Event_Id = tc.SourceEventId
  	    	    	    	  WHERE  	  tc.RAC = 0
  	    	    	    	    	    	  AND dbo.fnS95_ColumnUpdated(convert(binary(8), edh.Column_Updated_Bitmask), @EDDimXOP) = 1
  	    	    	    	  GROUP BY edh.Event_Id) edh ON tc.SourceEventId = edh.EventId
  	  WHERE tc.RAC = 0
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  -- 5.4  	  Loop through the remaining levels of the tree and recalculate 
 	 -- the ratio at each step  	    
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  UPDATE  	  @tComponents
  	  SET  	  RAC = -1
  	  WHERE  	  RAC = 0
  	  
  	  SELECT  	  @Cnt = 0  	  -- This is a sanity check to keep the next loop from potentially being infinite
  	  WHILE (  	  @Cnt < 10
  	    	    	  AND  	  (  	  SELECT  	  COUNT(*)
  	    	    	    	    	  FROM  	  @tComponents
  	    	    	    	    	  WHERE  	  RAC = -1) > 0)
  	  BEGIN
  	    	  SELECT  	  @Cnt = @Cnt + 1
  	  
  	    	  -- Insert subsequent levels
  	    	  INSERT  	  @tComponents (  	  PPId,
  	    	    	    	    	    	    	    	  CompId,
  	    	    	    	    	    	    	    	  SourceEventId,
  	    	    	    	    	    	    	    	  EventId,
  	    	    	    	    	    	    	    	  RAC,
  	    	    	    	    	    	    	    	  Quantity,
  	    	    	    	    	    	    	    	  ModifiedOn)
  	    	  SELECT  tc.PPId,
  	    	    	    	  ec.Component_Id,
  	    	    	    	  ec.Source_Event_Id,
  	    	    	    	  tc.EventId,
  	    	    	    	  COALESCE(ec.Report_As_Consumption, 0),
  	    	    	    	  COALESCE(ec.Dimension_X, 0)*tc.Ratio,
  	    	    	    	  tc.ModifiedOn
  	    	  FROM @tComponents tc
  	    	    	  JOIN dbo.Event_Components ec WITH (NOLOCK) ON ec.Event_Id = tc.SourceEventId
  	    	  WHERE   	  tc.RAC = -1
  	    	    	  
  	    	  -- Get the associated waste events
  	    	  INSERT  	  @tWaste (  	  EventId,
  	    	    	    	    	    	    	  Quantity)
  	    	  SELECT  wed.Event_Id,
  	    	    	    	  SUM(wed.Amount)
  	    	  FROM dbo.Waste_Event_Details wed 	 WITH (NOLOCK)
  	    	    	  JOIN (  	  SELECT DISTINCT  	  SourceEventId  	  = tc.SourceEventId
  	    	    	    	    	  FROM @tComponents tc 
  	    	    	    	    	  WHERE tc.RAC = 0) tc ON tc.SourceEventId = wed.Event_Id
  	    	  GROUP BY  	  wed.Event_Id,
  	    	    	    	    	  wed.Amount
  	  
  	    	  -- Calculate the current and previous ratio
  	    	  UPDATE tc
  	    	  SET  	  Ratio   	    	  = CASE
  	    	    	    	    	    	    	  WHEN  	  ped.Initial_Dimension_X IS NOT NULL
  	    	    	    	    	    	    	    	    	  AND (ped.Initial_Dimension_X - COALESCE(tw.Quantity, 0)) <> 0
  	    	    	    	    	    	    	    	  THEN  	  tc.Quantity
  	    	    	    	    	    	    	    	    	    	  / (ped.Initial_Dimension_X - COALESCE(tw.Quantity, 0))
  	    	    	    	    	    	    	  ELSE 1
  	    	    	    	    	    	    	  END
  	    	  FROM @tComponents tc
  	    	    	  LEFT JOIN dbo.Event_Details ped WITH (NOLOCK) ON ped.Event_Id = tc.SourceEventId
  	    	    	  LEFT JOIN @tWaste tw ON tw.EventId = tc.SourceEventId
  	    	  WHERE tc.RAC = 0
  	  
  	    	  -- Retrieve the last modification time
  	    	  -- Event Components last modification time
  	    	  UPDATE tc
  	    	  SET ModifiedOn = CASE  	  WHEN tch.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	    	  THEN tch.ModifiedOn
  	    	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	    	    	    	  END
  	    	  FROM @tComponents tc
  	    	    	  JOIN (  	  SELECT  	  Id  	    	    	  = tc.Id,
  	    	    	    	    	    	    	  ModifiedOn  	  = MAX(ech.Modified_On)
  	    	    	    	    	  FROM @tComponents tc
  	    	    	    	    	    	  LEFT JOIN Event_Component_History ech WITH (NOLOCK) ON  	  ech.Component_Id = tc.CompId
  	    	    	    	    	  WHERE dbo.fnS95_ColumnUpdated(convert(binary(8), ech.Column_Updated_Bitmask), @ECDimXOP) = 1
  	    	    	    	    	  GROUP BY tc.Id) tch ON tc.Id = tch.Id
  	  
  	    	  -- Waste Events last modification time
  	    	  UPDATE tc
  	    	  SET ModifiedOn = CASE   	  WHEN wdh.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	    	  THEN wdh.ModifiedOn
  	    	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	    	    	    	  END
  	    	  FROM @tComponents tc
  	    	    	  JOIN (  	  SELECT  EventId  	    	  = wed.Event_Id,
  	    	    	    	    	    	    	  ModifiedOn  	  = MAX(wedh.Modified_On)
  	    	    	    	    	  FROM dbo.Waste_Event_Details wed WITH (NOLOCK)
  	    	    	    	    	    	  JOIN (  	  SELECT DISTINCT  	  SourceEventId  	  = tc.SourceEventId
  	    	    	    	    	    	    	    	  FROM @tComponents tc 
  	    	    	    	    	    	    	    	  WHERE tc.RAC = 0) tc ON tc.SourceEventId = wed.Event_Id
  	    	    	    	    	    	  LEFT JOIN Waste_Event_Detail_History wedh WITH (NOLOCK) ON wed.WED_Id = wedh.WED_Id
  	    	    	    	    	  WHERE dbo.fnS95_ColumnUpdated(convert(binary(8), wedh.Column_Updated_Bitmask), @WEDAmountOP) = 1
  	    	    	    	    	  GROUP BY wed.Event_Id) wdh ON tc.SourceEventId = wdh.EventId
  	    	  WHERE tc.RAC = 0
  	  
  	    	  -- Event Details last modification time
  	    	  UPDATE tc
  	    	  SET ModifiedOn = CASE   	  WHEN edh.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	    	  THEN edh.ModifiedOn
  	    	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	    	    	    	  END
  	    	  FROM @tComponents tc
  	    	    	  JOIN (  	  SELECT  EventId  	    	  = edh.Event_Id,
  	    	    	    	    	    	    	  ModifiedOn  	  = MAX(edh.Modified_On)
  	    	    	    	    	  FROM @tComponents tc
  	    	    	    	    	    	  LEFT JOIN dbo.Event_Detail_History edh WITH (NOLOCK) ON edh.Event_Id = tc.SourceEventId
  	    	    	    	    	  WHERE  	  tc.RAC = 0
  	    	    	    	    	    	    	  AND dbo.fnS95_ColumnUpdated(convert(binary(8), edh.Column_Updated_Bitmask), @EDDimXOP) = 1
  	    	    	    	    	  GROUP BY edh.Event_Id) edh ON tc.SourceEventId = edh.EventId
  	    	  WHERE tc.RAC = 0
  	  
  	    	  -- Delete the old ones 
  	    	  DELETE
  	    	  FROM @tComponents
  	    	  WHERE RAC = -1
  	  
  	    	  UPDATE  	  @tComponents
  	    	  SET  	  RAC = -1  	  
  	    	  WHERE RAC = 0
  	  END
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  -- 5.5  	  Get the product id  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	     
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  UPDATE tc
  	  SET  	  ProdId = COALESCE(e.Applied_Product, ps.Prod_Id)  	 
  	  FROM @tComponents tc
  	    	  JOIN dbo.Events e WITH (NOLOCK) ON e.Event_Id = tc.SourceEventId 
  	    	  JOIN dbo.Production_Starts ps WITH (NOLOCK) ON  	  e.PU_Id = ps.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	  AND ps.Start_Time <= e.TimeStamp
  	    	    	    	    	    	    	    	    	    	    	    	  AND (  	  ps.End_Time > e.TimeStamp
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  OR ps.End_Time IS NULL) 
  	  WHERE tc.RAC = 1
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  -- 5.6  	  Get the product modification times  	    	    	    	    	    	    	    	    	    	    	    	    	    	     
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  UPDATE tc
  	  SET ModifiedOn = CASE  	  WHEN eh.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	  THEN eh.ModifiedOn
  	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	   	    	  END
  	  FROM @tComponents tc
  	    	  JOIN (  	  SELECT  	  Id  	    	    	  = tc.Id,
  	    	    	    	    	    	  ModifiedOn  	  = MAX(eh.Modified_On)
  	    	    	    	  FROM @tComponents tc
  	    	    	    	    	  LEFT JOIN dbo.Event_History eh WITH (NOLOCK) ON eh.Event_Id = tc.SourceEventId 
  	   	   	    	  WHERE  	  tc.RAC = 1
  	    	    	    	    	    	  AND dbo.fnS95_ColumnUpdated(convert(binary(8), eh.Column_Updated_Bitmask), @EAppProdOP) = 1
  	    	    	    	  GROUP BY tc.Id) eh ON tc.Id = eh.Id
  	  WHERE tc.RAC = 1
  	  UPDATE tc
  	  SET ModifiedOn = CASE  	  WHEN psh.ModifiedOn > tc.ModifiedOn
  	    	    	    	    	    	    	    	  THEN psh.ModifiedOn
  	    	    	    	    	    	    	  ELSE tc.ModifiedOn
  	    	    	    	    	    	    	  END
  	  FROM @tComponents tc
  	    	  JOIN (  	  SELECT  	  Id  	    	    	  = tc.Id,
  	    	    	    	    	    	  ModifiedOn  	  = MAX(psh.Modified_On)
  	    	    	    	  FROM @tComponents tc
  	    	    	    	    	  LEFT JOIN dbo.Production_Starts_History psh WITH (NOLOCK) ON tc.StartId = psh.Start_Id
  	    	    	    	  WHERE  	  tc.RAC = 1
  	    	    	    	    	    	  AND (  	  dbo.fnS95_ColumnUpdated(convert(binary(8), psh.Column_Updated_Bitmask), @PSStartOP) = 1
  	    	    	    	    	    	    	    	  OR dbo.fnS95_ColumnUpdated(convert(binary(8), psh.Column_Updated_Bitmask), @PSEndOP) = 1
  	    	    	    	    	    	    	    	  OR dbo.fnS95_ColumnUpdated(convert(binary(8), psh.Column_Updated_Bitmask), @PSProdIdOP) = 1)
  	    	    	    	  GROUP BY tc.Id) psh ON tc.Id = psh.Id
  	  WHERE tc.RAC = 1
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  -- 5.7 Calculate incremental consumption   	    	    	    	    	    	    	    	     
  	  -- The incremental consumption records are stored in an 'account' style table 
 	 -- so that we can calculate the ongoing incremental update.  This is more 
 	 -- efficient that querying each of the history tables each time.   	    	    	    	    	    	    	    
  	  ------------------------------------------------------------------------------   	    	    	    	    	    	    	    	    	    	    	    	     
  	  -- Consolidate to account for multiple INTermediate event component lines between same events
  	  INSERT @tConsumptionTotal (  	  PPId,
  	    	    	    	    	  CompId,
  	    	    	    	    	  EventId,
  	    	    	    	    	  SourceEventId,
  	    	    	    	    	  ProdId,
  	    	    	    	    	  Quantity,
  	    	    	    	    	  Ratio,
  	    	    	    	    	  ModifiedOn )
  	  SELECT  	  tc.PPId,
  	    	  tc.CompId,
  	    	  tc.EventId,
  	    	  tc.SourceEventId,
  	    	  tc.ProdId,
  	    	  SUM(tc.Quantity),
  	    	  SUM(tc.Ratio),
  	    	  MAX(ModifiedOn)
  	  FROM @tComponents tc
  	  GROUP BY  	  tc.PPId,
  	    	    	    	  tc.CompId,
  	    	    	    	  tc.EventId,
  	    	    	    	  tc.SourceEventId,
  	    	    	    	  tc.RAC,
  	    	    	    	  tc.ProdId
  	  
  	  -- Get previously reported consumption records
  	  INSERT INTO @tConsumptionHistory (  	  PPId,
  	    	    	    	    	    	  EventId,
  	    	    	    	    	    	  CompId,
  	    	    	    	    	    	  ProdId,
  	    	    	    	    	    	  Quantity)
  	  SELECT  	  ec.PP_Id,
  	    	    	  ec.Event_Id,
  	    	    	  ec.Component_Id,
  	    	    	  ec.Prod_Id,
  	    	    	  SUM(ec.Quantity)
  	  FROM dbo.ERP_Consumption ec 	 WITH (NOLOCK)
  	    	  JOIN @tConsumptionTotal tc ON tc.EventId = ec.Event_Id   
  	    	   AND tc.CompId = ec.Component_Id
  	    	  JOIN @tProcessOrder po on po.PPId = ec.PP_Id 
  	  WHERE  	  ec.Confirmed = 1
  	  GROUP BY  	  ec.PP_Id,
  	    	    	    	  ec.Event_Id,
  	    	    	    	  ec.Component_Id,
  	    	    	    	  ec.Prod_Id
  	  -- Get previously reported consumption records for event_component records that were deleted
  	  INSERT INTO @tConsumptionHistory (  	  PPId,
  	    	    	    	    	    	  EventId,
  	    	    	    	    	    	  CompId,
  	    	    	    	    	    	  ProdId,
  	    	    	    	    	    	  Quantity)
  	  SELECT  	  ec.PP_Id,
  	    	  ec.Event_Id,
  	    	  ec.Component_Id,
  	    	  ec.Prod_Id,
  	    	  SUM(ec.Quantity)
  	    	  FROM dbo.ERP_Consumption ec 	 WITH (NOLOCK)
  	    	  LEFT
  	    	  JOIN @tComponents tc ON   	  tc.EventId = ec.Event_Id
  	    	     AND   	  tc.CompId = ec.Component_Id
  	    	  JOIN @tProcessOrder po on po.PPId = ec.PP_Id 
  	    	  WHERE  	  ec.Confirmed = 1
  	    	    	  AND tc.eventId is null    	  -- deleted EC record does not exist on the @tComponents table
  	    	  GROUP 
  	    	  BY  	  ec.PP_Id,
  	   	    	  ec.Event_Id,
  	    	    	  ec.Component_Id,
  	    	    	  ec.Prod_Id
  	  -- Report incremental quantity consumption if the quantity has changed
  	  INSERT @tConsumption (  	  PPId,
  	    	    	    	  EventId,
  	    	    	    	  CompId,
  	    	    	    	  SourceEventId,
  	   	    	    	  ProdId,
  	    	    	    	  Quantity,
  	    	    	    	  ModifiedOn)
  	  SELECT  	  tct.PPId,
  	    	  tct.EventId,
  	    	  tct.CompId,
  	    	  tct.SourceEventId,
  	    	  tct.ProdId,
  	    	  tct.Quantity - isnull(tch.Quantity,0),
  	    	  tct.ModifiedOn
  	    	  FROM @tConsumptionTotal tct
  	    	  LEFT JOIN @tConsumptionHistory tch ON  	  tct.PPId = tch.PPId  
  	    	    	  AND tct.EventId = tch.EventId
  	    	    	  AND tct.CompId = tch.CompId
  	    	    	  AND tct.ProdId = tch.ProdId
  	  WHERE (tct.Quantity - isnull(tch.Quantity, 0)) <> 0
  	  -- Report product corrections
  	  --IF @ReportCorrections = 1
  	  --BEGIN
  	    	  INSERT @tConsumption (  	  PPId,
  	    	    	    	    	  EventId,
  	    	    	    	    	  CompId,
  	    	    	    	    	  ProdId,
  	    	    	    	    	  Quantity,
  	    	    	    	    	  ModifiedOn)
  	    	  SELECT  	  tch.PPId,
  	    	    	    	  tch.EventId,
  	    	    	    	  tch.CompId,
  	    	    	    	  tch.ProdId,
  	    	    	    	  tch.Quantity * -1,
  	    	    	    	  tct.ModifiedOn
  	    	  FROM @tConsumptionHistory tch
  	    	      JOIN @tProcessOrder po ON po.PPId = tch.PPId and po.ReportCorrections = 1
  	    	    	  JOIN @tConsumptionTotal tct ON  	  tct.PPId = tch.PPId
  	    	    	    	  AND tct.EventId = tch.EventId
  	    	    	    	  AND tct.CompId = tch.CompId
  	    	    	    	  AND tct.ProdId <> tch.ProdId
  	    	  WHERE tch.Quantity <> 0
  	  --END
  	  -- Report Event Deletions
  	  --IF @ReportDeletions = 1
  	  --BEGIN
  	    	  INSERT @tConsumption (  	  PPId,
  	    	    	    	    	  EventId,
  	    	    	    	    	  CompId,
  	    	    	    	    	  ProdId,
  	    	    	    	    	  Quantity,
  	    	    	    	    	  ModifiedOn,
  	    	    	    	    	  SourceEventId)
  	    	  SELECT  	  tch.PPId,
  	    	    	  tch.EventId,
  	    	    	  tch.CompId,
  	    	    	  tch.ProdId,
  	    	    	  tch.Quantity * -1,
  	    	    	  @TimeStamp,
  	    	    	  ech.Source_Event_Id  	    	  --Get information for the deleted EC from the history table
  	    	  FROM @tConsumptionHistory tch
  	    	    	  LEFT 
  	    	    	  JOIN   	  @tComponents tc 
  	    	    	  ON  	  tc.PPId = tch.PPId
  	    	    	  AND   	  tc.EventId = tch.EventId
  	    	    	  AND   	  tc.CompId = tch.CompId
  	    	      JOIN @tProcessOrder po ON po.PPId = tch.PPId and po.ReportDeletions = 1
  	    	    	  JOIN dbo.Event_Component_history ech WITH (NOLOCK) ON ech.Component_Id = tch.CompId  	  
  	    	    	  AND   	  ech.dbtt_id = 4  	    	    	    	    	    	    	  
  	    	    	  WHERE  	  tc.CompId IS NULL
  	    	    	  AND  	  tch.Quantity <> 0
  	  --END
  	  ----------------------------------------------------------------------------
  	  -- 5.8  	  Create MCA records   	    	    	    	    	    	    	    	    	    	    	  
  	  ----------------------------------------------------------------------------
  	  INSERT  	  @tMCA (  	  EventCompId,
  	    	    	  EventId,
  	    	    	  SourceEventId,
  	    	    	  SourceEventNum,
  	    	    	  ProcessOrder,
  	    	    	  PPId,
  	    	    	  PathId,
  	    	    	  BOMFId,
  	    	    	  Quantity,
  	    	    	  RAC,
  	    	    	  PUId,
  	    	    	  StartTime,
  	    	    	  EndTime,
  	    	    	  EngUnitId,
  	    	    	  UoM,
  	    	    	  ProdId,
  	    	    	  ProcessSegmentId,
  	    	    	  Ratio)
  	  SELECT  tc.CompId,
  	    	  tc.EventId,
  	    	  tc.SourceEventId,
  	    	  pe.Event_Num,
  	    	  pp.Process_Order,
  	    	  pp.PP_Id,
  	    	  pp.Path_Id,
  	    	  pp.BOM_Formulation_Id,
  	    	  tc.Quantity,
  	    	  ec.Report_As_Consumption,
  	    	  te.PUId,
  	    	  ec.Start_Time,
  	    	  ec.TimeStamp,
  	    	  ES.Dimension_X_Eng_Unit_Id,
  	    	  EU.Eng_Unit_Code, 
  	    	  tc.ProdId,
  	    	  @ConsProcSegmentId,
  	    	  tc.Ratio
  	  FROM @tConsumption tc
       JOIN @tProcessOrder po ON po.PPId = tc.PPId 
  	         AND(po.ReportByModifiedOn = 1 AND tc.ModifiedOn > po.LastProcessedTimestampUploadIncrementalCP)
  	    	    	  OR po.ReportByModifiedOn = 0
  	    	  JOIN dbo.Event_Components ec 	 WITH (NOLOCK) ON ec.Component_Id = tc.CompId
  	    	  JOIN @tEvents te ON te.EventId = tc.EventId
  	    	  JOIN dbo.Production_Plan pp 	 WITH (NOLOCK) ON pp.PP_Id = tc.PPId
  	    	  JOIN dbo.Events pe ON pe.Event_Id = tc.SourceEventId
  	    	  LEFT JOIN dbo.Event_Configuration ecfg 	 WITH (NOLOCK) ON   	  ecfg.PU_Id = pe.PU_Id
  	    	    	    	  AND  	  ecfg.ET_Id = 1
  	    	  LEFT JOIN dbo.Event_Subtypes es WITH (NOLOCK) ON es.Event_Subtype_Id = ecfg.Event_Subtype_Id
  	    	  LEFT JOIN dbo.engineering_unit EU WITH (NOLOCK) ON  	  EU.Eng_Unit_Id  	  = ES.Dimension_X_Eng_Unit_Id
  	   --TODO make this more efficient; don't get all the data first; instead just dont' ge
-- Create MCA records for deleted EC records
  	  --IF @ReportDeletions = 1
  	  --BEGIN
  	    	  INSERT  	  @tMCA (  	  EventCompId,
  	    	    	    	  EventId,
  	    	    	    	  SourceEventId,
  	    	    	    	  SourceEventNum,
  	    	    	    	  ProcessOrder,
  	    	    	    	  PPId,
  	    	    	    	  PathId,
  	    	    	    	  BOMFId,
  	    	    	    	  Quantity,
  	    	    	    	  RAC,
  	    	    	    	  PUId,
  	    	    	    	  StartTime,
  	    	    	    	  EndTime,
  	    	    	    	  EngUnitId,
  	    	    	    	  UoM,
  	    	    	    	  ProdId,
  	    	    	    	  ProcessSegmentId,
  	    	    	    	  Ratio)
  	    	  SELECT  tc.CompId,
  	    	    	  tc.EventId,
  	    	    	  tc.SourceEventId,
  	    	    	  pe.Event_Num,
  	    	    	  pp.Process_Order,
  	    	    	  pp.PP_Id,
  	    	    	  pp.Path_Id,
  	    	    	  pp.BOM_Formulation_Id,
  	    	    	  tc.Quantity,
  	    	    	  ec.Report_As_Consumption,
  	    	    	  te.PUId,
  	    	    	  ec.Start_Time,
  	    	    	  ec.TimeStamp,
  	    	    	  ES.Dimension_X_Eng_Unit_Id,
  	    	    	  EU.Eng_Unit_Code, 
  	    	    	  tc.ProdId,
  	    	    	  @ConsProcSegmentId,
  	    	    	  tc.Ratio
  	    	    	  FROM  	  @tConsumption tc
  	    	      JOIN    @tProcessOrder po ON po.PPId = tc.PPId and po.ReportDeletions = 1
  	    	    	  AND    (po.ReportByModifiedOn = 1 AND tc.ModifiedOn > po.LastProcessedTimestampUploadIncrementalCP)
  	    	    	    	    	  OR po.ReportByModifiedOn = 0
  	    	    	  JOIN   	  dbo.Event_Component_history ec 	  	 WITH (NOLOCK)
  	    	    	  ON   	  ec.Component_Id = tc.CompId
  	    	    	  AND   	  ec.dbtt_id = 4
  	    	    	  JOIN @tEvents te ON te.EventId = tc.EventId
  	    	    	  JOIN dbo.Production_Plan pp 	  	  	  	 WITH (NOLOCK) ON pp.PP_Id = tc.PPId
  	    	    	  JOIN dbo.Events pe 	  	 WITH (NOLOCK) ON pe.Event_Id = tc.SourceEventId
  	    	    	    	  LEFT JOIN dbo.Event_Configuration ecfg WITH (NOLOCK) ON   	  ecfg.PU_Id = pe.PU_Id
  	    	    	    	    	  AND  	  ecfg.ET_Id = 1
  	    	    	    	  LEFT JOIN dbo.Event_Subtypes es 	  	 WITH  (NOLOCK) ON es.Event_Subtype_Id = ecfg.Event_Subtype_Id
  	    	    	    	  LEFT JOIN dbo.engineering_unit EU 	  	 WITH  (NOLOCK) ON  	  EU.Eng_Unit_Id  	  = ES.Dimension_X_Eng_Unit_Id
  	  --END
  	  ----------------------------------------------------------------------------
  	  -- 5.9  	  Update Product Code/Storage Zone and Event Number  	    	    	    	    	    	    	    	    	    	  
  	  ----------------------------------------------------------------------------
  	  -- Retrieve the Product Code for the MCA records.
  	  UPDATE mca
  	  SET  	  Product  	  = COALESCE(dsx.Foreign_Key, p.Prod_Code),
  	    	  SAPProduct  	  = COALESCE(dsx.Foreign_Key, p.Prod_Code)
  	  FROM @tMCA mca
  	    	  JOIN dbo.Products p WITH (NOLOCK) ON mca.ProdId = p.Prod_Id
  	    	  LEFT JOIN dbo.Data_Source_XRef dsx WITH (NOLOCK) ON  	  mca.ProdId = dsx.Actual_Id
  	    	    	    	    	    	  AND  	  dsx.Table_Id = @ProductsTableId
  	    	    	    	    	    	  AND  	  dsx.DS_Id = @DataSourceId
  	  -- Retrieve the Storage Zone for the MCA records. Searches DSXref for PU and PL, and then uses PL.Desc
 	 UPDATE 	 mca
  	  SET 	 StorageZone = COALESCE(dspu.Foreign_Key,dsx.Foreign_Key, pl.PL_Desc)
  	  FROM 	 @tMCA mca
 	  	 JOIN dbo.Events ee WITH (NOLOCK) ON mca.SourceEventId = ee.Event_Id
 	  	 JOIN dbo.Prod_Units pu WITH (NOLOCK) ON ee.PU_Id = pu.PU_Id
 	  	 JOIN dbo.Prod_Lines pl WITH (NOLOCK) ON pu.PL_Id = pl.PL_Id
 	  	 LEFT JOIN dbo.Data_Source_XRef dsx  WITH (NOLOCK)
 	  	  	 ON  	  pu.PL_Id = dsx.Actual_Id
 	  	   	 AND  	  dsx.Table_Id = @ProdLinesTableId
 	  	   	 AND  	  dsx.DS_Id = @DataSourceId
 	  	 LEFT JOIN dbo.Data_Source_XRef dspu 	 WITH (NOLOCK) 	  	  	 
 	  	  	 ON  	 pu.PU_Id = dspu.Actual_Id
 	  	  	 AND 	 dspu.Table_Id = @ProdUnitsTableId 
 	  	  	 AND 	 dspu.DS_Id = @DataSourceId 	  	 
  	  ----------------------------------------------------------------------------
  	  -- Update event numbers from the xref table
  	  ----------------------------------------------------------------------------
  	  UPDATE mca
  	  SET  	  SourceEventNum = COALESCE(dsx.Foreign_Key, mca.SourceEventNum)
  	  FROM @tMCA mca
       JOIN @tProcessOrder po ON po.PPId = mca.PPId 
  	    	  JOIN dbo.Data_Source_XRef dsx WITH (NOLOCK) ON  	  mca.SourceEventId = dsx.Actual_Id
  	    	    	    	    	  AND  	  dsx.Table_Id = @EventsTableId
  	    	    	    	    	  AND  	  dsx.DS_Id = po.DSEventNumId
  	  ----------------------------------------------------------------------------
  	  -- If flag is On, gets the UOM for the BOMFI that matches the MCA prod Id 
 	  -- and converts the quantity to the BOMFI UOM
  	  --
  	  -- GET BOMFI UOM 
  	  ----------------------------------------------------------------------------
  	  --IF  	  @FlgConvertMCAUOMToBOMUOM  	   = 1 
  	  --BEGIN
  	    	  UPDATE  	  MCA
  	    	    	  SET  	  BOMEngUnitId  	  = EU.Eng_Unit_Id,
  	    	    	    	  BOMUoM  	    	  = EU.Eng_Unit_Code
  	    	    	  FROM  	  @tmca MCA
           JOIN    @tProcessOrder po ON po.PPId = mca.PPId and po.FlgConvertMCAUOMToBOMUOM = 1
  	    	    	  JOIN  	  dbo.Bill_Of_Material_Formulation_Item BOMFI 	  	 WITH (NOLOCK)
  	    	    	  ON  	  MCA.BOMFId  	    	  = BOMFI.BOM_Formulation_Id
  	    	    	  AND  	  MCA.ProdId  	    	  = BOMFI.Prod_Id
  	    	    	  JOIN  	  dbo.Engineering_Unit EU 	  	  	  	  	  	  	 WITH (NOLOCK)
  	    	    	  ON  	  BOMFI.Eng_Unit_Id  	  = EU.Eng_Unit_Id
  	    	  -------------------------------------------------------------------------
  	    	  --  	  Convert MCA quantity to the BOMFI UOM
  	    	  -------------------------------------------------------------------------
  	    	  UPDATE  	  MCA
  	    	    	  SET  	  ConvertedQuantity =  Coalesce(MCA.Quantity,0) * Coalesce(EUC.Slope, 1) + Coalesce(EUC.INTercept, 0),
  	    	    	    	  EngUnitConvId  	    =  EUC.Eng_Unit_Conv_Id  	    	    	  
  	    	    	  FROM  	  @tmca MCA
           JOIN    @tProcessOrder po ON po.PPId = mca.PPId and po.FlgConvertMCAUOMToBOMUOM = 1
  	    	    	  JOIN  	  dbo.Engineering_Unit_Conversion EUC 	  	  	  	 WITH (NOLOCK)
  	    	    	  ON  	  EUC.From_Eng_Unit_Id  	  = MCA.EngUnitId
  	    	    	  AND  	  EUC.To_Eng_Unit_Id  	  = MCA.BOMEngUnitId
  	    	    	  WHERE  	  MCA.BOMEngUnitId  	  <> MCA.EngUnitId
  	    	    	  AND  	  MCA.BOMEngUnitId  	  Is Not NULL
  	    	    	  AND  	  MCA.EngUnitId  	  Is Not NULL
  	  --END
  	 -----------------------------------------------------------------------------
 	 -- For sites where the S88 interface is implemented, the SP should report a 
 	  -- partial string for the SourceEventNum, if the Source Event Id is a virtual 
 	 -- batch
  	  ----------------------------------------------------------------------------
  	  IF  	  @FlgPAS88InterfaceImplemented = 1 
  	  BEGIN
 	  	 UPDATE 	 @tMCA
 	  	 SET 	 SourceEventNum 	 = SUBSTRING(SourceEventNum, 3, CASE
 	  	  	  	 WHEN CHARINDEX(':', SourceEventNum, 3) > 0 
 	  	  	  	  	 THEN CHARINDEX(':', SourceEventNum, 3) - 3
 	  	  	  	  	 ELSE CHARINDEX('!', SourceEventNum, 3) - 3
 	  	  	  	 END )
 	  	 WHERE 	 CHARINDEX('U:', SourceEventNum) = 1
 	 END
  	  ----------------------------------------------------------------------------
  	  -- 5.10 Retrieve the Material Consumed Actual Properties.  These records 
 	  -- will be found by locating variables associated with the Material Consumed 
 	  -- Actual records.  	    	    	    	    
  	  ----------------------------------------------------------------------------
  	  INSERT  	  @tMCAP (EventCompId,
  	    	    	  EventId,
  	    	    	  PropertyName,
  	    	    	  Value,
  	    	    	  DataType,
  	    	    	  UoM,
  	    	    	  VarId,
  	    	    	  TestId,
 	  	  	 ParentMCAId)
  	  SELECT   	  mca.EventCompId,
  	    	  mca.EventId,
  	    	  X.Foreign_Key,
  	    	  tt.Result,
  	    	  CASE  	  WHEN vv.Data_Type_Id IN (1, 2)
  	    	    	  THEN 'float'
  	    	    	  ELSE 'string'
  	    	  END,
  	    	  vv.Eng_Units,
  	    	  vv.var_id,
  	    	  tt.Test_Id,
 	  	  mca.Id
-- 	  	  select * from variables where var_id = 2344
  	  FROM  	  @tMCA mca
  	      JOIN    @tProcessOrder po on po.PPId = mca.PPId  
  	    	  JOIN  	  dbo.Event_Components ec WITH (NOLOCK) ON mca.EventCompId = ec.Component_Id
  	    	  JOIN   	  dbo.Data_Source_Xref X   WITH (NOLOCK)  	  ON   	  X.DS_Id   	    	  = @DataSourceId
  	    	    	    	    	    	  AND  	  X.Table_Id   	    	  = @VariablesTableId
  	    	    	    	    	    	  AND  	  X.Subscription_Id  	  = @OEUploadSubscription -- @OECommonSubscription
  	    	    	    	    	    	  AND  	  X.XML_Header  	    	  = po.MaterialConsumedActualPropertyHeader  	  
  	    	  JOIN   	  dbo.Variables vv   	   WITH (NOLOCK) ON   	  ec.PEI_Id  	    	  = vv.PEI_Id
  	    	    	    	    	    	  AND  	  VV.Var_id  	    	  = X.Actual_Id  	  
  	    	  JOIN  	  dbo.Tests tt  WITH (NOLOCK) ON tt.Var_Id   	    	    	    	  = vv.Var_Id
  	    	    	    	    	  AND  	  tt.Result_On   	    	    	  = ec.TimeStamp
  	    	    	    	    	  
  	  
  	  UPDATE  	  @tMCAP
  	  SET  	  PropertyName = LEFT(PropertyName, CHARINDEX(';', PropertyName) - 1)
  	  WHERE  	  CHARINDEX(';', PropertyName) > 1
END --IF @UploadType in (1,3)
-------------------------------------------------------------------------------
-- Not used on the WF demo -- AJ:18-Aug-2009
-- Not implemented in OE v1.0
-- SECTION 6: TEST PERFORMANCE  	   -- removed but stored in SVN history 	    	    	     	    	    	    	    	    	    	    	  
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- SECTION 7: ORDER CONFIRMATION  	   	      
-----------------------------------------------------------------------------
IF @UploadType = 1 AND 	 @FlgGroupMPAForOCMessage 	  = 1
 	 BEGIN
 	  	 INSERT 	 @tMPA 	 (PPId, ProcessOrder, PathId, EventId, StartTime, EndTime, PUId, ProdId, 
 	  	  	  	 Product, SAPProduct, EventNum, Batch, Quantity, UOM, ProcessSegmentId, 
 	  	  	  	 StorageZone)
 	  	  	  	 SELECT 	 Min(mpa.PPId), mpa.ProcessOrder, MAX(mpa.PathId), -1, MIN(mpa.StartTime), MAX(mpa.EndTime), 
 	  	  	  	  	 MAX(mpa.PUId), MAX(mpa.ProdId), MAX(mpa.Product), mpa.SAPProduct, 
 	  	  	  	  	 MIN(mpa.EventNum), MIN(mpa.Batch), SUM(mpa.Quantity), MAX(mpa.UOM), 
 	  	  	  	  	 MAX(mpa.ProcessSegmentId), MAX(mpa.StorageZone)
 	  	  	  	  	 FROM 	 @tMPA mpa
 	  	  	  	  	 JOIN  @tProcessOrder po on po.PPId = mpa.PPId AND po.FlgGroupMPAForOCMessage 	  = 1
 	  	  	  	  	 GROUP 	 BY  mpa.ProcessOrder, mpa.SAPProduct
 	 
 	  	 -- leaves just the summary MPA records
 	  	 --DELETE 	 @tMPA
 	  	 -- 	 WHERE 	 EventId 	 <> -1
 	 END 	  	 -- IF 	 @FlgGroupMPAForOCMessage 	  = 1
 	  
----------------------------------------------------------------------------
-- If flag is On, gets the UOM for the Production Setup (Stored as an UDP) 
-- that matches the event number and converts the quantity to the PS UOM
--
-- GET PS UOM 
----------------------------------------------------------------------------
IF  	  @FlgConvertMPAUOMToPSUOM = 1 AND @UploadType in (1,2)
BEGIN
  	  UPDATE  	  MPA
  	    	  SET  	  PSEngUnitId  	    	  = EU.Eng_Unit_Id,
  	    	    	  PSUoM  	    	    	  = EU.Eng_Unit_Code
  	    	  FROM  	  @tmpa MPA
  	    	  JOIN  @tProcessOrder po on po.PPId = MPA.PPId and po.FlgConvertMPAUOMToPSUOM  	   = 1 
  	    	  JOIN  	  dbo.Production_Setup PS 	  	  	  	 WITH (NOLOCK)
  	    	  ON  	  MPA.PPId  	    	  = PS.PP_Id
  	    	  AND  	  MPA.EventNum  	    	  = PS.Pattern_Code
  	    	  JOIN  	  dbo.Table_Fields_Values TFV 	  	  	 WITH (NOLOCK)
  	    	  ON  	  TFV.KeyId  	    	  = PS.PP_Setup_Id
  	    	  AND  	  TFV.Table_Field_id  	  = @PSOriginalEngUnitCodeUDP
  	    	  AND  	  TFV.TableId  	    	  = @ProductionSetupTableId
  	    	  JOIN  	  dbo.Engineering_Unit EU 	  	  	  	 WITH (NOLOCK)
  	    	  ON  	  TFV.Value  	    	  = EU.Eng_Unit_Code
  	  -----------------------------------------------------------------------------------------------------
  	  --  	  Convert MPA quantity to the BOMFI UOM
  	  -----------------------------------------------------------------------------------------------------
  	  UPDATE  	  MPA
  	    	  SET  	  ConvertedQuantity =  Coalesce(MPA.Quantity,0) * Coalesce(EUC.Slope, 1) + Coalesce(EUC.INTercept, 0),
  	    	    	  EngUnitConvId  	    =  EUC.Eng_Unit_Conv_Id  	  -- mark MPAs that could find conversion records for
  	    	  FROM  	  @tmpa MPA
  	    	  JOIN    @tProcessOrder po on po.PPId = MPA.PPId and po.FlgConvertMPAUOMToPSUOM  	   = 1 
  	    	  JOIN  	  dbo.Engineering_Unit_Conversion EUC 	  	 WITH (NOLOCK)
  	    	  ON  	  EUC.From_Eng_Unit_Id  	  = MPA.EngUnitId
  	    	  AND  	  EUC.To_Eng_Unit_Id  	  = MPA.PSEngUnitId
  	    	  WHERE  	  MPA.PSEngUnitId  	  <> MPA.EngUnitId
  	    	  AND  	  MPA.PSEngUnitId  	  Is Not NULL
  	    	  AND  	  MPA.EngUnitId  	  Is Not NULL
END
----------------------------------------------------------------------------
-- SECTION 8: OUTPUT RESULTS   	    	    	    	    	    	    	    	    	    	    	    	  
----------------------------------------------------------------------------
OUTPUTRESULTS:
----------------------------------------------------------------------------
-- MPA
----------------------------------------------------------------------------
IF 	  	 @FlgFixedOutput 	 =1
BEGIN 
 	  	 INSERT 	 @oMPA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, UnitOfMeasure,DataType, 
 	  	  	  	 EventId)
 	  	  	  	 VALUES('PI_PROD',
 	  	  	  	  	  	 'Aug  4 2009  8:35AM',
 	  	  	  	  	  	 '1',
 	  	  	  	  	  	 '1',
 	  	  	  	  	  	 'ProcessOrder01',
 	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	 'Jul 22 2009  5:39PM',
 	  	  	  	  	  	 'Jul 22 2009  5:40PM',
 	  	  	  	  	  	 'Product001',
 	  	  	  	  	  	 'BATCH001',
 	  	  	  	  	  	 @MPADefaultSiteId,
 	  	  	  	  	  	 'Site',
 	  	  	  	  	  	 @MPAStorageZone,
 	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	  500,
  	    	  	  	  	  	  'Kg',
  	    	  	  	  	  	 'float',
 	  	  	  	  	  	 41)
END 
ELSE
BEGIN
 	  	 INSERT 	 @oMPA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, UnitOfMeasure,DataType, 
 	  	  	  	 EventId)
 	  	  	  	 SELECT 	 'PI_PROD',
 	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50),DateAdd(mi, @TimeModifier, @TimeStamp),127),''),
 	  	  	  	  	  	 '1',
 	  	  	  	  	  	 coalesce(Id,''),
 	  	  	  	  	  	 ProcessOrder,
 	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50),DateAdd(mi, @TimeModifier,StartTime),127),''),
 	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50),DateAdd(mi, @TimeModifier,EndTime),127),''),
 	  	  	  	  	  	 SAPProduct,
 	  	  	  	  	  	 CASE  	  
  	    	    	  	    	  	  	  WHEN   	  CharIndex(':', Batch)  = 0 
  	    	    	    	  	  	  	  	  	 THEN  	  Coalesce(Batch,'')
  	    	    	    	  	  	  	  WHEN    CharIndex(':', Batch) > 0  
 	  	  	  	    	    	    	  	  	 THEN   	  Left(Batch, CharIndex(':', Batch) -1 )
  	    	    	    	  	  	 END,
 	  	  	  	  	  	 @MPADefaultSiteId,
 	  	  	  	  	  	 'Site',
 	  	  	  	  	  	 --COALESCE(StorageZone,@MPAStorageZone), -JG: this should never be null b/c @tProcessorder has the default 
 	  	  	  	  	  	 COALESCE(StorageZone,@MPAStorageZone),
 	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	  coalesce(ConvertedQuantity, Quantity,''),
  	    	  	  	  	  	  CASE   	    	 
   	    	  	  	  	  	  	 WHEN  	  EngUnitConvId Is NOT NULL
   	    	    	  	  	  	  	  	  	 THEN  	  coalesce(PSUoM,UoM,'')
   	    	  	  	  	  	  	 WHEN  	  EngUnitConvId IS NULL
   	    	    	  	  	  	  	  	  	 THEN  	  UOM
   	  	  	  	  	  	 END,
  	    	  	  	  	  	 coalesce(@MPAQuantityDataType,''),
 	  	  	  	  	  	 coalesce(EventId,'')
 	  	  	  	  	  	 FROM  	  @tMPA 
 	   	    	  	  	  	 ORDER 
 	  	  	  	  	  	 BY 	  	 Id
END
SELECT 	 [Description],
 	  	 PublishedDate,
 	  	 ProductionResponseId,
 	  	 ProductionRequestId,
 	  	 SegmentResponseId,
 	  	 ProcessSegmentId,
 	  	 ActualStartTime,
 	  	 ActualEndTime,
 	  	 MaterialDefinitionId,
 	  	 MaterialLotId,
 	  	 EquipmentId1,
 	  	 EquipmentElementLevel1,
 	  	 EquipmentId2,
 	  	 EquipmentElementLevel2,
 	  	 Quantity,
 	  	 UnitOfMeasure,
 	  	 DataType,
 	  	 EventId,
 	  	 Sequence 	 
 	  	 FROM 	 @oMPA
 	  	 ORDER
 	  	 BY 	  	 Sequence
----------------------------------------------------------------------------
-- MPAP
----------------------------------------------------------------------------
IF 	  	 @FlgFixedOutput 	 >0 
BEGIN
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 100','Property 100',1.00,'float',NULL, 41,24925,1)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 101','Property 101',2.00,'float',NULL,41,24926,1)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 102','Property 102',3.00,'float',NULL,41,24927,1)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 103','Property 103',4.00,'float',NULL,41,24928,1)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 104','Property 104',5.00,'float',NULL,41,24929,1)
/*
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 100','Property 100',10.00,'float',NULL,41,24930,2)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 101','Property 101',20.00,'float',NULL,41,24931,2)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 102','Property 102',30.00,'float',NULL,41,24932,2)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 103','Property 103',40.00,'float',NULL,41,24933,2)
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMPAId)
 	   	  	  	  	  	 VALUES('Property 104','Property 104',50.00,'float',NULL,41,24934,2)
*/
END
ELSE
BEGIN
 	  	 INSERT 	 @oMPAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,
 	  	  	  	 TestId, ParentMPAId)
 	   	  	  	  SELECT coalesce(PropertyName,''),
 	  	  	  	  	  	 coalesce(PropertyName,''),
 	  	  	  	  	  	 coalesce([Value],''),
 	  	  	  	  	  	 coalesce(DataType,''),
 	  	  	  	  	  	 coalesce(UoM,''),
 	  	  	  	  	  	 coalesce(EventId,''),
 	  	  	  	  	  	 coalesce(TestId,''),
 	  	  	  	  	  	 coalesce(ParentMPAId,'')
  	  	  	  	  	  	 FROM  	  @tMPAP
 	  	  	  	  	  	 ORDER
 	  	  	  	  	  	 BY 	  	 Id
END
SELECT 	 Id,
 	  	 [Description],
 	  	 [Value],
 	  	 DataType,
 	  	 UnitOfMeasure,
 	  	 EventId,
 	  	 TestId,
 	  	 ParentMPAId,
 	  	 Sequence 	 
 	  	 FROM 	 @oMPAP
 	  	 ORDER
 	  	 BY 	  	 Sequence
----------------------------------------------------------------------------
-- MCA
----------------------------------------------------------------------------
IF 	  	 @FlgFixedOutput 	 > 0 
BEGIN
 	  	  	 DECLARE @ProcessOrder 	 VarChar(255)
 	  	  	 SELECT @ProcessOrder = ProcessOrder FROM @tProcessOrder
 	  	  	 SELECT 	 @DefaultStorageZoneMCA 	 = 'ProductionLine1'
 	  	  	 INSERT 	 @oMCA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, DataType, UnitOfMeasure,
 	  	  	  	  	 ChildEventId)
 	  	  	  	  	 VALUES ('PI_CONS',
 	  	  	  	  	  	  	 'Aug  4 2009  8:35AM',
 	  	  	  	  	  	  	 '1',
 	  	  	  	  	  	  	 1,
 	  	  	  	  	  	  	 @ProcessOrder,
 	  	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	  	 'Jan  1 1900 12:00AM',
 	  	  	  	  	  	  	 'Jul 23 2009  6:11AM',
 	  	  	  	  	  	  	 'Material002',
 	  	  	  	  	  	  	 'LOT001',
 	  	  	  	  	  	  	 @MCADefaultSiteId,
 	  	  	  	  	  	  	 'Site',
 	  	  	  	  	  	  	 @DefaultStorageZoneMCA,
 	  	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	  	 200,
 	  	  	  	  	  	  	 'float',
 	  	  	  	  	  	  	 NULL,
 	  	  	  	  	  	  	 41)
 	  	  	 INSERT 	 @oMCA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, DataType, UnitOfMeasure,
 	  	  	  	  	 ChildEventId)
 	  	  	  	  	 VALUES ('PI_CONS',
 	  	  	  	  	  	  	 'Aug  4 2009  8:35AM',
 	  	  	  	  	  	  	 '1',
 	  	  	  	  	  	  	 2,
 	  	  	  	  	  	  	 @ProcessOrder,
 	  	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	  	 'Jan  1 1900 12:00AM',
 	  	  	  	  	  	  	 'Jul 23 2009  6:13AM',
 	  	  	  	  	  	  	 'Material002',
 	  	  	  	  	  	  	 'LOT002',
 	  	  	  	  	  	  	 @MCADefaultSiteId,
 	  	  	  	  	  	  	 'Site',
 	  	  	  	  	  	  	 '0001',
 	  	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	  	 205,
 	  	  	  	  	  	  	 'float',
 	  	  	  	  	  	  	 NULL,
 	  	  	  	  	  	  	 41)
 	  	 
 	  	  	 INSERT 	 @oMCA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, DataType, UnitOfMeasure,
 	  	  	  	  	 ChildEventId)
 	  	  	  	  	 VALUES ('PI_CONS',
 	  	  	  	  	  	  	 'Aug  4 2009  8:35AM',
 	  	  	  	  	  	  	 '1',
 	  	  	  	  	  	  	 3,
 	  	  	  	  	  	  	 @ProcessOrder,
 	  	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	  	 'Jan  1 1900 12:00AM',
 	  	  	  	  	  	  	 'Jul 23 2009  6:12AM',
 	  	  	  	  	  	  	 'Material002',
 	  	  	  	  	  	  	 'LOT002',
 	  	  	  	  	  	  	 @MCADefaultSiteId,
 	  	  	  	  	  	  	 'Site',
 	  	  	  	  	  	  	 '0001',
 	  	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	  	 210,
 	  	  	  	  	  	  	 'float',
 	  	  	  	  	  	  	 NULL,
 	  	  	  	  	  	  	 42)
 	  	  	 INSERT 	 @oMCA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, DataType, UnitOfMeasure,
 	  	  	  	  	 ChildEventId)
 	  	  	  	  	 VALUES ('PI_CONS',
 	  	  	  	  	  	  	 'Aug  4 2009  8:35AM',
 	  	  	  	  	  	  	 '1',
 	  	  	  	  	  	  	 4,
 	  	  	  	  	  	  	 @ProcessOrder,
 	  	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	  	 'Jan  1 1900 12:00AM',
 	  	  	  	  	  	  	 'Jul 23 2009  8:46AM',
 	  	  	  	  	  	  	 'Material003',
 	  	  	  	  	  	  	 'LOT003',
 	  	  	  	  	  	  	 @MCADefaultSiteId,
 	  	  	  	  	  	  	 'Site',
 	  	  	  	  	  	  	 '0001',
 	  	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	  	 30,
 	  	  	  	  	  	  	 'float',
 	  	  	  	  	  	  	 NULL,
 	  	  	  	  	  	  	 42)
END
ELSE
BEGIN
 	  	 INSERT 	 @oMCA 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	 MaterialDefinitionId, MaterialLotId, EquipmentId1, EquipmentElementLevel1, 
 	  	  	  	 EquipmentId2, EquipmentElementLevel2, Quantity, DataType, UnitOfMeasure,
 	  	  	  	 ChildEventId)
 	  	  	  	 SELECT 	 'PI_CONS',
 	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50),DateAdd(mi, @TimeModifier, @TimeStamp),127),''),
 	  	  	  	  	  	 '1',
 	  	  	  	  	  	 coalesce(Id,''),
 	  	  	  	  	  	 ProcessOrder,
 	  	  	  	  	  	 'MAKE',
 	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50),DateAdd(mi, @TimeModifier,StartTime),127),''),
 	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50),DateAdd(mi, @TimeModifier,EndTime),127),''),
 	  	  	  	  	  	 SAPProduct,
 	  	  	  	  	  	 CASE  	  
 	  	  	  	  	  	  	 WHEN   	 CharIndex(':', SourceEventNum)  = 0 
 	  	  	  	  	  	  	  	  	 THEN  	  Coalesce(SourceEventNum,'')
 	  	  	  	  	  	  	 WHEN     CharIndex(':', SourceEventNum) > 0  
 	  	  	  	  	  	  	  	  	 THEN   	  Left(SourceEventNum, CharIndex(':', SourceEventNum) -1 )
 	  	  	  	  	  	 END,
 	  	  	  	  	  	 @MCADefaultSiteId,
 	  	  	  	  	  	 'Site',
 	  	  	  	  	  	 --COALESCE(StorageZone,@DefaultStorageZoneMCA), --JG: this should never happen b/c the PLDesc is used if nothing else
 	  	  	  	  	  	 StorageZone,
 	  	  	  	  	  	 'StorageZone',
 	  	  	  	  	  	 coalesce(ConvertedQuantity, Quantity,''),
 	  	  	  	  	  	 coalesce(@MCAQuantityDataType,''),
 	  	  	  	  	  	 CASE   	  
 	  	  	  	  	  	  	  WHEN  	  EngUnitConvId Is NOT NULL
 	  	  	  	  	  	  	  	  	  THEN  	  coalesce(BOMUOM, UoM,'')
 	  	  	  	  	  	  	  WHEN  	  EngUnitConvId IS NULL
 	  	  	  	  	  	  	  	  	  THEN  	  UOM
 	  	  	  	  	  	 END,
 	  	  	  	  	  	 coalesce(EventId,'')
 	  	  	  	  	  	 FROM  	  @tMCA 
 	   	    	  	  	  	 ORDER 
 	  	  	  	  	  	 BY 	  	 Id
END
SELECT 	 [Description],
 	  	 PublishedDate,
 	  	 ProductionResponseId,
 	  	 ProductionRequestId,
 	  	 SegmentResponseId,
 	  	 ProcessSegmentId,
 	  	 ActualStartTime,
 	  	 ActualEndTime,
 	  	 MaterialDefinitionId,
 	  	 MaterialLotId,
 	  	 EquipmentId1,
 	  	 EquipmentElementLevel1,
 	  	 EquipmentId2,
 	  	 EquipmentElementLevel2,
 	  	 Quantity,
 	  	 UnitOfMeasure,
 	  	 DataType,
 	  	 ChildEventId,
 	  	 Sequence 	 
 	  	 FROM 	 @oMCA
 	  	 ORDER
 	  	 BY 	  	 Sequence
----------------------------------------------------------------------------
-- MCAP
----------------------------------------------------------------------------
IF 	  	 @FlgFixedOutput 	 >0 
BEGIN
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 200','Property 200',1.00,'float',NULL, 41,24955, 1)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 200','Property 200',21.00,'float',NULL,41,24970,2)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 200','Property 200',11.00,'float',NULL,42,24960,3)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 200','Property 200',31.00,'float',NULL,42,24975,4)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 201','Property 201',2.00,'float',NULL,41,24956,1)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 201','Property 201',22.00,'float',NULL,41,24971,2)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 201','Property 201',12.00,'float',NULL,42,24961,3)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 201','Property 201',32.00,'float',NULL,42,24976,4)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 202','Property 202',3.00,'float',NULL,41,24957,1)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 202','Property 202',23.00,'float',NULL,41,24972,2)
 	  	 
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 202','Property 202',13.00,'float',NULL, 42,24962, 3)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 202','Property 202',33.00,'float',NULL,42,24977,4)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 203','Property 203',4.00,'float',NULL,41,24958,1)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 203','Property 203',24.00,'float',NULL,41,24973,2)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 203','Property 203',14.00,'float',NULL,42,24963,3)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 203','Property 203',34.00,'float',NULL,42,24978,4)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 204','Property 204',5.00,'float',NULL,41,24959,1)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 204','Property 204',25.00,'float',NULL,41,24974,2)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 204','Property 204',15.00,'float',NULL,42,24964,3)
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,TestId, ParentMCAId)
 	  	  	  	 VALUES ('Property 204','Property 204',35.00,'float',NULL,42,24979,4)
END
ELSE
BEGIN
 	  	 INSERT 	 @oMCAP 	 (Id, [Description], [Value], DataType, UnitOfMeasure, EventId,
 	  	  	  	 TestId, ParentMCAId)
 	   	  	  	  SELECT coalesce(PropertyName,''),
 	  	  	  	  	  	 coalesce(PropertyName,''),
 	  	  	  	  	  	 coalesce([Value],''),
 	  	  	  	  	  	 coalesce(DataType,''),
 	  	  	  	  	  	 coalesce(UoM,''),
 	  	  	  	  	  	 coalesce(EventId,''),
 	  	  	  	  	  	 coalesce(TestId,''),
 	  	  	  	  	  	 coalesce(ParentMCAId,'')
  	  	  	  	  	  	 FROM  	  @tMCAP
 	  	  	  	  	  	 ORDER
 	  	  	  	  	  	 BY 	  	 Id
END
SELECT 	 Id,
 	  	 [Description],
 	  	 [Value],
 	  	 DataType,
 	  	 UnitOfMeasure,
 	  	 EventId,
 	  	 TestId,
 	  	 ParentMCAId,
 	  	 Sequence 	 
 	  	 FROM 	 @oMCAP
 	  	 ORDER
 	  	 BY 	  	 Sequence
----------------------------------------------------------------------------
-- OC
----------------------------------------------------------------------------
IF 	  	 @FlgFixedOutput 	 =1
BEGIN
  --IF @UploadType = 1 
  --BEGIN
 	  	 INSERT 	 @oOC 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	 MaterialDefinitionId, MaterialLotId, Quantity, UnitOfMeasure, DataType, PPId)
 	  	  	  	 VALUES('Production Performance Order Confirmation',
 	  	  	  	  	     'Aug  4 2009  8:35AM',
 	  	  	  	  	  	 '1',
 	  	  	  	  	  	 1,
 	  	  	  	  	  	 'ProcessOrder01',
 	  	  	  	  	  	 'ORDER CONFIRMATION',
 	  	  	  	  	  	 'Jul 22 2009  5:34PM',
 	  	  	  	  	  	 'Aug  4 2009  8:35AM',
 	  	  	  	  	  	 'Product001',
 	  	  	  	  	  	 'ProcessOrder01',
 	  	  	  	  	  	  500,
  	    	  	  	  	  	  'kg',
  	    	  	  	  	  	 'float',
 	  	  	  	  	  	 90)
 	 --END
END
ELSE
BEGIN
 	  	 INSERT 	 @oOC 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	  	  	 MaterialDefinitionId, MaterialLotId, Quantity,  UnitOfMeasure, DataType,PPId)
 	  	  	  	  	  	 SELECT 	 'Production Performance Order Confirmation',
 	  	  	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50), DateAdd(mi, @TimeModifier, @TimeStamp),127),''),
 	  	  	  	  	  	  	  	 '1',
 	  	  	  	  	  	  	  	 coalesce(PO.Id,''),
 	  	  	  	  	  	  	  	 PO.ProcessOrder,
 	  	  	  	  	  	  	  	 'ORDER CONFIRMATION',
 	  	  	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50), DateAdd(mi, @TimeModifier,PO.StartTime),127),''),
 	  	  	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50), DateAdd(mi, @TimeModifier,PO.EndTime),127),''),
 	  	  	  	  	  	  	  	 MPA.SAPProduct,
 	  	  	  	  	  	  	  	 PO.ProcessOrder,
 	  	  	  	  	  	  	  	  coalesce(ConvertedQuantity, Quantity,''),
  	    	  	  	  	  	  	  	  CASE   	    	 
   	    	  	  	  	  	  	  	  	 WHEN  	  EngUnitConvId Is NOT NULL
   	    	    	  	  	  	  	  	  	  	  	 THEN  	  coalesce(PSUoM,UoM,'')
   	    	  	  	  	  	  	  	  	 WHEN  	  EngUnitConvId IS NULL
   	    	    	  	  	  	  	  	  	  	  	 THEN  	  UOM
   	  	  	  	  	  	  	  	 END,
  	    	  	  	  	  	  	  	 coalesce(@MPAQuantityDataType,''),
 	  	  	  	  	  	  	  	 coalesce(PO.PPId,'')
 	  	  	  	  	  	  	  	 FROM 	 @tProcessOrder 	 PO
 	  	  	  	  	  	  	  	 JOIN 	 @tMPA 	 MPA
 	  	  	  	  	  	  	  	 ON 	  	 PO.PPId 	 = MPA.PPId
 	  	  	  	  	  	  	  	 AND 	  	 MPA.EventId 	 = -1
 	  	  	  	  	  	  	  	 --WHERE @UploadType = 1
  	  	  	  	  	  	  	  	 ORDER 
 	  	  	  	  	  	  	  	 BY 	  	 MPA.Id
END
IF Not Exists(SELECT 1 FROM @oOc)
BEGIN
 	  	 INSERT 	 @oOC 	 ([Description], PublishedDate, ProductionResponseId, SegmentResponseId,
 	  	  	  	  	  	 ProductionRequestId, ProcessSegmentId, ActualStartTime, ActualEndTime, 
 	  	  	  	  	  	 MaterialDefinitionId, MaterialLotId, Quantity,  UnitOfMeasure, DataType,PPId)
 	  	  	  	  	  	 SELECT 	 'Production Performance Order Confirmation',
 	  	  	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50), DateAdd(mi, @TimeModifier, @TimeStamp),127),''),
 	  	  	  	  	  	  	  	 '1',
 	  	  	  	  	  	  	  	 coalesce(PO.Id,''),
 	  	  	  	  	  	  	  	 PO.ProcessOrder,
 	  	  	  	  	  	  	  	 'ORDER CONFIRMATION',
 	  	  	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50), DateAdd(mi, @TimeModifier,PO.StartTime),127),''),
 	  	  	  	  	  	  	  	 coalesce(CONVERT(VARCHAR(50), DateAdd(mi, @TimeModifier,PO.EndTime),127),''),
 	  	  	  	  	  	  	  	 Null,
 	  	  	  	  	  	  	  	 PO.ProcessOrder,
 	  	  	  	  	  	  	  	 Null,
  	    	  	  	  	  	  	 Null,
  	    	  	  	  	  	  	 coalesce(@MPAQuantityDataType,''),
 	  	  	  	  	  	  	  	 coalesce(PO.PPId,'')
 	  	  	  	  	  	  	  	 FROM 	 @tProcessOrder 	 PO
END
SELECT 	 [Description],
 	  	 PublishedDate,
 	  	 ProductionResponseId,
 	  	 ProductionRequestId,
 	  	 SegmentResponseId,
 	  	 ProcessSegmentId,
 	  	 ActualStartTime,
 	  	 ActualEndTime,
 	  	 MaterialDefinitionId,
 	  	 MaterialLotId,
 	  	 Quantity,
 	  	 UnitOfMeasure,
 	  	 DataType,
 	  	 PPId,
 	  	 Sequence 	 
 	  	 FROM 	 @oOc
 	  	 ORDER
 	  	 BY 	  	 Sequence
/****************************************************************************************************
*  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  *
*  	    	    	    	    	    	    	  SECTION 9: UPDATE PRODUCTION/CONSUMPTION TABLES  	    	    	    	    	    	    	  *
*  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  *
****************************************************************************************************/
IF @UploadType in (1,2)
BEGIN
  	  INSERT dbo.ERP_Production (  	  PP_Id,
  	    	    	    	    	  TimeStamp,
  	    	    	    	    	  Subscription_Id,
  	    	    	    	    	  Production_Type,
  	    	    	    	    	  Key_Id,
  	    	    	    	    	  Quantity,
  	    	    	    	    	  Prod_Id,
  	    	    	    	    	  Modified_On)
    SELECT  	  PPId,
  	      @TimeStamp,
  	      -9,
  	      ProductionType,
  	      KeyId,
  	      Quantity,
  	      ProdId,
  	      ModifiedOn
  	      FROM @tProduction
END
IF @UploadType in (1,3)
BEGIN
  	  INSERT dbo.ERP_Consumption (PP_Id ,
  	    	    	    	    	  TimeStamp,
  	    	    	    	    	  Subscription_Id,
  	    	    	    	    	  Event_Id,
  	    	    	    	    	  Component_Id,
  	    	    	    	    	  Source_Event_Id,
  	    	    	    	    	  Quantity,
  	    	    	    	    	  Prod_Id,
  	    	    	    	    	  Modified_On)
  	  SELECT  	 PPId ,
  	    	  @TimeStamp,
  	    	  -9,
  	    	  EventId,
  	    	  CompId,
  	    	  SourceEventId,
  	    	  Quantity,
  	    	  ProdId,
  	    	  ModifiedOn
  	    	  FROM @tConsumption
END
--/****************************************************************************************************
--*                           APPENDIX A: CONFIRM PRODUCTION/CONSUMPTION TABLES  	    	    	    	    	    	  *
--*  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  *
--****************************************************************************************************/
IF @AutoConfirm =  1 -- 9999 for test   -- provisory
BEGIN --@AutoConfirm =  1 
  UPDATE epa
    SET epa.Confirmed = 1
    FROM dbo.ERP_Production epa
      JOIN @tProcessOrder po ON po.PPId = epa.PP_Id 
     	  AND epa.TimeStamp = @TimeStamp
  	  
  	 UPDATE eca
  	   SET eca.Confirmed = 1
  	   FROM dbo.ERP_Consumption eca
      JOIN @tProcessOrder po ON po.PPId = eca.PP_Id 
  	   	  AND eca.TimeStamp = @TimeStamp
  -- UPDATE last processed timestamp, Add Table Field Value for path if missing
  -- and if upload type 1 then set the SentToSAP flag
  /*******************************************************************
  *   -79 	 LastProcessedTimestampUploadFull
  *   -80 	 LastProcessedTimestampUploadIncrementalPP
  *   -81 	 LastProcessedTimestampUploadIncrementalCP
  *******************************************************************/
  SELECT @TableFieldId = 
     CASE  
       WHEN @UploadType=1 THEN -79
       WHEN @UploadType=2 THEN -80
       WHEN @UploadType=3 THEN -81
       ELSE NULL 
     END 
  DECLARE   	   TFV2Cursor INSENSITIVE CURSOR   
 	   For (SELECT DISTINCT PathId 
 	           FROM @tProcessOrder
 	           )
   	      	      For Read Only 
  OPEN   	   TFV2Cursor
  FETCH   	   NEXT FROM TFV2Cursor INTO @KeyId
  WHILE   	   @@Fetch_Status = 0
  BEGIN
    IF (EXISTS (SELECT KeyId FROM Table_Fields_Values WHERE Table_Field_id = @TableFieldId AND TableId = @ProductionPlanTableId AND KeyId = @KeyId))
    BEGIN
      UPDATE Table_Fields_Values
        SET Value = @Timestamp
        WHERE Table_Field_id = @TableFieldId AND TableId = @ProductionPlanTableId AND KeyId = @KeyId
    END
    ELSE
    BEGIN
      INSERT into Table_Fields_Values (KeyId,Table_Field_id,TableId, Value) 
        SELECT @KeyId,@TableFieldId, @ProductionPlanTableId, @Timestamp
    END
    ------------------------------------------------------------------------------
    --  	  lock process orders after a FULL upload is requested
    ------------------------------------------------------------------------------
    IF @UploadType = 1 
    BEGIN
    IF EXISTS 
   	   (SELECT *
 	    	    FROM  	  dbo.Table_Fields_Values
 	    	    WHERE  	  KeyId  	    	  = @KeyId
 	    	    AND  	  TableId  	    	  = @ProductionPlanTableId
 	    	    AND  	  Table_Field_Id  	  = @SentToSAPFlagFieldId)
    BEGIN
      UPDATE  	  dbo.Table_Fields_Values
           SET  	  Value  	  = 'Y'
           WHERE  	  KeyId  	    	  = @PPId
           AND  	  TableId  	    	  = @ProductionPlanTableId
           AND  	  Table_Field_Id  	  = @SentToSAPFlagFieldId
    END
    ELSE
    BEGIN
      INSERT  	  dbo.Table_Fields_Values  	  (KeyId, TableId, Table_Field_Id, Value)
         VALUES  	  (@PPId, @ProductionPlanTableId, @SentToSAPFlagFieldId, 'Y')
      END
    END  	  
    FETCH   	   NEXT FROM TFV2Cursor INTO @KeyId
  END
  CLOSE   	      	   TFV2Cursor
  DEALLOCATE   	   TFV2Cursor
END --@AutoConfirm =  1 
SET NOCOUNT OFF
RETURN 
