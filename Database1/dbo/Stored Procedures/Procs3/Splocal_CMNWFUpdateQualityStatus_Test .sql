
--------------------------------------------------------------------------------------------------
-- Stored Procedure: [dbo].[Splocal_CMNWFUpdateQualityStatus]
--------------------------------------------------------------------------------------------------
-- Author				: BalaMurugan Rajendran
-- Date created			: 09-25-2013
-- Version 				: 1.0
-- SP Type				: Updates Quality status info in Packing lot storage unit.
-- Caller				: Called from WF
-- Description			: Fetches records from transaction table.
--						  
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
-- Sections		Description

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		05-Jan-2017 	TCS Rajendran BalaMurugan					Created Stored Procedure


--================================================================================================
---- ManualDebug
--Declare @ErrorMsg Varchar(100)
--EXEC Splocal_CMNWFUpdateQualityStatus
--' <pm:ProcessMaterial xsi:schemaLocation="http://www.wbf.org/xml/B2MML-V0401123 ProcessMaterial.xsd" xmlns:pm="http://www.wbf.org/xml/B2MML-V0401123" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ns4="http://www.wbf.org/xml/B2MML-V0401123" xmlns="http://www.wbf.org/xml/B2MML-V0401">   -<ProcessSegment><ID schemeName="TransactionCode">MB1B</ID><Description>Material Movement</Description><!--Target Location-->    -<Location><EquipmentID schemeName="DestinationPlant">2702</EquipmentID><EquipmentElementLevel>Site</EquipmentElementLevel>   -<Location><EquipmentID schemeName="DestinationStorageLocation">EG00</EquipmentID><EquipmentElementLevel>Area</EquipmentElementLevel></Location></Location><!--Document Information-->    -<Parameter><ID>DocumentDate</ID><!--Creation of transaction-->    -<Value><ValueString>20160726</ValueString><DataType>date</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>PostingDate</ID><!--Execution of transaction-->    -<Value><ValueString>20160726</ValueString><DataType>date</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>ReferenceDocumentNumber</ID>   -<Value><ValueString>55208804</ValueString><DataType>ID</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>DocumentHeaderText</ID>   -<Value><ValueString>55208804</ValueString><DataType>ID</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter><!--Movement Type-->    -<Parameter><ID>MaterialMovementType</ID>   -<Value><ValueString>341</ValueString><DataType>int</DataType><UnitOfMeasure>Identifier</UnitOfMeasure><Key>Status change of a batch (unrestricted-use to restricted)</Key></Value></Parameter><!--Order Information-->    -<Parameter><ID>OrderStartDateTime</ID>   -<Value><ValueString format="yyyymmdd,hh:mm:ssZ">20160726,12:12:12CET</ValueString><DataType>DateTime</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>OrderFinishDateTime</ID>   -<Value><ValueString format="yyyymmdd,hh:mm:ssZ">20160726,12:12:12CET</ValueString><DataType>DateTime</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter></ProcessSegment><!--Material Information-->    -<MaterialInformation xsi:schemaLocation="http://www.wbf.org/xml/B2MML-V0401 B2MML-V0401-Material.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.wbf.org/xml/B2MML-V0401"><!--Reference Document number: Link between the material lot information and process segment. Unique identifier.--><ID>55208804</ID><Description>Material Lot Information</Description>   -<MaterialLot><ID>000000000096855894-0000000000</ID><!--Material ID: Material number--><MaterialDefinitionID>000000000096855894</MaterialDefinitionID>   -<MaterialLotProperty><!--Material Lot ID: Material number and Batch number combination--><ID>000000000096855894-0000000000</ID><!--Reference document number to link the material information with the process segment-->    -<Value><ValueString>55208804</ValueString><DataType>ID</DataType><UnitOfMeasure>None</UnitOfMeasure><Key>Reference Document Number</Key></Value><!--Batch numbers-->    -<Value><ValueString>6208270200</ValueString><DataType>nonNegativeInteger</DataType><UnitOfMeasure>None</UnitOfMeasure><Key>Source Batch Number</Key></Value><!--Destination batch number same as source batch number for Preweigh Proficy-->    -<Value><ValueString>6208270200</ValueString><DataType>nonNegativeInteger</DataType><UnitOfMeasure>None</UnitOfMeasure><Key>Destination Batch Number</Key></Value></MaterialLotProperty><!--Material source location-->    -<Location><EquipmentID schemeName="SourcePlant">2702</EquipmentID><EquipmentElementLevel>Site</EquipmentElementLevel>   -<Location><EquipmentID schemeName="SourceStorageLocation">EG00</EquipmentID><EquipmentElementLevel>Area</EquipmentElementLevel></Location></Location><!--Material lot quanitity-->    -<Quantity><QuantityString>36</QuantityString><DataType>nonNegativeInteger</DataType><UnitOfMeasure>CS</UnitOfMeasure></Quantity></MaterialLot></MaterialInformation></pm:ProcessMaterial>'
--,1,0,@ErrorMsg




