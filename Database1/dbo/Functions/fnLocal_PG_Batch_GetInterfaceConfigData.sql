
--=====================================================================================================================

-- Function: 			fnLocal_PG_Batch_GetInterfaceConfigData

-- Author:				Dan Hinchey

-- Date Created:		2010-09-25

-- Sp Type:				Function

-- Editor Tab Spacing: 	4

-----------------------------------------------------------------------------------------------------------------------

-- DESCRIPTION:

--

-- This function is very specific to the P&G Batch History configuration and relies on custom configuration

-- requirements.

--

-- Most of the information retrieved by this functions comes from the Event Model configuration for the Batch Import

-- (Model 118) model.

--

-- Also, there are four UDP's that must be defined and populated on the Main Batch Unit that are used to define the

-- name of the Batch History database and Archive Table as well as the Product Code and End of Batch string values.

-----------------------------------------------------------------------------------------------------------------------

-- EDIT HISTORY:

-----------------------------------------------------------------------------------------------------------------------

-- Revision		Date		Who					What

-- ========		====		===					====

-- 1.0			2010-09-25	Dan Hinchey			Initial Development
-- 1.1			2016-08-09	Anurag Singh		Revised for Optimization with respect to TableID
-----------------------------------------------------------------------------------------------------------------------

-- SAMPLE EXEC STATEMENT

-----------------------------------------------------------------------------------------------------------------------

/*

SELECT * FROM fnLocal_PG_Batch_GetInterfaceConfigData ()

*/

--=====================================================================================================================

CREATE  FUNCTION dbo.fnLocal_PG_Batch_GetInterfaceConfigData ()

RETURNS 


@tblBatchImportUnits TABLE(

	RcdIdx				INT Identity(1,1),

	ECId				INT,

	PUId				INT,

	Department			VARCHAR(50),

	Line				VARCHAR(50),

	Unit				VARCHAR(50),

	BatchUnit			VARCHAR(50),

	BatchUnitId			INT,

	S88Area				VARCHAR(100),

	S88Cell				VARCHAR(100),

	S88Unit				VARCHAR(100),

	IsProductionPoint	BIT DEFAULT 0,

	EndOfBatchString	VARCHAR(100),

	ProductCodeString	VARCHAR(100),

	ArchiveDatabase		VARCHAR(100),

	ArchiveTable		VARCHAR(100))

AS  

