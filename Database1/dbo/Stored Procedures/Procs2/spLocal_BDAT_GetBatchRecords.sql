

/*Step B Creation Of SP*/
CREATE   PROCEDURE [dbo].[spLocal_BDAT_GetBatchRecords]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDAT_GetBatchRecords
Author				:		Pratik Patil
Date Created		:		08-29-2023
SP Type				:		BDAT
Editor Tab Spacing  :       3
	
Description:
=========
To retrieve all records for batch from batchhistory table
CALLED BY:  BDAT Tool
Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			29-Aug-2023	    Pratik Patil		   Creation of SP
Test Code:
Declare @BatchId varchar(50) = '0008526212'
exec spLocal_BDAT_GetBatchRecords @BatchId
*/

@BatchId VARCHAR(50)

AS
SET NOCOUNT ON
DECLARE 

@Path_id INT, 
@EXUDPID INT, 
@UnitUDPID INT,
@ArchiveTableName VARCHAR(255),
@vchSQLString NVARCHAR(3000)

SET @EXUDPID = (
		SELECT Table_Field_id
		FROM table_fields
		WHERE table_field_desc LIKE 'PE_BachHistoryPendingCancel'
		);
SET @UnitUDPID = (
		SELECT Table_Field_id
		FROM table_fields
		WHERE table_field_desc LIKE 'PG_UDP_BatchHistoryArchiveTableName'
		);

DECLARE @ORDER TABLE (Process_Order VARCHAR(50), Line VARCHAR(20), PATH_ID INT, OrderStatus VARCHAR(20), TIMESTAMP DATETIME, Archivetable VARCHAR(50), Batchnumber VARCHAR(20));


IF EXISTS ( SELECT User_General_1 from Production_Plan (NOLOCK) where User_General_1 like '%' + @BatchId + '%')
BEGIN

INSERT INTO @ORDER (Process_Order, Line, path_id, OrderStatus, TIMESTAMP, Batchnumber)
SELECT pp.Process_Order, PL.pl_desc, pp.path_id, st.pp_status_desc, PP.Entry_On, PP.User_General_1
FROM production_plan pp (NOLOCK)
INNER JOIN prdexec_paths pe (NOLOCK)
	ON pp.Path_Id = pe.Path_Id
INNER JOIN prod_lines pl (NOLOCK)
	ON pl.pl_id = pe.PL_Id
INNER JOIN production_plan_statuses st (NOLOCK)
	ON pp.pp_status_id = St.pp_status_id
INNER JOIN table_fields_values tfv(NOLOCK) 
	ON tfv.KeyId = pe.Path_Id
INNER JOIN Table_Fields tf(NOLOCK) 
	ON tf.Table_Field_Id = tfv.Table_Field_Id
WHERE pp.User_General_1 LIKE '%' + @BatchId + '%'
	AND tf.Table_Field_Id = @EXUDPID;

UPDATE @ORDER
SET Archivetable = (
		SELECT value
		FROM Table_Fields_Values tfv (NOLOCK)
		INNER JOIN Prod_Units_Base pu (NOLOCK)
			ON tfv.KeyId = pu.PU_Id
		WHERE Table_Field_Id = @UnitUDPID
			AND tfv.KeyId IN (
				SELECT PU_Id
				FROM PrdExec_Path_Units (NOLOCK)
				WHERE path_id = (
						SELECT path_id
						FROM @ORDER
						)
				)
		);

END


SELECT  @ArchiveTableName = Archivetable  FROM @ORDER;
SELECT  @vchSQLString = NULL;

SET @vchSQLString = 'Select [GMT]
      ,[lclTime]
      ,[UniqueID]
      ,[BatchID]
      ,[Recipe]
      ,[Descript]
      ,[Event]
      ,[PValue]
      ,[DescriptAPI]
      ,[EventAPI]
      ,[PValueAPI]
      ,[EU]
      ,[Area]
      ,[ProcCell]
      ,[Unit]
      ,[Phase]
      ,[Printed]
      ,[UserID]
      ,[PhaseDesc]
      ,[MaterialName]
      ,[MaterialID]
      ,[LotName]
      ,[Label]
      ,[Container]
      ,[PromiseID]
      ,[Signature]
      ,[ERP_Flag]
      ,[RecordNo]
      ,[ReactivationNumber]
      ,[InstructionHTML]
      ,[SignatureID]
      ,[ActionID] from BatchHistory.dbo.' + @ArchiveTableName + ' where BatchID =' + @BatchId;

EXEC sys.sp_executesql  @vchSQLString;

/* -------------------------------------------------------------------------------------------------------------------
-- Version Management
---------------------------------------------------------------------------------------------------------------------- */
DECLARE @SP_Name NVARCHAR(200) = 'spLocal_BDAT_GetBatchRecords',
@Version NVARCHAR(20) = '1.0.0' ,
@AppId INT = 0;
UPDATE dbo.AppVersions
SET App_Version = @Version,
Modified_On = GETDATE()
WHERE App_Name = @SP_Name;
IF @@ROWCOUNT = 0
BEGIN
SELECT @AppId = ISNULL(MAX(App_Id) + 1 ,1) FROM dbo.AppVersions WITH(NOLOCK);
INSERT INTO dbo.AppVersions (App_Id, App_name, App_version)
VALUES (@AppId, @SP_Name, @Version);
END