CREATE PROCEDURE   [dbo].[Splocal_CMNWFUpdateQualityStatus_Test ]

--Declare
 	@XML Ntext,
	@DebugOnline int,
	@DebugManual int=0,
	@ErrorMsg  Varchar(500) OUTPUT,
	@ErrorMsg1 Varchar(500) OUTPUT

	
--SET @XML = '  <pm:ProcessMaterial xsi:schemaLocation="http://www.wbf.org/xml/B2MML-V0401123 ProcessMaterial.xsd" xmlns:pm="http://www.wbf.org/xml/B2MML-V0401123" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ns4="http://www.wbf.org/xml/B2MML-V0401123" xmlns="http://www.wbf.org/xml/B2MML-V0401">   -<ProcessSegment><ID schemeName="TransactionCode">MB1B</ID><Description>Material Movement</Description><!--Target Location-->    -<Location><EquipmentID schemeName="DestinationPlant">2702</EquipmentID><EquipmentElementLevel>Site</EquipmentElementLevel>   -<Location><EquipmentID schemeName="DestinationStorageLocation">EG00</EquipmentID><EquipmentElementLevel>Area</EquipmentElementLevel></Location></Location><!--Document Information-->    -<Parameter><ID>DocumentDate</ID><!--Creation of transaction-->    -<Value><ValueString>20160726</ValueString><DataType>date</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>PostingDate</ID><!--Execution of transaction-->    -<Value><ValueString>20160726</ValueString><DataType>date</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>ReferenceDocumentNumber</ID>   -<Value><ValueString>55208804</ValueString><DataType>ID</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>DocumentHeaderText</ID>   -<Value><ValueString>55208804</ValueString><DataType>ID</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter><!--Movement Type-->    -<Parameter><ID>MaterialMovementType</ID>   -<Value><ValueString>341</ValueString><DataType>int</DataType><UnitOfMeasure>Identifier</UnitOfMeasure><Key>Status change of a batch (unrestricted-use to restricted)</Key></Value></Parameter><!--Order Information-->    -<Parameter><ID>OrderStartDateTime</ID>   -<Value><ValueString format="yyyymmdd,hh:mm:ssZ">20160726,12:12:12CET</ValueString><DataType>DateTime</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter>   -<Parameter><ID>OrderFinishDateTime</ID>   -<Value><ValueString format="yyyymmdd,hh:mm:ssZ">20160726,12:12:12CET</ValueString><DataType>DateTime</DataType><UnitOfMeasure>None</UnitOfMeasure></Value></Parameter></ProcessSegment><!--Material Information-->    -<MaterialInformation xsi:schemaLocation="http://www.wbf.org/xml/B2MML-V0401 B2MML-V0401-Material.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.wbf.org/xml/B2MML-V0401"><!--Reference Document number: Link between the material lot information and process segment. Unique identifier.--><ID>55208804</ID><Description>Material Lot Information</Description>   -<MaterialLot><ID>000000000099009901-0000000000</ID><!--Material ID: Material number--><MaterialDefinitionID>000000000099009901</MaterialDefinitionID>   -<MaterialLotProperty><!--Material Lot ID: Material number and Batch number combination--><ID>000000000099009901-0000000000</ID><!--Reference document number to link the material information with the process segment-->    -<Value><ValueString>55208804</ValueString><DataType>ID</DataType><UnitOfMeasure>None</UnitOfMeasure><Key>Reference Document Number</Key></Value><!--Batch numbers-->    -<Value><ValueString>0000000000</ValueString><DataType>nonNegativeInteger</DataType><UnitOfMeasure>None</UnitOfMeasure><Key>Source Batch Number</Key></Value><!--Destination batch number same as source batch number for Preweigh Proficy-->    -<Value><ValueString>0000000000</ValueString><DataType>nonNegativeInteger</DataType><UnitOfMeasure>None</UnitOfMeasure><Key>Destination Batch Number</Key></Value></MaterialLotProperty><!--Material source location-->    -<Location><EquipmentID schemeName="SourcePlant">2702</EquipmentID><EquipmentElementLevel>Site</EquipmentElementLevel>   -<Location><EquipmentID schemeName="SourceStorageLocation">EG00</EquipmentID><EquipmentElementLevel>Area</EquipmentElementLevel></Location></Location><!--Material lot quanitity-->    -<Quantity><QuantityString>36</QuantityString><DataType>nonNegativeInteger</DataType><UnitOfMeasure>CS</UnitOfMeasure></Quantity></MaterialLot></MaterialInformation></pm:ProcessMaterial>'
 AS



