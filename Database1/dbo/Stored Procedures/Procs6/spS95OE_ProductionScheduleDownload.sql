-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spS95_ProductionScheduleDownload
-----------------------------------------------------------
-------------------------------------------------------------------------------
-- Enterprise Connector version of the spS95OE_PGBTProductionSchedule SP.
--
-- Developed for P&G, this SP is called by a Web Service that is part of an 
-- Interim BizTalk solution for interfacing Plant Applications to SAP.  
-- This SP passes data from the B2MML schema ProductionSchedule, as modified by 
-- P&G, into the Plant Applications database.
-------------------------------------------------------------------------------
-- DATE   	      	   BY   	      	      	   DESCRIPTION
-- 03-Apr-2005   	   RMinnichi,   	   01 01   	   Initial coding.
--    	      	   SRobertson,
--    	      	   BSeely
-- 11-Apr-05    AJudkowicz      01 02    	   Finish converting to table variables, 
--   	      	      	      	      	   change BOM routine
-- 12-Apr-05    AJudkowicz      01 03   	   Add error code if it fails when creating 
--   	      	      	      	      	   production schedule
--   	      	      	      	   01 04   	   Check for KeyId equals to null when assigning 
--   	      	      	      	      	   values to UDPs
--   	      	      	      	      	   Update MCR.ProdId when Product is created
-- 13-Apr-05    AJudkowicz      01 05   	   Change BOM_Formulation_Id UDP to use TableId=28
--   	      	      	      	      	   Fix routine to support multiple MCRs with the same Product   	      	      	      	   
-- 18-Apr-05    AJudkowicz      01 06   	   BOM routine does not have the master concept anymore
--   	      	      	      	      	   BOMF.Description = RuleId:PO#
--   	      	      	      	      	   Change cursor for PP to not join MPR to avoid multiple records
--   	      	      	      	      	   when multiple MPRs
-- 20-Apr-05    AJudkowicz   	   01 07   	   Add Flag to truncate leading 0s for ProductCode and ProcessOrder
-- 22-Apr-05    AJudkowicz      01 08   	   Change cursor names, because there was another cursor with the same
--   	      	      	      	      	   name on the PP spserver
-- 25-Apr-05    AJudkowicz      01 09   	   Ignore Paths with PLId = 0 when looking up ER paths
--   	      	      	      	      	   Change Default value for Nopath UDP to 3, since it does not create
--   	      	      	      	      	   paths anymore
-- 04-May-05    	   ''   	      	   01 10   	   MCR.EquipmentElementLevel.Location.EquipmentId is not mandatory. If
--   	      	      	      	      	   not present, the SP will ALTER  the product, if necessary, but it 
--   	      	      	      	      	   will not associate with any PU. It will not return -180 error either
--   	      	      	      	      	   It will populate BOMFI.PU_ID with null too.
-- 05-May-05    ''   	      	   01 11   	   Move the UDP routine for PP AFTER the PP record is created
-- 13-May-05    ''   	      	   01 12   	   Stop returning warning message when new MCA product is not associated
--   	      	      	      	      	   with new unit (error -185).
--   	      	      	      	      	   ALTER  PP records with error status if any new MCA product could not
--   	      	      	      	      	   be associated with any PUId or the PP is unbound and a new MCA
--   	      	      	      	      	   product was created (therefore, not associated with any Path)
-- 17-May-05   	   ''   	      	   01 13   	   Change Product creation routine for MPR/MCR, so it checks for 
--   	      	      	      	      	   PU and Path association, even for existing products
-- 29-Jun-05   	      	      	   01 14   	   Not update process orders if they are not pending
--   	      	      	      	      	   Rename error codes to comply  with pre-defined error ranges
-- 21-Sep-05   	   AJudkowicz   	   01 15   	   Add support to UDP to ignore XML BOM info
--   	      	      	      	      	   Add support to UDP to point to default product family for raw material
-- 30-Sep-05    AJudkowicz      01 16     Change how to handle new MPR products, when a MPR product 
--   	      	      	      	      	   does not have a PU or Path to associate with, when a new MCR 
--   	      	      	      	      	   product does not have a PU to associate with
-- 03-Oct-05    AJudkowicz   	   01 17   Fix 2nd call to spS95OE_BTScheduleProdCreate
-- 20-Oct-05    Alex Judkowicz  01 18     Add parameter listing the PP status that do NOT allow a PO
--   	      	      	      	      	   to be updated. It changed how error 108 works
-- 21-Oct-05    Alex Judkowicz  01 19     Keep the current status for existing POs which new status
--   	      	      	      	      	   was not set to 'error'
-- 28-Nov-05    Alex Judkowicz  01 20     Change the Update Subscription column to use the passed
--   	      	      	      	      	   SubscriptionId. 
--   	      	      	      	      	   Add support to UDPs to append product code to product descr 
--   	      	      	      	      	   when creating new products and to allow prod descn update. 
--   	      	      	      	      	   Changed where condition for the cursor on the MCR loop to 
--   	      	      	      	      	   force all MCRs to call the inner SP. 
--   	      	      	      	      	   Change the product handle SP call to add a new input param 
--   	      	      	      	      	   to flag if prod description is configured.
--   	      	      	      	      	   Change MPR and MCR lookups to pre-pend prod code to proddesc,
--   	      	      	      	      	   if parameter is on.
--   	      	      	      	      	   Change product existence error checking to use prod code
--   	      	      	      	      	   instead prod desc, since prod desc can now be updated
-- 10-Jan-06   	   Alex Judkowicz  02  01   	   EC 1.5:
--   	      	      	      	      	   Rename SP
--   	      	      	      	      	   Add support for <UDP> UDPs for PP and PS, <ANY> spLocals
--   	      	      	      	      	   retrieve UDPs by Id
--   	      	      	      	      	   remove most of the cursors
--   	      	      	      	      	   change to code to not crash with the 'error' pp status does
--   	      	      	      	      	   not exist
--   	      	      	      	      	   Support TimeModified UDP
-- 23-Jan-06   	   Alex Judkowicz  02  02  Change TimeModifier UDP id from -999 to -69
-- 24-Jan-06   	   Alex Judkowicz  02  03  Get MPR.PathUoM using the Event_Subtypes.Dim_X_ENg_Unit_Id 
--   	      	      	      	      	   instead Event_Subtypes.DImX_Eng_Unit string
--   	      	      	      	      	   Incorporate error when the <ANY> SP can not be found   	      	   
--   	      	      	      	      	   Store the Original UOM for the Production Setup (batch) in
--   	      	      	      	      	   a UDP
-- 26-Jan-06   	   Alex Judkowicz 02   04  Disable StorageZOne, Truncate extra zeroes and preprend
--   	      	      	      	      	   product code routines, because they are to be moved to the
--   	      	      	      	      	   custom orchestrations.
-- 09-Feb-06   	   Ahmir Hussain 02    05  Changed ErrorIdSPNotFound to '-999' and ErrorIdSPFailed to '-998'
--   	      	      	      	      	   to match what is in the error_message_data table
-- 09-Feb-06   	   Ahmir Hussain 02   06   Changed @tXML to #tXML
-- 21-Mar-06     Alex Judkowicz  	  02   07  Disabled error codes -102,..,-105, error codes -109,..,-112
--  	    	    	    	    	   Disabled RepeatedPO (-18) UDP
-- 22-Mar-06     Alex Judkowicz 02   08  	   Replace message -144 with -142
-- 31-Mar-06  	   Alex Judkowicz 02   09  Stop harcoding the -26 UDP to 0 meaning it will support
--  	    	    	    	    	   using prodcode:proddescription to look up products
--=================================================================================================
CREATE PROCEDURE [dbo].[spS95OE_ProductionScheduleDownload]
   	   @XML   	      	      	     TEXT  	 -- The B2MML Production Schedule Message
-- 	   @ProcessOrderOutput 	  	     VARCHAR(25) = '' 	 OUTPUT,
--    @ErrCode   	      	      	 VARCHAR(255) = ''   	   OUTPUT
AS 
SET NOCOUNT ON
DECLARE   @iDoc    	      	      	   INT,
      @RowCount INT,
      @KeyId    INT,
      @TableFieldId   INT,
      @TableFieldValue VARCHAR(255),
      @SubscriptionTableID            INT,
      @PrdExecPathTableID   INT,
 	     @FlgCreateProduct 	  	  	  	 INT,
 	     @FlgCreateUOM 	  	  	  	  	 INT,
   	   @ErrMsg    	      	      	   VARCHAR(4000),
   	   @ErrCode  INT,
   	   @RC   	      	      	      	   INT,
   	   @PPId    	      	      	   INT,
   	   @UserId   	      	      	   INT,
   	   @ProcessOrder    	      	   VARCHAR(100),
   	   @CommentId    	      	      	   INT,
   	   @Comment   	      	      	   VARCHAR(4000),
   	   @ProdId   	      	      	   INT,
   	   @PathId   	      	      	   INT,
   	   @PPStatusId   	      	      	   INT,
   	   @SPPPStatusId   	      	   INT,
   	   @ParentId   	      	      	   INT,
   	   @NodeId   	      	      	   INT,
   	   @ERNodeId   	      	      	   INT,
   	   @SRNodeId   	      	      	   INT,
   	   @PPSetupId   	      	      	   INT,
   	   @PUId   	      	      	   INT,
   	   @DebugFlag   	      	      	   INT,
   	   @mprNoProduct     	      	   INT,
   	   @mcrNoProduct   	        	   INT,
   	   @mprNoPathProd   	      	   INT,
   	   @mprNoPath   	      	      	   INT,
   	   @NoFormulation   	      	   INT,
   	   @DefaultMPRProdId   	      	   INT,
   	   @DefaultMCRProdId   	      	   INT,
   	   @DefaultBOMFamilyId   	      	   INT,
   	   @DefaultProdFamilyId   	   INT,
   	   @DefaultRawMaterialProdId   	   INT,
   	   @ProdCode   	      	      	   VARCHAR(100),
   	   @ProdDesc   	      	      	   VARCHAR(100),
   	   @DataSourceId    	      	   INT,
   	   @FormulationId   	      	   INT,
   	   @FormulationItemId   	      	   INT,
   	   @TableFieldDesc   	      	   VARCHAR(255),
   	   @ValueString   	      	   VARCHAR(255),
   	   @StartTime   	      	      	   DATETIME,
   	   @EndTime   	      	      	   DATETIME,
   	   @TransType   	      	      	   INT,
   	   @TransNum   	      	      	   INT,
   	   @Qty   	      	      	   FLOAT,
   	   @MaterialLotId   	      	   VARCHAR(100),
   	   @ErrTemp   	      	      	   VARCHAR(255),
   	   @BOMFITableId   	      	   INT,
   	   @ProdUnitsTableId   	      	   INT,
   	   @PPTableId   	      	      	   INT,
   	   @FlgRemoveLeadingZeros   	   INT,
   	   @PPErrorStatusID   	      	   INT,
   	   @OriginalProdId   	      	   INT,
   	   @FlgIgnoreBOMInfo   	      	   INT,
   	   @CreatePUAssoc   	      	   INT,
   	   @CreatePathAssoc   	      	   INT,
   	   @NoUpdatePOStatusesMask   	   VARCHAR(255),
   	   @Pos   	      	      	   INT,
   	   @ParsedString   	      	   VARCHAR(255),
   	   @CurrentPPStatusId   	      	   INT,
   	   @FlgPrependNewProdWithDesc   	   INT,
   	   @PrependNewProdDelimiter   	   VARCHAR(255),
   	   @FlgUpdateMCRDesc   	      	   INT,
   	   @FlgUpdateMPRDesc   	      	   INT,
   	   @FlgUpdateDesc   	      	   INT,
   	   @MaterialReservationSequence    VARCHAR(255),
   	   @ScrapPercent   	      	   VARCHAR(255),
   	   @RecSPTotal   	      	   INT,
   	   @RecSPId   	      	      	   INT,
   	   @RecParmTotal   	      	   INT,
   	   @RecParmId   	      	      	   INT,
   	   @SQLStatement   	      	   NVARCHAR(2000),
   	   @Id   	      	      	      	   INT,
   	   @ParmDefinition   	      	   NVARCHAR(2000),
   	   @SPOutputValue   	      	   INT,
   	   @flgCheckErrorStatus   	   INT,
   	   @PSTableId   	      	      	   INT,
   	   @TimeModifier   	      	   INT,
   	   @SqlRetStat    	      	   INT,
   	   @PSOriginalEngUnitCodeUDP   	   INT,
   	   @UOM   	      	      	   VARCHAR(255),
 	  	  	 @ReferenceString 	  	  	  	 VARCHAR(255),
 	     @RetProcessOrder 	  	  	 VarChar(50),
 	     @RetPathCode 	  	  	  	 VarChar(50),
 	     @RetPathProdCode 	  	  	 Varchar(50),
 	     @RetPathUOM 	  	  	  	  	 VarChar(25),
 	     @RetErrCode 	  	  	  	  	 VarChar(50),
 	     @RetErrMsg 	  	  	  	  	 VarChar(4000),
 	     @FlgSendRSProductionPlan 	 Int,
 	     @FlgSendRSProductionSetup 	 Int,
 	     @FlagCreate 	  	  	  	  	 Int,
      @OECommonSubscription    Int,
      @OEDownloadSubscription Int
-------------------------------------------------------------------------------
-- Error Code table
-------------------------------------------------------------------------------
DECLARE  @tErr   	      	   TABLE (
   	   ErrorCode    	      	   INT,
   	   ErrorCategory         VARCHAR(500),
   	   ErrorMsg              VARCHAR(500),
   	   Severity              INT,
   	   ReferenceData    	     VARCHAR(500))
DECLARE  @tErrRef   	      	   TABLE (
   	   ErrorCode    	      	   INT,
   	   ReferenceData    	     VARCHAR(500))
-------------------------------------------------------------------------------
-- FUNCTION 1  PARSE XML
-------------------------------------------------------------------------------
SELECT  @DebugFlag = 0
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT  @ErrMsg    	      	      	 = '',
 	  	 @FlgSendRSProductionPlan 	 = 0,
 	  	 @FlgSendRSProductionSetup 	 = 0,
 	  	 @FlagCreate = 1,
    @SubscriptionTableID          = 27, 
    @PrdExecPathTableID       = 13, 
    @OECommonSubscription     = -7,
    @OEDownloadSubscription     = -8,
 	  	 @BOMFITableId   	      	     = 28,   	   -- Bill_Of_Material_Formulation_Item
 	  	 @PPTableId   	      	     = 7,   	   -- Production_Plan,
 	  	 @PSTableId   	      	     = 8,   	   -- Production_Setup
 	  	 @ProdUnitsTableId   	      	 = 43,   	   -- Prod_Units
    @PSOriginalEngUnitCodeUDP   	 = -71    	 -- Production Setup (batch to produce) Original Engineering Unit 
-- Get Common\Site Parameters
EXEC   	   dbo.spCmn_UDPLookupById 
   	   @DataSourceId   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OECommonSubscription,
   	   -3,
   	   '18'   	      	      	      	   --@DefaultValue   	   NVARCHAR(1000)
EXEC   	   dbo.spCmn_UDPLookupById
   	   @PPStatusID   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OECommonSubscription,
   	   -11,   	      	      	      	   --BTSched - DefPPStatusId
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @PPErrorStatusID   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OECommonSubscription,
   	   -12,   	      	      	      	   --BTSched - ErrPPStatusId
   	   '0'   	      	      	      	   --@DefaultValue   	   NVARCHAR(1000)   	      	   
EXEC   	   dbo.spCmn_UDPLookupById
   	   @TimeModifier   	      	 OUTPUT,  
   	   @SubscriptionTableID,
   	   @OECommonSubscription,
   	   -69,   	      	      	      	   --Time Modifier
   	   0
-- Download Subscriptions
EXEC   	   dbo.spCmn_UDPLookupById
   	   @DefaultBOMFamilyId   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -5,   	      	      	      	      	   --BTSched - DefBOMFamilyId
   	   '-1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @mprNoPath   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -8,   	      	      	      	      	   --BTSched - NoPathOption
   	   '3'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @FlgIgnoreBOMInfo   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -19,   	      	      	      	   --BTSched - IgnoreBOMInfo
   	   '0'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @MaterialReservationSequence   OUTPUT, 
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -59,   	      	      	      	   --'BTSched - MaterialSeqMCRPDesc',   	      	   
   	   'materialreservationsequence'   	   --@DefaultValue   	   NVARCHAR(1000)
EXEC   	   dbo.spCmn_UDPLookupById
   	   @ScrapPercent   	      	 OUTPUT,  
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -60,   	      	      	      	   --BTSched - ScrapPercentMCRPDesc
   	   'scrappercent'   	      	      	    --@DefaultValue   	   NVARCHAR(1000)
-------------------------------------------------------------------------------
--  Configure Flag to enable/disable routine that assigns the 'Error' status
-- to a process order if some conditions such as new MPR product happens
-- based on the existence of this status Id.
-------------------------------------------------------------------------------
SELECT   	   @flgCheckErrorStatus   	   = 0
IF   	   (SELECT   	   Count(*)
   	      	   FROM   	   Production_Plan_Statuses
   	      	   WHERE   	   PP_Status_Id   	   = @PPErrorStatusID) > 0
BEGIN
   	   SELECT   	   @flgCheckErrorStatus   	   = 1
END
-------------------------------------------------------------------------------
-- Make a Table to hold the parsed xml.
-------------------------------------------------------------------------------
--DECLARE   	   @tXML   	   TABLE (
CREATE TABLE #tXML (
   	   Id    	      	      	   INT, 
   	   ParentId    	      	   INT, 
   	   NodeType    	      	   INT, 
   	   LocalName    	      	   VARCHAR(2000), 
   	   Prev    	      	   INT, 
   	   Ttext    	      	   VARCHAR(2000))
CREATE CLUSTERED INDEX txml_idx4 on #tXML(parentid, id)
-------------------------------------------------------------------------------
-- parse the xml
-------------------------------------------------------------------------------
-- print '--EnteringXMLPrepareDoc: ' + convert(char(30), getdate(), 21)
EXEC   	   dbo.sp_xml_PrepareDocument 
   	   @Idoc   	      	      	   OUTPUT, 
   	   @Xml,
--   	   '<ns0:ProcessProductionSchedule xmlns:ns0="http://www.wbf.org/xml/B2MML-V0401"/>'
   	   '<ns0:ProductionSchedule xmlns:ns0="http://www.wbf.org/xml/B2MML-V0401"/>'
-------------------------------------------------------------------------------
-- fill the TABLE with parsed xml
-------------------------------------------------------------------------------
-- print '--EnteringInsert: ' + convert(char(30), getdate(), 21)
INSERT   	   #tXML (Id,ParentId,NodeType,LocalName,Prev,tText)
 	 SELECT   	 Id,ParentId,NodeType,SUBSTRING(LocalName, 1, 4000),Prev,SUBSTRING(TEXT, 1, 4000)
 	 FROM   	   OPENXML(@idoc, '/ns0:ProductionSchedule', 2) 
-------------------------------------------------------------------------------
-- close the xml document
------------------------------------------------------------------------------
EXEC   	   dbo.sp_xml_RemoveDocument 
   	   @Idoc
   	   
--IF @DebugFlag = 1
 	 --select * from #tXML order by ParentId, id
------------------------------------------------------------------------------
-- Now we are ready to make something useful of the parsed xml document
-- Production Request table
-------------------------------------------------------------------------------
--RETURN(0) --------------
DECLARE   @tPR   	      	   TABLE (
   	   Id   	      	      	   INT   	      	   IDENTITY(1,1),
   	   NodeId    	      	   INT,
   	   ProcessOrder    	   VARCHAR(100),
   	   Comment    	      	   VARCHAR(1000),
   	   FormulationDesc    	   VARCHAR(255),
   	   BOMId   	      	   INT,
   	   FormulationId   	   INT,
   	   CommentId   	      	   INT,
   	   Status   	      	   INT)
   	    
-------------------------------------------------------------------------------
-- Segment Request table
-------------------------------------------------------------------------------
DECLARE  @tSR   	      	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   EarliestStartTime    	   DATETIME,
   	   LatestEndTime    	   DATETIME)
