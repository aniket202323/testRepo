 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_INVN_PrintRMCLabel]
		@OutputValue	VARCHAR(25)		OUTPUT,
		@EventId		INT,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
AS
-------------------------------------------------------------------------------
-- This SP creates the text file Loftware expects to be able to print a label
--
-- Date         Version Build Author		Remarks
-- 08-Oct-2015  001     001   AJ (GEF)		Initial development
/*
declare @e int, @m varchar(255)
exec spLocal_MPWS_INVN_PrintRMCLabel @e output, @m output, 5738336
select @e, @m
*/
------------------------------------------------------------------------------- 
-- Declare variables
-------------------------------------------------------------------------------
DECLARE	@PUId				INT,
		@EventNum			VARCHAR(255),
		@InitialDimX		FLOAT
		
DECLARE	@DestinationFolder	VARCHAR(255),		
		@ConstructionFolder	VARCHAR(255),		
		@Copies				INT,
		@PrinterNumber		INT,
		@TemplateFile		VARCHAR(255),
		@LabelExtension		VARCHAR(255),
		@FileName			VARCHAR(255)
-------------------------------------------------------------------------------
-- Create temporary file for resultset
-------------------------------------------------------------------------------
/***** Outputfile Result Set
 	// --------------------------------
 	// 0 -	Result Set Type (50)
 	// 1 -	File#
 	// 2 -	Filename
 	// 3 -	Field#
 	// 4 -	FieldName
 	// 5 -	Type
 	// 6 -	Length
 	// 7 -	Precision
 	// 8 -	Value
 	// 9 -	CariageReturn
 	// 10 -	Construction\ion Path
 	// 11 -	Final Path
 	// 12 -	Move Mask (w/o path)
 	// 13 - AddTimeStamp (0-No, 1-Short, 2-Full)  ****/
 
 
--*FORMAT,FQTest2.LWL
--TEXT0001,11223344
--BARC0003,98765432
--TEXT0004,55667788
--*JOBNAME,Test4
--*QUANTITY,1
--*DUPLICATES,1
--*PRINTERNUMBER,1
--*PRINTLABEL
 
DECLARE	@tFileOutput	TABLE 
(
	FileNumber 			INT,
 	[FileName]			VARCHAR(255) 	NULL, 
 	FieldNumber			INT				PRIMARY KEY		IDENTITY (1,1), 				
	FieldName			VARCHAR(255),
 	FieldType			VARCHAR(250),
 	FieldLength			INT,
 	FieldPrecision		INT 			NULL,
 	FieldValue			VARCHAR(255)	NULL,
 	FieldCR				INT 			DEFAULT 0 
)
------------------------------------------------------------------------------- 
-- Retrieve event attributes
-------------------------------------------------------------------------------
SELECT	@PUId				= EV.PU_Id,
		@EventNum			= EV.Event_Num,
		@InitialDimX		= ED.Initial_Dimension_X
		FROM	dbo.Events EV			WITH (NOLOCK)
		JOIN	dbo.Event_Details ED	WITH (NOLOCK)
		ON		EV.Event_Id	= ED.Event_Id
		AND		EV.Event_Id	= @EventId
		
IF		@PUId	IS NULL
BEGIN
	SELECT	@OutputValue	= 'ProductionEvent~Found'
			RETURN
END
------------------------------------------------------------------------------- 
-- Retrieve label-related parameters associated with this PU
-------------------------------------------------------------------------------
SELECT	@DestinationFolder = CONVERT(VARCHAR(255), PEE.Value)
		FROM	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PAS.PU_Id = @PUId
		AND		PAS.Origin1EquipmentId	= PEE.EquipmentId
		AND		PEE.Name = 'Receiving Label.Destination Folder'
 
SELECT	@ConstructionFolder = CONVERT(VARCHAR(255), PEE.Value)
		FROM	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PAS.PU_Id = @PUId
		AND		PAS.Origin1EquipmentId	= PEE.EquipmentId
		AND		PEE.Name = 'Receiving Label.Construction Folder'
		
SELECT	@Copies = CONVERT(INT, PEE.Value)
		FROM	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PAS.PU_Id = @PUId
		AND		PAS.Origin1EquipmentId	= PEE.EquipmentId
		AND		PEE.Name = 'Receiving Label.Number Of Copies'
 
SELECT	@PrinterNumber = CONVERT(INT, PEE.Value)
		FROM	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PAS.PU_Id = @PUId
		AND		PAS.Origin1EquipmentId	= PEE.EquipmentId
		AND		PEE.Name = 'Receiving Label.Printer Number'
		
