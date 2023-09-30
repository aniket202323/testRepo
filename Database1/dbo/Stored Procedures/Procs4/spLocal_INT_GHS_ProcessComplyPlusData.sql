 
 
/*	-------------------------------------------------------------------------------
	dbo.splocal_INT_GHS_ProcessComplyPlusData
	
	Comply Plus files received by Proficy shall be moved by the Workflow defined above to the "Incoming" folder.  
	The model 75 responds when a file is placed in the \Incoming folder and will invoke a SPROC: splocal_INT_GHS_ProcessComplyPlusData, for every record in the file.
	The SPROC would process the data in each record and populate a local table: Local_INT_GHS_Material_Safety_Data for use by applications that require this data. 
	
	Date			Version		Build	Author  
	29-Aug-2016		001			001		Jim Cameron (GE Digital)		Initial development
	29-Nov-2017		002			001		Jim Cameron (GE Digital)		Changed to individual parameters for each field in a line vs 1 parameter for entire line and splitting it in the sp.
  
 
GRANT EXECUTE ON dbo.splocal_INT_GHS_ProcessComplyPlusData TO [public]
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_INT_GHS_ProcessComplyPlusData]
	@ReturnStatus					INT				OUTPUT,
	@ReturnMessage					VARCHAR(255)	OUTPUT,
	@User_Id						INT,
	@EC_Id							INT,
	@GCASNumber						NVARCHAR(25),
	@Signal_Word					NVARCHAR(25),
	@Corrosion						CHAR(1),
	@Environment					CHAR(1),
	@Exclamation_Mark				CHAR(1),
	@Exploding_Bomb					CHAR(1),
	@Flame							CHAR(1),
	@Flame_Over_Circle				CHAR(1),
	@Gas_Cylinder					CHAR(1),
	@Health_Hazard					CHAR(1),
	@Skulls_and_Crossbones			CHAR(1),
	@Type							NVARCHAR(25),
	@Document_Id					NVARCHAR(25),
	@File_Name						NVARCHAR(25),
	@Common_Name					NVARCHAR(50),
	@Manufacturer					NVARCHAR(255),
	@Revision_Date					NVARCHAR(25),
	@Language						NVARCHAR(50),
	@SDS_Format						NVARCHAR(25),
	@Site_Name						NVARCHAR(50),
	@SDS_State						NVARCHAR(25),
	@PrecautionStatement_General	NVARCHAR(4000),
	@PrecautionStatement_Prevention	NVARCHAR(4000),
	@PrecautionStatement_Response	NVARCHAR(4000),
	@PrecautionStatement_Storage	NVARCHAR(4000),
	@PrecautionStatement_Disposal	NVARCHAR(4000),
	@HazardStatement_Physical		NVARCHAR(4000),
	@HazardStatement_Health			NVARCHAR(4000),
	@HazardStatement_Environmental	NVARCHAR(4000)

--WITH ENCRYPTION 

AS
 
SET NOCOUNT ON;
 
DECLARE
	@ErrorSeverity	INT,
	@ProcName		NVARCHAR(128),
	@Delimiter		CHAR(1);
	
SELECT
	@ReturnStatus	= 0,
	@ReturnMessage	= 'Initialized';
 
SET @ProcName = OBJECT_NAME(@@PROCID);	-- get actual sp name in case something like _debug is running.

SET @Delimiter = '^';

-- Check for header row
IF @ReturnStatus = 0 AND @GCASNumber = 'GCAS_Number'
BEGIN
 
	SELECT
		@ReturnStatus	= 4,
		@ReturnMessage	= @ProcName + ' - Info - Header Row Received - ********** Processing Start **********';
 
END;
  
-- Check for End Of File
IF @ReturnStatus = 0 AND @GCASNumber = 'EOF'
BEGIN
 
	SELECT
		@ReturnStatus	= 5,
		@ReturnMessage	= @ProcName + ' - Info - EOF Recieved - ********** Processing Complete **********';
 
END;
  
IF @ReturnStatus = 0
BEGIN
 
	BEGIN TRY
		
		;WITH s AS
		(
			SELECT
				SUBSTRING( @GCASNumber, 1,  25) GCAS_Number,
				SUBSTRING( @Signal_Word, 1,  25) Signal_Word,
				SUBSTRING( @Corrosion, 1,   1) Corrosion,
				SUBSTRING( @Environment, 1,   1) Environment,
				SUBSTRING( @Exclamation_Mark, 1,   1) Exclamation_mark,
				SUBSTRING( @Exploding_Bomb, 1,   1) Exploding_bomb,
				SUBSTRING( @Flame, 1,   1) Flame,
				SUBSTRING( @Flame_Over_Circle, 1,   1) Flame_Over_Circle,
				SUBSTRING( @Gas_Cylinder, 1,   1) Gas_Cylinder,
				SUBSTRING( @Health_Hazard, 1,   1) Health_hazard,
				SUBSTRING( @Skulls_and_Crossbones, 1,   1) Skulls_and_Crossbones,
				SUBSTRING( @Type, 1,  25) [Type],
				SUBSTRING( @Document_Id, 1,  25) Document_ID,
				SUBSTRING( @File_Name, 1,  25) [File_Name],
				SUBSTRING( @Common_Name, 1,  50) Common_Name,
				SUBSTRING( @Manufacturer, 1, 255) Manufacturer,
				CAST(@Revision_Date AS DATETIME)  Revision_Date,
				SUBSTRING( @Language, 1,  50) [Language],
				SUBSTRING( @SDS_Format, 1,  25) SDS_Format,
				SUBSTRING( @Site_Name, 1,  50) Site_Name,
				SUBSTRING( @SDS_State, 1,  25) SDS_State,
				@PrecautionStatement_General PrecautionStatement_General,	-- the rest of the destination columns are nvarchar(4000) already
				@PrecautionStatement_Prevention PrecautionStatement_Prevention,
				@PrecautionStatement_Response PrecautionStatement_Response,
				@PrecautionStatement_Storage PrecautionStatement_Storage,
				@PrecautionStatement_Disposal PrecautionStatement_Disposal,
				@HazardStatement_Physical HazardStatement_Physical,
				@HazardStatement_Health HazardStatement_Health,
				@HazardStatement_Environmental HazardStatement_Environmental,
				CASE @Corrosion				WHEN 'Y' THEN '1' ELSE '' END + 
				CASE @Environment			WHEN 'Y' THEN '2' ELSE '' END + 
				CASE @Exclamation_Mark		WHEN 'Y' THEN '3' ELSE '' END + 
				CASE @Exploding_Bomb		WHEN 'Y' THEN '4' ELSE '' END + 
				CASE @Flame					WHEN 'Y' THEN '5' ELSE '' END + 
				CASE @Flame_Over_Circle		WHEN 'Y' THEN '6' ELSE '' END + 
				CASE @Gas_Cylinder			WHEN 'Y' THEN '7' ELSE '' END + 
				CASE @Health_Hazard			WHEN 'Y' THEN '8' ELSE '' END + 
				CASE @Skulls_and_Crossbones	WHEN 'Y' THEN '9' ELSE '' END PictogramYeses
		)
		MERGE INTO dbo.Local_INT_GHS_MATERIAL_SAFETY_DATA WITH(HOLDLOCK) t
		USING s 
			ON s.GCAS_Number = t.GCAS_Number
		WHEN MATCHED AND s.Revision_Date > t.Revision_Date THEN UPDATE
			SET Signal_Word							= s.Signal_Word,
				Corrosion							= s.Corrosion,
				Environment							= s.Environment,
				Exclamation_Mark					= s.Exclamation_Mark,
				Exploding_Bomb						= s.Exploding_Bomb,
				Flame								= s.Flame,
				Flame_Over_Circle					= s.Flame_Over_Circle,
				Gas_Cylinder						= s.Gas_Cylinder,
				Health_Hazard						= s.Health_Hazard,
				Skulls_and_Crossbones				= s.Skulls_and_Crossbones,
				[Type]								= s.[Type],
				Document_Id							= s.Document_Id,
				[File_Name]							= s.[File_Name],
				Common_Name							= s.Common_Name,
				Manufacturer						= s.Manufacturer,
				Revision_Date						= s.Revision_Date,
				[Language]							= s.[Language],
				SDS_Format							= s.SDS_Format,
				Site_Name							= s.Site_Name,
				SDS_State							= s.SDS_State,
				PrecautionStatement_General			= s.PrecautionStatement_General,
				PrecautionStatement_Prevention		= s.PrecautionStatement_Prevention,
				PrecautionStatement_Response		= s.PrecautionStatement_Response,
				PrecautionStatement_Storage			= s.PrecautionStatement_Storage,
				PrecautionStatement_Disposal		= s.PrecautionStatement_Disposal,
				HazardStatement_Physical			= s.HazardStatement_Physical,
				HazardStatement_Health				= s.HazardStatement_Health,
				HazardStatement_Environmental		= s.HazardStatement_Environmental,
 
				SDS1								= CASE SUBSTRING(s.PictogramYeses, 1, 1)
															WHEN '1' THEN 'acid.jpg'
															WHEN '2' THEN 'fish.jpg'
															WHEN '3' THEN 'exclam.jpg'
															WHEN '4' THEN 'explode.jpg'
															WHEN '5' THEN 'flame.jpg'
															WHEN '6' THEN 'flame2.jpg'
															WHEN '7' THEN 'gascylinder.jpg'
															WHEN '8' THEN 'resp.jpg'
															WHEN '9' THEN 'skull.jpg'
															ELSE '' 
														END,
				SDS2								= CASE SUBSTRING(s.PictogramYeses, 2, 1)
															WHEN '1' THEN 'acid.jpg'
															WHEN '2' THEN 'fish.jpg'
															WHEN '3' THEN 'exclam.jpg'
															WHEN '4' THEN 'explode.jpg'
															WHEN '5' THEN 'flame.jpg'
															WHEN '6' THEN 'flame2.jpg'
															WHEN '7' THEN 'gascylinder.jpg'
															WHEN '8' THEN 'resp.jpg'
															WHEN '9' THEN 'skull.jpg'
															ELSE '' 
														END,
				SDS3								= CASE SUBSTRING(s.PictogramYeses, 3, 1)
															WHEN '1' THEN 'acid.jpg'
															WHEN '2' THEN 'fish.jpg'
															WHEN '3' THEN 'exclam.jpg'
															WHEN '4' THEN 'explode.jpg'
															WHEN '5' THEN 'flame.jpg'
															WHEN '6' THEN 'flame2.jpg'
															WHEN '7' THEN 'gascylinder.jpg'
															WHEN '8' THEN 'resp.jpg'
															WHEN '9' THEN 'skull.jpg'
															ELSE '' 
														END,
				SDS4								= CASE SUBSTRING(s.PictogramYeses, 4, 1)
															WHEN '1' THEN 'acid.jpg'
															WHEN '2' THEN 'fish.jpg'
															WHEN '3' THEN 'exclam.jpg'
															WHEN '4' THEN 'explode.jpg'
															WHEN '5' THEN 'flame.jpg'
															WHEN '6' THEN 'flame2.jpg'
															WHEN '7' THEN 'gascylinder.jpg'
															WHEN '8' THEN 'resp.jpg'
															WHEN '9' THEN 'skull.jpg'
															ELSE '' 
														END,
				SDS5								= CASE s.Signal_Word 
															WHEN 'Warning' THEN 'Warning' 
															WHEN 'Danger' THEN 'Danger' 
															ELSE 'None' 
														END,
				Record_Processed_DateTime			= GETDATE(),
				Processed_Result					= 3,
				[Error_Message]						= 'Success. Record includes material record updates'
					
		WHEN NOT MATCHED THEN INSERT
			VALUES (
				s.GCAS_Number,
				s.Signal_Word,
				s.Corrosion,
				s.Environment,
				s.Exclamation_Mark,
				s.Exploding_Bomb,
				s.Flame,
				s.Flame_Over_Circle,
				s.Gas_Cylinder,
				s.Health_Hazard,
				s.Skulls_and_Crossbones,
				s.[Type],
				s.Document_Id,
				s.[File_Name],
				s.Common_Name,
				s.Manufacturer,
				s.Revision_Date,
				s.[Language],
				s.SDS_Format,
				s.Site_Name,
				s.SDS_State,
				s.PrecautionStatement_General,
				s.PrecautionStatement_Prevention,
				s.PrecautionStatement_Response,
				s.PrecautionStatement_Storage,
				s.PrecautionStatement_Disposal,
				s.HazardStatement_Physical,
				s.HazardStatement_Health,
				s.HazardStatement_Environmental,
					
				CASE SUBSTRING(s.PictogramYeses, 1, 1)
					WHEN '1' THEN 'acid.jpg'
					WHEN '2' THEN 'fish.jpg'
					WHEN '3' THEN 'exclam.jpg'
					WHEN '4' THEN 'explode.jpg'
					WHEN '5' THEN 'flame.jpg'
					WHEN '6' THEN 'flame2.jpg'
					WHEN '7' THEN 'gascylinder.jpg'
					WHEN '8' THEN 'resp.jpg'
					WHEN '9' THEN 'skull.jpg'
					ELSE '' 
				END,
				CASE SUBSTRING(s.PictogramYeses, 2, 1)
					WHEN '1' THEN 'acid.jpg'
					WHEN '2' THEN 'fish.jpg'
					WHEN '3' THEN 'exclam.jpg'
					WHEN '4' THEN 'explode.jpg'
					WHEN '5' THEN 'flame.jpg'
					WHEN '6' THEN 'flame2.jpg'
					WHEN '7' THEN 'gascylinder.jpg'
					WHEN '8' THEN 'resp.jpg'
					WHEN '9' THEN 'skull.jpg'
					ELSE '' 
				END,
				CASE SUBSTRING(s.PictogramYeses, 3, 1)
					WHEN '1' THEN 'acid.jpg'
					WHEN '2' THEN 'fish.jpg'
					WHEN '3' THEN 'exclam.jpg'
					WHEN '4' THEN 'explode.jpg'
					WHEN '5' THEN 'flame.jpg'
					WHEN '6' THEN 'flame2.jpg'
					WHEN '7' THEN 'gascylinder.jpg'
					WHEN '8' THEN 'resp.jpg'
					WHEN '9' THEN 'skull.jpg'
					ELSE '' 
				END,
				CASE SUBSTRING(s.PictogramYeses, 4, 1)
					WHEN '1' THEN 'acid.jpg'
					WHEN '2' THEN 'fish.jpg'
					WHEN '3' THEN 'exclam.jpg'
					WHEN '4' THEN 'explode.jpg'
					WHEN '5' THEN 'flame.jpg'
					WHEN '6' THEN 'flame2.jpg'
					WHEN '7' THEN 'gascylinder.jpg'
					WHEN '8' THEN 'resp.jpg'
					WHEN '9' THEN 'skull.jpg'
					ELSE '' 
				END,
				CASE s.Signal_Word 
					WHEN 'Warning' THEN 'Warning' 
					WHEN 'Danger' THEN 'Danger' 
					ELSE 'None' 
				END,
				GETDATE(),
				1,
				'Success. New record creation.'
			);
				
		-- If a row was INSERTED or UPDATED, get the return params from the row.
		IF @@ROWCOUNT > 0
		BEGIN
			
			SELECT 
				@ReturnStatus = Processed_Result,
				@ReturnMessage = LEFT(@ProcName + ' - GCAS = ' + @GCASNumber + ', ' + [Error_Message], 255)
			FROM dbo.Local_INT_GHS_MATERIAL_SAFETY_DATA
			WHERE GCAS_Number = @GCASNumber;
		
		END
		ELSE
		BEGIN
			
			-- if no row was modified, it's most likely the "new" revision date was older.
			-- since no error just signal Success - no changes made.
			SELECT 
				@ReturnStatus = 2,
				@ReturnMessage = LEFT(@ProcName + ' - GCAS = ' + @GCASNumber + ', Success. Record Processed no material record changes', 255)
 
		END;
		
	END TRY
	BEGIN CATCH
	
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		
		SELECT
			@ReturnStatus = ERROR_NUMBER(),
			@ReturnMessage = LEFT(@ProcName + ' - GCAS = ' + ISNULL(@GCASNumber, 'UNKNOWN') + ', ' + ERROR_MESSAGE(), 255),
			@ErrorSeverity = ERROR_SEVERITY();
			
		RAISERROR(@ReturnMessage, @ErrorSeverity, 1);
				
	END CATCH
	
END;
 