-------------------------------------------------------------------------------
-- Equipment Request table
-------------------------------------------------------------------------------
DECLARE  @tER   	      	   TABLE (
   	   Id   	      	      	   INT   	      	   IDENTITY(1,1),
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   EquipmentId    	   VARCHAR(100),
   	   PathId    	      	   INT,
   	   PPId    	      	   INT,
   	   CommentId   	      	   INT,
   	   FormulationId   	   INT,
   	   PPStatusId   	      	   INT,
   	   Status   	      	   INT,
   	   --Path specific UDPs
      DefaultProdFamilyId   	 INT 	 ,
      UserId 	 INT 	 ,
      mprNoPathProd 	 INT 	 ,
      mprNoProduct 	 INT 	 ,
      mcrNoProduct 	 INT 	 ,
      NoFormulation 	 INT 	 ,
      DefaultMPRProdId 	 INT 	 ,
      DefaultMCRProdId 	 INT 	 ,
      DefaultRawMaterialProdId 	 INT 	 ,
      NoUpdatePOStatusesMask 	 VARCHAR(255) 	 ,
      FlgPrependNewProdWithDesc  	 INT 	 ,
      PrependNewProdDelimiter  	 VARCHAR(255) 	 ,
      FlgUpdateMPRDesc 	 INT 	 ,
      FlgUpdateMCRDesc 	 INT 	 ,
      FlgCreateProduct 	 INT 	 )
   	   
-------------------------------------------------------------------------------
-- Material Produced Requirement table
-------------------------------------------------------------------------------
DECLARE  @tMPR   	      	   TABLE (
   	   Id   	      	      	   INT   	      	   IDENTITY(1,1),
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   ProdCode    	      	   VARCHAR(100),
   	   ProdDesc    	      	   VARCHAR(100),
   	   ProdId    	      	   INT,
   	   MaterialLotID    	   VARCHAR(100),
   	   EquipmentId    	   VARCHAR(100),
   	   QuantityString    	   VARCHAR(100),
   	   UOM    	      	   VARCHAR(100),
   	   PUId    	      	   INT,
   	   PathUoM    	      	   VARCHAR(100),
   	   Qty    	      	   FLOAT,
   	   FlgNewProduct   	   INT,
   	   PathId   	      	   INT,
   	   CreatePUAssoc   	   INT,
   	   CreatePathAssoc   	   INT,
   	   Status   	      	   INT,
   	   PPSetupId   	      	   INT)
-------------------------------------------------------------------------------
-- Material Produced Requirement Property table
-------------------------------------------------------------------------------
DECLARE  @tMPRP   	      	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   Id    	      	      	   VARCHAR(100),
   	   ValueString    	   VARCHAR(100))
-------------------------------------------------------------------------------
-- Material Consumed Requirement table
-------------------------------------------------------------------------------
DECLARE  @tMCR   	      	   TABLE (
   	   Id   	      	      	   INT   	      	   IDENTITY(1,1),
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   ProdCode    	      	   VARCHAR(100),
   	   ProdDesc    	      	   VARCHAR(100),
   	   ProdId    	      	   INT,
   	   MaterialLotId    	   VARCHAR(100),
   	   EquipmentId    	   VARCHAR(100),
   	   QuantityString    	   VARCHAR(100),
   	   UOM    	      	   VARCHAR(100),
   	   PUId    	      	   INT,
   	   FormulationUoM    	   VARCHAR(100),
   	   FormulationId    	   INT,
   	   FormulationItemId    	   INT,
   	   FlgNewProduct   	   INT,
   	   Status   	      	   INT)
-------------------------------------------------------------------------------
-- Material Consumed Requirement Property table
-------------------------------------------------------------------------------
DECLARE  @tMCRP   	      	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   Id    	      	      	   VARCHAR(100),
   	   ValueString    	   VARCHAR(100))
-------------------------------------------------------------------------------
-- Location table
-------------------------------------------------------------------------------
DECLARE  @tLocation    	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   EquipmentId    	   VARCHAR(100),
   	   EquipmentElementLevel   VARCHAR(100))
-------------------------------------------------------------------------------
-- Quantity table
-------------------------------------------------------------------------------
DECLARE  @tQty   	      	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   QuantityString    	   VARCHAR(100),
   	   UOM    	      	   VARCHAR(100))
-------------------------------------------------------------------------------
-- <Any> UDPS table for ProductionRequest element (ProductionPlan) 
-------------------------------------------------------------------------------
DECLARE  @tAnyUDP   	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   TableId   	      	   INT,
   	   KeyId   	      	   INT,
   	   tText   	      	   VARCHAR(255),
   	   ElementName   	      	   VARCHAR(255),
   	   UDPElementId    	   INT)
-------------------------------------------------------------------------------
-- <Any> Custom Stored Procedures elements
-------------------------------------------------------------------------------
DECLARE  @tAnySP   	      	   TABLE (
   	   Id   	      	      	   INT   	   IDENTITY(1,1),   	   
   	   ParentId    	      	   INT,
   	   ElementName   	      	   VARCHAR(255),
   	   NodeId    	      	   INT,
   	   tText   	      	   VARCHAR(255),
   	   Status   	      	   INT)
-------------------------------------------------------------------------------
-- <Any> UDPS table for MaterialProducedRequirement element (ProductionSetup)
-------------------------------------------------------------------------------
DECLARE  @tAnyMPRUDP   	   TABLE (
   	   ParentId    	      	   INT,
   	   NodeId    	      	   INT,
   	   TableId   	      	   INT,
   	   KeyId   	      	   INT,
   	   tText   	      	   VARCHAR(255),
   	   ElementName   	      	   VARCHAR(255),
   	   UDPElementId    	   INT)
-------------------------------------------------------------------------------
-- Non Update Statuses table
-- print '--Non Update Statuses table: ' + convert(char(30), getdate(), 21)
-------------------------------------------------------------------------------
DECLARE   	   @tPPStatus TABLE (
   	   PPStatusId   	   INT   	      	   NULL)
SELECT   	   @NoUpdatePOStatusesMask = @NoUpdatePOStatusesMask +','
SELECT   	   @Pos =CharIndex(',', @NoUpdatePOStatusesMask)
WHILE   	   @Pos > 1 
BEGIN
   	   SELECT   	   @ParsedString   	   = SubString(@NoUpdatePOStatusesMask, 1, @Pos -1)
   	   IF   	   ISNumeric(@ParsedString) = 1
   	      	   INSERT   	   @tPPStatus (PPStatusId)
   	      	      	   VALUES   	   (Convert(Int,@ParsedString))
   	   SELECT   	   @NoUpdatePOStatusesMask   	   = Right(@NoUpdatePOStatusesMask, Len(@NoUpdatePOStatusesMask) - @Pos)
   	   SELECT   	   @Pos =CharIndex(',', @NoUpdatePOStatusesMask)
END
-------------------------------------------------------------------------------
-- Production Request    	   
-- print '--pr: ' + convert(char(30), getdate(), 21)
-------------------------------------------------------------------------------
INSERT   	   @tPR ( NodeId ) 
   	   SELECT   	   Id 
   	      	   FROM   	   #tXML 
   	      	   WHERE   	   LocalName = 'ProductionRequest'
   	   UPDATE   	   pr
   	   SET   	 ProcessOrder = xIc.tText,
   	      	   Comment = xDc.tText,
   	      	   FormulationDesc = xPDRIc.tText
   	   FROM   	   @tPR pr
   	   LEFT   	   JOIN   	   #tXML xI ON pr.NodeId = xI.ParentId AND xI.LocalName = 'Id'
   	   LEFT   	   JOIN   	   #tXML xIc ON xI.Id = xIc.ParentId
   	   LEFT   	   JOIN   	   #tXML xD ON pr.NodeId = xD.ParentId AND xD.LocalName = 'Description'
   	   LEFT   	   JOIN   	   #tXML xDc ON xD.Id = xDc.ParentId
   	   LEFT   	   JOIN   	   #tXML xPDRI ON pr.NodeId = xPDRI.ParentId AND xPDRI.LocalName = 'ProductProductionRuleId'
   	   JOIN   	   #tXML xPDRIc ON xPDRI.Id = xPDRIc.ParentId
UPDATE   	   pr  -- BOM
   	   SET   	   BOMId = bom.BOM_Id
   	   FROM   	   @tPR pr
   	   JOIN   	   Bill_Of_Material bom ON pr.FormulationDesc = bom.BOM_Desc
IF @DebugFlag = 1
 	 SELECT 'Production Request', * FROM @tPR
IF (SELECT COUNT(*) FROM @tPR) > 1 
  BEGIN
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT -300, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL
        FROM dbo.email_message_data emd 
        WHERE emd.Message_Id = -301
 	   GOTo ErrCode
  END
IF 	 EXISTS(SELECT 	 1 FROM 	 @tPR WHERE 	 ProcessOrder IS NULL)
BEGIN
 	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	   VALUES (1001,'Schedule Download Critical Message', 
 	  	  	  	 'At least one of the received ProductionRequests is missing the ID element (Process Order number)', 1, 'Missing Process Order Number')
 	  	  	 GOTo ErrCode
END
-------------------------------------------------------------------------------
-- Segment Requirement    	  
-- print '--sr: ' + convert(char(30), getdate(), 21) 
-------------------------------------------------------------------------------
INSERT    	   @tSR (
   	   ParentId,
   	   NodeId )
   	   SELECT   	   x1.ParentId,
   	      	   x1.Id 
   	      	   FROM   	   #tXML x1 
   	      	   WHERE   	   x1.LocalName = 'SegmentRequirement'
UPDATE   	   sr
 	  	  SET  	  EarliestStartTime = xESTc.tText,
  	    	  	  	  LatestEndTime = xLETc.tText
   	   FROM   	   @tSR sr
   	   LEFT   	   JOIN   	   #tXML xEST ON sr.NodeId = xEST.ParentId AND xEST.LocalName = 'EarliestStartTime'
   	   LEFT   	   JOIN   	   #tXML xESTc ON xEST.Id = xESTc.ParentId
   	   LEFT   	   JOIN   	   #tXML xLET ON sr.NodeId = xLET.ParentId AND xLET.LocalName = 'LatestEndTime'
   	   LEFT   	   JOIN   	   #tXML xLETc ON xLET.Id = xLETc.ParentId
    	    
    	    
IF EXISTS (SELECT 1 FROM @tSR WHERE EarliestStartTime IS NULL OR LatestEndTime IS NULL)
  BEGIN
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT 1000, 'Schedule Download Informational Message', 'EarliestStartTime is set to null for Parent/Node:' 
 	  	  	 + CAST(sr.ParentId AS VARCHAR(10)) + '/' + CAST(sr.NodeId AS VARCHAR(10)), 1, 'Process Order: ' 
 	  	  	 + COALESCE(pr.ProcessOrder, 'NA') 
        FROM @tSR sr
        JOIN @tPR pr
        on pr.NodeId = sr.ParentId
        WHERE sr. EarliestStartTime IS NULL
   END
IF   	   @TimeModifier <> 0
BEGIN
   	   UPDATE   	   @tSR
   	      	   SET   	   EarliestStartTime = DateAdd(mi, @TimeModifier, EarliestStartTime),
   	      	      	   LatestEndTime = DateAdd(mi, @TimeModifier, LatestEndTime)
END
IF @DebugFlag = 1
 	 SELECT 'Segment Req', * FROM @tSR
-------------------------------------------------------------------------------
-- Equipment Requirement
-- print '--er: ' + convert(char(30), getdate(), 21)
-------------------------------------------------------------------------------
-- Each of these records will correspond to a Production_Plan record.
-------------------------------------------------------------------------------
INSERT   	   @tER (
   	   ParentId,
   	   NodeId,
   	   EquipmentId)
   	   SELECT   	   x1.ParentId,
   	      	   x1.Id,
   	      	   x3.tText
   	      	   FROM   	   #tXML x1
   	      	   JOIN   	   #tXML x2 ON x2.ParentId = x1.Id AND x2.LocalName = 'EquipmentId'
   	      	   JOIN   	   #tXML x3 ON x3.ParentId = x2.Id 
   	      	   WHERE   	   x1.LocalName = 'EquipmentRequirement'
--Try 3 ways to set the PathId   	      	   
UPDATE   	   er
   	   SET   	   PathId = dsx.Actual_Id
   	   FROM   	   @tER er
   	   JOIN   	   dbo.Data_Source_XRef dsx ON er.EquipmentId = dsx.Foreign_Key
   	      	   AND   	   dsx.DS_Id = @DataSourceId
   	      	   AND   	   dsx.Table_Id = 13
UPDATE   	   er
   	   SET   	   PathId = pep.Path_Id
   	   FROM   	   @tER er
   	   JOIN   	   dbo.PrdExec_Paths pep 
   	   ON    	   er.EquipmentId = pep.Path_Code
   	   AND   	   pep.PL_Id   	   <> 0
   	   WHERE   	   er.PathId IS NULL
UPDATE   	   er
   	   SET   	   PathId = pep.Path_Id
   	   FROM   	   @tER er
   	   JOIN   	   dbo.PrdExec_Paths pep 
   	   ON    	   er.EquipmentId = pep.Path_Desc
   	   AND   	   pep.PL_Id   	   <> 0
   	   WHERE   	   er.PathId IS NULL
-- For BOUND POs, Set Path Defined UDPs, default where not set
-- For UNBOUND POs, Set UDPs based on the Download Subscription, default where not set
-------------------------------------------------------------------------------
-- Set the path based parms first by subscription/default then by path in mass 
-- to catch all paths that don't have UDPs and catch the unbound equipment.
-- Then loop through each @tER setting an specific PathUDP Values
-------------------------------------------------------------------------------
EXEC   	   dbo.spCmn_UDPLookupById
   	   @DefaultProdFamilyId   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -4,
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById 
   	   @UserId   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -6,
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @mprNoPathProd   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -7,   	      	      	      	      	   --BTSched - NoProdOnPathOption
   	   '2'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @mprNoProduct   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -9,   	      	      	      	      	   --BTSched - NoMprProductOption
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @mcrNoProduct   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -10,   	      	      	      	   --BTSched - NoMcrProductOption
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @NoFormulation   	      	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -13,   	      	      	      	   --BTSched - NoBOMFormulationOption
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @DefaultMPRProdId   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -15,   	      	      	      	   --BTSched - DefMPRProdId
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @DefaultMCRProdId   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -16,   	      	      	      	   --BTSched - DefMCRProdId
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @DefaultRawMaterialProdId   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -20,   	      	      	      	   --BTSched - DefRawMatProdFamId
   	   '1'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @NoUpdatePOStatusesMask   	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -25,   	      	      	      	      	   --BTSched - NoUpdateProcessOrderStatuses
   	   ''
EXEC   	   dbo.spCmn_UDPLookupById
   	   @FlgPrependNewProdWithDesc    	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -26,   	      	      	      	   --BTSched - ProdCodeInDescription
   	   0
EXEC   	   dbo.spCmn_UDPLookupById
   	   @PrependNewProdDelimiter    	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -27,   	      	      	      	   --BTSched - DelimiterProdCode
   	   ':'
EXEC   	   dbo.spCmn_UDPLookupById
   	   @FlgUpdateMPRDesc   	       	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -28,   	      	      	      	   --BTSched - UpdateMPRDescription
   	   0
EXEC   	   dbo.spCmn_UDPLookupById
   	   @FlgUpdateMCRDesc   	       	   OUTPUT,
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -29,   	      	      	      	   --BTSched - UpdateMCRDescription
   	   0
EXEC   	   dbo.spCmn_UDPLookupById
   	   @FlgCreateProduct   	      	 OUTPUT,  
   	   @SubscriptionTableID,
   	   @OEDownloadSubscription,
   	   -82,   	      	      	      	   --Create product on the fly
   	   '0'
-- Set all records to the download subscription/default obtained from the previous queries
-- this will set the default for both bound and unbound 
UPDATE   	   er 	 
SET 	 DefaultProdFamilyId   = @DefaultProdFamilyId   	 ,
 	 UserId = @UserId   	 ,
 	 mprNoPathProd = @mprNoPathProd   	 ,
 	 mprNoProduct = @mprNoProduct   	 ,
 	 mcrNoProduct = @mcrNoProduct   	 ,
 	 NoFormulation = @NoFormulation   	 ,
 	 DefaultMPRProdId = @DefaultMPRProdId   	 ,
 	 DefaultMCRProdId = @DefaultMCRProdId   	 ,
 	 DefaultRawMaterialProdId = @DefaultRawMaterialProdId   	 ,
 	 NoUpdatePOStatusesMask = @NoUpdatePOStatusesMask   	 ,
 	 FlgPrependNewProdWithDesc  = @FlgPrependNewProdWithDesc    	 ,
 	 PrependNewProdDelimiter  = @PrependNewProdDelimiter    	 ,
 	 FlgUpdateMPRDesc = @FlgUpdateMPRDesc   	 ,
 	 FlgUpdateMCRDesc = @FlgUpdateMCRDesc   	 ,
 	 FlgCreateProduct = @FlgCreateProduct 	 
 	 FROM @tER er 	 
-- Now Update any Paths that have specific UDPs
DECLARE   	   TFVCursor INSENSITIVE CURSOR  
 	 For (SELECT tfv.KeyId, tfv.Table_Field_Id, tfv.Value
 	         FROM Table_Fields_Values tfv
 	         JOIN @tER er on tfv.KeyId = er.PathId and tfv.TableId = @PrdExecPathTableID
 	         )
   	      	 For Read Only 
OPEN   	   TFVCursor
FETCH   	   NEXT FROM TFVCursor INTO @KeyId, @TableFieldId, @TableFieldValue
WHILE   	   @@Fetch_Status = 0
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
 	   FETCH   	   NEXT FROM TFVCursor INTO @KeyId, @TableFieldId, @TableFieldValue
END
CLOSE   	      	   TFVCursor
DEALLOCATE   	   TFVCursor
UPDATE   	   er -- Bound Process Orders
   	   SET   	   PPId    	      	   = pp.PP_Id,
   	      	   FormulationId    	   = pp.BOM_Formulation_Id,
   	      	   PPStatusId   	   = pp.PP_Status_Id
   	   FROM   	   @tER er
   	   JOIN   	   @tSR sr ON er.ParentId = sr.NodeId
   	   JOIN   	   @tPR pr ON sr.ParentId = pr.NodeId
   	   JOIN   	   dbo.Production_Plan pp   	   ON    	   er.PathId = pp.Path_Id  AND   	   pr.ProcessOrder = pp.Process_Order
   	   WHERE   	   er.PathId   	   Is Not Null
UPDATE   	   er -- Unbound Process Orders
   	   SET   	   PPId    	      	   = pp.PP_Id,
   	      	   FormulationId    	   = pp.BOM_Formulation_Id,
   	      	   PPStatusId   	   = pp.PP_Status_Id
   	   FROM   	   @tER er
   	   JOIN   	   @tSR sr ON er.ParentId = sr.NodeId
   	   JOIN   	   @tPR pr ON sr.ParentId = pr.NodeId
   	   JOIN   	   dbo.Production_Plan pp   ON    	   pp.Path_Id   	   Is Null  AND pr.ProcessOrder = pp.Process_Order
   	   WHERE   	   er.PathId   	   Is Null
UPDATE   	   er
   	   SET   	   CommentId = cc.Comment_Id
   	   FROM   	   @tER er
   	   JOIN   	   dbo.Production_Plan pp ON er.PPId = pp.PP_Id
   	   JOIN   	   dbo.Comments cc ON (pp.Comment_Id = cc.TopOfChain_Id  OR   	   pp.Comment_Id = cc.Comment_Id)
   	      	   AND   	   cc.User_Id = @UserId
IF @DebugFlag = 1
 	 SELECT 'Equipment Req', * FROM @tER