BEGIN

	--=================================================================================================================

	-- Retrieve data from all Model 118's.

	--=================================================================================================================

	INSERT	@tblBatchImportUnits(
			ECId,
			PUId,
			Department,
			Line,
			Unit,
			BatchUnit,
			BatchUnitId)
	SELECT	ec.EC_Id,
			ec.PU_Id,
			Case When @@options&(512) !=(0) THEN  Coalesce(ccc.S95Id,d.Dept_Desc,d.Dept_Desc_Global)
                              ELSE  Coalesce(d.Dept_Desc_Global,ccc.S95Id,d.Dept_Desc)
                              END,
			Case When @@options&(512) !=(0) THEN Coalesce(cc.S95Id,pl.PL_Desc,pl.PL_Desc_Global)
                              ELSE  Coalesce(pl.PL_Desc_Global,cc.S95Id,pl.PL_Desc)
                              END,
			Case When @@options&(512) !=(0) THEN Coalesce(c.S95Id,pu.PU_Desc,pu.PU_Desc_Global)
                ELSE  Coalesce(pu.PU_Desc_Global,c.S95Id,pu.PU_Desc)
            END,
			Case When @@options&(512) !=(0) THEN Coalesce(cccc.S95Id,pub.PU_Desc,pub.PU_Desc_Global)
                ELSE  Coalesce(pub.PU_Desc_Global,cccc.S95Id,pub.PU_Desc)
            END,
			pub.PU_Id
	FROM dbo.Event_Configuration ec	WITH (NOLOCK)
	JOIN dbo.Prod_Units_Base pu	WITH (NOLOCK) ON ec.PU_Id = pu.PU_Id
		LEFT JOIN PAEquipment_Aspect_SOAEquipment b WITH (NOLOCK) on pu.PU_Id = b.PU_Id
		LEFT JOIN Equipment c WITH (NOLOCK) on b.Origin1EquipmentId = c.EquipmentId

	JOIN dbo.Prod_Lines_Base pl	WITH (NOLOCK) ON pu.PL_Id = pl.PL_Id
		LEFT JOIN PAEquipment_Aspect_SOAEquipment bb WITH (NOLOCK) On pl.PL_Id = bb.PL_Id
		LEFT JOIN Equipment cc WITH (NOLOCK) on  bb.Origin1EquipmentId = cc.EquipmentId
	
	JOIN dbo.Departments_Base d	WITH (NOLOCK) ON pl.Dept_Id = d.Dept_Id
		LEFT JOIN PAEquipment_Aspect_SOAEquipment bbb WITH (NOLOCK) On bbb.Dept_Id = d.Dept_Id
		LEFT JOIN Equipment ccc WITH (NOLOCK) ON bbb.Origin1EquipmentId = ccc.EquipmentId

	LEFT JOIN dbo.Prod_Units_Base pub WITH (NOLOCK) ON pl.PL_Id = pub.PL_Id AND pub.Extended_Info = 'BATCH:'
		LEFT JOIN PAEquipment_Aspect_SOAEquipment bbbb WITH (NOLOCK) on pub.PU_Id = bbbb.PU_Id
		LEFT JOIN Equipment cccc WITH (NOLOCK) on b.Origin1EquipmentId = cccc.EquipmentId

	WHERE	ec.ED_Model_Id = 100

	--=================================================================================================================

	-- Get model input value for Area

	--=================================================================================================================

	UPDATE	biu

			SET	S88Area = Value

	FROM	@tblBatchImportUnits				biu

		JOIN	dbo.Event_Configuration_Data	ecd		WITH (NOLOCK)

												ON biu.ECId = ecd.EC_Id

		JOIN	dbo.ED_Fields					edf		WITH (NOLOCK)

												ON ecd.ED_Field_Id = edf.ED_Field_Id

		LEFT

		JOIN	dbo.Event_Configuration_Values	ecv		WITH (NOLOCK)

												ON ecd.ECV_Id = ecv.ECV_Id

	WHERE	Field_Desc = 'Area'

	--=================================================================================================================

	-- Get model input value for Cell

	--=================================================================================================================

	UPDATE	biu

			SET	S88Cell = Value

	FROM	@tblBatchImportUnits				biu

		JOIN	dbo.Event_Configuration_Data	ecd		WITH (NOLOCK)

												ON biu.ECId = ecd.EC_Id

		JOIN	dbo.ED_Fields					edf		WITH (NOLOCK)

												ON ecd.ED_Field_Id = edf.ED_Field_Id

		LEFT

		JOIN	dbo.Event_Configuration_Values	ecv		WITH (NOLOCK)

												ON ecd.ECV_Id = ecv.ECV_Id

	WHERE	Field_Desc = 'Cell'

	--=================================================================================================================

	-- Get model input value for Unit

	--=================================================================================================================

	UPDATE	biu

			SET	S88Unit = Value

	FROM	@tblBatchImportUnits				biu

		JOIN	dbo.Event_Configuration_Data	ecd		WITH (NOLOCK)

												ON biu.ECId = ecd.EC_Id

		JOIN	dbo.ED_Fields					edf		WITH (NOLOCK)

												ON ecd.ED_Field_Id = edf.ED_Field_Id

		LEFT

		JOIN	dbo.Event_Configuration_Values	ecv		WITH (NOLOCK)

												ON ecd.ECV_Id = ecv.ECV_Id

	WHERE	Field_Desc = 'Unit'

	--=================================================================================================================

	-- Get Production Unit UDP value that defines Batch History database name

	--=================================================================================================================

	
	UPDATE	biu

			SET	ArchiveDatabase = Value

	FROM	@tblBatchImportUnits		biu

		JOIN	dbo.Table_Fields_Values	tfv	WITH (NOLOCK)

										ON	biu.BatchUnitId = tfv.KeyId

		JOIN	dbo.Table_Fields		tf	WITH (NOLOCK)

										ON	tfv.Table_Field_Id = tf.Table_Field_Id
										JOIN dbo.Tables t on t.tableid = tf.tableid AND t.tablename like 'Prod_units' --1.1
										AND	Table_Field_Desc = 'PG_UDP_BatchHistoryDatabaseName'

	--=================================================================================================================

	-- Get Production Unit UDP value that defines Batch History database archive table name

	--=================================================================================================================

	UPDATE	biu

			SET	ArchiveTable = Value

	FROM	@tblBatchImportUnits		biu

		JOIN	dbo.Table_Fields_Values	tfv	WITH (NOLOCK)

										ON	biu.BatchUnitId = tfv.KeyId

		JOIN	dbo.Table_Fields		tf	WITH (NOLOCK)

										ON	tfv.Table_Field_Id = tf.Table_Field_Id
										JOIN dbo.Tables t on t.tableid = tf.tableid AND t.tablename like 'Prod_units' --1.1
										AND	Table_Field_Desc = 'PG_UDP_BatchHistoryArchiveTableName'

	--=================================================================================================================

	-- Get Production Unit UDP value that defines Batch History Product Code parameter name

	--=================================================================================================================

	UPDATE	biu

			SET	ProductCodeString = COALESCE(Value, 'Product Code')

	FROM	@tblBatchImportUnits		biu

		JOIN	dbo.Table_Fields_Values	tfv	WITH (NOLOCK)

										ON	biu.BatchUnitId = tfv.KeyId

		JOIN	dbo.Table_Fields		tf	WITH (NOLOCK)

										ON	tfv.Table_Field_Id = tf.Table_Field_Id
										JOIN dbo.Tables t on t.tableid = tf.tableid AND t.tablename like 'Prod_units'  --1.1
										AND	Table_Field_Desc = 'PG_UDP_BatchHistoryProductCodeString'

	UPDATE	@tblBatchImportUnits

		SET	ProductCodeString = 'Product Code'

	WHERE	ProductCodeString IS NULL

	--=================================================================================================================

	-- Get Production Unit UDP value that defines Batch History Product Code parameter name

	--=================================================================================================================

	UPDATE	biu

			SET	EndOfBatchString = COALESCE(Value, 'End of Batch')

	FROM	@tblBatchImportUnits		biu

		JOIN	dbo.Table_Fields_Values	tfv	WITH (NOLOCK)

										ON	biu.BatchUnitId = tfv.KeyId

		JOIN	dbo.Table_Fields		tf	WITH (NOLOCK)

										ON	tfv.Table_Field_Id = tf.Table_Field_Id
										JOIN dbo.Tables t on t.tableid = tf.tableid AND t.tablename like 'Prod_units'  --1.1
										AND	Table_Field_Desc = 'PG_UDP_BatchHistoryEndOfBatchString'

	UPDATE	@tblBatchImportUnits

		SET	EndOfBatchString = 'End of Batch'

	WHERE	EndOfBatchString IS NULL

	--=================================================================================================================

	-- Determine if Unit is a production point on a path

	--=================================================================================================================

	UPDATE	biu

	SET	IsProductionPoint = Is_Production_Point

	FROM	@tblBatchImportUnits		biu

		JOIN	dbo.PrdExec_Path_Units	pep

										ON	biu.PUId = pep.PU_Id

										AND	Is_Production_Point = 1

	--=================================================================================================================

	-- Return function table

	--=================================================================================================================
	
	RETURN

END

--=====================================================================================================================

-- END FUNCTION

--=====================================================================================================================
