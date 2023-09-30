
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetProductionPlanVariableSpecificationLimit_TimeFrame]
        @varId					int = 43
       ,@startDate              Datetime = '2017-03-05 12:42:19.000'
       ,@endDate                Datetime = '2017-03-07 12:44:08.000'
	   ,@isLive					bit = 0
AS 
BEGIN
		SET NOCOUNT ON

		SET @isLive = ISNULL(@isLive, 0)

		IF NOT EXISTS(SELECT 1 FROM dbo.Variables_Base WHERE Var_Id = @varId)
        BEGIN
            SELECT Error = 'ERROR: No Valid Variable Found', Code = 'InvalidData', ErrorType = 'ValidVariableNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

		IF NOT EXISTS(SELECT 1 FROM dbo.Var_Specs VS WHERE Var_Id = @varId)
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		DECLARE @ProductionPlanStarts TABLE(
			Id int
			,ProductionPlanStartId int
			,ProductionPlanId int
			,ProcessOrder nVARCHAR(255)
			,ProductId int
			,Prod_desc nVARCHAR(255)
			,ProductionPlanStartTime datetime
			,ProductionPlanEndTime datetime
		)

		DECLARE @VariableSpec Table(
			Id int Identity
			,VarId int
			,VarEffectiveDate dateTime
			,VarExpDate dateTime
			,LReject nVARCHAR(25)
			,LWarning nVARCHAR(25)
			,UReject nVARCHAR(25)
			,UWarning nVARCHAR(25)
			,LUser nVARCHAR(25)
			,UpperUser nVARCHAR(25)
			,UEntry nVARCHAR(25)
			,LEntry nVARCHAR(25)
			,[Target]  nVARCHAR(25)
			,ProductId int
			,ProdDesc  nVARCHAR(50)
			,ProductionPlanStartTime dateTime
			,ProductionPlanEndTime dateTime
			,RowNumber int
		)

		DECLARE @VariableSpec2 Table(
			Id int
			,VarId int
			,LReject nVARCHAR(25)
			,LWarning nVARCHAR(25)
			,UReject nVARCHAR(25)
			,UWarning nVARCHAR(25)
			,LUser nVARCHAR(25)
			,UpperUser nVARCHAR(25)
			,UEntry nVARCHAR(25)
			,LEntry nVARCHAR(25)
			,[Target]  nVARCHAR(25)
			,ProductId int
			,ProdDesc nVARCHAR(50)
			,ProductionPlanStartTime dateTime
			,ProductionPlanEndTime dateTime
			,RowNumber int
		)

		DECLARE @CountProductionStarts Int, @PUId Int, @ConvertedST DateTime, @ConvertedET DateTime, @DbTZ nvarchar(200)

		SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startDate, 'UTC')
		SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endDate, 'UTC')
		SELECT @DbTZ = value from site_parameters where parm_id = 192
		SELECT @PUId = PU_Id From Variables Where Var_Id = @varId
		Select @PUId = ISNULL(Master_Unit,@PUId) from Prod_Units where Pu_id = @PUId 

		;WITH CTE AS (
			SELECT 
			Id = ROW_NUMBER() OVER(ORDER BY PPS.PP_Start_Id)
			,ProductionPlanStartId = PPS.PP_Start_Id
			,ProductionPlanId = PPS.PP_Id
			,ProcessOrder = PP.Process_Order
			,ProductId = PB.Prod_Id
			,Product_Description = PB.Prod_Desc
			,ProductionPlanStartTime = PPS.Start_Time
			,ProductionPlanEndTime = ISNULL(PPS.End_Time, @ConvertedET)
		FROM 
			dbo.Production_Plan_Starts		PPS WITH(NOLOCK)
			JOIN dbo.Production_Plan		PP  WITH(NOLOCK) ON PPS.PP_Id = PP.PP_Id
			JOIN dbo.Products_Base			PB  WITH(NOLOCK) ON PP.Prod_Id = PB.Prod_Id
		WHERE 
			PPS.PU_Id = @PUId
			AND (PPS.Start_Time <= @ConvertedET
			AND (PPS.End_time > @ConvertedST OR PPS.End_Time IS NULL))
		)
		INSERT INTO @ProductionPlanStarts
		SELECT * FROM CTE 
		ORDER BY ProductionPlanStartTime, ProductionPlanEndTime ASC

		IF EXISTS (SELECT 1 FROM @ProductionPlanStarts)
		BEGIN
			DECLARE @Start int = 0, @End int
			SET @End = (SELECT COUNT(*) FROM @ProductionPlanStarts)
			WHILE @Start < @End
			BEGIN
				SET @Start = @Start + 1
				/* If variable specification limit exists for the product, then get all during it's production time 
				Else insert the product production information into a table variable @VariableSpec */
				IF EXISTS(SELECT 1 FROM @ProductionPlanStarts PPS 
						JOIN Var_Specs VS WITH(NOLOCK) ON PPS.ProductId = VS.Prod_Id AND VS.Var_Id = @varId
						WHERE (VS.Effective_Date <= PPS.ProductionPlanEndTime) AND (VS.Expiration_Date >= PPS.ProductionPlanStartTime OR VS.Expiration_Date IS NULL)
						AND PPS.Id = @Start)
				BEGIN
					INSERT INTO @VariableSpec
					SELECT 
						VarId = VS.Var_Id
						,VarEffectiveDate = VS.Effective_Date
						,VarExpDate = VS.Expiration_Date
						,LReject = VS.L_Reject
						,LWarning = VS.L_Warning
						,UReject = VS.U_Reject
						,UWarning = VS.U_Warning
						,LUser =VS.L_User
						,UpperUser =VS.U_User
						,UEntry =VS.U_Entry
						,LEntry =VS.L_Entry
						,[Target] =VS.Target
						,ProductId = VS.Prod_Id  
						,ProdDesc = PPS.Prod_desc
						,ProductionPlanStartTime = PPS.ProductionPlanStartTime
						,ProductionPlanEndTime = PPS.ProductionPlanEndTime
						,RowNumber = ROW_NUMBER() OVER(PARTITION BY VS.Prod_Id ORDER BY PPS.ProductionPlanStartTime) 
					FROM 
						@ProductionPlanStarts PPS 
						JOIN Var_Specs VS                WITH(NOLOCK) ON PPS.ProductId = VS.Prod_Id 
						AND VS.Var_Id = @varId
					WHERE 
						(VS.Effective_Date <= PPS.ProductionPlanEndTime)
						AND (VS.Expiration_Date >= PPS.ProductionPlanStartTime OR VS.Expiration_Date IS NULL)
						AND PPS.Id = @Start
				END
				ELSE
				BEGIN 
					INSERT INTO @VariableSpec
					SELECT 
						VarId = @varId
						,VarEffectiveDate = NULL
						,VarExpDate = NULL
						,LReject = NULL
						,LWarning = NULL
						,UReject = NULL
						,UWarning = NULL
						,LUser =NULL
						,UpperUser =NULL
						,UEntry =NULL
						,LEntry =NULL
						,[Target] = NULL
						,ProductId = PPS.ProductId  
						,ProdDesc = PPS.Prod_desc
						,ProductionPlanStartTime = PPS.ProductionPlanStartTime
						,ProductionPlanEndTime = PPS.ProductionPlanEndTime
						,RowNumber =  1
					FROM 
						@ProductionPlanStarts PPS 
					WHERE 
						PPS.Id = @Start
				END
			END
		END

		/* If there is any variable specification change in between production is continued */
		UPDATE VS SET VS.ProductionPlanStartTime = VS.VarEffectiveDate From @VariableSpec VS WHERE VS.RowNumber > 1
		UPDATE VS SET VS.ProductionPlanEndTime = VS.VarExpDate From @VariableSpec VS WHERE VS.VarExpDate < VS.ProductionPlanEndTime

		INSERT INTO @VariableSpec
		SELECT 
			VarId
			,VarEffectiveDate 
			,VarExpDate
			,LReject
			,LWarning
			,UReject
			,UWarning
			,LUser 
			,UpperUser 
			,UEntry 
			,LEntry 
			,[Target]
			,ProductId 
			,ProdDesc
			,ProductionPlanStartTime = ProductionPlanEndTime
			,ProductionPlanEndTime
			,RowNumber
		FROM @VariableSpec

		;WITH CTE AS (
			SELECT
				Id
				,VarId
				,LReject = ISNULL(LReject, '')
				,LWarning = ISNULL(LWarning, '')
				,UReject = ISNULL(UReject, '')
				,UWarning = ISNULL(UWarning, '')
				,LUser = ISNULL(LUser, '')
				,UpperUser = ISNULL(UpperUser, '')
				,UEntry = ISNULL(UEntry, '')
				,LEntry = ISNULL(LEntry, '')
				,[Target] = ISNULL([Target], '')
				,ProductId
				,ProdDesc
				,ProductionPlanStartTime = ProductionPlanStartTime
				,ProductionPlanEndTime = ProductionPlanEndTime
				,RowNumber 
			FROM @VariableSpec WHERE ProductionPlanStartTime > @ConvertedST AND  ProductionPlanStartTime < @ConvertedET
		)
		INSERT INTO @VariableSpec2 
		SELECT * FROM CTE ORDER BY ProductionPlanStartTime, ProductionPlanEndTime


		/* The condition is:
		1.	If the records are outside the input parameter time range, or on the time range: update the 1st and last record and return
		2.	If the records is inside the input parameter time range
		*/
		IF EXISTS(SELECT 1 FROM @VariableSpec) AND NOT EXISTS(SELECT 1 FROM @VariableSpec2)
		BEGIN 
			DECLARE @ProdId int
			SELECT @ProdId = ProductId FROM @ProductionPlanStarts WHERE @ConvertedST BETWEEN ProductionPlanStartTime AND ProductionPlanEndTime 
				AND @ConvertedET BETWEEN  ProductionPlanStartTime AND ProductionPlanEndTime

			/* Insert a record at last position */
			INSERT INTO @VariableSpec2 
			SELECT TOP 1 Id, VarId
			,LReject, LWarning
			,UReject, UWarning
			,LUser 
			,UpperUser 
			,UEntry 
			,LEntry
			,[Target]
			,ProductId, ProdDesc
			,@ConvertedET, @ConvertedET
			,RowNumber
			FROM @VariableSpec WHERE ProductionPlanStartTime >= @ConvertedET AND ProductId = @ProdId ORDER BY ProductionPlanStartTime, ProductionPlanEndTime

			/* Insert a record at 1st position */
			INSERT INTO @VariableSpec2 
			SELECT TOP 1 Id, VarId
			,LReject, LWarning
			,UReject, UWarning,LUser 
			,UpperUser 
			,UEntry 
			,LEntry,[Target]
			,ProductId, ProdDesc
			,DATEADD(SECOND, + 1, @ConvertedST), DATEADD(SECOND, + 1, @ConvertedST) 
			,RowNumber
			FROM @VariableSpec WHERE ProductionPlanStartTime >= @ConvertedET AND ProductId = @ProdId ORDER BY ProductionPlanStartTime, ProductionPlanEndTime

			/* Update sequence number properly */
			;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY ProductionPlanStartTime, ProductionPlanEndTime) AS RN FROM @VariableSpec2)
			UPDATE CTE SET id = RN

			SELECT
				Id
				,VarId
				,ProductId
				,LReject = ISNULL(LReject, '')
				,LWarning = ISNULL(LWarning, '')
				,UReject = ISNULL(UReject, '')
				,UWarning = ISNULL(UWarning, '')
				,LUser = ISNULL(LUser, '')
				,UpperUser = ISNULL(UpperUser, '')
				,UEntry = ISNULL(UEntry, '')
				,LEntry = ISNULL(LEntry, '')
				,[Target]= ISNULL([Target], '')
				,StartDate = dbo.fnServer_CmnConvertTime(ProductionPlanStartTime, @DbTZ,'UTC')
				,ProdDesc
				,RowNumber 
			FROM @VariableSpec2 ORDER BY ProductionPlanStartTime, ProductionPlanEndTime 

			RETURN
		END
		
		/* Update sequence number properly */
		;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY ProductionPlanStartTime, ProductionPlanEndTime) AS RN	FROM @VariableSpec2)
		UPDATE CTE SET id = RN

		/* Insert a record at last position */
		IF EXISTS(SELECT 1 FROM @VariableSpec WHERE ProductionPlanStartTime > @ConvertedET)
		BEGIN
			INSERT INTO @VariableSpec2 
			SELECT Id, VarId
			,LReject, LWarning
			,UReject, UWarning,LUser 
			,UpperUser 
			,UEntry 
			,LEntry,[Target]
			,ProductId, ProdDesc
			,@ConvertedET, @ConvertedET
			,RowNumber
			FROM @VariableSpec2 WHERE Id = (SELECT MAX(ID) FROM @VariableSpec2)
		END
				
		/* Insert a record at 1st position */
		IF EXISTS(SELECT 1 FROM @VariableSpec WHERE ProductionPlanStartTime < @ConvertedST)
		BEGIN
			INSERT INTO @VariableSpec2 
			SELECT Id, VarId
			,LReject, LWarning
			,UReject, UWarning,LUser 
			,UpperUser 
			,UEntry 
			,LEntry,[Target]
			,ProductId, ProdDesc
			,@ConvertedST, @ConvertedST
			,RowNumber
			FROM @VariableSpec2 WHERE Id = 1
		END

		/* Update sequence number properly */
		;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY ProductionPlanStartTime, ProductionPlanEndTime) AS RN	FROM @VariableSpec2)
		UPDATE CTE SET id = RN

		SELECT
			Id
			,VarId
			,ProductId
			,LReject = ISNULL(LReject, '')
			,LWarning = ISNULL(LWarning, '')
			,UReject = ISNULL(UReject, '')
			,UWarning = ISNULL(UWarning, '')
			,LUser = ISNULL(LUser, '')
			,UpperUser = ISNULL(UpperUser, '')
			,UEntry = ISNULL(UEntry, '')
			,LEntry = ISNULL(LEntry, '')
			,[Target] = ISNULL([Target], '')
			,StartDate = dbo.fnServer_CmnConvertTime(ProductionPlanStartTime, @DbTZ,'UTC')
			,ProdDesc
			,RowNumber 
		FROM @VariableSpec2 ORDER BY ProductionPlanStartTime, ProductionPlanEndTime 
END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetProductionPlanVariableSpecificationLimit_TimeFrame] TO [ComXClient]