DECLARE
--XML Variable
@idoc						Int,
--Local Variables
@Batchcode					Varchar(25),
@StorageLocationid		    Int,
@Eventid					Int,
@sp							Varchar(25),
@ErrMsg						Varchar(1000),
@tablefieldid				Int,
@tableid					Int,
@Restrictedid				Int,
@QualtiyInspid				Int,
@Blocked					Int,
@MovementType				Int,
@Unrestrictedid				Int,
@Blockedid					Int,
@UpdateStatusid				Int,
@UpdateStatusdesc			Varchar(20),
@Prodid						Int,
@prodcode				    Varchar(20),

-- prod_units variables
@EquipmentPropertyName      Varchar(25),
@EquipTypeLotStorage		Varchar(25),
@FromEventStatus            Varchar(15),
@ToEventStatus				Varchar(15),
@PackingLotStoragePuId      Int,
@BatchEquipTypeLotStorage   Varchar(20),
@BatchPuId                      Int,

--SpServer Variables

@RC								Int,
@dbeTransactionType				Int,
@dbeTransNum					Int,
@dbeConfirmed					Int,
@dbeEventSubtypeId				Int,
@dbeUserId						Int,
@dbeTestingStatus				Int,
@dbeStartTime					datetime,
@dbeTimestamp					datetime,
@dbeReturnResultSet				Int,
@dbeConformance					Int,
@dbeTestPctComplete				Int,
@dbeSecondUserId				Int,
@dbeEntryOn						datetime,
@dbeApproverUserId				Int,
@dbeApproverReasonId			Int,
@dbeUserReasonId				Int,
@dbeUserSignoffId				Int,
@dbeExtendedInfo				varchar(255),
@dbeCommentId					Int,
@dbeUpdateType					Int,
@dbeSourceEvent					Int,
@dbeSendEventPost				Int,
@EventSubTypeID					Int,
@ParmComponentId				Int,	
@ParmEntryOn					datetime,
@ParmPEIId						Int	,
@UserID                         Int,
@BatchEventNum              Varchar(50),
@PalletTimestamp				DateTime,
@productid						Int,
@PackinglotEventid				Int,
@batchingLotEventid				Int,
@FromEventStatusPackinglot   Varchar(25),
@FromEventStatusBatchlot   Varchar(25)


CREATE TABLE #tXML (  
       Id              Int,   
       ParentId             Int,   
       NodeType             Int,   
       LocalName            VARCHAR(2000),   
       Prev              Int,   
       Ttext             VARCHAR(2000))  
 
CREATE CLUSTERED INDEX txml_idx4 on #tXML(parentid, id)  

Declare @MaterialLOT TABLE(
id          Int Identity (1,1),
xmlid       Int,
Batchcode   Varchar(100),
prodcode    Varchar(100))

Declare @MaterialLOTProperties TABLE(
id			Int Identity (1,1),
xmlid		Int,
Keyname		Varchar(100),
Value		Varchar(100),
Parentid	Int)

Declare @MaterialLocation TABLE(
id			Int Identity (1,1),
xmlid		Int,
Keyname		Varchar(100),
Value		Varchar(100),
Parentid	Int)

Declare @MaterialLocation1 TABLE(
id			Int Identity (1,1),
xmlid		Int,
Keyname		Varchar(100),
Value		Varchar(100),
Parentid	Int)

Declare @MaterialMov TABLE (
id				Int Identity (1,1),
Value			Varchar(500),
Movementtype	Varchar(500),
XMLId			Int,
KeyValue	    Varchar(50))

Declare @KeyValues TABLE (
id			Int Identity (1,1),
XMLId		Int,
Parentid	Int,
KeyValue	Varchar(500),
Linkid		Int)

Declare @Quantity TABLE (
id			Int Identity (1,1),
XMLId		Int,
Parentid	Int,
Name		Varchar(50),
KeyValue	Varchar(500))

DECLARE @TABLEdata TABLE (
id					Int Identity (1,1),
prodcode			Varchar(20),
Batchcode			Varchar(200),
MovementType		Int,
MovementTypeDesc	Varchar(200),
Quantity			Int,
UOM					Varchar(25),
Location			Varchar(10),
Postingdate			Varchar(10),
Documentdate		Varchar(10),
ReferenceNumber		Varchar(10),
OrderStartdate		Varchar(50),
Orderfinishdate		Varchar(50)
)

DECLARE @EventStatus TABLE
(
id				Int Identity (1,1),
EventStatusid	Int,
EventStatusDesc Varchar(20))


DECLARE @Paths TABLE (
path_id			Int,
Path_code		varchar(50),
Path_desc		varchar(50),
pl_id			Int,
pl_desc			varchar(50),
IsPE			bit
)

Declare @pathProdunits TABLE (
PUID		Int,
PATHid	    Int,
prod_id		Int)



SET @ErrorMsg = 'Success'
SET	@ErrorMsg1 = 'Success'	

-- Fetch the XML In a TABLE format