-------------------------------------------------------------------------------
-- Locations
-- print '--loc: ' + convert(char(30), getdate(), 21)
-------------------------------------------------------------------------------
INSERT   	   @tLocation (NodeId,ParentId,EquipmentId,EquipmentElementLevel )
 	 SELECT   	   xL.Id,
 	  	 xL.ParentId,
 	  	 xEIc.tText,
 	  	 xEELc.tText
 	  	 FROM #tXML xL
 	  	 LEFT JOIN #tXML xEI ON xL.Id = xEI.ParentId AND xEI.LocalName = 'EquipmentId'
 	  	 LEFT JOIN #tXML xEIc ON xEI.Id = xEIc.ParentId
 	  	 LEFT JOIN #tXML xEEL ON xL.Id = xEEL.ParentId AND xEEL.LocalName = 'EquipmentElementLevel'
 	  	 LEFT JOIN #tXML xEELc ON xEEL.Id = xEELc.ParentId
 	 WHERE xL.LocalName = 'Location'
IF @DebugFlag = 1
   	 SELECT 'Location', * FROM @tLocation
-------------------------------------------------------------------------------
-- Quantities    	   
-- print '--q: ' + convert(char(30), getdate(), 21)
-------------------------------------------------------------------------------
INSERT   	   @tQty (NodeId,ParentId,QuantityString, UOM )
   	   SELECT   	   xQ.Id,xQ.ParentId,xQSc.tText,xUOMc.tText
   	      	   FROM   	   #tXML xQ
   	      	   LEFT JOIN #tXML xQS ON xQ.Id = xQS.ParentId AND xQS.LocalName = 'QuantityString'
   	      	   LEFT JOIN #tXML xQSc ON xQS.Id = xQSc.ParentId
   	      	   LEFT JOIN #tXML xUOM ON xQ.Id = xUOM.ParentId AND xUOM.LocalName = 'UnitOfMeasure'
   	      	   LEFT JOIN #tXML xUOMc ON xUOM.Id = xUOMc.ParentId
   	      	   WHERE    	   xQ.LocalName = 'Quantity'
DELETE   	   q1
   	   FROM   	   @tQty q1
   	   JOIN   	   @tQty q2 ON q1.ParentId = q2.ParentId  AND q1.NodeId > q2.NodeId
IF @DebugFlag = 1
   	 SELECT 'Quantities', * FROM @tQty
-------------------------------------------------------------------------------
-- print '--Entering MPR: ' + convert(char(30), getdate(), 21)
-- Material Produced Requiremnt
-------------------------------------------------------------------------------
INSERT   	   @tMPR (NodeId,ParentId,ProdCode,ProdDesc,MaterialLotId,FlgNewProduct,CreatePUAssoc,CreatePathAssoc,Status)
   	   SELECT   	   xMPR.Id, xMPR.ParentId,xPC.tText,xPD.tText,xSPC.tText,0,0,0,0
   	      	   FROM #tXML xMPR
   	      	   LEFT JOIN #tXML xMDI ON xMPR.Id = xMDI.ParentId AND xMDI.LocalName = 'MaterialDefinitionID'
   	      	   LEFT JOIN #tXML xPC ON xMDI.Id = xPC.ParentId
   	      	   LEFT JOIN #tXML xD ON xMPR.Id = xD.ParentId AND xD.LocalName = 'Description'
   	      	   LEFT JOIN #tXML xPD ON xD.Id = xPD.ParentId 
   	      	   LEFT JOIN #tXML xMLI ON xMPR.Id = xMLI.ParentId AND xMLI.LocalName = 'MaterialLotID'
   	      	   LEFT JOIN #tXML xSPC ON xMLI.Id = xSPC.ParentId
   	      	   WHERE   	   xMPR.LocalName = 'MaterialProducedRequirement'
IF   	   (SELECT   	   COUNT(*) FROM @tMPR) = 0 
BEGIN
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT -300, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Process Order: ' + COALESCE( pr.ProcessOrder, 'NA')  
        FROM dbo.email_message_data emd 
        JOIN @tPR pr
        ON 	  	 emd.Message_Id = -300
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- print '--EXIT MPR, Entering LookUP: ' + convert(char(30), getdate(), 21)
-- Look up product 
-------------------------------------------------------------------------------
-- For products that could not be found based on the product code, the SP tries
-- to search based on the description. If configured so, it will compare the 
-- XML value with the concatenation of the ProductCode+delimiter+ProdDescription
-------------------------------------------------------------------------------
IF @DebugFlag = 1
 	 SELECT 'ER TO MPR', er.parentid,er.FlgPrependNewProdWithDesc, er.PrependNewProdDelimiter,mpr.proddesc, mpr.prodcode FROM @tMPR mpr JOIN @tER er on mpr.parentid = er.parentid
-- Adjust product desc based on UPDs 
UPDATE  mpr
   	 SET   	   mpr.prodDesc = COALESCE(mpr.ProdCode,'') +  COALESCE(er.PrependNewProdDelimiter,'') + COALESCE(mpr.ProdDesc,'') 
 	   FROM @tMPR mpr
 	   JOIN @tER er on er.ParentId = mpr.ParentId and er.FlgPrependNewProdWithDesc = 1
UPDATE   	   mpr
   	   SET   	   ProdId = dsx.Actual_Id
   	   FROM   	   @tMPR mpr
   	   JOIN   	   dbo.Data_Source_XRef dsx ON mpr.ProdCode = dsx.Foreign_Key
   	      	   AND   	   dsx.DS_Id = @DataSourceId
   	   JOIN   	   dbo.Tables tt ON dsx.Table_Id = tt.TableId
   	      	   AND   	   tt.TableName = 'Products'
UPDATE   	   mpr
   	   SET   	   ProdId = p.Prod_Id
   	   FROM   	   @tMPR mpr
   	   JOIN   	   dbo.Products p ON mpr.ProdCode = p.Prod_Code
   	   WHERE   	   mpr.ProdId IS NULL
UPDATE   	   mpr
   	   SET   	   ProdId = p.Prod_Id
   	   FROM   	   @tMPR mpr
   	   JOIN   	   dbo.Products p ON mpr.ProdDesc = p.Prod_Desc
   	   WHERE   	   mpr.ProdId IS NULL
UPDATE   	   mpr
   	   SET   	   QuantityString = q.QuantityString,
   	      	   UoM = q.Uom,
   	      	   EquipmentId = l.EquipmentId
   	   FROM   	   @tMPR mpr
   	   LEFT   	   JOIN   	   @tQty q ON mpr.NodeId = q.ParentId
   	   LEFT   	   JOIN   	   @tLocation l ON mpr.NodeId = l.ParentId
UPDATE   	   mpr
   	   SET   	   PUId = dsx.Actual_Id
   	   FROM   	   @tMPR mpr
   	   JOIN   	   dbo.Data_Source_XRef dsx ON mpr.EquipmentId = dsx.Foreign_Key
   	      	   AND   	   dsx.DS_Id = @DataSourceId
   	      	   AND   	   dsx.Table_Id = @ProdUnitsTableId
------------------------------------------------------------------------------
-- Get PUId for MPR by looking for the IsProductionPOint PU for the Path
--
-- Get First MPR record to process
-------------------------------------------------------------------------------
SELECT    	   @Id   	   = NULL
SELECT   	   @Id   	   = MIN(Id)
   	   FROM   	   @tMPR
   	   WHERE   	   PUID   	   IS NULL
   	   AND   	   Status   	   = 0
-------------------------------------------------------------------------------
-- Loop all MPR records with PuId is Null
-------------------------------------------------------------------------------
WHILE   	   (@Id   	   IS NOT NULL)
BEGIN
   	   -------------------------------------------------------------------------------
   	   -- Mark this MPR as processed
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMPR
   	      	   SET   	   Status   	   = 1
   	      	   WHERE   	   Id   	   = @Id
   	   -------------------------------------------------------------------------------
   	   -- Retrieve some MPR attributes
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @NodeId   	      	   = NodeId,
   	      	   @ParentId   	   = ParentId,
   	      	   @PUId   	      	   = PUId
   	      	   FROM   	   @tMPR
   	      	   WHERE   	   Id   	   = @Id
   	   -------------------------------------------------------------------------------
   	   -- Get Path from the EquipmentRequirement (Assume a single ER for a given SR. 
   	   -- If wrong, we need an inner loop)
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @PathId   	   = Null,
   	      	   @PUId   	   = Null
   	   SELECT   	   TOP 1 @PathId = PathId
   	      	   FROM   	   @tER
   	      	   WHERE   	   ParentId   	   = @ParentId
   	   -------------------------------------------------------------------------------
   	   -- Get IsPOroductionPoint PUId for this path
   	   -------------------------------------------------------------------------------
   	   IF   	   @PathId   	   Is Not Null
   	   BEGIN
   	      	   SELECT   	   @PUId   	   = PU_Id
   	      	      	   FROM   	   PrdExec_Path_Units
   	      	      	   WHERE   	   Path_Id   	   = @PathId
   	      	      	   AND   	   Is_Production_Point = 1
   	      	   IF   	   @PUId   	   Is Not Null
   	      	   BEGIN
   	      	      	   UPDATE   	   @tMPR
   	      	      	      	   SET   	   PUId   	   = @PUId
   	      	      	      	   WHERE   	   NodeId   	   = @NodeId
   	      	   END
   	   END
   	   -------------------------------------------------------------------------------
   	   -- Get Next MPR record
   	   -------------------------------------------------------------------------------
   	   SELECT    	   @Id   	   = NULL
   	   SELECT   	   @Id   	   = MIN(Id)
   	      	   FROM   	   @tMPR
   	      	   WHERE   	   PUID   	   IS NULL
   	      	   AND   	   Status   	   = 0
END
UPDATE   	   mpr
   	   SET   	   PathUoM = EU.Eng_Unit_Code -- es.Dimension_X_Eng_Units
   	   FROM   	   @tMPR mpr
   	   JOIN   	   @tER er ON mpr.ParentId = er.ParentId
   	   JOIN   	   dbo.PrdExec_Path_Units pepu ON er.PathId = pepu.Path_Id AND pepu.Is_Production_Point = 1
   	   JOIN   	   dbo.Event_Configuration ec ON pepu.PU_Id = ec.PU_Id AND ec.ET_Id = 1
   	   JOIN   	   dbo.Event_SubTypes es ON ec.Event_SubType_Id = es.Event_SubType_Id
   	   JOIN   	   dbo.Engineering_Unit EU ON ES.dimension_x_eng_unit_id = EU.Eng_Unit_Id
IF @DebugFlag = 1
 	 SELECT 'Material Produce Req', * FROM @tMPR
-------------------------------------------------------------------------------
-- print '--Entering MPRP' + convert(char(30), getdate(), 21)
-- Material Produced Requirement Properties
-------------------------------------------------------------------------------
INSERT   	   @tMPRP (NodeId,ParentId,Id)
   	   SELECT   	   xMPRP.Id,xMPRP.ParentId,xIDc.tText
   	  	  	 FROM   	   #tXML xMPRP
   	      	   JOIN   	   #tXML xID ON xMPRP.Id = xID.ParentId AND   	   xID.LocalName = 'ID'
   	      	   JOIN   	   #tXML xIDc ON xID.Id = xIDc.ParentId
   	      	   WHERE   	   xMPRP.LocalName = 'MaterialProducedRequirementProperty'
UPDATE   	   mprp
   	   SET   	   ValueString = xVSc.tText
   	   FROM   	   @tMPRP mprp
   	   JOIN   	   #tXML xV ON mprp.NodeId = xV.ParentId AND xV.LocalName = 'Value'
   	   JOIN   	   #tXML xVS ON xV.Id = xVS.ParentId AND xVS.LocalName = 'ValueString'
   	   JOIN   	   #tXML xVSc ON xVS.Id = xVSc.ParentId
IF @DebugFlag = 1
 	 SELECT 'Material Produce Req Property', * FROM @tMPRP
-------------------------------------------------------------------------------
-- print '--Entering MCR: ' + convert(char(30), getdate(), 21)
-- Material Consumed Requirement
-------------------------------------------------------------------------------
INSERT   	   @tMCR (NodeId,ParentId,Status)
 	 SELECT   	   x1.Id,x1.ParentId,0
 	   FROM   	   #tXML x1
 	   WHERE   	   x1.LocalName = 'MaterialConsumedRequirement'
UPDATE   	   mcr
   	   SET   	 ProdCode = xMDIc.tText,
   	      	   MaterialLotId = xMLIc.tText,
   	      	   ProdDesc = xDc.tText,
   	      	   QuantityString = q.QuantityString,
   	      	   UoM = q.UoM,
   	      	   EquipmentId = lSZ.EquipmentId
   	   FROM @tMCR mcr
   	   LEFT JOIN #tXML xMDI ON mcr.NodeId = xMDI.ParentId AND xMDI.LocalName = 'MaterialDefinitionId'
   	   LEFT JOIN #tXML xMDIc ON xMDI.Id = xMDIc.ParentId
   	   LEFT JOIN #tXML xMLI ON mcr.NodeId = xMLI.ParentId AND xMLI.LocalName = 'MaterialLotId'
   	   LEFT JOIN #tXML xMLIc ON xMLI.Id = xMLIc.ParentId
   	   LEFT JOIN #tXML xD ON mcr.NodeId = xD.ParentId AND xD.LocalName = 'Description'
   	   LEFT JOIN #tXML xDc ON xD.Id = xDc.ParentId
   	   LEFT JOIN @tQty q ON mcr.NodeId = q.ParentId
   	   LEFT JOIN @tLocation lS ON mcr.NodeId = lS.ParentId
   	   LEFT JOIN @tLocation lSZ ON lS.NodeId = lSZ.ParentId
-------------------------------------------------------------------------------
-- Search MCR Product
-------------------------------------------------------------------------------
UPDATE   	   mcr
   	   SET   	   ProdId    	      	   = dsx.Actual_Id,
   	      	   FlgNewProduct   	   = 0
   	   FROM   	   @tMCR mcr
   	   JOIN   	   dbo.Data_Source_XRef dsx ON mcr.ProdCode = dsx.Foreign_Key
   	      	   AND   	   dsx.DS_Id = @DataSourceId
   	   JOIN   	   dbo.Tables tt ON dsx.Table_Id = tt.TableId
   	      	   AND   	   tt.TableName = 'Products'
UPDATE   	   mcr
   	   SET   	   ProdId    	      	   = p.Prod_Id,
   	      	   FlgNewProduct   	   = 0
   	   FROM   	   @tMCR mcr
   	   JOIN   	   dbo.Products p ON mcr.ProdCode = p.Prod_Code
   	   WHERE   	   mcr.ProdId IS NULL
-------------------------------------------------------------------------------
-- For products that could not be found based on the product code, the SP tries
-- to search based on the description. If configured so, it will compare the 
-- XML value with the concatenation of the ProductCode+delimiter+ProdDescription
-------------------------------------------------------------------------------
-- Adjust product desc based on UPDs 
UPDATE  mcr
   	 SET   	   mcr.prodDesc = COALESCE(mcr.ProdCode,'') +  COALESCE(er.PrependNewProdDelimiter,'') + COALESCE(mcr.ProdDesc,'') 
 	   FROM @tMCR mcr
 	   JOIN @tER er on er.ParentId = mcr.ParentId and er.FlgPrependNewProdWithDesc = 1
UPDATE   	   mcr
   	   SET   	   PUId = dsx.Actual_Id 
   	   FROM   	   @tMCR mcr
   	   JOIN   	   dbo.Data_Source_Xref dsx ON mcr.EquipmentId = dsx.Foreign_Key AND   	   dsx.DS_Id = @DataSourceId
   	     AND   	   dsx.Table_Id = @ProdUnitsTableId
UPDATE   	   mcr
   	   SET   	   PUId = PU.PU_Id
   	   FROM   	   @tMCR mcr
   	   JOIN   	   dbo.Prod_Units PU ON mcr.EquipmentId = PU.PU_Desc AND   	   mcr.PUId IS Null
UPDATE   	   mcr
   	   SET   	   ProdId   	       	   = p.Prod_Id,  FlgNewProduct   	   = 0
   	   FROM   	   @tMCR mcr
   	   JOIN   	   dbo.Products p ON mcr.ProdDesc = p.Prod_Desc
   	   WHERE   	   mcr.ProdId IS NULL
IF @DebugFlag = 1
 	 SELECT 'Material Consumed Req', * FROM @tMCR
-------------------------------------------------------------------------------
-- Material Consumed Requirement Properties
-------------------------------------------------------------------------------
INSERT   	   @tMCRP (NodeId,ParentId,Id)
SELECT  xMCRP.Id,
   	   xMCRP.ParentId,
   	   xIDc.tText
   	   FROM   	   #tXML xMCRP
   	   JOIN   	   #tXML xID ON xMCRP.Id = xID.ParentId AND  xID.LocalName = 'ID'
   	   JOIN   	   #tXML xIDc ON xID.Id = xIDc.ParentId
   	   WHERE   	   xMCRP.LocalName = 'MaterialConsumedRequirementProperty'
UPDATE   	   mcrp
   	   SET   	   ValueString = xVSc.tText
   	   FROM   	   @tMCRP mcrp
   	   JOIN   	   #tXML xV ON mcrp.NodeId = xV.ParentId AND xV.LocalName = 'Value'
   	   JOIN   	   #tXML xVS ON xV.Id = xVS.ParentId AND xVS.LocalName = 'ValueString'
   	   JOIN   	   #tXML xVSc ON xVS.Id = xVSc.ParentId
IF @DebugFlag = 1
 	 SELECT 'Material Consumed Req Property', * FROM @tMCRP
-------------------------------------------------------------------------------
-- Error Checks
-------------------------------------------------------------------------------
-- If the MPR product doesn't exist, then quit.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM  @tMPR mpr
     	   JOIN @tER er on er.ParentId = mpr.ParentId and er.mprNoProduct = 3
     	   LEFT  JOIN  dbo.Products p ON mpr.ProdCode = p.Prod_Code
     	   WHERE  mpr.ProdId IS NULL AND p.Prod_Id IS NULL
      	    
IF @RowCount > 0 
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -161
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
    SELECT @ErrCode, 'Process Order: ' 
 	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	 FROM  @tMPR mpr
 	  	  	 JOIN 	 @tER er ON er.ParentId = mpr.ParentId AND 	 er.mprNoProduct = 3
 	  	  	 JOIN @tSR sr 	 ON er.ParentId = sr.NodeId
 	  	  	 JOIN @tPR pr 	 ON sr.ParentId = pr.NodeId
 	  	  	 LEFT  jOIN  dbo.Products p ON mpr.ProdCode = p.Prod_Code
 	  	  	 WHERE  mpr.ProdId IS NULL AND p.Prod_Id IS NULL
      	          
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the MCR product doesn't exist, then quit.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM  @tMCR mcr
     	   JOIN @tER er on er.ParentId = mcr.ParentId and er.mcrNoProduct = 3
     	   LEFT  JOIN  dbo.Products p 
     	   ON mcr.ProdCode = p.Prod_Code
     	   WHERE  mcr.ProdId IS NULL  
     	   AND   	   p.Prod_Id IS NULL
IF @RowCount > 0 
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -168
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
    SELECT @ErrCode,  'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') 
 	  	  	 + ' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	 + ' - Product Code: ' + COALESCE(mcr.ProdCode, 'NA')
 	  	  	 FROM  @tMCR mcr
 	  	  	 JOIN @tER er on er.ParentId = mcr.ParentId and er.mcrNoProduct = 3
 	  	  	 JOIN @tSR sr on er.ParentId = sr.NodeId
 	  	  	 JOIN @tPR pr on sr.ParentId = pr.NodeId
 	  	  	 LEFT  JOIN  dbo.Products p ON mcr.ProdCode = p.Prod_Code
 	  	  	 WHERE  mcr.ProdId IS NULL AND p.Prod_Id IS NULL
      	          
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the MPR product doesn't exist, but the description has already been used, 
-- then quit.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM  @tMPR mpr
     	   JOIN  Products p ON mpr.ProdDesc = p.Prod_Desc
     	   WHERE  mpr.ProdId IS NULL
