









-------------------------------------------------------------------------------
-- Edit history
-------------------------------------------------------------------------------
-- AM MSI 15-Mar-2004 Development

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Parameters
-------------------------------------------------------------------------------
/* 	
	@ErrorCode	INTEGER OUTPUT,
	@ErrorMessage	VARCHAR (1000) OUTPUT,
	@Mode. Values: 0,1
		0 - Return Locations filtered by MasterPUIdList and intWebFilterProdUnitsETIdList and charfilter
		1 - Return Locations where PU_Id in the @PUIdList 
	@CharFilter. Default = Null. Description Filter string
	@MasterPUIdList. Default = Null. Pipe-separated list of master PUId's
	@PUIdList. Default = Null. Pipe-separated list of PUId's
	@EventTypeId
*/
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Sample input:
/*
EXEC spRS_FilterLocation 
0, --ERRCODE
'', --ERRMESSAGE
0,  --@MODE
'%%', --@CHARFILTER
'', --@MasterPUIdList
'689', --@PUIDLIST
2   --@EVENTTYPEID

SELECT PU_DESC, * FROM PROD_UNITS WHERE PU_ID = 675


*/
-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spRS_FilterLocation]
@ErrorCode				INT OUTPUT,
@ErrorMessage			VARCHAR (1000) OUTPUT,
@Mode  					INT,
@CharFilter  			VARCHAR(100) = Null,
@MasterPUIdList		VARCHAR (4000) = Null,
@PUIdList  				VARCHAR (4000) = Null,
@EventTypeId			INT = NULL
AS 
	SET NOCOUNT ON
	
	DECLARE @SQLStatement 	VARCHAR (4000)
  
	DECLARE @PUId 		INTEGER
	DECLARE @Seploc 	INTEGER
	
	IF @Mode Not in (0,1)
	BEGIN
		RETURN 0
	END

	CREATE TABLE #TempProdUnits	(
		PU_Id 	INT
   )	

	CREATE TABLE #TempMasterUnits
		(
		PU_Id INT
   )
	
	IF (LEN(IsNull(@MasterPUIdList,'')) > 0) AND UPPER(ISNULL(@MasterPUIdList,'')) != '!NULL'   
	
	BEGIN
		WHILE Len(@MasterPUIdList) > 0
		BEGIN
			IF CHARINDEX('|', @MasterPUIdList) > 0
			BEGIN
				SELECT @Seploc = CHARINDEX('|', @MasterPUIdList)
				IF ISNUMERIC(left(@MasterPUIdList, @Seploc-1)) = 1
				BEGIN
					SELECT @PUId = Cast(left(@MasterPUIdList, @Seploc-1)  AS INT)
					INSERT	#TempMasterUnits (
								PU_Id		)
					VALUES	(
								@PUId	)
          	END
				SELECT @MasterPUIdList = right(@MasterPUIdList, len(@MasterPUIdList) - @Seploc)
			END
			ELSE
			BEGIN
				IF ISNUMERIC(@MasterPUIdList) = 1
				BEGIN
					SELECT @PUId = Cast(@MasterPUIdList  as INT)
					INSERT	#TempMasterUnits (
								PU_Id		)
					VALUES	(
								@PUId	)
            END
				SELECT @MasterPUIdList = ''
			END
		END
	END
	ELSE
	BEGIN
		INSERT	#TempMasterUnits (
					PU_Id		)
		SELECT   PU_ID 
		FROM		PROD_UNITS
		WHERE		PU_ID !=0
	END
	
	
	
	IF LEN(ISNULL(@CharFilter,'')) <=0
		SELECT @CharFilter = '%%'
	
	IF @Mode = 0
	BEGIN
				
		SELECT @SQLStatement = 	' SELECT SU.PU_Id AS PU_Id,  MU.PU_DESC AS MASTER_DESC, SU.PU_DESC AS SLAVE_DESC ' +
										' FROM PROD_EVENTS PE ' +
										' JOIN PROD_UNITS SU ON PE.PU_ID = SU.PU_ID AND PE.EVENT_TYPE = ' + CONVERT(VARCHAR(10), @EventTypeId) + ' ' +
										' JOIN PROD_UNITS MU ON SU.MASTER_UNIT = MU.PU_ID ' +
										' JOIN #TempMasterUnits TMU ON MU.PU_ID = TMU.PU_ID ' +
										' WHERE SU.PU_DESC LIKE "' + @CharFilter + '"' +
										' ORDER BY MU.PU_DESC, SU.PU_DESC'
	END
	
	IF @Mode = 1
	BEGIN
		IF (LEN(IsNull(@PUIdList,'')) > 0) AND UPPER(ISNULL(@PUIdList,'')) != '!NULL'   
		
		BEGIN
			WHILE Len(@PUIdList) > 0
			BEGIN
				IF CHARINDEX('|', @PUIdList) > 0
				BEGIN
					SELECT @Seploc = CHARINDEX('|', @PUIdList)
					IF ISNUMERIC(left(@PUIdList, @Seploc-1)) = 1
					BEGIN
						SELECT @PUId = Cast(left(@PUIdList, @Seploc-1)  AS INT)
						INSERT	#TempProdUnits (
									PU_Id		)
						VALUES	(
									@PUId	)
          		END
					SELECT @PUIdList = right(@PUIdList, len(@PUIdList) - @Seploc)
				END
				ELSE
				BEGIN
					IF ISNUMERIC(@PUIdList) = 1
					BEGIN
						SELECT @PUId = Cast(@PUIdList  as INT)
						INSERT	#TempProdUnits (
									PU_Id		)
						VALUES	(
									@PUId	)
            	END
					SELECT @PUIdList = ''
				END
			END
		END
		ELSE
		BEGIN
			INSERT	#TempProdUnits (
						PU_Id		)
			SELECT   PU_ID 
			FROM		PROD_UNITS
			WHERE		PU_ID !=0
		END
		
		SELECT @SQLStatement = 	' SELECT SU.PU_Id AS PU_Id,  MU.PU_DESC AS MASTER_DESC, SU.PU_DESC AS SLAVE_DESC ' +
										' FROM #TempProdUnits TPU JOIN PROD_UNITS SU ON TPU.PU_ID  = SU.PU_ID ' +
										' JOIN PROD_UNITS MU ON SU.MASTER_UNIT = MU.PU_ID ' +
										' JOIN PROD_EVENTS PE ON PE.PU_ID = SU.PU_ID AND PE.EVENT_TYPE = "' + CONVERT(VARCHAR(10), @EventTypeId) + '"' 

	END
	


	
	PRINT @SQLStatement
	
	EXECUTE (@SQLStatement)
	
	IF @@ERROR !=0 	
	BEGIN	
		SELECT @ErrorCode = @@ERROR
		SELECT @ERRORMESSAGE = 'Error in stored procedure spRS_FilterLocation  WHILE EXECUTING QUERY "' + @SQLStatement + '"'
		GOTO CLEAN_AND_EXIT
	END
	
CLEAN_AND_EXIT:
	
	DROP TABLE #TempProdUnits
	DROP TABLE #TempMasterUnits
	
	RETURN @ErrorCode
			