EXEC sp_xml_preparedocument 
				@idoc OUTPUT,
				@xml, --Preparing XML handle 
				 '<pm:ProcessMaterial  xmlns:pm="http://www.wbf.org/xml/B2MML-V0401123"/>'    
			



  
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
        FROM  OPENXML(@idoc,'/pm:ProcessMaterial',2)  


  


EXEC sp_xml_removedocument @idoc --Releasing memory 


-- Get Paths for DMO Lines


INSERT @Paths (path_id, Path_code, Path_desc, pl_id, pl_desc, IsPE)
SELECT pp.path_id, pp.Path_code, pp.Path_desc , pl.pl_id, pl.pl_desc, CONVERT(bit,tfv.value)
FROM		dbo.prdExec_Paths pp		WITH(NOLOCK)
JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK)		ON tfv.keyid = pp.path_id
JOIN dbo.Table_Fields tf				WITH(NOLOCK)		ON tfv.Table_Field_Id = tf.Table_Field_Id
																AND tf.Table_Field_Desc = 'PE_General_IsPELine' AND Tfv.Value = '1'
LEFT JOIN	dbo.Prod_Lines pl			WITH(NOLOCK)		ON	pl.pl_id = pp.pl_id


INSERT @pathProdunits ( PUID,PATHid,prod_id)
(SELECT ppu.PU_Id,p.path_id,pp.Prod_Id FROM DBO.PrdExec_Path_Units PPU
JOIN @paths p ON P.path_id= ppu.path_id
JOIN Pu_Products pp ON pp.PU_Id = ppu.PU_Id)

-- Fill data in Local debug for Troubleshooting purpose

SET @sp = 'CMNWFUpdateQualityStatus'
IF @DebugOnline = 1

BEGIN

		SET @ErrMsg =	'0010 ' +
						'SP started ' 
					


		INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@sp,
				@ErrMsg 				
				)
			
				
		
		
END

--Get the Production Status Ids

SELECT @Restrictedid   = (SELECT ProdStatus_id FROM Production_Status WITH (NOLOCK) WHERE ProdStatus_Desc like 'RESTRICTED')
SELECT @QualtiyInspid  = (SELECT ProdStatus_id FROM Production_Status WITH (NOLOCK) WHERE ProdStatus_Desc like 'QualityInspection')
SELECT @Unrestrictedid = (SELECT ProdStatus_id FROM Production_Status WITH (NOLOCK) WHERE ProdStatus_Desc like 'UnRestricted')
SELECT @Blockedid      = (SELECT ProdStatus_id FROM Production_Status WITH (NOLOCK) WHERE ProdStatus_Desc like 'Blocked')


-- Get the Packing lot storage unit
	SET @EquipTypeLotStorage = 'LotStorage'
	SET @PackingLotStoragePuId = (SELECT	PU_ID	FROM	dbo.Prod_Units   WITH(NOLOCK)	WHERE	Equipment_Type = @EquipTypeLotStorage)
	SET @BatchEquipTypeLotStorage  = 'BatchLotStorage'
	SET @Batchpuid            =  (SELECT	PU_ID	FROM	dbo.Prod_Units   WITH(NOLOCK)	WHERE	Equipment_Type = @BatchEquipTypeLotStorage)
IF (@PackingLotStoragePuId IS NULL)

BEGIN						

	IF @DebugOnline = 1
	BEGIN
			SET @ErrMsg =	'Packing Lot Storage unit id: ' + CONVERT(Varchar(20), @PackingLotStoragePuId) +
							'PU_ID does not exists'

			INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@sp,
					@ErrMsg 					
					)
	END
END

IF (@BatchPuId IS NULL)

BEGIN						

	IF @DebugOnline = 1
	BEGIN
			SET @ErrMsg =	'BatchPuId: ' + CONVERT(Varchar(20), @BatchPuId) +
							'PU_ID does not exists'

			INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@sp,
					@ErrMsg 					
					)
	END
END


INSERT @EventStatus (EventStatusid,EventStatusDesc)
SELECT ProdStatus_id, ProdStatus_Desc FROM dbo.Production_Status WITH (NOLOCK) 
WHERE ProdStatus_Id in (@Restrictedid,@QualtiyInspid,@Unrestrictedid,@Blockedid)

INSERT @MaterialLocation (xmlid,Keyname,Value,Parentid)
(SELECT  DISTINCT xmpr.id,xMDI.Localname,XMDI1.Ttext,xMdI.id
FROM       #tXML xMPR       
JOIN  #tXML xMDI ON xMPR.Id = xMDI.ParentId  
JOIN #txml XMDI1 ON xMDI.id = XMDI1.ParentId
AND xMDI.Localname = 'EquipmentID' AND XMDI1.Ttext is not null
WHERE xMPR.LocalName = 'Location' ) 