IF @RowCount > 0 
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -168
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
      SELECT @ErrCode, 'Product: ' + mpr.ProdDesc + ' on Path:' + CONVERT(VARCHAR(10),er.PathId)
     	   FROM  @tMPR mpr
     	   JOIN  Products p ON mpr.ProdDesc = p.Prod_Desc
     	   JOIN @tER er on er.ParentId = mpr.ParentId 
     	   WHERE  mpr.ProdId IS NULL
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the MPR product isn't associated to the path, then quit.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM  @tER er
     	   JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId
     	   LEFT  JOIN   	   dbo.PrdExec_Path_Products pepp ON er.PathId = pepp.Path_Id AND mpr.ProdId = pepp.Prod_Id
     	   WHERE   	   pepp.PEPP_Id IS NULL and er.mprNoPathProd = 3
IF @RowCount > 0 
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -164
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
      SELECT @ErrCode, 'Process Order: ' 
 	  	  	  	  	  	  	  	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') + ' on Path: ' + COALESCE(er.EquipmentID, 'NA') 
 	  	  	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	 FROM  @tER er
 	  	  	  	 JOIN  @tMPR mpr ON er.ParentId = mpr.ParentId
 	  	  	  	 JOIN @tSR sr ON er.ParentId = sr.NodeId
 	  	  	  	 JOIN @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	 LEFT JOIN dbo.PrdExec_Path_Products pepp ON er.PathId = pepp.Path_Id AND mpr.ProdId = pepp.Prod_Id
 	  	  	  	 WHERE pepp.PEPP_Id IS NULL and er.mprNoPathProd = 3
      	    
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the required path isn't configured in Plant Applications, then quit.
-------------------------------------------------------------------------------
IF   	   @mprNoPath = 3
   	   AND   	   (SELECT   	   COUNT(*)
   	      	      	   FROM   	   @tER
   	      	      	   WHERE   	   PathId IS NULL) > 0
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -142
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
      SELECT @ErrCode, 'Process Order: ' 
        + COALESCE(pr.ProcessOrder, 'NA') + ' on Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	 FROM  @tER er
 	  	  	  	 JOIN @tSR sr on er.ParentId = sr.NodeId
 	  	  	  	 JOIN @tPR pr on sr.ParentId = pr.NodeId 
 	  	  	  	 WHERE er.PathId  IS NULL
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
    GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the associated path has no UoM, then quit.
-------------------------------------------------------------------------------
IF   	   (SELECT   	   COUNT(*)
   	      	   FROM   	   @tMPR MPR
   	      	   JOIN   	   @tER ER
   	      	   ON   	   MPR.ParentId   	   = ER.ParentId
   	      	   WHERE   	   MPR.PathUoM IS NULL
   	      	   AND   	   ER.PathId   IS NOT NULL) > 0   	      	   -- do not check for unbound POs
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -143
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
 	  	 SELECT 	 @ErrCode, 'Process Order: ' 
        + COALESCE(pr.ProcessOrder, 'NA') + ' on Path: ' + COALESCE(er.EquipmentID, 'NA') 
     	   FROM   	   @tER er
 	  	  	  	 JOIN   	   @tMPR mpr ON er.ParentId = mpr.ParentId  AND  mpr.PathUoM IS NULL
 	  	  	  	 JOIN @tSR sr on er.ParentId = sr.NodeId
 	  	  	  	 JOIN @tPR pr on sr.ParentId = pr.NodeId
      	         	    
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
    GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If there is no conversion factor between the MPR UoM and the Path UoM, 
-- then quit.
-------------------------------------------------------------------------------
IF   	   (SELECT   	   COUNT(*)
   	      	   FROM   	      	   @tMPR mpr
   	      	   LEFT   	   JOIN   	   Engineering_Unit eu1 ON mpr.UoM = eu1.Eng_Unit_Code
   	      	   LEFT   	   JOIN   	   Engineering_Unit eu2 ON mpr.PathUoM = eu2.Eng_Unit_Code
   	      	   LEFT   	   JOIN   	   Engineering_Unit_Conversion euc ON eu2.Eng_Unit_Id = euc.From_Eng_Unit_Id
   	      	      	      	   AND   	   eu1.Eng_Unit_Id = euc.To_Eng_Unit_Id
   	      	   WHERE   	   euc.Eng_Unit_Conv_Id IS NULL
   	      	   AND   	   mpr.UoM <> mpr.PathUoM) > 0
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -165
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
        SELECT @ErrCode ,  'Process Order: '  + COALESCE(pr.ProcessOrder, 'NA') 
 	  	  	  	  	  	 + ' on Path: ' + COALESCE(er.EquipmentID, 'NA') 
 	  	         + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	         + ' - UoM: ' + COALESCE(mpr.UOM, 'NA')
   	      	   FROM   	      	   @tER er
      	     JOIN @tSR sr on er.ParentId = sr.NodeId
          JOIN @tPR pr on sr.ParentId = pr.NodeId
 	      	   JOIN @tMPR mpr ON er.ParentId = mpr.ParentId
 	      	   LEFT JOIN Engineering_Unit eu1 ON mpr.UoM = eu1.Eng_Unit_Code
 	      	   LEFT JOIN Engineering_Unit eu2 ON mpr.PathUoM = eu2.Eng_Unit_Code
 	      	   LEFT JOIN Engineering_Unit_Conversion euc ON eu2.Eng_Unit_Id = euc.From_Eng_Unit_Id AND eu1.Eng_Unit_Id = euc.To_Eng_Unit_Id
 	      	   WHERE euc.Eng_Unit_Conv_Id IS NULL  AND mpr.UoM <> mpr.PathUoM
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
    GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the provided BOM is not configured in Plant Applications, then quit.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
 	   FROM   	   @tPR pr
  	    JOIN @tSR sr ON pr.NodeId = sr.ParentId -- AJ:20111215
 	   JOIN @tER er ON er.ParentId = sr.NodeId AND er.NoFormulation = 2 AND @FlgIgnoreBOMInfo = 0
 	   WHERE   	   pr.BOMId IS NULL
IF @RowCount > 0 
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -121
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
      SELECT @ErrCode, 'Process Order: ' + pr.ProcessOrder + ' on Path:' + COALESCE(ER.EquipmentID, 'NA')
 	       FROM   	   @tPR pr
  	        JOIN @tSR sr ON pr.NodeId = sr.ParentId -- AJ:20111215
 	       JOIN @tER er ON er.ParentId = sr.NodeId AND er.NoFormulation = 2 AND @FlgIgnoreBOMInfo = 0
 	       WHERE   	   pr.BOMId IS NULL
  	        
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- If the passed process order has already been active, then quit.
-------------------------------------------------------------------------------
IF   	   (SELECT   	   COUNT(*)
   	      	   FROM   	   @tER er
   	      	   JOIN   	   dbo.Production_Plan_Starts pps ON er.PPId = pps.PP_Id) > 0
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -101
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
    SELECT @ErrCode, 'Process Order: ' + COALESCE(pr.ProcessOrder,'NA')
 	  	  	 FROM   	   @tER er
 	  	  	 JOIN @tSR sr ON er.ParentId = sr.NodeId
 	  	  	 JOIN @tPR pr on sr.ParentId = pr.NodeId
 	  	  	 JOIN dbo.Production_Plan_Starts pps ON er.PPId = pps.PP_Id
    	        	    
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	  	 GOTO ErrCode
END
-------------------------------------------------------------------------------
-- If the passed process order already exists and its status matches one of the
-- passed non-update status parameter, then quits
-------------------------------------------------------------------------------
IF   	   (SELECT   	   COUNT(*)
   	      	   FROM   	   @tER er
   	      	   JOIN   	   dbo.Production_Plan PP ON er.PPId = PP.PP_Id
   	      	   JOIN   	   @tPPStatus t ON t.PPStatusId = PP.PP_Status_Id) > 0
BEGIN
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
     SELECT -108, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Process Order: ' + pp.Process_Order 
 	  	 FROM 	 @tER er
 	  	 JOIN 	 dbo.Production_Plan pp ON 	 pp.PP_Id = er.PPId
 	  	 JOIN    	    @tPPStatus t ON t.PPStatusId = PP.PP_Status_Id
 	  	 JOIN 	 dbo.email_message_data emd ON 	 emd.Message_Id = -108
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- End of Fatal Error Checks 
-------------------------------------------------------------------------------
-- If the MPR product doesn't exist, use the default product.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM  @tMPR mpr
     	   JOIN @tER er on er.ParentId = mpr.ParentId and er.mprNoProduct = 2
     	   LEFT  JOIN  dbo.Products p ON mpr.ProdCode = p.Prod_Code
     	   WHERE  mpr.ProdId IS NULL AND   	   p.Prod_Id IS NULL
IF @RowCount > 0 
BEGIN
   	   UPDATE   	   mpr
     	   SET   	   ProdId = @DefaultMPRProdId
     	   FROM   	      	   @tMPR mpr
 	       JOIN @tER er on er.ParentId = mpr.ParentId and er.mprNoProduct = 2
     	   LEFT JOIN dbo.Products p ON mpr.ProdCode = p.Prod_Code
     	   WHERE   	   mpr.ProdId IS NULL AND p.Prod_Id IS NULL
--TODO: ADD ERR REFERENCE CODE
      INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	         SELECT -160, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Process Order: ' 
 	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	 FROM 	 @tMPR mpr 
 	  	  	  	 JOIN 	 @tSR sr on mpr.ParentId = sr.NodeId
 	  	  	  	 JOIN 	 @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	 JOIN 	 @tER er ON er.ParentId = sr.NodeId
 	  	  	  	 JOIN 	 dbo.email_message_data emd ON emd.Message_Id = -160
 	  	  	  	 WHERE 	 mpr.ProdId = @DefaultMPRProdId 	 
END
-------------------------------------------------------------------------------
-- If the MCR product doesn't exist, use the default product.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM  @tMCR mcr
     	   JOIN @tER er on er.ParentId = mcr.ParentId and er.mcrNoProduct = 2
     	   LEFT  JOIN  dbo.Products p ON mcr.ProdCode = p.Prod_Code
     	   WHERE  mcr.ProdId IS NULL  AND p.Prod_Id IS NULL
      	    
      	        	    
IF @RowCount > 0 
BEGIN
   	   UPDATE   	   mcr
   	  	  	 SET   	   ProdId = @DefaultMCRProdId
   	  	  	 FROM   	      	   @tMCR mcr
       	     JOIN @tER er on er.ParentId = mcr.ParentId and er.mcrNoProduct = 2
   	      	   LEFT   	   JOIN   	   dbo.Products p ON mcr.ProdCode = p.Prod_Code
   	      	   WHERE   	   mcr.ProdId IS NULL AND p.Prod_Id IS NULL
      INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	 SELECT -167, emd.Message_Subject, emd.Message_Text, emd.Severity, 
 	  	         'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') 
 	  	         + ' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mcr.ProdCode, 'NA')
 	  	  	  	 FROM 	 @tMCR mcr 
 	  	  	  	 JOIN 	 @tSR sr ON 	  	 mcr.ParentId = sr.NodeId
 	  	  	  	 JOIN 	 @tPR pr 	 ON 	  	 sr.ParentId = pr.NodeId
 	  	  	  	 JOIN 	 @tER er 	 ON 	  	 er.ParentId = sr.NodeId
 	  	  	  	 JOIN 	 dbo.email_message_data emd ON 	  	 emd.Message_Id = -167
 	  	  	  	 WHERE   mcr.ProdId = @DefaultMCRProdId
END
-------------------------------------------------------------------------------
-- If the required path isn't configured in Plant Applications, then exit with 
-- fatal error
-------------------------------------------------------------------------------
-- This must use the global Download subscription since there is no path to tie it to
IF   	   @mprNoPath = 1
   	   AND   	   (SELECT   	   COUNT(*)
   	      	      	   FROM   	   @tER
   	      	      	   WHERE   	   PathId IS NULL) > 0
BEGIN
--TODO: ADD ERR REFERENCE CODE
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT -142, emd.Message_Subject, emd.Message_Text, emd.Severity, NULL
        FROM dbo.email_message_data emd 
        WHERE emd.Message_Id = -142
 	   GOTo ErrCode
   	   --RETURN   	   (0)
END
-------------------------------------------------------------------------------
-- If the required path isn't configured in Plant Applications, then the 
-- schedule will be unbound.
-------------------------------------------------------------------------------
-- This must use the global Download subscription since there is no path to tie it to
IF   	   @mprNoPath = 2
   	   AND   	   (SELECT   	   COUNT(*)
   	      	      	   FROM   	   @tER
   	      	      	   WHERE   	   PathId IS NULL) > 0
BEGIN
    	    SELECT    	    TOP 1    	    @ErrMsg = 'Path: ' + COALESCE(EquipmentId, 'NA')
   	      	   FROM   	   @tER
   	      	   WHERE   	   PathId IS NULL
--TODO: ADD ERR REFERENCE CODE
      INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
        SELECT -141, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Process Order: ' 
        + COALESCE(pr.ProcessOrder, 'NA') + ' on Path: ' + COALESCE(er.EquipmentID, 'NA') 
          FROM dbo.email_message_data emd 
          JOIN @tER er ON emd.Message_Id = -141AND 	 er.PathId is null
          join @tSR sr ON er.ParentId = sr.NodeId
          join @tPR pr ON sr.ParentId = pr.NodeId
END
-------------------------------------------------------------------------------
-- If the MPR product isn't associated to the path, then the schedule will be 
-- unbound.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
     	   FROM @tER er
     	   JOIN @tMPR mpr ON er.ParentId = mpr.ParentId
     	   LEFT JOIN dbo.PrdExec_Path_Products pepp ON er.PathId = pepp.Path_Id AND  mpr.ProdId = pepp.Prod_Id
     	   WHERE pepp.PEPP_Id IS NULL and er.mprNoPathProd = 2
IF @RowCount > 0 
BEGIN
-------------------------------------------------------------------------------
-- AJ:20111006v2
--
-- Add routine that quits SP if the MPA.Product does not exist and the SP is not
-- configured to create the missing product. If I don't have this routine, the
-- SP will quit with error -163 which is misleading.
-------------------------------------------------------------------------------
 	 IF 	 @FlgCreateProduct = 0
 	 BEGIN
 	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	    	 SELECT 1003, 'Schedule Download Critical Message', 
 	  	  	  	  	  	  	 'At least one of the Products to make does not exist in the database',
 	  	  	  	  	  	  	 1, 'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	 FROM @tER er 
 	  	  	  	 JOIN @tMPR mpr ON er.ParentId = mpr.ParentId
 	  	  	  	 JOIN @tSR sr on er.ParentId = sr.NodeId
 	  	  	  	 JOIN @tPR pr on sr.ParentId = pr.NodeId
 	  	  	  	 LEFT JOIN dbo.PrdExec_Path_Products pepp ON er.PathId = pepp.Path_Id AND mpr.ProdId = pepp.Prod_Id
      	  	 WHERE pepp.PEPP_Id IS NULL and er.mprNoPathProd = 2
 	  	  	  	 GOTo ErrCode
 	 END
 	 ELSE
 	 BEGIN
-- aqui
    DELETE FROM @tErrRef
    SELECT @ErrCode = -163
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
     SELECT @ErrCode, 'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	 FROM @tMPR mpr
 	  	  	  	 JOIN @tER er ON mpr.ParentId = er.ParentId and er.mprNoPathProd = 2
 	  	  	  	 JOIN dbo.PrdExec_Paths pep ON er.PathId = pep.Path_Id
 	  	  	  	 JOIN @tSR sr ON er.ParentId = sr.NodeId
 	  	  	  	 JOIN @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	 LEFT JOIN dbo.PrdExec_Path_Products pepp ON pep.Path_Id = pepp.Path_Id AND  mpr.ProdId = pepp.Prod_Id
 	  	  	  	 WHERE   	   pepp.PEPP_Id IS NULL 
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	 END
 	   UPDATE   	   er
 	      	   SET   	   PathId = NULL
 	      	   FROM @tMPR mpr
 	      	   JOIN @tER er ON mpr.ParentId = er.ParentId
 	      	   JOIN dbo.PrdExec_Paths pep ON er.PathId = pep.Path_Id
 	      	   LEFT JOIN dbo.PrdExec_Path_Products pepp ON pep.Path_Id = pepp.Path_Id AND mpr.ProdId = pepp.Prod_Id
 	      	   WHERE   	   pepp.PEPP_Id IS NULL
END
-------------------------------------------------------------------------------
-- If the process order is unbound, then don't convert the engineering units.
-------------------------------------------------------------------------------
IF   	   (SELECT   	   COUNT(*)
   	      	   FROM   	   @tER
   	      	   WHERE   	   PathId IS NULL) > 0
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -166
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
        SELECT @ErrCode ,  'Process Order: '  + COALESCE(pr.ProcessOrder, 'NA') 
 	  	  	  	  	  	  	  	  	 + ' on Path: ' + COALESCE(er.EquipmentID, 'NA') 
 	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	  	  	  	  	  	 + ' - UoM: ' + COALESCE(mpr.UOM, 'NA')
 	  	  	  	 FROM @tER er
 	  	  	  	 join @tSR sr ON er.ParentId = sr.NodeId
 	  	  	  	 join @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	 join @tmpr mpr ON mpr.ParentId = sr.NodeId
 	  	  	  	 WHERE er.PathId IS NULL
    	        	    
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   UPDATE   	   mpr
 	      	   SET   	   Qty = mpr.QuantityString
 	      	   FROM   	   @tMPR mpr
 	      	   JOIN   	   @tER er ON mpr.ParentId = er.ParentId
 	      	   WHERE   	   er.PathId IS NULL
END
-------------------------------------------------------------------------------
-- End of Warning Error Checks 
-------------------------------------------------------------------------------
-- Loop through each MPR. even for existing products, to check if they are 
-- associated with the pu and path
--
-- Mark all MPR records as unprocessed
-------------------------------------------------------------------------------
UPDATE   	   @tMPR
   	   SET   	   Status = 0
-------------------------------------------------------------------------------
-- Get first MPR to be processed
-------------------------------------------------------------------------------
SELECT   	   @Id   	   = NULL
SELECT   	   @Id   	   = MIN(Id)
   	   FROM   	   @tMPR
   	   WHERE   	   Status = 0
