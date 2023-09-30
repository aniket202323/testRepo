


--------------------------------------------------------------------------------------------------
-- Local Stored Procedure: spLocal_CTS_Scan_Validation
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-09-01
-- Version 				:	1.0
-- Description			:	The purpose of this query is to get the CTS object info
--							It first validates that the serial number matches an object in CTS (location or appliance) 
--							and return the object type
-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-09-01		F.Bergeron				Initial Release 



--------------------------------------------------------------------------------------------------
--Testing Code
--------------------------------------------------------------------------------------------------

-- EXECUTE spLocal_CTS_Scan_Validation '1'
-- EXECUTE spLocal_CTS_Scan_Validation '2000001'

CREATE PROCEDURE [dbo].[spLocal_CTS_Scan_Validation]
	@Serial				VARCHAR(25)


AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables
	DECLARE
	@PUId				INTEGER,
	@EventId			INTEGER

	DECLARE
	@Output TABLE
	(
		Serial				VARCHAR(25),
		CTS_Message			VARCHAR(255),
		CTS_Type			VARCHAR(25),
		CTS_Sub_Type		VARCHAR(25),
		PPA_Id				VARCHAR(25),
		PPA_Desc			VARCHAR(25)
	)


	BEGIN --LOCATION
		-- VALIDATE LOCATION 
		
			SELECT		@PUId = PUB.PU_Id
			FROM		dbo.prod_units_base PUB 
						JOIN dbo.Table_Fields_Values TFV ON TFV.KeyId = PUB.PU_Id
						JOIN dbo.Table_Fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id
						JOIN dbo.Tables T ON t.tableid = TF.tableId 
			WHERE		TF.Table_Field_Desc = 'CTS Location serial number' 
						AND T.tableName = 'Prod_Units' 
						AND TFV.Value = @Serial
	
		IF @PUId IS NOT NULL
		BEGIN
			--GET Location type (Production or non production)
			INSERT INTO @Output
			(
				Serial,
				CTS_Message,
				CTS_Type,
				CTS_Sub_Type,
				PPA_Id,
				PPA_Desc
			)
			SELECT	@Serial, NULL, 'Location', UT.UT_Desc, PUB.PU_Id,PUB.PU_Desc
			FROM	dbo.prod_units_base PUB
					JOIN dbo.Unit_Types UT ON UT.Unit_Type_Id = PUB.Unit_Type_Id
					WHERE PUB.PU_Id = @PUId
		END
	END


	IF (SELECT COUNT(1) FROM @Output) = 0
	BEGIN 
		-- VALIDATE APPLIANCE 
		
			SELECT		@EventId = E.Event_id
			FROM		dbo.events E WITH(NOLOCK)
						JOIN dbo.Event_Details ED WITH(NOLOCK) ON ED.Event_Id = E.Event_Id
			WHERE		ED.Alternate_Event_Num = @serial
	
		IF @EventId IS NOT NULL
		BEGIN
			-- BUILD LOCATION OUTPUT
			INSERT INTO @Output
			(
				Serial,
				CTS_Message,
				CTS_Type,
				CTS_Sub_Type,
				PPA_Id,
				PPA_Desc
			)
			SELECT	@Serial, 
					NULL, 
					'Appliance', 
					TFV.Value,
					PUB.PU_Id,PUB.PU_Desc
			FROM	dbo.events E WITH(NOLOCK) 
					JOIN dbo.prod_units_base PUB ON PUB.pu_id = E.PU_Id
					JOIN dbo.Table_Fields_Values TFV ON TFV.KeyId = PUB.PU_Id
					JOIN dbo.Table_Fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id
					JOIN dbo.Tables T ON t.tableid = TF.tableId 
			WHERE		
					E.Event_Id = @EventId
						AND TF.Table_Field_Desc = 'CTS Appliance type' 
		

		END
	END

	IF (SELECT COUNT(1) FROM @Output) = 0
	BEGIN
			-- BUILD APPLIANCE OUTPUT
			INSERT INTO @Output
			(
				Serial,
				CTS_Message,
				CTS_Type,
				CTS_Sub_Type,
				PPA_Id,
				PPA_Desc
			)
			SELECT	@Serial, 'Object unknown', NULL, NULL, NULL,NULL
	END

	SELECT * FROM @Output
END