SET @StorageLocationid = (SELECT id FROM #tXML  WHERE Ttext like 'DestinationStorageLocation')

INSERT @MaterialLocation1 (xmlid,Keyname,Value,Parentid)
(SELECT xp1.id,xp.Ttext,ML.Value,xp.id
FROM #tXML XMPR 
JOIN @MaterialLocation ML ON ML.Parentid= xmpr.parentid
JOIN #txml xp ON xp.parentid = Xmpr.id
JOIN #txml xp1 ON xp1.parentid  = xp.Parentid
AND XP1.id = @StorageLocationid)


INSERT @Quantity (xmlid,Parentid,Name,KeyValue)
(SELECT XMDI1.id, xMDI.id,xp.Localname,XMDI1.Ttext
FROM       #tXML xMPR       
JOIN  #tXML xMDI ON xMPR.Id = xMDI.ParentId  
JOIN #txml XMDI1 ON XMDI1.Parentid = xMDI.id
JOIN #txml xp ON xp.id = xMDI.id
WHERE xMPR.Localname = 'Quantity')


INSERT @MaterialLOT
( Xmlid,Batchcode,prodcode)
(SELECT xMDI.id,xMDI1.Ttext,xps1.Ttext
FROM       #tXML xMPR       
LEFT JOIN  #tXML xMDI ON xMPR.Id = xMDI.ParentId   
JOIN #tXML XMDI1 ON XMDI1.ParentId = xMDI.id 
              AND xMDI.LocalName = 'ID'
LEFT JOIN  #tXML xps ON xMPR.Id = xps.ParentId   
JOIN #tXML Xps1 ON xps1.ParentId = xps.id 
              AND xps.LocalName = 'MaterialDefinitionID'			        
    
			  WHERE xMPR.LocalName = 'MaterialLot')


INSERT @MaterialMov (Value,XMLId)
(SELECT xp1.Ttext,xMDI.ParentId
FROM       #tXML xMPR    
 JOIN #tXML xMDI ON xMPR.Id = xMDI.ParentId   
 JOIN #tXML xp on xMDI.id = xp.Parentid
     AND xp.LocalName = 'ValueString'
   JOIN #txml xp1 ON xp.id = xp1.Parentid
WHERE xMPR.LocalName = 'Parameter')


Update @MaterialMov
SET Movementtype = Txml1.Ttext
FROM @MaterialMov M
JOIN #tXML txml ON txml.Parentid = m.XMLId
JOIN #txml Txml1 ON txml.id = Txml1.Parentid


INSERT @KeyValues (keyvalue,xmlid,Parentid, Linkid)
(SELECT Xmdi.Ttext,xMPR.id,xmpr.Parentid,xp.ParentId
FROM #tXML xMPR    
 JOIN #tXML xMDI ON xMPR.Id = xMDI.ParentId  
 JOIN #txml xp ON xp.id = xMPR.ParentId
 JOIN #txml xp1 ON xp1.parentid = xMPR.id
 WHERE xMPR.LocalName = 'Key' )


 INSERT @MaterialLOTProperties ( xmlid,Value,Parentid)
(SELECT xp1.id,xp1.Ttext,xp1.parentid
FROM       #tXML xMPR    
 JOIN #tXML xMDI ON xMPR.Id = xMDI.ParentId   
 JOIN #tXML xp on xMDI.id = xp.Parentid
     AND xp.LocalName = 'ValueString'
   JOIN #txml xp1 ON xp.id = xp1.Parentid  
WHERE xMPR.LocalName = 'MaterialLotproperty')


Update @MaterialLOTProperties
SET Keyname = kv.KeyValue
FROM #tXML MLP
     JOIN @MaterialLOTProperties xml1 ON xml1.Parentid = MLP.ID
	 JOIN @KeyValues kv ON Kv.Parentid = MLP.Parentid
	        
			--Trobleshooting Purpose 
			--Select * From #txml order by id
	  --      Select * From @MaterialLOT
	  --      Select * From @Quantity
   --         Select * From @MaterialLocation			  
			--Select * From @MaterialMov
			--Select 'KeyValues',* From @KeyValues
			--Select * From @MaterialLOTProperties
	
INSERT @Tabledata ( prodcode,Batchcode)-- Location, MovementType, MovementTypeDesc, Quantity, UOM )
SELECT Coalesce(Right('000000000000' + ML.prodcode,8) ,''),Substring(ML.batchcode,Charindex('-',ML.batchcode)+1,Len(ML.batchcode))
FROM #txml xMPR 
JOIN @MaterialLOT ML ON xMPR.id = ML.xmlid 


Update @tabledata
SET OrderStartdate = MV.Value
FROM @MaterialMov MV
WHERE MV.Movementtype = 'OrderStartDateTime' and  Value is not NULL