-------------------------------------------------------------------------------
-- Loop through each MPR
-------------------------------------------------------------------------------
WHILE   	   (@Id   	   Is Not NULL)
BEGIN
   	   -------------------------------------------------------------------------------
   	   -- Mark this MPR as processed
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMPR
   	      	   SET   	   Status   	   = 1
   	      	   WHERE   	   Id   	   = @Id
   	   -------------------------------------------------------------------------------
   	   -- Retrieve some MPR attributes
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @ParentId   	   = ParentId,
   	      	   @ProdCode   	   = ProdCode,
   	      	   @ProdDesc   	   = ProdDesc,
   	      	   @PUId   	      	   = PUId,
   	      	   @ProdId   	      	   = ProdId,
   	      	   @NodeId   	      	   = NodeId
   	      	   FROM   	   @tMPR
   	      	   WHERE   	   Id   	   = @Id
   	   -------------------------------------------------------------------------------
   	   -- Get Path from the EquipmentRequirement (Assume a single ER for a given SR. 
   	   -- If wrong, we need an inner loop)
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @PathId   	   = Null,
   	       @FlgCreateProduct= NULL,
   	       @OriginalProdId   	 = @ProdId
   	   SELECT   	   TOP 1 @PathId = PathId, 
   	       @FlgCreateProduct = FlgCreateProduct, 
   	       @DefaultPRODFamilyId = DefaultPRODFamilyId,
   	       @UserId = UserId,
   	       @FlgUpdateMPRDesc = FlgUpdateMPRDesc
     	   FROM   	   @tER
     	   WHERE   	   ParentId   	   = @ParentId
 	     IF @FlgCreateProduct = 1
   	  	   EXEC   	   spS95_ScheduleProdCreate
   	      	  	   @ProdId   	      	      	   OUTPUT,   	 --  @OutputValue  VARCHAR(25) OUTPUT,
   	      	  	   @CreatePUAssoc   	      	   OUTPUT,  	 --
   	      	  	   @CreatePathAssoc    	      	   OUTPUT,   	 --
   	      	  	   @ProdCode,    	      	      	      	    	 --  @PssblNewProdDesc       VARCHAR(255),
   	      	  	   @ProdDesc,    	      	      	      	   	 --  @NoProductId            int = Null,
   	      	  	   @DefaultPRODFamilyId,    	      	      	 --  @FamilyId               Int,
   	      	  	   @UserId,   	      	      	      	    	 --  @UserId                 Int,
   	      	  	   @PUId,   	      	      	      	      	 --  @PUId   	      	     Int,
   	      	  	   @PathId,    	      	      	      	    	 --  @PathId                 Int,
   	      	  	   @FlgUpdateMPRDesc   	      	      	    	 --  @FlgUpdateDesc   	     Int
   	   -------------------------------------------------------------------------------
   	   -- For new products: if can not be created, then exits with fatal error
   	   -------------------------------------------------------------------------------
    	    IF    	    @OriginalProdId    	    Is Null
   	   BEGIN
 	  	  	  	 IF   	   @ProdID   	   Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	 SELECT -169, emd.Message_Subject, emd.Message_Text, emd.Severity, 
 	  	  	  	  	  	  	 'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA') 	  	  	  	  	     
 	  	  	  	  	  	 FROM 	 @tMPR mpr
 	  	  	  	  	  	 JOIN 	 @tSR sr ON mpr.ParentId = sr.NodeId AND 	  	 mpr.Id = @Id
 	  	  	  	  	  	 JOIN 	 @tPR pr 	 ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	 JOIN 	 @tER er 	 ON er.ParentId = sr.NodeId
 	  	  	  	  	  	 JOIN 	 dbo.email_message_data emd ON 	 emd.Message_Id = -169
 	  	  	  	  	 GOTo ErrCode
 	  	  	  	 END
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- For new products: update the MPR record with the new product id
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 UPDATE @tMPR
 	  	  	  	 SET    	   ProdId  = @ProdId,FlgNewProduct   	   = 1 
 	  	  	  	 WHERE NodeId = @NodeId
   	   END
   	   -------------------------------------------------------------------------------
   	   -- Update pathId for new and old products
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMPR
   	      	   SET   	   PathId   	      	   = @PathId,
   	      	      	   CreatePUAssoc   	   = @CreatePUAssoc,
   	      	      	   CreatePathAssoc   	   = @CreatePathAssoc 
   	      	   WHERE   	   NodeId   	   = @NodeId
   	   -------------------------------------------------------------------------------
   	   -- Move to next MPR
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @Id   	   = NULL
   	   SELECT   	   @Id   	   = MIN(Id)
   	      	   FROM   	   @tMPR
   	      	   WHERE   	   Status = 0
END
-------------------------------------------------------------------------------
-- If the MCR product doesn't exist, make a new product under the Default 
-- Product Family.
-- If the MCR product exists and the PU Id was passed, then associates PU to 
-- ProdId, if necessary
-------------------------------------------------------------------------------
-- Loop through each MCR
-------------------------------------------------------------------------------
SELECT   	   @PathId   	   = Null,
   	  	   @ProdId   	   = Null 
-------------------------------------------------------------------------------
-- Get first MCR to be processed
-------------------------------------------------------------------------------
SELECT   	   @Id   	   = NULL
SELECT   	   @Id   	   = MIN(Id)
   	   FROM   	   @tMCR
   	   WHERE   	   Status = 0
-------------------------------------------------------------------------------
-- Loop through each MCR
-------------------------------------------------------------------------------
WHILE   	   (@Id   	   Is Not NULL)
BEGIN
   	   -------------------------------------------------------------------------------
   	   -- Mark this MCR as processed
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMCR
   	      	   SET   	   Status   	   = 1
   	      	   WHERE   	   Id   	   = @Id
   	   -------------------------------------------------------------------------------
   	   -- Retrieve some MCR attributes
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @PUId   	      	   = mcr.PUId,
   	      	   @ProdCode   	   = mcr.ProdCode,
   	      	   @ProdDesc   	   = mcr.ProdDesc,
   	      	   @NodeId   	      	   = mcr.NodeId,
   	      	   @ProdId   	      	   = mcr.ProdId,
   	      	   @FlgCreateProduct = er.FlgCreateProduct
   	      	   FROM   	   @tMCR mcr
   	      	   JOIN @tER er ON mcr.ParentId = er.ParentId
   	      	   WHERE   	   mcr.Id   	   = @Id
     	    
   	   IF   	   @FlgIgnoreBOMInfo = 0  AND @FlgCreateProduct = 1  -- if site processes BOM info
      BEGIN   	   
   	     -------------------------------------------------------------------------------
   	     -- create the product. If PUId is passed, associate with PU. If Path is passed, 
   	     -- associated with path
   	     -------------------------------------------------------------------------------
   	     SELECT   	   @OriginalProdId   	   = @ProdId
   	     EXEC   	   spS95_ScheduleProdCreate
   	      	     @ProdId   	   OUTPUT,   	       	 --  @OutputValue    	   VARCHAR(25) OUTPUT,
   	      	     @CreatePUAssoc   	   OUTPUT,     	 --
   	      	     @CreatePathAssoc  	   OUTPUT,    	 --
   	      	     @ProdCode,    	      	       	  	 --  @PossiblNewProdDesc   VARCHAR(255),
   	      	     @ProdDesc,    	      	       	  	 --  @NoProductId          int = Null,
   	      	     @DefaultRawMaterialProdId,  	  	 --  @FamilyId             Int,
   	      	     @UserId,   	      	       	  	 --  @UserId               Int,
   	      	     @PUId,   	      	      	       	 --  @PUId   	      	   Int,
   	      	     @PathId,    	      	       	  	 --  @PathId               Int
   	      	     @FlgUpdateMCRDesc   	       	  	 --  @FlgUpdateDesc   	   Int
   	     -------------------------------------------------------------------------------
   	     -- If a product could not be created, then exit with an error
   	     -------------------------------------------------------------------------------
   	     IF   	   @OriginalProdId   	   Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 IF   	   @ProdID   	   Is Null
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT -170, emd.Message_Subject, emd.Message_Text, emd.Severity, 
 	  	  	  	  	  	  	  	  	 'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mcr.ProdCode, 'NA')
 	  	  	  	  	  	 FROM 	 @tMCR mcr
 	  	  	  	  	  	 JOIN 	 @tSR sr ON mcr.ParentId = sr.NodeId AND 	  	 mcr.Id = @Id
 	  	  	  	  	  	 JOIN 	 @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	 JOIN 	 @tER er ON er.ParentId = sr.NodeId
 	  	  	  	  	  	 JOIN 	 dbo.email_message_data emd  	 ON emd.Message_Id = -170
 	  	  	  	  	  	 GOTo ErrCode
 	  	  	  	  	 END
 	  	  	  	  	 ELSE
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 UPDATE @tMCR SET ProdId = @ProdId,FlgNewProduct = 1WHERE   	   NodeId   	   = @NodeId
 	  	  	  	  	 END
 	  	  	  	 END
   	   END
 	     -------------------------------------------------------------------------------
 	     -- Get next MCR to be processed
 	     -------------------------------------------------------------------------------
 	     SELECT   	   @Id   	   = NULL
 	     SELECT   	   @Id   	   = MIN(Id)
 	      	     FROM   	   @tMCR
 	      	     WHERE   	   Status = 0
END
-------------------------------------------------------------------------------
-- Create Engineering Units As Needed
-------------------------------------------------------------------------------
INSERT   	   Engineering_Unit (
   	   Eng_Unit_Desc, 
   	   Eng_Unit_Code)
   	   SELECT   	   DISTINCT UOM, UOM
   	      	   FROM   	   @tMCR   	   M
   	      	   LEFT
   	      	   JOIN   	   Engineering_Unit EU
   	      	   ON   	   M.UOM   	   = EU.Eng_Unit_Code
   	      	   WHERE   	   EU.Eng_Unit_Id   	   Is Null
-------------------------------------------------------------------------------
-- Handle UOM conversion
-------------------------------------------------------------------------------
IF (SELECT COUNT(*) 
   	   FROM   	   @tMPR
   	   WHERE   	   PathUoM is null)>0
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -166
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
     -- AJ:20111006
      --SELECT @ErrCode, 'PathUOM missing for ' + er.PathId + ' Product ' + mpr.ProdCode
      SELECT @ErrCode, 'PathUOM missing for ' + CONVERT(VARCHAR(25), COALESCE(mpr.PathId, 0)) + ' Product ' + COALESCE(mpr.ProdCode, 'NA')
   	     FROM   	   @tMPR mpr
    	   --   JOIN      @tER er on er.ParentId = mpr.ParentId 	 -- AJ:20111006
   	     WHERE   	   mpr.PathUoM is null
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
END
UPDATE @tMPR 
   	   SET    	   PathUoM = UoM
   	   WHERE   	   PathUoM is NULL
UPDATE   	   MPR
   	   SET   	   QTY   	   =  Convert(Float, MPR.QuantityString) * Coalesce(EUC.Slope, 1) + Coalesce(EUC.Intercept, 0)
     	   FROM   	   @tMPR MPR 
 	  	  	   JOIN   	   Engineering_Unit E1 ON   	   MPR.UOM   	   = E1.Eng_Unit_Code
     	   JOIN   	   Engineering_Unit E2 ON   	   MPR.PathUOM = E2.Eng_unit_Code
     	   JOIN   	   Engineering_Unit_Conversion EUC ON   	   EUC.From_Eng_Unit_Id   	   = E1.Eng_Unit_Id
     	   AND   	   EUC.To_Eng_Unit_Id   	   = E2.Eng_Unit_Id
UPDATE   	   @tMPR
   	   SET   	   QTY   	   = QuantityString
   	   WHERE   	   QTY   	   Is Null   	   
--IF @DebugFlag = 1
-- 	 SELECT 'Material Produce Req', * FROM @tMPR
-------------------------------------------------------------------------------
-- If the provided BOM is not configured in Plant Applications, then make the 
-- BOM Formulation records.
-------------------------------------------------------------------------------
SELECT @RowCount = 0
SELECT @RowCount = COUNT(*)
 	   FROM   	   @tPR pr
  	    JOIN @tSR sr ON pr.nodeId = sr.ParentId -- AJ:20111215
 	   JOIN @tER er ON er.ParentId = sr.NodeId AND er.NoFormulation = 1 AND @FlgIgnoreBOMInfo = 0
 	   WHERE   	   pr.BOMId IS NULL
  	    
IF @RowCount > 0 
BEGIN
    DELETE FROM @tErrRef
    SELECT @ErrCode = -120
    INSERT INTO @tErrRef (ErrorCode, ReferenceData)
      SELECT @ErrCode, 'Process Order: ' + pr.ProcessOrder + ' on Path:' + COALESCE(ER.EquipmentID, 'NA')
 	       FROM   	   @tPR pr
  	        JOIN @tSR sr ON pr.NodeId = sr.ParentId -- AJ:20111215
  	        JOIN @tER er ON er.ParentId = sr.NodeId AND er.NoFormulation = 1 AND @FlgIgnoreBOMInfo = 0
 	       WHERE   	   pr.BOMId IS NULL
  	        
  	        
    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
      SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
        FROM dbo.email_message_data emd 
        JOIN @tErrRef er on er.ErrorCode = @ErrCode
        WHERE emd.Message_Id = @ErrCode
 	   GOTo ErrCode
