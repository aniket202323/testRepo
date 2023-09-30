

/*Step B Creation Of SP*/
CREATE  PROCEDURE [dbo].spLocal_BDAT_SearchbyBatchorPO


/*-------------------------------------------------------------------------------------------------
Stored Procedure			spLocal_BDAT_SearchbyBatchorPO
Author						Pratik Patil
Date Created				08-31-2023
SP Type						BDAT
Editor Tab Spacing         3
	
Description
=========
The Purpose of this stored procedure to get details of batch along with process order, line, PU_ID, UniqueId. So this details will be
used to get batch summary data.


CALLED BY  BDAT Tool

Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			31-Aug-2023	    Pratik Patil		   Creation of SP

Test Code
Declare @Searchdata varchar(50) ='000909841170'
EXEC spLocal_BDAT_SearchbyBatchorPO @Searchdata
*/

@Searchdata VARCHAR(50)
AS

DECLARE
 @Path_id INT, 
 @EXUDPID INT,
 @UnitUDPID INT,
 @ArchiveTableName VARCHAR(255),
 @vchSQLString NVARCHAR(3000),
 @BatchId Varchar(20)

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

DECLARE @ORDER TABLE (Process_Order VARCHAR(50), Line VARCHAR(20), PATH_ID INT, OrderStatus VARCHAR(20), TIMESTAMP DATETIME, Archivetable VARCHAR(50), Batchnumber VARCHAR(20),UniqueID VARCHAR(20), PU_ID VARCHAR(20));
DECLARE @UniqueIdTemp TABLE (UniqueId Varchar(20), BatchId Varchar(20));

IF EXISTS ( SELECT PP_ID from Production_Plan (NOLOCK) where Process_Order like '%' + @Searchdata + '%')
BEGIN

INSERT INTO @ORDER (Process_Order, Line, path_id, OrderStatus, TIMESTAMP, Batchnumber, PU_ID)
SELECT pp.Process_Order, PL.pl_desc, pp.path_id, st.pp_status_desc, PP.Entry_On, PP.User_General_1, gicd.PUId
FROM production_plan pp (NOLOCK)
INNER JOIN prdexec_paths pe (NOLOCK)
	ON pp.Path_Id = pe.Path_Id
INNER JOIN prod_lines pl (NOLOCK)
	ON pl.pl_id = pe.PL_Id
INNER JOIN production_plan_statuses st (NOLOCK)
	ON pp.pp_status_id = St.pp_status_id
INNER JOIN table_fields_values tfv(NOLOCK) 
	ON tfv.KeyId = pe.Path_Id
INNER JOIN dbo.fnLocal_PG_Batch_GetInterfaceConfigData() gicd 
	ON pl.PL_Desc = gicd.Line
INNER JOIN Table_Fields tf(NOLOCK) 
	ON tf.Table_Field_Id = tfv.Table_Field_Id
WHERE pp.Process_Order LIKE '%' + @Searchdata + '%'
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

	SELECT  @ArchiveTableName = Archivetable  FROM @ORDER;
	SELECT  @vchSQLString = NULL;

	SELECT @BatchId = Batchnumber from @ORDER where Process_Order = @Searchdata;
	SET @vchSQLString = 'Select Distinct UniqueID,BatchID from BatchHistory.dbo.' + @ArchiveTableName + ' where BatchID =' + @BatchId;
	INSERT @UniqueIdTemp(UniqueId,BatchId) EXEC sys.sp_executesql  @vchSQLString;

END

ELSE

IF EXISTS ( SELECT User_General_1 from Production_Plan (NOLOCK) where User_General_1 like '%' + @Searchdata + '%')
BEGIN

INSERT INTO @ORDER (Process_Order, Line, path_id, OrderStatus, TIMESTAMP, Batchnumber, PU_ID)
SELECT pp.Process_Order, PL.pl_desc, pp.path_id, st.pp_status_desc, PP.Entry_On, PP.User_General_1,gicd.PUId 
FROM production_plan pp (NOLOCK)
INNER JOIN prdexec_paths pe (NOLOCK)
	ON pp.Path_Id = pe.Path_Id
INNER JOIN prod_lines pl (NOLOCK)
	ON pl.pl_id = pe.PL_Id
INNER JOIN production_plan_statuses st (NOLOCK)
	ON pp.pp_status_id = St.pp_status_id
INNER JOIN table_fields_values tfv(NOLOCK) 
	ON tfv.KeyId = pe.Path_Id
INNER JOIN dbo.fnLocal_PG_Batch_GetInterfaceConfigData() gicd 
	ON pl.PL_Desc = gicd.Line
INNER JOIN Table_Fields tf(NOLOCK) 
	ON tf.Table_Field_Id = tfv.Table_Field_Id
WHERE pp.User_General_1 LIKE '%' + @Searchdata + '%'
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

	SELECT  @ArchiveTableName = Archivetable  FROM @ORDER;
	SELECT  @vchSQLString = NULL;

	SET @vchSQLString = 'Select Distinct UniqueID,BatchID from BatchHistory.dbo.'
		+ @ArchiveTableName + ' where BatchID =' + @Searchdata;
	INSERT @UniqueIdTemp(UniqueId,BatchId) EXEC sys.sp_executesql  @vchSQLString;

END

SELECT o.Process_Order,o.Line, o.PATH_ID, o.OrderStatus, o.TIMESTAMP, o.Archivetable, o.Batchnumber, o.PU_ID, un.UniqueId 
FROM @ORDER o JOIN @UniqueIdTemp un ON o.Batchnumber = un.BatchId;