SELECT	@TemplateFile = CONVERT(VARCHAR(255), PEE.Value)
		FROM	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PAS.PU_Id = @PUId
		AND		PAS.Origin1EquipmentId	= PEE.EquipmentId
		AND		PEE.Name = 'Receiving Label.Termplate File'		
 
SELECT	@LabelExtension = CONVERT(VARCHAR(255), PEE.Value)
		FROM	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEE	WITH (NOLOCK)
		ON		PAS.PU_Id = @PUId
		AND		PAS.Origin1EquipmentId	= PEE.EquipmentId
		AND		PEE.Name = 'Receiving Label.Label Extension'			
 
IF	@ConstructionFolder	IS NULL
	OR LEN(RTRIM(LTRIM(@ConstructionFolder))) = 0
BEGIN
	SELECT	@OutputValue= 'ConstructionFolderNotFound'
	RETURN
END
 
IF	@DestinationFolder	IS NULL
	OR LEN(RTRIM(LTRIM(@DestinationFolder))) = 0
BEGIN
	SELECT	@OutputValue= 'DestinationFolderNotFound'
	RETURN
END
 
IF	@TemplateFile	IS NULL
	OR LEN(RTRIM(LTRIM(@TemplateFile))) = 0
BEGIN
	SELECT	@OutputValue= 'TemplateFileNotFound'
	RETURN
END
 
IF	@PrinterNumber	IS NULL
	OR	@PrinterNumber = 0
BEGIN
	SELECT	@OutputValue= 'PrinterNumberNotFound'
	RETURN
END
 
IF	@LabelExtension	IS NULL
	OR LEN(RTRIM(LTRIM(@LabelExtension))) = 0
BEGIN
	SELECT	@OutputValue	= 'LabelExtensionNotFound'
	RETURN
END
-------------------------------------------------------------------------------
-- Build Label file
-------------------------------------------------------------------------------
-- *FORMAT,FQTest2.LWL
-------------------------------------------------------------------------------
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*FORMAT,' + @TemplateFile) 
-------------------------------------------------------------------------------
-- Event Info
-- *<FieldName>,<FieldValue>
--
-- The FieldNames are declared on the label template file on design time
------------------------------------------------------------------------------- 	
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*TEXT001,' + @EventNum) 	
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*BARCODE001,' + @EventNum) 	 	
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*TEXT002,' + CONVERT(VARCHAR(25), @InitialDimX))
-------------------------------------------------------------------------------
-- *JOBNAME    
--
-- It generates the FileName by appending the getdate() to the Template File
-- name and eventId. It removes :,- and blanks from the getdate()
-------------------------------------------------------------------------------
select @FileName	= LEFT(@TemplateFile, CHARINDEX('.', @TemplateFile) -1) 
					+ CONVERT(VARCHAR(25), @EventId)
					+ REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(25), GETDATE(),120), '-',''),':',''),' ','')
					+ @LabelExtension
 
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*JOBNAME,' + @FileName)
-------------------------------------------------------------------------------
-- *QUANTITY,1
-------------------------------------------------------------------------------
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*QUANTITY,' + CONVERT(VARCHAR(255), @Copies))
-------------------------------------------------------------------------------
-- *PRINTERNUMBER,1
-------------------------------------------------------------------------------
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*PRINTERNUMBER,' + CONVERT(VARCHAR(255), @PrinterNumber))
-------------------------------------------------------------------------------
-- *PRINTLABEL
-------------------------------------------------------------------------------
INSERT	@tFileOutput (FieldValue)
 	VALUES	('*PRINTLABEL')
-------------------------------------------------------------------------------
-- Update common fields
------------------------------------------------------------------------------- 
UPDATE	@tFileOutput
		SET	FileNumber		= 1,
			FileName		= @FileName,
			FieldCR			= 1,
			FieldName		= 0,
			FieldType		= 'Alpha',
			FieldPrecision	= NULL,
			FieldLength		= LEN(RTRIM(LTRIM(FieldValue)))
-------------------------------------------------------------------------------
-- Return Resultset
------------------------------------------------------------------------------- 
SELECT	50, FileNumber,	[FileName], FieldNumber, FieldName, FieldType, FieldLength,
		FieldPrecision, FieldValue, FieldCR, @ConstructionFolder, @DestinationFolder, 
		'*' + @LabelExtension, 0 
		FROM	@tFileOutput
		ORDER
		BY	FileNumber, 
			FieldNumber
 
SELECT	@Outputvalue = CONVERT(VARCHAR(25), GETDATE(), 120)
 
--GRANT EXEcute on dbo.spLocal_MPWS_INVN_PrintRMCLabel to comxclient
RETURN