Update @tabledata
SET OrderFinishdate = MO.Value
FROM @MaterialMov MO
WHERE MO.Movementtype = 'OrderFinishDateTime' and  Value is not NULL

Update @Tabledata 
SET MovementType = MV.Value,
MovementTypeDesc = KV.KeyValue
FROM #txml xMPR
JOIN @MaterialMov MV ON xMPR.id = MV.XMLId AND MV.Movementtype = 'MaterialMovementType'
JOIN @KeyValues KV ON KV.Linkid = MV.XMLId

Update @Tabledata
SET Quantity = Qty.KeyValue
FROM #txml xMPR
 JOIN @Quantity Qty ON xMPR.id = Qty.XMLId AND Qty.Name = 'QuantityString'


Update @Tabledata
SET UOM = Qty.Keyvalue
FROM #txml xMPR
 JOIN @Quantity Qty ON xMPR.id = Qty.XMLId AND Qty.Name = 'UnitOfMeasure'

 Update @Tabledata
 SET Location = Value
 FROM @MaterialLocation1 

 Update @Tabledata 
 SET ReferenceNumber = Value
 FROM @MaterialMov M WHERE M.Movementtype = 'ReferenceDocumentNumber'

  Update @Tabledata 
 SET Postingdate = Value
 FROM @MaterialMov M WHERE M.Movementtype = 'PostingDate'

   Update @Tabledata 
 SET Documentdate = Value
 FROM @MaterialMov M WHERE M.Movementtype = 'DocumentDate'

 IF @DebugOnline = 1
BEGIN
		SET @ErrMsg =	(SELECT '0020 ' +
						'Quality Status parameter Values Batchcode=' + Batchcode +
						'ProducutCode ='+ Prodcode +
						'Location = '+Location +
						'MovementType = '+ Convert(varchar(10),Movementtype) +
						'MovementTypeDesc = '+ MovementTypeDesc +
						'Quanity =' +Convert(Varchar(10),Quantity) +
						'UOM =' + UOM FROM @Tabledata)
					


		INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@sp,
				@ErrMsg 				
				)
		
		
		
END




-- Validate the Product to check if it is present in Proficy and it belongs to DMO/Non DMO line


SET @productid = (SELECT  p.Prod_id FROM @Tabledata T
				JOIN dbo.products_base p WITH (NOLOCK)  ON T.prodcode = p.Prod_Code
				)


SELECT @Prodid = ( SELECT TOP 1 p.PROD_ID FROM @Tabledata T
					JOIN dbo.products_base p WITH (NOLOCK)  ON T.prodcode = p.Prod_Code
					JOIN @pathProdunits ppu ON ppu.prod_id = p.prod_id)


IF (@prodid is null )
BEGIN

--SET @ErrorMsg = (SELECT Prodcode FROM @Tabledata) + ':'+ 'Product does not belong to PE line or does not exist in Proficy'


 IF @DebugOnline = 1
BEGIN
		SET @ErrMsg =	(SELECT Prodcode  + ' Product does not belong to PE line or does not exist in Proficy' FROM @Tabledata  ) 
					


		INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@sp,
				@ErrMsg 				
				)
		
		
		
END



END


-- Get the Update Status Id based on Cross reference


SELECT @tablefieldid = (Select Table_Field_id from Table_Fields WITH (NOLOCK) where Table_Field_Desc like 'BTSched - MaterialMovementType')
SELECT @tableid = (SELECT tableid FROM Tables WITH (NOLOCK) where TableName like 'Subscription_Group')

SET @MovementType = (SELECT MovementType FROM @Tabledata)

SET @Batchcode = (SELECT  Batchcode FROM @Tabledata )


SELECT @UpdateStatusid = (SELECT E.EventStatusid
							FROM @EventStatus E
							JOIN dbo.Table_Fields_Values tfv ON tfv.KeyId = @MovementType
							AND tfv.Value = E.EventStatusDesc
							AND  tfv.Table_Field_Id = @tablefieldid AND TAbleid = @tableid)


SELECT @UpdateStatusdesc = (SELECT ProdStatus_Desc FROM dbo.Production_Status WITH (NOLOCK) WHERE ProdStatus_Id = @UpdateStatusid)


--if already exists, Update the event else throw an error Event does not exists.

SET @prodcode = (SELECT Prod_code FROM dbo.Products_Base WHERE Prod_Id = @prodid)
SET @Batchcode =  (Select Batchcode FROM @tabledata )



SET @PackinglotEventid = (SELECT EVENT_ID FROM EVENTS WITH (NOLOCK) WHERE PU_Id = @PackingLotStoragePuId AND EVENT_NUM LIKE '%'+@Batchcode+'%' )
SET @BatchingLotEventID = (SELECT EVENT_ID FROM EVENTS WITH (NOLOCK) WHERE PU_Id = @BatchPuId AND EVENT_NUM LIKE '%'+@Batchcode+'%' )