END
-------------------------------------------------------------------------------
-- Handle Bill_Of_Material, if site configured to not ignore BOM info on the
-- XML file
-- populate BOM
-- Table Bill_Of_Material, Bill_Of_Material_Formulation 
-- Bill_Of_Material_Formulation_Item
-------------------------------------------------------------------------------
--JG: this is a site UDP as are all UDPs in this IF statement (i.e. @MaterialReservationSequence, etc). Some could be made Path specific... 
IF   	   @FlgIgnoreBOMInfo = 0
BEGIN
   	   -------------------------------------------------------------------------------
   	   -- Handle Bill Of Material table
   	   -------------------------------------------------------------------------------
   	   INSERT   	   Bill_of_material 
   	      	   (Bom_Desc, 
   	      	    Bom_Family_Id) 
   	      	   SELECT   	   FormulationDesc, 
   	      	      	   @DefaultBomFamilyId
   	      	      	   FROM   	   @tPR
   	      	      	   WHERE   	   BOMId IS NULL
   	   -------------------------------------------------------------------------------
   	   -- Handle Bill_Of_Material_Formulation
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   pr
   	      	   SET   	   FormulationId   	   = bmf.BOM_Formulation_Id
   	      	   FROM   	   @tPR pr
   	      	   JOIN   	   Bill_Of_Material_Formulation bmf
   	      	   ON   	   BMF.BOM_Formulation_Desc = PR.FormulationDesc + ':' + LTRIM(PR.ProcessOrder)
   	   
   	   INSERT    	   Bill_Of_Material_Formulation   	   
   	      	   (Bom_Id, 
   	      	    Standard_Quantity, 
   	      	    Bom_Formulation_Desc, 
   	      	    Eng_Unit_Id)
   	      	   SELECT   	   bom.bom_id, 
    	        	        	    MPR.Qty,   -- AJ:20111017  -- Use the PO quantity as the standard quantity instead of harcoding 1
   	      	      	   FormulationDesc + ':' + LTRIM(ProcessOrder), 
   	      	      	   eu.Eng_Unit_Id
   	      	   FROM   	   @tPR PR
   	      	   JOIN   	   Bill_Of_Material BOM ON pr.FormulationDesc = BOM.Bom_Desc
   	      	   JOIN   	   @tSR SR ON SR.ParentId = PR.NodeId
   	      	   JOIN   	   @tMPR MPR ON MPR.ParentId = SR.NodeId
   	      	   JOIN    	   Engineering_Unit EU ON  EU.Eng_Unit_Code = mpr.uom
   	      	   WHERE   	   PR.FormulationId IS NULL
   	   
   	   UPDATE   	   pr
   	      	   SET   	   FormulationId   	   = bmf.BOM_Formulation_Id
   	      	   FROM   	   @tPR pr
   	      	   JOIN   	   Bill_Of_Material_Formulation bmf  ON   	   BMF.BOM_Formulation_Desc = PR.FormulationDesc + ':' + LTRIM(PR.ProcessOrder)
   	   -------------------------------------------------------------------------------
   	   -- Update mcr with formulationid 
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMCR
   	      	   SET   	   FormulationId   	   = PR.FormulationId
   	      	   FROM   	   @tMCR MCR
   	      	   JOIN    	   @tSR SR  ON MCR.ParentId = SR.NodeId
   	      	   JOIN   	   @tPR PR  ON SR.ParentId = PR.NodeId
   	   -------------------------------------------------------------------------------
   	   -- Handle Bill Of Material Formulation Item
   	   -- see if formulation item exists by looking for same product id in same place 
   	   -- on bill (formulation_order)
   	   -------------------------------------------------------------------------------
      --SELECT @MaterialReservationSequence AS MaterialReservationSequence
   	   UPDATE   	   @tMCR
   	      	   SET   	   FormulationItemId   	      	   = BMFI.Bom_Formulation_Item_Id
   	      	   FROM   	   @tMCR MCR
   	      	   JOIN   	   @tMCRP MCRP1 ON MCRP1.ParentId = MCR.NodeId AND MCRP1.Id = @MaterialReservationSequence
   	      	   JOIN   	   Bill_Of_Material_Formulation_Item BMFI ON BMFI.Bom_Formulation_Id = MCR.FormulationId
 	  	  	  	  	  	  	  	  	  	  	  	 AND BMFI.Bom_Formulation_Order = Convert(INT, MCRP1.ValueString)
 	  	  	  	  	  	  	  	  	  	  	  	 AND BMFI.Prod_Id = MCR.ProdId
 	 IF @DebugFlag = 1
 	  	 SELECT 'tMCR', * FROM @tMCR
   	   INSERT   	   Bill_Of_Material_Formulation_Item 
   	  	  	  	 (BOM_Formulation_Id,Prod_Id, Bom_Formulation_Order, Scrap_Factor, PU_Id,Quantity,Eng_Unit_Id,Lot_Desc)
   	      	   SELECT  MCR.FormulationId, 
   	      	      	    MCR.ProdId, 
   	      	      	   CONVERT(INT,mcrp1.VALUEString), 
   	      	      	   CONVERT(FLOAT,mcrp2.VALUEString), 
   	      	      	   MCR.PUId,
   	      	      	   CONVERT(FLOAT,MCR.quantitystring), 
   	      	      	   EU.Eng_Unit_Id,
   	      	      	   MCR.MaterialLotId
   	      	      	   FROM   	   @tMCR mcr
   	      	      	   JOIN   	   @tMCRP mcrp1 ON    	   mcrp1.ParentId    	   = mcr.NodeId 
   	      	      	  	  	  	  	 AND    	   mcrp1.Id   	   = @MaterialReservationSequence
   	      	      	   JOIN   	   @tMCRP mcrp2 ON    	   mcrp2.ParentId    	   = mcr.NodeId 
   	      	      	  	  	  	  	 AND    	   mcrp2.id   	   = @ScrapPercent
   	      	      	   JOIN   	   Engineering_Unit EU ON    	   EU.eng_unit_code = mcr.uom 
 	  	  	  	  	   WHERE   	   MCR.FormulationItemId is NULL 	 
  	    	    	    	    	    AND 	  	    mcr.ProdId IS NOT NULL --  -- AJ:20110930
  	    	    	    	    	    -------------------------------------------------------------------------------
  	    	    	    	    	    -- AJ:20111006
  	    	    	    	    	    --
 	  	  	  	  	    -- at least one of the BOM formulation items is for a product that does not 
 	  	  	  	  	    -- exist in PA yet 
 	  	  	  	  	    -------------------------------------------------------------------------------
 	  	  	 IF 	 EXISTS 	 (SELECT 	 1 	 FROM @tMCR 	  	 WHERE 	 ProdId IS NULL)
 	  	  	 BEGIN  	  
 	  	  	 INSERT 	 @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	  	  	  	  	 SELECT 	 1002,'Schedule Download Warning Message', 
 	  	  	  	  	 'At least one of the received MaterialConsumed Product does not exist in the database, therefore a BOM Formulation Item was not created for it',
 	  	  	  	  	  	  	  	  	  	  	  	  2,
 	  	  	  	  	  	  	  	  	  	  	  	  'Process Order: ' + COALESCE(pr.ProcessOrder, 'NA') 
 	  	  	  	  	  	  	  	  	  	  	  	  + ' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	  	  	  	  	  	  + ' - Product Code: ' + COALESCE(mcr.ProdCode, 'NA') 	  	  	  	  	  	  	  	  	  	  	  	  
 	  	  	  	  	  	  	  	  	  	  	  	  FROM @tMCR mcr 
 	  	  	  	  	  	  	  	  	  	  	  	  JOIN @tSR sr
 	  	  	  	  	  	  	  	  	  	  	  	  on mcr.ParentId = sr.NodeId
 	  	  	  	  	  	  	  	  	  	  	  	  AND mcr.ProdId IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  JOIN @tPR pr
 	  	  	  	  	  	  	  	  	  	  	  	  on sr.ParentId = pr.NodeId
 	  	  	  	  	  	  	  	  	  	  	  	  JOIN @tER er
 	  	  	  	  	  	  	  	  	  	  	  	  ON 	 er.ParentId = sr.NodeId
 	  	  	 END
  	   
   	   UPDATE   	   @tMCR
   	      	   SET   	   FormulationItemId   	   = BMFI.Bom_Formulation_Item_Id
   	      	   FROM   	   @tMCR MCR
   	      	   JOIN   	   @tMCRP MCRP1
   	      	   ON   	   MCRP1.ParentId   	      	   = MCR.NodeId
   	      	   AND   	   MCRP1.Id   	      	   = @MaterialReservationSequence
   	      	   JOIN   	   Bill_Of_Material_Formulation_Item BMFI
   	      	   ON   	   BMFI.Bom_Formulation_Id    	   = MCR.FormulationId
   	      	   AND   	   BMFI.Bom_Formulation_Order   	   = Convert(INT, MCRP1.ValueString)
   	      	   AND   	   BMFI.Prod_Id   	      	      	   = MCR.ProdId
   	   
    	        	     	    
   	   -------------------------------------------------------------------------------
   	   -- if the prod_id and sequence have not changed then check for changes in 
   	   -- quantity, scrap factor, puid, eng_unit, lot
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   BMFI
   	   SET   	   BMFI.Scrap_Factor   	   = CONVERT(FLOAT, MCRP2.ValueString),
   	      	   BMFI.Quantity   	      	   = CONVERT(FLOAT, MCR.QuantityString),
   	      	   BMFI.Eng_Unit_Id   	   = EU.Eng_Unit_Id,
   	      	   BMFI.Lot_Desc   	      	   = MCR.MaterialLotId
   	      	   FROM   	   Bill_Of_Material_Formulation_Item BMFI
   	      	   JOIN   	   @tMCR MCR 
   	      	   ON    	   MCR.FormulationItemId   	   = BMFI.Bom_Formulation_Item_Id
   	      	   JOIN   	   @tMCRP MCRP1 
   	      	   ON    	   MCRP1.ParentId    	      	   = MCR.NodeId 
   	      	   AND    	   MCRP1.Id   	      	   = @MaterialReservationSequence
   	      	   JOIN   	   @tMCRP MCRP2 
   	      	   ON    	   MCRP2.ParentId    	      	   = MCR.NodeId 
   	      	   AND    	   MCRP2.Id   	      	   = @ScrapPercent
   	      	   JOIN   	   Engineering_Unit eu 
   	      	   ON    	   EU.Eng_Unit_Code    	   = MCR.UOM
   	      	   WHERE   	   BMFI.Scrap_Factor   	   <> CONVERT(FLOAT, MCRP2.ValueString)
   	      	   OR BMFI.Quantity   	   <> CONVERT(FLOAT, MCR.QuantityString)
   	      	   OR BMFI.Eng_Unit_Id   	   <> EU.Eng_Unit_Id
   	      	   OR BMFI.Lot_Desc   	   <> MCR.MaterialLotId
   	   -------------------------------------------------------------------------------
   	   -- If the old formulation has items that are not on the current SAP formulation, 
   	   -- delete them
   	   -- Loop through each distinct MCR formulationId 
   	   -------------------------------------------------------------------------------
   	   --
   	   -- Mark all MCR records as unprocessed
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMCR
   	      	   SET   	   Status = 0
   	   -------------------------------------------------------------------------------
   	   -- Get first MPR to be processed
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @Id   	   = NULL
   	   SELECT   	   @Id   	   = MIN(Id)
   	      	   FROM   	   @tMCR
   	      	   WHERE   	   FormulationId Is Not Null
   	      	   AND   	   Status = 0
   	   -------------------------------------------------------------------------------
   	   -- Loop through each MCR
   	   -------------------------------------------------------------------------------
   	   WHILE   	   (@Id   	   Is Not NULL)
   	   BEGIN
   	      	   -------------------------------------------------------------------------------
   	      	   -- Retrieve some MPR attributes
   	      	   -------------------------------------------------------------------------------
   	      	   SELECT   	   @FormulationId   	   = FormulationId
   	      	      	   FROM   	   @tMCR
   	      	      	   WHERE   	   Id   	   = @Id
   	      	   -------------------------------------------------------------------------------
   	      	   -- Mark this MCR as processed   	   (use formulationId on the where so it works
   	      	   -- as a select distinct)
   	      	   -------------------------------------------------------------------------------
   	      	   UPDATE   	   @tMCR
   	      	      	   SET   	   Status   	      	   = 1
   	      	      	   WHERE   	   FormulationId   	   = @FormulationId
   	      	   -------------------------------------------------------------------------------
   	      	   -- delete BMFI formulation items not existent on the MCR items for this formulation id 
   	      	   -------------------------------------------------------------------------------
   	      	   DELETE   	   Bill_Of_Material_Formulation_Item
   	      	      	   FROM   	   Bill_Of_Material_Formulation_Item bmfi
   	      	      	   LEFT
   	      	      	   JOIN    	   @tMCR MCR
   	      	      	   ON   	   BMFI.Bom_Formulation_Id    	   = MCR.formulationid
   	      	      	   AND   	   BMFI.Bom_Formulation_Item_Id    	   = MCR.FormulationItemId
   	      	      	   WHERE   	   BMFI.Bom_Formulation_Id   	      	   = @FormulationId
   	      	      	   AND   	   MCR.FormulationItemId    	      	   IS NULL
   	      	   -------------------------------------------------------------------------------
   	      	   -- Get next MCR to be processed
   	      	   -------------------------------------------------------------------------------
   	      	   SELECT   	   @Id   	   = NULL
   	      	   SELECT   	   @Id   	   = MIN(Id)
   	      	      	   FROM   	   @tMCR
   	      	      	   WHERE   	   FormulationId Is Not Null
   	      	      	   AND   	   Status = 0
   	   END
   	   -------------------------------------------------------------------------------
   	   -- get uom for the Bill_Of_Material_Formulation_Item
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMCR
   	      	   SET   	   FormulationUOM   	      	   = EU.Eng_Unit_Code
   	      	   FROM   	   @tMCR MCR
   	      	   JOIN   	   Bill_Of_Material_Formulation_Item BMFI
   	      	   ON   	   BMFI.Bom_Formulation_Item_Id = MCR.FormulationItemId
   	      	   JOIN   	   Engineering_Unit EU
   	      	   ON   	   EU.Eng_Unit_Id   	      	   = BMFI.Eng_Unit_Id
   	   -------------------------------------------------------------------------------
   	   -- convert quantity if MCR UOM <> Bill_OF_material_Formulation_Item UOM
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   MCR
   	      	   SET   	   QuantityString  =  Convert(Float, MCR.QuantityString) * Coalesce(EUC.Slope, 1) + Coalesce(EUC.Intercept, 0)
   	      	      	   FROM   	   @tMCR MCR
   	      	      	   JOIN   	   Engineering_Unit E1
   	      	      	   ON   	   MCR.UOM   	   = E1.Eng_Unit_Code
   	      	      	   JOIN   	   Engineering_Unit E2
   	      	      	   ON   	   MCR.FormulationUOM = E2.Eng_unit_Code
   	      	      	   JOIN   	   Engineering_Unit_Conversion EUC
   	      	      	   ON   	   EUC.From_Eng_Unit_Id   	   = E1.Eng_Unit_Id
   	      	      	   AND   	   EUC.To_Eng_Unit_Id   	   = E2.Eng_Unit_Id
   	      	      	   WHERE   	   Coalesce(MCR.FormulationUOM,'XXX') <> Coalesce(MCR.UOM, 'YYY')
   	   -------------------------------------------------------------------------------
   	   -- Update User Defined Fields for Bill_Of_Material_Formulation
   	   -- Create Table Fields for  MCRP.Id
   	   -------------------------------------------------------------------------------
    	      	    
 	  	  	  	  	 INSERT   	   Table_Fields(Ed_Field_Type_Id,Table_Field_Desc,TableId)
   	      	   SELECT   	   Distinct 1, MCRP.Id, @BOMFITableId
   	      	      	   FROM   	   @tMCR MCR
   	      	      	   JOIN   	   @TMCRP MCRP
   	      	      	   ON   	   MCRP.ParentId   	      	   = MCR.NodeId
   	      	      	   LEFT
   	      	      	   JOIN   	   Table_Fields TF
   	      	      	   ON   	   MCRP.Id   	      	      	   = TF.Table_Field_Desc
   	      	      	   WHERE   	   MCRP.Id   	      	      	   Is Not Null
   	      	      	   AND   	   TF.Table_Field_Id   	   Is Null
   	   -------------------------------------------------------------------------------
   	   -- Delete user_defined_values previously associated with the formulations
   	   -------------------------------------------------------------------------------
   	   DELETE   	   Table_Fields_Values
   	      	   FROM   	   Table_Fields_Values TFV
   	      	   JOIN   	   Table_Fields TF
   	      	   ON   	   TF.Table_Field_Id   	   = TFV.Table_Field_Id
   	      	   AND   	   @BOMFITableId   	      	   = TFV.TableId   	      	      	   
   	      	   JOIN   	   @tMCRP MCRP
   	      	   ON   	   MCRP.Id    	      	   = TF.Table_Field_Desc
   	      	   JOIN   	   @tMCR MCR
   	      	   ON   	   MCRP.ParentId   	      	   = MCR.NodeId
   	      	   AND   	   MCR.FormulationItemId   	   = TFV.KeyId
   	   -------------------------------------------------------------------------------
   	   -- create table_fields_vales for mcrp 
   	   -------------------------------------------------------------------------------
   	   INSERT   	   Table_Fields_Values
   	      	   (KeyId, 
   	      	   TableId, 
   	      	   Table_Field_Id, 
   	      	   Value) 
   	   SELECT  MCR.FormulationItemId, 
   	      	   @BOMFITableId,    	      	    
   	      	   TF.Table_Field_Id, 
   	      	   MCRP.ValueString
   	      	   FROM   	   @tMCR MCR
   	      	   JOIN   	   @tMCRP MCRP
   	      	   ON   	   MCR.NodeId   	   = MCRP.ParentId 
   	      	   JOIN   	   TABLE_Fields TF 
   	      	   ON    	   TF.Table_field_desc = MCRP.Id
   	      	   WHERE   	   MCRP.ValueString IS NOT NULL 
   	      	   AND   	   MCR.FormulationItemId   	   Is Not Null
END -- IF   	   @FlgIgnoreBOMInfo = 0  
-------------------------------------------------------------------------------
-- Handle Production_Plan
-------------------------------------------------------------------------------
DECLARE   	   PPXCursor INSENSITIVE CURSOR    	   
   	   FOR (SELECT   	   ER.PPId, 
   	      	      	   PR.ProcessOrder, 
   	      	      	   PR.CommentId, 
   	      	      	   PR.Comment, 
   	      	      	   ER.PathId, 
   	      	      	   SR.EarliestStartTime, 
   	      	      	   SR.LatestEndTime,
   	      	      	   ER.NodeId,
   	      	      	   SR.NodeId,
   	      	      	   ER.PPStatusId,
   	      	      	   ER.UserId
   	      	      	   FROM   	   @tPR PR
   	      	      	   JOIN   	   @tSR SR
   	      	      	   ON   	   SR.ParentId   	   = PR.NodeId
   	      	      	   JOIN   	   @tER ER
   	      	      	   ON   	   ER.ParentId   	   = SR.NodeId)
   	      	       	   ORDER   	   By PR.ProcessOrder For Read Only 
OPEN   	   PPXCursor
FETCH   	   NEXT FROM PPXCursor INTO  @PPId, @ProcessOrder, @CommentId, @Comment,  @PathId, @StartTime, @EndTime, @ERNodeId, @SRNodeId, 
   	      	      	      	     @CurrentPPStatusId, @UserId
WHILE   	   @@Fetch_Status = 0
BEGIN
   	   -------------------------------------------------------------------------------
   	   -- Get Product (can not join to tMPR on the cursor definition, because it might 
   	   -- have multiple MPRs)
   	   -- All the MPRs for a given SR are for the same product
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @ProdId   	   = Null,
   	      	   @QTy   	   = Null
   	   SELECT   	   TOP 1 @ProdId = ProdId
   	      	   FROM   	   @tMPR
   	      	   WHERE   	   ParentId   	   = @SRNodeId   	      	   
   	   -------------------------------------------------------------------------------
   	   -- Add all MPR.Qty (already UOM converted) to get the PP.Forecast_Quantity
   	   -- All the MPRs for a given SR are for the same product
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @Qty   	   = Sum(Qty)
   	      	   FROM   	   @tMPR
   	      	   WHERE   	   ParentId   	   = @SRNodeId   	      	   
   	   -------------------------------------------------------------------------------
   	   -- Figure out the PP Status
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @SPPPStatusId   	   = @PPStatusId
   	   -------------------------------------------------------------------------------
   	   -- If the UDP for PP Error Status was configured and the PP Status exists, then
   	   -- the value for the flag will be 1 and the interface will check if any condition
   	   -- to set the PP Status to error happened.
   	   -------------------------------------------------------------------------------
   	   IF   	   @flgCheckErrorStatus   	   = 1 
   	   BEGIN
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Step1:If there is any new MPR product then set PP status to error
 	  	  	  	 -- and return a warning message.
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 IF (SELECT COUNT(*) 	 FROM   	   @tMPR 	 WHERE   	   ParentId   	   = @SRNodeId 	 AND   	   FlgNewProduct   	   = 1) > 0
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT   	   @SPPPStatusId   	   = @PPErrorStatusId
 	  	  	  	  	 DELETE FROM @tErrRef
 	  	  	  	  	 SELECT @ErrCode = -171
 	  	  	  	  	 INSERT INTO @tErrRef (ErrorCode, ReferenceData)
 	  	  	  	  	  	 SELECT @ErrCode, 'Process Order: ' 
 	  	  	  	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	  	  	 FROM @tMPR mpr
 	  	  	  	  	  	 JOIN @tSR sr ON mpr.ParentId = sr.NodeId AND sr.NodeId = @SRNodeId AND mpr.FlgNewProduct   = 1
 	  	  	  	  	  	 JOIN @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	 JOIN @tER er ON er.ParentId = sr.NodeId
 	  	  	  	  	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
 	  	  	  	  	  	 FROM dbo.email_message_data emd 
 	  	  	  	  	  	 JOIN @tErrRef er on er.ErrorCode = @ErrCode
 	  	  	  	  	  	 WHERE emd.Message_Id = @ErrCode
 	  	  	  	 END
     	   ELSE 
   	      	   -------------------------------------------------------------------------------
   	      	   -- Step2:If there is any MPR product (will apply to only existing products, since an
   	      	   -- error message will be generated above for the new products) that the interface
   	      	   -- found the PUId (production point for the path) and associated with the product,
   	      	   -- it will set the PP status to error and return a warning message.
   	      	   -------------------------------------------------------------------------------
   	        	    
   	      	   IF   	   (SELECT   	   COUNT(*)
   	      	      	      	   FROM   	   @tMPR
   	      	      	      	   WHERE   	   ParentId   	   = @SRNodeId
   	      	      	      	   AND   	   FlgNewProduct   	   <> 1  -- doesn't really matter
   	      	      	      	   AND   	   CreatePUAssoc   	   = 1
   	      	      	      	   AND   	   PUId   	   Is NOT NULL) > 0
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT   	   @SPPPStatusId   	   = @PPErrorStatusId
 	  	  	  	  	  	  	 DELETE FROM @tErrRef
 	  	  	  	  	  	  	 SELECT @ErrCode = -175
 	  	  	  	  	  	  	 INSERT INTO @tErrRef (ErrorCode, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, 'Process Order: ' 
 	  	  	  	  	  	  	  	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	  	  	  	  	  	  	  	 + ' - Prod Unit: ' + COALESCE(PU.PU_Desc, 'NA')
 	  	  	  	  	  	  	  	 FROM @tMPR mpr
 	  	  	  	  	  	  	  	 JOIN dbo.Prod_Units PU ON mpr.PUId = PU.PU_Id
 	  	  	  	  	  	  	  	 JOIN 	 @tSR sr ON mpr.ParentId = sr.NodeId AND sr.NodeId = @SRNodeId
 	  	  	  	  	  	  	  	  	  	 AND mpr.FlgNewProduct   <> 1 AND mpr.CreatePUAssoc   = 1 AND mpr.PUId IS NOT NULL
 	  	  	  	  	  	  	  	 JOIN @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	  	  	 JOIN @tER er ON er.ParentId = sr.NodeId
 	  	  	  	  	  	  	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
 	  	  	  	  	  	  	  	 FROM dbo.email_message_data emd 
 	  	  	  	  	  	  	  	 JOIN @tErrRef er on er.ErrorCode = @ErrCode
 	  	  	  	  	  	  	  	 WHERE emd.Message_Id = @ErrCode
 	  	  	  	  	  	 END
   	      	   ELSE
   	      	   -------------------------------------------------------------------------------
   	      	   -- Step3:If there is any MPR product (will apply to only existing products, since an
   	      	   -- error message will be generated above for the new products) that the interface
   	      	   -- found the PathId (bound PO) and associated with the path,
   	      	   -- it will set the PP status to error and return a warning message.
   	      	   -------------------------------------------------------------------------------
   	      	   IF   	   (SELECT   	   COUNT(*)
   	      	      	      	   FROM   	   @tMPR
   	      	      	      	   WHERE   	   ParentId   	   = @SRNodeId
   	      	      	      	   AND   	   FlgNewProduct   	   <> 1  -- doesn't really matter
   	      	      	      	   AND   	   CreatePathAssoc   	   = 1
   	      	      	      	   AND   	   PathId   	   Is NOT NULL) > 0
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT   	   @SPPPStatusId   	   = @PPErrorStatusId
 	  	  	  	  	  	  	 DELETE FROM @tErrRef
 	  	  	  	  	  	  	 SELECT @ErrCode = -176
 	  	  	  	  	  	  	 INSERT INTO @tErrRef (ErrorCode, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, 'Process Order: ' 
 	  	  	  	  	  	  	  	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	  	  	  	  	 FROM @tMPR mpr
 	  	  	  	  	  	  	  	 JOIN 	 @tSR sr
 	  	  	  	  	  	  	  	 ON mpr.ParentId = sr.NodeId AND sr.NodeId = @SRNodeId AND 	  	 mpr.FlgNewProduct   <> 1
 	  	  	  	  	  	  	  	  	  	  	 AND mpr.CreatePathAssoc = 1 AND mpr.PathId IS NOT NULL
 	  	  	  	  	  	  	  	 JOIN 	 @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	  	  	 JOIN 	 @tER er ON er.ParentId = sr.NodeId
 	  	  	  	  	  	  	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
 	  	  	  	  	  	  	  	 FROM dbo.email_message_data emd 
 	  	  	  	  	  	  	  	 JOIN @tErrRef er on er.ErrorCode = @ErrCode
 	  	  	  	  	  	  	  	 WHERE emd.Message_Id = @ErrCode
 	  	  	  	  	  	 END
   	      	   ELSE
   	      	   -------------------------------------------------------------------------------
   	      	   -- Step4:If there is any MPR product (will apply to only existing products, since an
   	      	   -- error message will be generated above for the new products) that the interface
   	      	   -- could not find a PUId (production point for the path) to associate the 
   	      	   -- product with, then set the PP status to error and return a warning message.
   	      	   -------------------------------------------------------------------------------
   	      	   IF   	   (SELECT   	   COUNT(*)
   	      	      	      	   FROM   	   @tMPR
   	      	      	      	   WHERE   	   ParentId   	   = @SRNodeId
   	      	      	      	   AND   	   FlgNewProduct   	   <> 1  -- doesn't really matter
   	      	      	      	   AND   	   PUId   	   Is NULL) > 0
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT   	   @SPPPStatusId   	   = @PPErrorStatusId
 	  	  	  	  	  	  	 DELETE FROM @tErrRef
 	  	  	  	  	  	  	 SELECT @ErrCode = -172
 	  	  	  	  	  	  	 INSERT INTO @tErrRef (ErrorCode, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, 'Process Order: ' 
 	  	  	  	  	  	  	  	  	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	  	  	  	  	 FROM @tMPR mpr
 	  	  	  	  	  	  	  	 JOIN @tSR sr ON mpr.ParentId = sr.NodeId AND sr.NodeId = @SRNodeId
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	  	 mpr.FlgNewProduct  <> 1 AND mpr.PUId IS NULL
 	  	  	  	  	  	  	  	 JOIN 	 @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	  	  	 JOIN 	 @tER er ON er.ParentId = sr.NodeId    	        	        	        	    
 	  	  	  	  	  	  	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
 	  	  	  	  	  	  	  	 FROM dbo.email_message_data emd 
 	  	  	  	  	  	  	  	 JOIN @tErrRef er on er.ErrorCode = @ErrCode
 	  	  	  	  	  	  	  	 WHERE emd.Message_Id = @ErrCode
 	  	  	  	  	  	 END
   	      	   ELSE
   	      	   -------------------------------------------------------------------------------
   	      	   -- Step5:If there is any MPR product (will apply to only existing products, since an
   	      	   -- error message will be generated above for the new products) that the interface
   	      	   -- could not find a Path (unbound PO) to associate the 
   	      	   -- product with, then set the PP status to error and return a warning message.
   	      	   -------------------------------------------------------------------------------
   	      	   IF   	   (SELECT   	   COUNT(*)
   	      	      	      	   FROM   	   @tMPR
   	      	      	      	   WHERE   	   ParentId   	   = @SRNodeId
   	      	      	      	   AND   	   FlgNewProduct   	   <> 1   -- doesn't really matter
   	      	      	      	   AND   	   PathId   	   Is NULL) > 0
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT   	   @SPPPStatusId   	   = @PPErrorStatusId
 	  	  	  	  	  	  	 DELETE FROM @tErrRef
 	  	  	  	  	  	  	 SELECT @ErrCode = -173
 	  	  	  	  	  	  	 INSERT INTO @tErrRef (ErrorCode, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, 'Process Order: ' 
 	  	  	  	  	  	  	  	  	  	  	  	 + COALESCE(pr.ProcessOrder, 'NA') +' On Path: ' + COALESCE(er.EquipmentID, 'NA')
 	  	  	  	  	  	  	  	  	  	  	  	 + ' - Product Code: ' + COALESCE(mpr.ProdCode, 'NA')
 	  	  	  	  	  	  	  	 FROM @tMPR mpr
 	  	  	  	  	  	  	  	 JOIN @tSR sr ON mpr.ParentId = sr.NodeId
 	  	  	  	  	  	  	  	  	  	 AND sr.NodeId = @SRNodeId AND mpr.FlgNewProduct <> 1 AND mpr.PathId IS NULL
 	  	  	  	  	  	  	  	 JOIN @tPR pr ON sr.ParentId = pr.NodeId
 	  	  	  	  	  	  	  	 JOIN @tER er ON er.ParentId = sr.NodeId   
 	  	  	  	  	  	  	 INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
 	  	  	  	  	  	  	  	 SELECT @ErrCode, emd.Message_Subject, emd.Message_Text, emd.Severity, er.ReferenceData
 	  	  	  	  	  	  	  	  	 FROM dbo.email_message_data emd 
 	  	  	  	  	  	  	  	  	 JOIN @tErrRef er on er.ErrorCode = @ErrCode
 	  	  	  	  	  	  	  	  	 WHERE emd.Message_Id = @ErrCode
 	  	  	  	  	  	 END
   	      	   ELSE
   	      	   -------------------------------------------------------------------------------
   	      	   -- If there is any new MCR product that the interface didn't get a PU id to
   	      	   -- associate with, set the PP status.
   	      	   -------------------------------------------------------------------------------
   	      	   IF   	   (SELECT   	   COUNT(*)
   	      	      	      	   FROM   	   @tMCR
   	      	      	      	   WHERE   	   ParentId   	   = @SRNodeId
   	      	      	      	   AND   	   PUId   	      	   Is Null
   	      	      	      	   AND   	   FlgNewProduct   	   = 1) > 0
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT   	   @SPPPStatusId   	   = @PPErrorStatusId
 	  	  	  	  	  	 END
   	      	   ELSE
   	      	   -------------------------------------------------------------------------------
   	      	   -- If there is any new MCR product (associated or not associated to a PU) and 
   	      	   -- the PP is unbound, then set the PP status to error (because the new product 
   	      	   -- could not be associated with any path)
   	      	   -------------------------------------------------------------------------------
 	  	  	  	  	  	 IF @PathId Is Null AND (SELECT COUNT(*) FROM @tMCR WHERE ParentId = @SRNodeId AND FlgNewProduct = 1) > 0   	      	   
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT @SPPPStatusId = @PPErrorStatusId
 	  	  	  	  	  	 END   	   
   	   END
   	   -------------------------------------------------------------------------------
   	   --  First, make changes to Comments TABLE
   	   -------------------------------------------------------------------------------
   	   IF   	   @CommentId IS NOT NULL
   	   BEGIN
 	  	  	  	 UPDATE Comments 	  SET Comment_Text = @Comment, Comment = @Comment WHERE Comment_Id = @CommentId
   	   END
   	   ELSE
   	   BEGIN
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Add Comment WHERE Comment_text = Comment + Process_Order to make it unique
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 IF @Comment IS NOT NULL
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT Comments (Comment_Text,Comment,User_Id,CS_Id,Modified_On) 
 	  	  	  	  	  	 VALUES (@Comment+ LTRIM(@ProcessOrder),@Comment,@UserId,3,GetDate())
 	  	  	  	  	 SELECT   	   @CommentId   	   = @@Identity
 	  	  	  	  	 UPDATE   	   @tPR 
 	  	  	  	  	 SET   	   CommentId    	   = @CommentID 
 	  	  	  	  	 WHERE   	   ProcessOrder   	   = @ProcessOrder
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- now UPDATE the unique Comment.  Now It may NOT be unique
 	  	  	  	 -- I don't know why he does that, since the table does not have any unique 
 	  	  	  	 -- constraint for the commenttext column
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 UPDATE Comments 	 SET Comment_text = Comment,TopOfChain_id = Comment_Id 
 	  	  	  	  	 WHERE   	   Comment_Id    	   = @CommentId
 	  	  	  	 END
   	   END
   	   -------------------------------------------------------------------------------
   	   -- now add / change production plan
   	   -------------------------------------------------------------------------------
   	   IF   	   @PPId   	   Is Null
   	   BEGIN
   	      	   SELECT   	   @TransType   	   = 1,
   	      	      	   @TransNum   	   = 0 
   	   END
   	   ELSE
   	   BEGIN
   	      	   SELECT   	   @TransType   	   = 2,
   	      	      	   @TransNum   	   = 0
   	   END
   	   -------------------------------------------------------------------------------
   	   -- For existing Process orders which new status was not set to 'error' (due
   	   -- some MPR/MCR situation), set it to the current status
   	   -------------------------------------------------------------------------------
   	   IF   	   @SPPPStatusId   	   = @PPStatusId
   	   BEGIN
   	      	   IF   	   @PPId   	   Is Not Null
   	      	   BEGIN
   	      	      	 SELECT   	   @SPPPStatusId   	   = @CurrentPPStatusId
   	      	   END
   	   END
IF @FlagCreate = 1
   	   EXECUTE   	   @RC = spServer_DBMgrUpdProdPlan 
   	      	   @PPId   	      	      	   OUTPUT, -- PPId   	      	      	   
   	      	   @TransType,   	      	      	      	   -- TransType
   	      	   @TransNum,   	      	      	      	   -- TransNum
   	      	   @PathId,   	      	      	      	   -- PathId    	      	      	   
   	      	   @CommentId,    	      	      	   -- CommentId
   	      	   @ProdId,    	      	      	      	   -- ProdId
   	      	   Null,   	      	      	      	   -- Implied Sequence
   	      	   @SPPPStatusId,   	      	      	   -- Status Id
   	      	   1,        	       	      	      	   -- PP Type Id
   	      	   Null,    	      	      	      	   -- Source PP Id
   	      	   @UserId,   	      	      	      	   -- User Id
   	      	   Null,    	      	      	      	   -- Parent PP Id
   	      	   2,   	      	      	      	      	   -- Control Type 
   	      	   @StartTime,    	      	      	   -- Forecast_Start_Time
   	      	   @EndTime,    	      	      	      	   -- Forecast_End_Time
   	      	   Null,    	      	      	      	   -- Entry_On
   	      	   @Qty,   	      	      	      	   -- Forecast_Quantity 
   	      	   0,   	      	      	      	      	   -- Production_Rate 
   	      	   0,   	      	      	      	      	   -- Adjusted Quantity 
   	      	   Null,   	      	      	      	   -- Block Number, 
   	      	   @ProcessOrder,   	      	      	   -- Process_Order
   	      	   Null,   	      	      	      	   -- Transaction Time   	   
   	      	   Null,   	      	      	      	   -- Misc1
   	      	   Null,   	      	      	      	   -- Misc2
   	      	   Null,   	      	      	      	   -- Misc3
   	      	   Null   	      	      	      	   -- Misc4
   	   IF   	   @RC   	   = -100
   	   BEGIN
   	      	   CLOSE   	      	   PPXCursor
   	      	   DEALLOCATE   	   PPXCursor
            INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
              SELECT -106, emd.Message_Subject, emd.Message_Text, emd.Severity, 'ProcessOrder: ' + COALESCE(@ProcessOrder,'NA')
                FROM dbo.email_message_data emd 
                WHERE emd.Message_Id = -106
 	  	  	   GOTo ErrCode
   	  	  	   --RETURN   	   (0)
   	   END
 	   SELECT @FlgSendRSProductionPlan 	 = 1
 	   --INSERT Local_Update_ScheduleView(PPId, ProcessOrder, EntryOn, Processed)
 	   -- 	 VALUES (@PPId, @ProcessOrder, GetDate(), 0)
   	   -- Update ER with newly created PPId
   	   IF   	   (SELECT   	   Count(*)
   	      	      	   FROM   	   @tER
   	      	      	   WHERE   	   NodeId   	   = @ERNodeId
   	      	      	   AND   	   PPId   	   Is Null) > 0
   	   BEGIN
   	      	   UPDATE   	   @tER
   	      	      	   SET   	   PPId   	   = @PPId
   	      	      	   WHERE   	   NodeId   	   = @ERNodeId
   	   END
   	   FETCH   	   NEXT FROM PPXCursor INTO  @PPId, @ProcessOrder, @CommentId, @Comment,  @PathId, @StartTime, @EndTime, @ERNodeId, @SRNodeId,
   	      	      	      	      	     @CurrentPPStatusId, @UserId
END 
CLOSE   	      	   PPXCursor
DEALLOCATE   	   PPXCursor
-------------------------------------------------------------------------------
-- Handle PP fields not supported by resultset
--
-- TODO: Incorporate the BOM_Formulation_Id column to the spServer
-------------------------------------------------------------------------------
UPDATE PP 
   	   SET BOM_Formulation_Id    	   = PR.FormulationId
   	   FROM production_plan PP
   	   JOIN @tER ER ON ER.PPId = PP.PP_Id
   	   JOIN @tSR SR ON ER.ParentId = SR.NodeId
   	   JOIN @tPR PR ON PR.NodeId = SR.ParentId
-------------------------------------------------------------------------------
-- Handle PP UDPs
--
-- Create Table Fields for  MPRP.Id
-------------------------------------------------------------------------------
INSERT   	   Table_Fields(Ed_Field_Type_Id,Table_Field_Desc,TableId)
 	 SELECT   	   Distinct 1,MPRP.Id, @PPTableId
 	  	 FROM @tMPR MPR
 	  	 JOIN @tMPRP MPRP ON MPRP.ParentId = MPR.NodeId
 	  	 LEFT JOIN Table_Fields TF ON MPRP.Id = TF.Table_Field_Desc
 	  	 WHERE MPRP.Id Is Not Null AND TF.Table_Field_Id   	   Is Null
-------------------------------------------------------------------------------
-- delete table_fields_values pointing to ppids AND table_fields_ids
-------------------------------------------------------------------------------
DELETE Table_Fields_Values
 	 FROM Table_Fields_Values TFV
 	 JOIN Table_Fields TF 	 ON TF.Table_Field_Id = TFV.Table_Field_Id 	 AND @PPTableId = TFV.TableId
 	 JOIN @tMPRP MPRP 	 ON MPRP.Id = TF.Table_Field_Desc
 	 JOIN @tMPR MPR 	 ON MPRP.ParentId = MPR.NodeId
 	 JOIN @tER ER 	 ON MPR.ParentId = ER.ParentId 	 AND ER.PPId = TFV.KeyId
-------------------------------------------------------------------------------
-- create table_fields_values for mprp associated with a ppid
-------------------------------------------------------------------------------
INSERT    	   Table_Fields_Values  (KeyId,TableId,Table_Field_Id,Value) 
 	 SELECT DISTINCT ER.PPId,@PPTableId,TF.Table_Field_Id,MPRP.ValueString
 	  	 FROM @tMPRP MPRP
 	  	 JOIN @tMPR MPR ON MPRP.ParentId = MPR.NodeId
 	  	 JOIN @tER ER ON MPR.ParentId = ER.ParentId AND ER.PPId Is Not Null
 	  	 JOIN Table_Fields TF ON TF.Table_Field_Desc = MPRP.Id
 	 WHERE ER.PPId IS Not Null
-------------------------------------------------------------------------------
-- Handle <Any> UDPs for the PPId
--
-- Extract the UDPS from the ProductionRequest XML element
-------------------------------------------------------------------------------
INSERT    	   @tAnyUDP (ParentId,NodeId,tText,ElementName,UDPElementId)
 	 SELECT x0.Id,x1.Id,x4.tText,x3.LocalName,x3.ParentId
 	 FROM #tXML x0
 	 JOIN  #tXML x1  	 ON x1.ParentId= x0.Id 	 AND x0.LocalName = 'ProductionRequest'
 	 JOIN #tXML x2 	 ON x2.ParentId = x1.Id AND x1.LocalName = 'Any' 	 AND x2.LocalName = 'UDP'
 	 JOIN #tXML x3 	 ON x2.Id = x3.Parentid
 	 JOIN #tXML x4 	 ON x3.Id= x4.Parentid 	 AND x4.LocalName= '#Text'
-------------------------------------------------------------------------------
-- Get PPId and TableId
-------------------------------------------------------------------------------
UPDATE   	   AN
   	   SET   	   KeyId   	      	   = ER.PPId,
   	      	   TableId   	      	   = @PPTableId
   	   FROM   	   @tAnyUDP AN
   	   JOIN   	   @tSR SR ON SR.ParentId = AN.ParentId
   	   JOIN   	   @tER ER ON ER.ParentId = SR.NodeId   	   
--select '11'
--select * from @tAnyUDP
-------------------------------------------------------------------------------
-- Create Table Fields for the <ANY> elements
-------------------------------------------------------------------------------
INSERT   	   Table_Fields(Ed_Field_Type_Id,Table_Field_Desc,TableId)
 	 SELECT   	   Distinct 1,tText,AN.TableId 
 	  	 FROM   	   @tAnyUDP AN
 	  	 LEFT JOIN Table_Fields TF ON AN.tText = TF.Table_Field_Desc
 	  	 WHERE   	   AN.ElementName  ='NAME' AND AN.tText IS NOT Null AND TF.Table_Field_Id Is Null
-------------------------------------------------------------------------------
-- create table_fields_values for the <Any> UDP elements for PPId
-------------------------------------------------------------------------------
INSERT  Table_Fields_Values (KeyId, TableId, Table_Field_Id,Value) 
SELECT    	   DISTINCT AN.KeyId,AN.TableId,TF.Table_Field_Id,AN.tText
 	 FROM @tAnyUDP AN
 	 JOIN @tAnyUDP AN1 	 ON AN.UDPElementId  = AN1.UDPElementId 	 AND AN1.ElementName = 'NAME'
 	 JOIN Table_Fields TF 	 ON AN1.tText = TF.Table_Field_Desc
 	 LEFT JOIN Table_Fields_Values TFV 	 ON TFV.KeyId = AN.KeyId
 	  	  	 AND TFV.TableId = AN.TableId 	 AND TFV.Table_Field_Id = TF.Table_Field_Id
 	 WHERE   	   AN.ElementName  = 'VALUE' 	 AND  TFV.KeyId   	      	   IS NULL
-------------------------------------------------------------------------------
-- UPDATE existing <Any> UDP elements for PPId
-------------------------------------------------------------------------------
UPDATE   	   TFV
 	 SET TFV.Value = AN1.tText
 	 FROM Table_Fields_Values TFV
 	 JOIN @tAnyUDP AN ON AN.KeyId = TFV.KeyId 	 AND AN.ElementName = 'Name'
 	 JOIN   	   Table_Fields TF 	 ON TFV.Table_Field_Id = TF.Table_Field_Id 	 AND TF.Table_Field_Desc  = AN.tText
 	 JOIN   	   @tAnyUDP AN1 	 ON AN.UDPElementId = AN1.UDPElementId 	 AND  AN1.ElementName   = 'Value'
-------------------------------------------------------------------------------
-- Handle Production_Setup
-------------------------------------------------------------------------------
DECLARE   	   PSXCursor INSENSITIVE CURSOR    	   
   	   For (SELECT   	   ER.PPId, 
   	      	      	   MPR.Qty,
   	      	      	   MPR.MaterialLotId,
   	      	      	   MPR.PUId,
   	      	      	   PP.Path_Id,
   	      	      	   MPR.Id,
   	      	      	   MPR.UOM
   	      	      	   FROM   	   @tER ER
   	      	      	   JOIN   	   @tMPR MPR
   	      	      	   ON   	   MPR.ParentId   	   = ER.ParentId
   	      	      	   JOIN   	   Production_Plan PP
   	      	      	   ON   	   ER.PPId   	      	   = PP.PP_Id)
   	      	       	   ORDER   	   By ER.PPId For Read Only 
OPEN   	   PSXCursor
FETCH   	   NEXT FROM PSXCursor INTO  @PPId, @Qty, @MaterialLotId, @PUId, @PathId, @Id, @UOM
WHILE   	   @@Fetch_Status = 0
BEGIN
   	   SELECT   	   @PPSetupId   	   = Null
   	   SELECT   	   @PPSetupId   	   = PP_Setup_Id
   	      	   FROM   	   Production_Setup 
   	      	   WHERE   	   PP_Id   	      	   = @PPId
   	      	   AND   	   Pattern_Code   	   = @MaterialLotId
   	   IF   	   @PPSetupId   	   Is Null
   	   BEGIN
   	      	   SELECT   	   @TransType   	   = 1,
   	      	      	   @TransNum   	   = 0
   	   END
   	   ELSE
   	   BEGIN
   	      	   SELECT   	   @TransType   	   = 2,
   	      	      	   @TransNum   	   = 0
   	   END
IF @FlagCreate = 1
   	   EXECUTE   	   @RC = SpServer_DBMgrUpdProdSetup
   	      	   @PPSetupId   	   OUTPUT,   	   -- SetupID
   	      	   @TransType,   	          	   -- Action
   	      	   @TransNum,   	       	      	   -- TransNum
   	      	   @UserId,     	      	      	   -- UserId
   	      	   @PPId,   	      	      	   -- PPId
   	      	   NULL,    	      	      	   -- ImpliedSequence
   	      	   @PPStatusId,       	      	   -- PPStatusId
   	      	   NULL,        	      	      	   -- PatternRepetitions
   	      	   NULL,     	      	      	   -- CommentId
   	      	   @Qty,    	      	      	   -- ForecastQuantity
   	      	   NULL,    	      	      	   -- BaseDimX
   	      	   NULL,    	      	      	   -- BaseDimY
   	      	   NULL,    	      	      	   -- BaseDimZ
   	      	   NULL,    	      	      	   -- BaseDimA
   	      	   NULL,    	      	      	   -- BaseGeneral1
   	      	   NULL,    	      	      	   -- BaseGeneral2
   	      	   NULL,    	      	      	   -- BaseGeneral3
   	      	   NULL,    	      	      	   -- BaseGeneral4
   	      	   NULL,    	      	      	   -- Shrinkage
   	      	   @MaterialLotId,   	      	   -- PatternCode
   	      	   @PathID,     	      	      	   -- PathId
   	      	   NULL,    	      	      	   -- EntryOn
   	      	   NULL,       	      	      	   -- TransactionTime
   	      	   NULL   	      	      	   -- ParentPPSetupId
   	   IF   	   @RC   	   = -100
   	   BEGIN
   	      	   CLOSE   	      	   PSXCursor
   	      	   DEALLOCATE   	   PSXCursor
    	        	    
    	        	 SELECT 	 @ReferenceString = NULL   
    	        	 SELECT 	 @ReferenceString = Process_Order
    	        	  	  	 FROM 	 dbo.Production_Plan
    	        	  	  	 WHERE 	 PP_Id = @PPId   
            INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
              SELECT -107, emd.Message_Subject, emd.Message_Text, emd.Severity, 
 	  	  	  	  	 'Process Order: ' + COALESCE(@ReferenceString, 'NA') 
                FROM dbo.email_message_data emd 
                WHERE emd.Message_Id = -107
 	  	  	       GOTo ErrCode
   	  	  	   --RETURN   	   (0)
   	   END
 	   SELECT @FlgSendRSProductionSetup 	 = 1
   	   -------------------------------------------------------------------------------
   	   -- Update MPR with the PPSetupId
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tMPR
   	      	   SET   	   PPSetupId   	   = @PPSetupId
   	      	   WHERE   	   Id   	      	   = @Id
   	   -------------------------------------------------------------------------------
   	   -- Handle UDPs for PPSetupId
   	   -------------------------------------------------------------------------------
   	   IF   	   (SELECT   	   COUNT(Table_Field_Id)
   	      	      	   FROM   	   Table_Fields
   	      	      	   WHERE   	   Table_Field_Id   	   = @PSOriginalEngUnitCodeUDP) > 0
   	   BEGIN
   	      	   -------------------------------------------------------------------------------
   	      	   -- Store the original UOM for this PPSetup (Batch)
   	      	   -------------------------------------------------------------------------------
   	      	   IF   	   (SELECT   	   COUNT(KeyId)
   	      	      	      	   FROM   	   Table_Fields_Values
   	      	      	      	   WHERE   	   KeyId   	      	   = @PPSetupId
   	      	      	      	   AND   	   Table_Field_Id   	   = @PSOriginalEngUnitCodeUDP
   	      	      	      	   AND   	   TableId   	      	   = @PSTableId) > 0
   	      	   BEGIN
   	      	      	   UPDATE   	   Table_Fields_Values
   	      	      	      	   SET   	   Value   	      	   = @UOM
   	      	      	      	   WHERE   	   KeyId   	      	   = @PPSetupId
   	      	      	      	   AND   	   Table_Field_Id   	   = @PSOriginalEngUnitCodeUDP
   	      	      	      	   AND   	   TableId   	      	   = @PSTableId
   	      	   END
   	      	   ELSE
   	      	   BEGIN
   	      	      	   INSERT   	   Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
   	      	      	      	   VALUES   	   (@PPSetupId, @PSOriginalEngUnitCodeUDP, @PSTableId, @UOM)
   	      	   END
   	   END
   	   FETCH   	   NEXT FROM PSXCursor INTO  @PPId, @Qty, @MaterialLotId, @PUId, @PathId, @Id, @UOM
END
CLOSE   	      	   PSXCursor
DEALLOCATE   	   PSXCursor
-------------------------------------------------------------------------------
-- Handle <Any> UDPs for the PPId
--
-- Extract the UDPS from the ProductionRequest XML element
-------------------------------------------------------------------------------
INSERT    	   @tAnyMPRUDP (
   	   ParentId,   	      	      	   -- PR.Id
   	   NodeId,   	      	      	      	   -- ANY.Id
   	   tText,
   	   ElementName,
   	   UDPElementId)
 	 SELECT   	   x0.Id,x1.Id,x4.tText,x3.LocalName,x3.ParentId
 	  	 FROM #tXML x0
 	  	 JOIN #tXML x1 ON x1.ParentId = x0.Id AND x0.LocalName = 'MaterialProducedRequirement'
 	  	 JOIN #tXML x2 ON x2.ParentId = x1.Id AND x1.LocalName = 'Any' AND x2.LocalName = 'UDP'
 	  	 JOIN #tXML x3 ON x2.Id = x3.Parentid
 	  	 JOIN #tXML x4 ON x3.Id = x4.Parentid AND x4.LocalName  = '#Text'
-------------------------------------------------------------------------------
-- Get PSId and TableId
-------------------------------------------------------------------------------
UPDATE   	   AN
   	   SET   	   KeyId   	      	   = MPR.PPSetupId,
   	      	   TableId   	      	   = @PSTableId
   	   FROM   	   @tAnyMPRUDP AN
   	   JOIN   	   @tMPR MPR
   	   ON    	   MPR.NodeId    	   = AN.ParentId
-------------------------------------------------------------------------------
-- Create Table Fields for the <ANY> elements for MPR 
-------------------------------------------------------------------------------
INSERT Table_Fields (Ed_Field_Type_Id, Table_Field_Desc,TableId)
 	 SELECT   	   Distinct 1,tText,AN.TableId 
 	  	 FROM @tAnyMPRUDP AN
 	  	 LEFT JOIN   	   Table_Fields TF 	 ON AN.tText = TF.Table_Field_Desc
 	  	 WHERE AN.ElementName ='NAME' AND AN.tText IS NOT Null 	 AND TF.Table_Field_Id Is Null
-------------------------------------------------------------------------------
-- create table_fields_values for the <Any> UDP elements for PPId
-------------------------------------------------------------------------------
INSERT Table_Fields_Values (KeyId, TableId, Table_Field_Id, Value) 
 	 SELECT DISTINCT AN.KeyId,AN.TableId,TF.Table_Field_Id,AN.tText
 	 FROM @tAnyMPRUDP AN
 	 JOIN @tAnyMPRUDP AN1 ON AN.UDPElementId = AN1.UDPElementId 	 AND  AN1.ElementName = 'NAME'
 	 JOIN Table_Fields TF 	 ON AN1.tText = TF.Table_Field_Desc
 	 LEFT 	 JOIN Table_Fields_Values TFV 	 ON TFV.KeyId = AN.KeyId 	 AND TFV.TableId = AN.TableId 	 AND TFV.Table_Field_Id = TF.Table_Field_Id
 	 WHERE AN.ElementName = 'VALUE' 	 AND TFV.KeyId IS NULL
-------------------------------------------------------------------------------
-- UPDATE existing <Any> UDP elements for PPId
-------------------------------------------------------------------------------
UPDATE TFV
   	   SET TFV.Value = AN1.tText
   	   FROM Table_Fields_Values TFV
   	   JOIN @tAnyMPRUDP AN ON AN.KeyId = TFV.KeyId AND AN.ElementName = 'Name'
   	   JOIN Table_Fields TF ON TFV.Table_Field_Id = TF.Table_Field_Id AND TF.Table_Field_Desc = AN.tText
   	   JOIN @tAnyMPRUDP AN1 ON AN.UDPElementId = AN1.UDPElementId AND AN1.ElementName = 'Value'
-------------------------------------------------------------------------------
-- Handle <Any> SPs
--
-- Extract the <Any> Sps from the entire XML document
-------------------------------------------------------------------------------
INSERT    	   @tAnySP (ParentId,ElementName,NodeId,tText,Status)
 	 SELECT x2.ParentId,x2.LocalName,x3.id,x3.tText,0
 	  	 FROM #tXML x0
 	  	 JOIN #tXML x1 ON x1.ParentId = x0.Id AND x0.LocalName = 'Any' AND x1.LocalName = 'SP'
 	  	 JOIN #tXML x2 ON x2.ParentId = x1.Id
 	  	 JOIN #tXML x3 ON x3.ParentId = X2.Id AND x3.LocalName = '#Text'   	      	   
-------------------------------------------------------------------------------
-- Find first Stored Procedure name
-------------------------------------------------------------------------------
SELECT @RecSPId = NULL
SELECT @RecSPId = MIN(Id)
   	   FROM   	   @tAnySP
   	   WHERE ElementName = 'Name'  AND Status = 0
-------------------------------------------------------------------------------
-- Loop through the tAnySP table for all SP elements (elementName=Name)
-------------------------------------------------------------------------------
WHILE   	   (@RecSPId Is NOT NULL)
BEGIN
   	   -------------------------------------------------------------------------------
   	   -- Retrieve ELementId for this SP
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @ParentId   	   = ParentId,
   	      	   @SQLStatement   	   = tText  
   	      	   FROM   	   @tAnySP
   	      	   WHERE   	   Id   	   = @RecSPId
   	   -------------------------------------------------------------------------------
   	   -- Mark SP as 'processed'
   	   -------------------------------------------------------------------------------
   	   UPDATE   	   @tAnySP
   	      	   SET   	   Status   	   = 1
   	      	   WHERE   	   Id   	   = @RecSPId
   	   -------------------------------------------------------------------------------
   	   -- Check if SP exists
   	   -------------------------------------------------------------------------------
   	   IF   	   (SELECT   	   COUNT(Id)
   	      	      	   FROM   	   SysObjects
   	      	      	   WHERE   	   xType='P'
   	      	      	   AND   	   name   	   = @SQLStatement) = 0
   	   BEGIN
          INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
            SELECT -999, emd.Message_Subject, emd.Message_Text, emd.Severity, 'Custom Stored Procedure: ' 
 	  	  	  	 + COALESCE(@SQLStatement, 'NA')
              FROM dbo.email_message_data emd 
              WHERE emd.Message_Id = -999
   	   END
   	   ELSE
   	   BEGIN
   	      	   -------------------------------------------------------------------------------
   	      	   -- Search first parameter for this SP
   	      	   -------------------------------------------------------------------------------
   	      	   SELECT   	   @SQLStatement   	   = 'EXEC ' + @SQLStatement
   	      	   SELECT   	   @RecParmId   	   = NULL
   	      	   SELECT   	   @RecParmId   	   = MIN(Id)
   	      	      	   FROM   	   @tAnySP
   	      	      	   WHERE   	   ParentId   	   = @ParentId
   	      	      	   AND   	   ElementName   	   = 'Parm'
   	      	      	   AND   	   Status   	      	   = 0
   	      	   -------------------------------------------------------------------------------
   	      	   -- Loop through all other parameters for this SP
   	      	   -------------------------------------------------------------------------------
   	      	   WHILE   	   (@RecParmId   	   IS NOT NULL)
   	      	   BEGIN
   	      	      	   -------------------------------------------------------------------------------
   	      	      	   -- Build SQL Statement and mark the parameter record as processed
   	      	      	   -------------------------------------------------------------------------------
   	      	      	   SELECT   	   @SPOutputValue   	   = NULL
   	      	      	   SELECT   	   @SQLStatement    	   = @SQLStatement + ' ' +tText + ','
   	      	      	      	   FROM   	   @tAnySP
   	      	      	      	   WHERE   	   Id   	   = @RecParmId
   	      	      	   UPDATE   	   @tAnySP
   	      	      	      	   SET   	   Status   	   = 1
   	      	      	      	   WHERE   	   Id   	   = @RecParmId
   	      	      	   -------------------------------------------------------------------------------
   	      	      	   -- Move to the next parameter
   	      	      	   -------------------------------------------------------------------------------
   	      	      	   SELECT   	   @RecParmId   	   = NULL
   	      	      	   SELECT   	   @RecParmId   	   = MIN(Id)
   	      	      	      	   FROM   	   @tAnySP
   	      	      	      	   WHERE   	   ParentId   	   = @ParentId
   	      	      	      	   AND   	   ElementName   	   = 'Parm'
   	      	      	      	   AND   	   Status   	      	   = 0
   	      	   END
   	      	   -------------------------------------------------------------------------------
   	      	   -- Remove the last extra comma, if exists and then run the sql statement
   	      	   --
   	      	   -- The only way to get the exec to run with SPs with parameter was to encapsulate
   	      	   -- the sqlstatement between (). But I can not get the SP status to be set to a   	   
   	      	   -- variable. ex: EXEC @RC=@SQLStatement, it only works without parameters
   	      	   --
   	      	   -------------------------------------------------------------------------------
   	      	   --IF   	   CHARINDEX(',', @SQLStatement) > 0
   	      	   --   	   SELECT   	   @SQLStatement   	   = LEFT(@SQLStatement,LEN(@SqlStatement) - 1)
   	      	   --EXEC  (@SQLStatement)
   	      	   -------------------------------------------------------------------------------
   	      	   -- Replaced exc with sp_executeSQL because it is more efficient and allows to
   	      	   -- capture the ouput parameter of the SP.
   	      	   -- 
   	      	   -- Please note the called SP must have an output parameter with datatype INT
   	      	   -- as the LAST parameter on the SP definition.   	   This output parameter can be
   	      	   -- set to null on the called SP, if un-necessary.  ALso, the output from the
   	      	   -- called SP is appended to the errCode string (as a warning error). MOre info
   	      	   -- MS KB Article Id #262499. Example of a called SP:
   	      	   -- CREATE PROCEDURE dbo.spS95OE_Test6
   	      	   --   	   @Parm1 varchar(255) = NULL,
   	      	   --   	   ..
   	      	   --   	   @outputvalue INT output
   	      	   -- 
   	      	   -------------------------------------------------------------------------------
   	      	   SELECT   	   @SQLStatement   	   = @SQLStatement + N' @OutputValue OUTPUT'
   	      	   SELECT   	   @ParmDefinition   	   = N'@OutputValue INT OUTPUT'
   	      	   EXECUTE @SQLRetStat   	   = sp_executeSQL
   	      	      	      	      	   @SQLStatement,
   	          	      	      	      	   @ParmDefinition,
   	          	      	      	      	   @SPOutputValue   	   OUTPUT
   	      	   -------------------------------------------------------------------------------
   	      	   -- output a hardcoded error code if the called custom stored procedure returns
   	      	   -- an error. Please be aware the return code is different than when returning
   	      	   -- a value within the sp.
   	      	   -------------------------------------------------------------------------------
   	      	   IF   	   @SQLRetStat <> 0
   	      	   BEGIN
              INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
                SELECT -998, emd.Message_Subject, emd.Message_Text, emd.Severity, COALESCE(@SQLStatement, 'NA')
                  FROM dbo.email_message_data emd 
                  WHERE emd.Message_Id = -998
   	      	   END
   	      	   ELSE
   	      	   BEGIN
   	      	      	   IF   	   @SPOutputValue   	   Is NOT NULL
   	      	      	   BEGIN
                    INSERT INTO @tErr (ErrorCode, ErrorCategory, ErrorMsg, Severity, ReferenceData)
                      SELECT @SPOutputValue, 'Schedule Download Error', 'SP call returned bad return code', 0, @SQLStatement + ' Parms: ' + @ParmDefinition
   	      	      	   END
   	      	   END
   	   END
   	   -------------------------------------------------------------------------------
   	   -- Move to the next Stored Procedure
   	   -------------------------------------------------------------------------------
   	   SELECT   	   @RecSPId   	      	   = NULL
   	   SELECT   	   @RecSPId   	      	   = MIN(Id)
   	      	   FROM   	   @tAnySP
   	      	   WHERE   	   ElementName   	   = 'Name'
   	      	   AND   	   Status   	      	   = 0
END
-------------------------------------------------------------------------------
-- Update LastProcessedDateDownload for each Path processed
-------------------------------------------------------------------------------
-- Add a record for each path in the system
Insert into Table_Fields_Values (KeyId,Table_Field_id,TableId, Value) 
  SELECT p.Path_Id, -78, @PrdExecPathTableID, '1970-01-01 00:00:00.000'  --
    from table_fields_values  v
    right outer join prdexec_paths p on p.path_id = v.KeyId and v.TableId = @PrdExecPathTableID and Table_field_id = -78
    Where v.KeyId IS NULL 
UPDATE tfv
  SET Value = CONVERT(VARCHAR(25), getdate())
  FROM Table_Fields_Values tfv
  JOIN @tER er on er.PathId = tfv.KeyId
  WHERE Table_Field_id = -78 and TableId = @PrdExecPathTableID
ErrCode:
--IF 	 @ErrCode = '-000'
-- 	 SELECT @ErrCode AS ErrCode
IF @FlgSendRSProductionPlan 	 = 0
 	  	 -- Send dummy Production Plan ResultSet
 	  	 SELECT
 	  	  	 NULL 	 AS 	  	 Result,
 	  	  	 NULL 	 AS 	  	 PreDB,
 	  	  	 NULL 	 AS 	  	 TransType,
 	  	  	 NULL 	 AS 	  	 TransNum,
 	  	  	 NULL 	 AS 	  	 PathId,
 	  	  	 NULL 	 AS 	  	 PPId,
 	  	  	 NULL 	 AS 	  	 CommentId,
 	  	  	 NULL 	 AS 	  	 ProdId,
 	  	  	 NULL 	 AS 	  	 ImpliedSequence,
 	  	  	 NULL 	 AS 	  	 PPStatusId,
 	  	  	 NULL 	 AS 	  	 PPTYpeId,
 	  	  	 NULL 	 AS 	  	 SourcePPId,
 	  	  	 NULL 	 AS 	  	 UserId,
 	  	  	 NULL 	 AS 	  	 ParentPPId,
 	  	  	 NULL 	 AS 	  	 ControlType,
 	  	  	 NULL 	 AS 	  	 ForecastStartTime,
 	  	  	 NULL 	 AS 	  	 ForecastEndTime,
 	  	  	 NULL 	 AS 	  	 EntryOn,
 	  	  	 NULL 	 AS 	  	 ForecastQuantity,
 	  	  	 NULL 	 AS 	  	 ProductionRate,
 	  	  	 NULL 	 AS 	  	 AdjustedQuantity,
 	  	  	 NULL 	 AS 	  	 BlockNumber,
 	  	  	 NULL 	 AS 	  	 ProcessOrder,
 	  	  	 NULL 	 AS 	  	 TransactionTime,
 	  	  	 NULL 	 AS 	  	 BOMFormulationId
 	 WHERE NULL IS NOT NULL -- for empty result set
IF @FlgSendRSProductionSetup = 0
 	  	 -- Send dummy Production Setup ResultSet 	 
 	  	 SELECT
 	  	  	 NULL AS 	 Result,
 	  	  	 NULL AS 	 PreDB,
 	  	  	 NULL AS 	 TransType,
 	  	  	 NULL AS 	 TransNum,
 	  	  	 NULL AS 	 PathId,
 	  	  	 NULL AS 	 PPSetupId,
 	  	  	 NULL AS 	 PPId,
 	  	  	 NULL AS 	 ImpliedSequence,
 	  	  	 NULL AS 	 PPStatusId,
 	  	  	 NULL AS 	 PatternReptition,
 	  	  	 NULL AS 	 CommentId,
 	  	  	 NULL AS 	 ForecastQuantity,
 	  	  	 NULL AS 	 BaseDimensionX,
 	  	  	 NULL AS 	 BaseDimensionY,
 	  	  	 NULL AS 	 BaseDimensionZ,
 	  	  	 NULL AS 	 BaseDimensionA,
 	  	  	 NULL AS 	 BaseGeneral1,
 	  	  	 NULL AS 	 BaseGeneral2,
 	  	  	 NULL AS 	 BaseGeneral3,
 	  	  	 NULL AS 	 BaseGeneral4,
 	  	  	 NULL AS 	 Shrinkage,
 	  	  	 NULL AS 	 PatternCode,
 	  	  	 NULL AS 	 UserId,
 	  	  	 NULL AS 	 EntryOn,
 	  	  	 NULL AS 	 TransactionTime,
 	  	  	 NULL AS 	 ParentPPSetupId
 	 WHERE NULL IS NOT NULL -- for empty result set
SELECT @RetProcessOrder = ProcessOrder FROM @tPR
SELECT @RetPathCode = EquipmentId FROM @tER
SELECT 	 @RetPathProdCode = ProdCode,
 	  	 @RetPathUOM = UOM
 	  	 FROM @tMPR
--SELECT 	 @RetErrCode = @ErrCode,
-- 	  	 @RetErrMsg = @ErrMsg
SELECT 
   	   ErrorCode    	  as Code    	   ,
   	   ErrorCategory  as Category       ,
   	   ErrorMsg       as Message       ,
   	   Severity       as Severity       ,
   	   ReferenceData  as Reference  	     
   	 FROM @tERR
SELECT  	 @RetProcessOrder 	  	  	 AS ProcessOrder,
 	  	 @RetPathCode 	  	  	  	 AS PathCode,
 	  	 @RetPathProdCode 	  	  	 AS PathProdCode,
 	  	 @RetPathUOM 	  	  	  	  	 AS PathUOM
-- print '--EXIT: ' + convert(char(30), getdate(), 21)
--drop table #tXML
SET NOCOUNT OFF
RETURN (0)