IF ( @PackinglotEventid IS NOT NULL)
BEGIN
INSERT Local_tblQualityStatus
(PRodid,Product,Batchcode,Postingdate,DocuemntDate,ReferenceNumber,Location,MovementType,MovementTypedesc,Quantity,UOM,InsertedDate,OrderStartdate,OrderFinishdate,PU_id,FromStatus,ToStatus)
 SELECT @prodid,prodcode, Batchcode,Postingdate,Documentdate,ReferenceNumber,Location,MovementType,MovementTypeDesc,Quantity,UOM,Getdate(),OrderStartdate,Orderfinishdate,@PackingLotStoragePuId,@FromEventStatusPackinglot,@UpdateStatusdesc FROM @Tabledata
END

IF ( @BatchingLotEventID IS NOT NULL)
BEGIN
INSERT Local_tblQualityStatus
(PRodid,Product,Batchcode,Postingdate,DocuemntDate,ReferenceNumber,Location,MovementType,MovementTypedesc,Quantity,UOM,InsertedDate,OrderStartdate,OrderFinishdate,PU_id,FromStatus,ToStatus)
 SELECT @prodid,prodcode, Batchcode,Postingdate,Documentdate,ReferenceNumber,Location,MovementType,MovementTypeDesc,Quantity,UOM,Getdate(),OrderStartdate,Orderfinishdate,@BatchPuId,@FromEventStatusBatchlot,@UpdateStatusdesc FROM @Tabledata
END

IF ( @UpdateStatusid IS NULL )
BEGIN
SET @ErrorMsg = (SELECT 'MovementType'+ Convert(Varchar(10),MovementType)  + 'Does not exist in Proricy' FROM @Tabledata)
SET @ErrorMsg1 = ''
GOTO FinalOutput
END 



Select @FromEventStatusPackinglot = ( SELECT ProdStatus_Desc FROM dbo.Production_Status ps WITH (NOLOCK)
							JOIN dbo.Events E WITH (NOLOCK) ON E.Event_Status = ps.ProdStatus_id
							AND E.Event_id = @PackinglotEventid)

Select @FromEventStatusBatchlot = ( SELECT ProdStatus_Desc FROM dbo.Production_Status ps WITH (NOLOCK)
							JOIN dbo.Events E WITH (NOLOCK) ON E.Event_Status = ps.ProdStatus_id
							AND E.Event_id = @BatchingLotEventID)


 


IF EXISTS ( SELECT EVENT_ID FROM EVENTS WITH (NOLOCK) WHERE  Pu_id = @PackingLotStoragePuId AND EVENT_NUM LIKE '%'+@Batchcode+'%' )
BEGIN

(SELECT @BatchEventNum = Event_num,@PalletTimestamp = Timestamp,@EventSubTypeID = Event_Subtype_Id  
FROM dbo.Events WITH (NOLOCK) WHERE Event_id = @PackinglotEventid)

IF ( @UpdateStatusid IS NOT NULL)

BEGIN

SELECT		@dbeTransactionType                = 2,
				@dbeTransNum                       = 0,
				@dbeConfirmed                      = 0,
				@dbeUserId                         = @UserID,  
				@dbeEventSubtypeId                 = @EventSubTypeID,
				@dbeTestingStatus                  = NULL,
				@dbeStartTime                      = NULL,
				@dbeTimestamp                      = @PalletTimestamp,
				@dbeReturnResultSet                = 1,
				@dbeConformance                    = NULL,
				@dbeTestPctComplete                = NULL,
				@dbeSecondUserId                   = NULL,
				@dbeApproverUserId                 = NULL,
				@dbeApproverReasonId               = NULL,
				@dbeUserReasonId                   = NULL,
				@dbeUserSignoffId                  = NULL,
				@dbeExtendedInfo                   = NULL,
				@dbeCommentId                      = NULL,
				@dbeEventSubTypeId                 = NULL,
				@dbeUpdateType                     = 0 

EXECUTE @RC = dbo.spServer_DBMgrUpdEvent
				@PackinglotEventid OUTPUT,
				@BatchEventNum,
				@BatchPuId,
				@dbeTimeStamp,
				@ProdID,
				@dbeSourceEvent,
				@UpdateStatusid,
				@dbeTransactionType,
				@dbeTransNum,
				@dbeUserId,
				@dbeCommentId,
				@EventSubTypeID,
				@dbeTestingStatus,
				@dbeStartTime,
				@dbeEntryOn             OUTPUT,
				@dbeReturnResultSet,
				@dbeConformance         OUTPUT,
				@dbeTestPctComplete     OUTPUT,
				@dbeSecondUserId,
				@dbeApproverUserId,
				@dbeApproverReasonId,
				@dbeUserReasonId,
				@dbeUserSignoffId,
				@dbeExtendedInfo,
				@dbeSendEventPost

					IF @DebugOnline = 1
		BEGIN
			SET @ErrMsg =	'PackingLotEventId : '+(CONVERT(Varchar(20), @Eventid)) + ' has been updated with Status: '+ @UpdateStatusdesc
			INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@sp,
					@ErrMsg 
					)
		END

		END
END
	ELSE
	BEGIN

	

	SET @ErrorMsg = (SELECT 'PackingLotEventId : '+  Coalesce(CONVERT(Varchar(20),@Eventid),'') +  ' does not exist: With Batchcode: '  + Batchcode FROM @Tabledata)
		IF @DebugOnline = 1
		 BEGIN
			SET @ErrMsg =	(SELECT 'PackingLotEventId : '+  Coalesce(CONVERT(Varchar(20),@Eventid),'') +  ' does not exist: With Batchcode: '  + Batchcode FROM @Tabledata)
			INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@sp,
					@ErrMsg 					
					)
		 END


    END



	IF EXISTS ( SELECT EVENT_ID FROM EVENTS WITH (NOLOCK) WHERE  Pu_id = @BatchPuId AND EVENT_NUM LIKE '%'+@Batchcode+'%' )
BEGIN

IF ( @UpdateStatusid IS NOT NULL)

BEGIN

(SELECT @BatchEventNum = Event_num,@PalletTimestamp = Timestamp,@EventSubTypeID = Event_Subtype_Id  
FROM dbo.Events WITH (NOLOCK) WHERE Event_id = @BatchingLotEventID)


SELECT		@dbeTransactionType                = 2,
				@dbeTransNum                       = 0,
				@dbeConfirmed                      = 0,
				@dbeUserId                         = @UserID,  
				@dbeEventSubtypeId                 = @EventSubTypeID,
				@dbeTestingStatus                  = NULL,
				@dbeStartTime                      = NULL,
				@dbeTimestamp                      = @PalletTimestamp,
				@dbeReturnResultSet                = 1,
				@dbeConformance                    = NULL,
				@dbeTestPctComplete                = NULL,
				@dbeSecondUserId                   = NULL,
				@dbeApproverUserId                 = NULL,
				@dbeApproverReasonId               = NULL,
				@dbeUserReasonId                   = NULL,
				@dbeUserSignoffId                  = NULL,
				@dbeExtendedInfo                   = NULL,
				@dbeCommentId                      = NULL,
				@dbeEventSubTypeId                 = NULL,
				@dbeUpdateType                     = 0 

EXECUTE @RC = dbo.spServer_DBMgrUpdEvent
				@BatchingLotEventID OUTPUT,
				@BatchEventNum,
				@BatchPuId,
				@dbeTimeStamp,
				@ProdID,
				@dbeSourceEvent,
				@UpdateStatusid,
				@dbeTransactionType,
				@dbeTransNum,
				@dbeUserId,
				@dbeCommentId,
				@EventSubTypeID,
				@dbeTestingStatus,
				@dbeStartTime,
				@dbeEntryOn             OUTPUT,
				@dbeReturnResultSet,
				@dbeConformance         OUTPUT,
				@dbeTestPctComplete     OUTPUT,
				@dbeSecondUserId,
				@dbeApproverUserId,
				@dbeApproverReasonId,
				@dbeUserReasonId,
				@dbeUserSignoffId,
				@dbeExtendedInfo,
				@dbeSendEventPost

					IF @DebugOnline = 1
		BEGIN
			SET @ErrMsg =	'BatchEventId : '+(CONVERT(Varchar(20), @Eventid)) + ' has been updated with Status: '+ @UpdateStatusdesc
			INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@sp,
					@ErrMsg 
					)
		END

		END
END

ELSE
	BEGIN

	

	SET @ErrorMsg1 = (SELECT 'BatchEventId : '+  Coalesce(CONVERT(Varchar(20),@Eventid),'') +  ' does not exist: With Batchcode: '  + Batchcode FROM @Tabledata)
		IF @DebugOnline = 1
		 BEGIN
			SET @ErrMsg =	(SELECT 'BatchEventId : '+  Coalesce(CONVERT(Varchar(20),@Eventid),'') +  ' does not exist: With Batchcode: '  + Batchcode FROM @Tabledata)
			INSERT INTO Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	getdate(), 
					@sp,
					@ErrMsg 					
					)
		 END


END

-- Results


FinalOutput:

IF (@Prodid  IS NULL)
BEGIN
SET @Prodid = @productid
END
SELECT Postingdate,Documentdate,Referencenumber,@prodid,prodcode, Batchcode, Location,MovementType,MovementTypeDesc,Quantity,UOM,Getdate(),OrderStartdate,Orderfinishdate FROM @Tabledata
SELECT @ErrorMsg
SELECT @ErrorMsg1

-- Insert INTO Permenant table Local_tblQualityStatus



Drop TABLE #txml

