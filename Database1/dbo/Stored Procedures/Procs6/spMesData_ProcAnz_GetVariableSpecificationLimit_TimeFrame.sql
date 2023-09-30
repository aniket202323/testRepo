
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetVariableSpecificationLimit_TimeFrame]
        @varId					int = NULL
       ,@startDate              Datetime = NULL
       ,@endDate                Datetime = NULL
	   ,@isLive					bit =0
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

		DECLARE @ProductionStarts TABLE(
			Id int
			,ProductId int
			,Prod_desc nVARCHAR(255)
			,StartTime datetime
			,EndTime datetime
			,EventId int
			,EventStartTime datetime
			,EventEndTime datetime
			,IsAppliedProduct int
			,ProductionRepeat int
			,flag int
			,IsAppliedProductrepeate int
		)

		DECLARE @VariableSpec Table(
			Id int Identity
			,VarId int
			,ProductId int
			,LReject nVARCHAR(25)
			,LWarning nVARCHAR(25)
			,UReject nVARCHAR(25)
			,UWarning nVARCHAR(25)
			,LUser nVARCHAR(25)
			,UpperUser nVARCHAR(25)
			,UEntry nVARCHAR(25)
			,LEntry nVARCHAR(25)
			,[Target] nVARCHAR(25)
			,TControl nVARCHAR(25)
			,UControl nVARCHAR(25)
			,LControl nVARCHAR(25)
			,ProStartDate dateTime
			,VarEffectiveDate dateTime
			,VarExpDate dateTime
			,ProductionEndTime dateTime
			,ProdDesc nVARCHAR(50)
			,RowNumber int
		)

		DECLARE @VariableSpec2 Table(
			Id int
			,VarId int
			,ProductId int
			,LReject nVARCHAR(25)
			,LWarning nVARCHAR(25)
			,UReject nVARCHAR(25)
			,UWarning nVARCHAR(25)
			,LUser nVARCHAR(25)
			,UpperUser nVARCHAR(25)
			,UEntry nVARCHAR(25)
			,LEntry nVARCHAR(25)
			,[Target]  nVARCHAR(25)
			,TControl nVARCHAR(25)
			,UControl nVARCHAR(25)
			,LControl nVARCHAR(25)
			,StartDate dateTime
			,ProductionEndTime datetime
			,ProdDesc nVARCHAR(50)
			,RowNumber int
		)

		DECLARE @CountProductionStarts Int, @PUId Int, @ConvertedST DateTime, @ConvertedET DateTime, @DbTZ nvarchar(200), @LastEventTimestamp DateTime

		SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startDate, 'UTC')
		SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endDate, 'UTC')
		SELECT @DbTZ = value from site_parameters where parm_id = 192
		SELECT @PUId = PU_Id From Variables Where Var_Id = @varId
		SELECT @PUId = ISNULL(Master_Unit, PU_Id) From Prod_Units_Base Where PU_Id = @PUId

		SELECT TOP 1 
			@LastEventTimestamp = MIN(TimeStamp)
		FROM 
			dbo.Departments_Base            D  WITH(NOLOCK)
			JOIN dbo.Prod_Lines_Base        L  WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
			JOIN dbo.Prod_Units_Base        U  WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
			JOIN dbo.Events                 E  WITH(NOLOCK)  ON U.PU_Id = E.PU_Id 
		WHERE  
			U.PU_Id = @PUId
			AND E.TimeStamp >= @ConvertedET
    
		/* Identify production changes (here event is in consideration because of applied product) */
		;WITH CTE AS (
			SELECT 
				Id = ROW_NUMBER() OVER(ORDER BY E.Timestamp)
				,Product = ISNULL(E.Applied_Product, PS.Prod_Id)
				,Product_Description = CASE WHEN E.Applied_Product IS NULL THEN P.Prod_Desc ELSE '**' + P.Prod_Desc + '**' END
				,StartTime = CASE WHEN E.Applied_Product IS NULL 
								  THEN PS.Start_Time
								  ELSE COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp) END
				,EndTime = CASE WHEN E.Applied_Product IS NULL 
								THEN ISNULL(PS.End_Time, GETDATE())
								ELSE E.Timestamp END
				,EventId = E.Event_id
				,EventStartTime = COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp)
				,EventEndTime = E.TimeStamp
				,IsAppliedProduct = CASE WHEN E.Applied_Product IS NULL THEN 0 ELSE 1 END
				,ProductionRepeat = ROW_NUMBER() OVER(PARTITION BY ISNULL(E.Applied_Product, PS.Prod_Id), 
				CASE WHEN E.Applied_Product IS NULL THEN PS.Start_Time ELSE ISNULL(E.Start_Time, E.TimeStamp)  END
			   ,CASE WHEN E.Applied_Product IS NULL THEN ISNULL(PS.End_Time, GETDATE()) ELSE E.TimeStamp END, E.Applied_Product ORDER BY E.PU_Id, E.Timestamp, PS.Start_Time)
			   ,flag = NULL
			   ,IsAppliedProductrepeate = CASE WHEN E.Applied_Product IS NOT NULL THEN
			   ROW_NUMBER() OVER(PARTITION BY  E.Event_Id, E.TimeStamp ORDER BY E.PU_Id, E.Timestamp, PS.Start_Time) ELSE 1 END
			FROM 
				dbo.Events							E  WITH(NOLOCK)
				JOIN dbo.Production_Starts			PS WITH(NOLOCK) ON E.PU_Id = PS.PU_Id 
				JOIN dbo.Products_Base				P  WITH(NOLOCK) ON ISNULL(E.Applied_Product, PS.Prod_Id) = P.Prod_Id
			WHERE 
			    E.TimeStamp BETWEEN @ConvertedST AND ISNULL(@LastEventTimestamp, @ConvertedET)
				AND E.PU_Id = @PUId
				AND PS.Start_Time <= E.TimeStamp 
				AND (PS.End_time > ISNULL(E.Start_Time, E.TimeStamp) OR PS.End_Time IS NULL)
			)
			INSERT INTO @ProductionStarts
			SELECT * FROM CTE 
			WHERE IsAppliedProductrepeate = 1
			ORDER BY EventEndTime, StartTime ASC

		IF(@isLive = 1 AND NOT EXISTS(SELECT 1 FROM @ProductionStarts))
		BEGIN 
			;WITH CTE AS (
				SELECT 
				Id = ROW_NUMBER() OVER(ORDER BY PS.Start_Time)
				,Product = PS.Prod_Id
				,Product_Description =  P.Prod_Desc
				,StartTime = PS.Start_Time
				,EndTime = ISNULL(PS.End_Time, @ConvertedET)
				,EventId = NULL
				,EventStartTime = NULL
				,EventEndTime = NULL
				,IsAppliedProduct = NULL
				,ProductionRepeat = NULL
			    ,flag = NULL
			   ,IsAppliedProductrepeate = NULL
			FROM 
				dbo.Production_Starts			PS WITH(NOLOCK)
				JOIN dbo.Products_Base			P WITH(NOLOCK) ON PS.Prod_Id = P.Prod_Id
			WHERE 
				PS.PU_Id = @PUId
				AND (PS.Start_Time <= @ConvertedET
				AND (PS.End_time > @ConvertedST OR PS.End_Time IS NULL))
			)
			INSERT INTO @ProductionStarts
			SELECT * FROM CTE 
			ORDER BY EventEndTime, StartTime ASC
		END

		IF NOT EXISTS(SELECT 1 FROM @ProductionStarts)
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		;WITH CTE AS (SELECT id, ROW_NUMBER() OVER (ORDER BY EventEndTime, StartTime, EndTime ASC) AS RN FROM @ProductionStarts)
		UPDATE CTE SET id = RN

		/* Calculation for adjusting the start_time and end_time, when there is any applied product */
		IF EXISTS(SELECT 1 FROM @ProductionStarts WHERE IsAppliedProduct = 1)
		BEGIN
			DECLARE @AppliedProduct Table (Id int, StartTime dateTime, EndTime dateTime, IsAppliedProduct int)
			
			INSERT INTO @AppliedProduct
			SELECT Id, StartTime, EndTime, IsAppliedProduct FROM @ProductionStarts WHERE IsAppliedProduct = 1

			UPDATE PS SET PS.EndTime = T.StartTime, flag = 1 FROM @ProductionStarts PS JOIN @AppliedProduct T ON T.Id - 1 = PS.Id WHERE PS.EndTime > T.StartTime AND PS.IsAppliedProduct = 0;
			UPDATE PS SET PS.StartTime = T.EndTime, flag = 1 FROM @ProductionStarts PS JOIN @AppliedProduct T ON T.Id + 1 = PS.Id WHERE PS.StartTime < T.EndTime AND PS.IsAppliedProduct = 0;
		END
		
		/* After adjusting the start time and end time of the row which where lies before and after applied product, 
		delete the duplicate rows with having same product, production start time and production end time, as there is chance that, 
		two different event having same production start time. */
		DELETE FROM @ProductionStarts WHERE ProductionRepeat > 1 AND flag IS NULL

		/* Update the sequence number properly after deletion of duplicate row */
		;WITH CTE AS (SELECT id, ROW_NUMBER() OVER (ORDER BY EventEndTime, StartTime, EndTime ASC) AS RN FROM @ProductionStarts)
		UPDATE CTE SET id = RN

		/* Delete the remaining duplicate rows which were having same production start and product */
		DELETE T1 FROM @ProductionStarts T1
		JOIN @ProductionStarts T2 ON T1.ProductId = T2.ProductId AND T1.StartTime = T2.StartTime
		WHERE T1.Id = T2.Id - 1	AND T1.ProductionRepeat = 1 AND T1.flag IS NULL

		/* to plot the value update time if greater than endtime  */
		--UPDATE PS SET PS.EndTime = @ConvertedET FROM @ProductionStarts PS WHERE PS.EndTime > @ConvertedET

		/* Update the sequence number properly after deletion of row */
		;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY EventEndTime, StartTime, EndTime) AS RN	FROM @ProductionStarts)
		UPDATE CTE SET id = RN

		IF EXISTS (SELECT 1 FROM @ProductionStarts)
		BEGIN
			DECLARE @Start int = 0, @End int
			SET @End = (SELECT COUNT(*) FROM @ProductionStarts)
			WHILE @Start < @End
			BEGIN
				SET @Start = @Start + 1
				/* If variable specification limit exists for the product, then get all during it's production time 
				Else insert the product production information into a table variable @VariableSpec */
				IF EXISTS(SELECT 1 FROM @ProductionStarts PS 
						JOIN Var_Specs VS WITH(NOLOCK) ON PS.ProductId = VS.Prod_Id AND VS.Var_Id = @varId
						WHERE (VS.Effective_Date <= PS.EndTime)	AND (VS.Expiration_Date >= PS.StartTime OR VS.Expiration_Date IS NULL)
						AND PS.Id = @Start)
				BEGIN
					INSERT INTO @VariableSpec
					SELECT 
						VarId = VS.Var_Id
						,ProductId = VS.Prod_Id  
						,LReject = VS.L_Reject
						,LWarning = VS.L_Warning
						,UReject = VS.U_Reject
						,UWarning = VS.U_Warning
						,LUser =VS.L_User
						,UpperUser =VS.U_User
						,UEntry = VS.U_Entry
						,LEntry = VS.L_Entry
						,[Target] = VS.Target
						,TControl = VS.T_Control
						,UControl = VS.U_Control
						,LControl =  VS.L_Control
						,ProStartDate = PS.StartTime
						,VarEffectiveDate = VS.Effective_Date
						,VarExpDate = VS.Expiration_Date
						,ProductionEndTime = PS.EndTime
						,ProdDesc = PS.Prod_desc
						,RowNumber = ROW_NUMBER() OVER(PARTITION BY VS.Prod_Id ORDER BY PS.StartTime) 
					FROM 
						@ProductionStarts PS 
						JOIN Var_Specs VS                WITH(NOLOCK) ON PS.ProductId = VS.Prod_Id 
						AND VS.Var_Id = @varId
					WHERE 
						(VS.Effective_Date <= PS.EndTime)
						AND (VS.Expiration_Date >= PS.StartTime OR VS.Expiration_Date IS NULL)
						AND PS.Id = @Start
				END
				ELSE
				BEGIN 
					INSERT INTO @VariableSpec
					SELECT 
						VarId = @varId
						,ProductId = PS.ProductId 
						,LReject = NULL
						,LWarning = NULL
						,UReject = NULL
						,UWarning = NULL
						,LUser =NULL
						,UpperUser =NULL
						,UEntry =NULL
						,LEntry =NULL
						,[Target] = NULL
						,TControl = NULL
						,UControl = NULL
						,LControl =  NULL
						,ProStartDate = PS.StartTime
						,VarEffectiveDate = NULL
						,VarExpDate = NULL
						,ProductionEndTime = PS.EndTime
						,ProdDesc = PS.Prod_desc
						,RowNumber =  1
					FROM 
						@ProductionStarts PS 
					WHERE 
						PS.Id = @Start
				END
			END

			/* If there is any variable specification change in between production is continued */
			UPDATE VS SET VS.ProStartDate = VS.VarEffectiveDate From @VariableSpec VS WHERE VS.RowNumber > 1
			UPDATE VS SET VS.ProductionEndTime = VS.VarExpDate From @VariableSpec VS WHERE VS.VarExpDate < VS.ProductionEndTime

			/* As UI needs data within the time range to plot into a chart area and record from data base is different. The following calculation is happing:
				1.	Select the variable specification which is inside the input parameter time range 
				2.	Insert a row at 1st and last position based on the current 1st and last position data with input parameter start_time and end_time 
			*/
			INSERT INTO @VariableSpec
			SELECT 
				VarId 
				,ProductId 
				,LReject
				,LWarning 
				,UReject 
				,UWarning
				,LUser 
				,UpperUser 
				,UEntry 
				,LEntry 
				,[Target]
				,TControl
				,UControl
				,LControl
				,ProStartDate = ProductionEndTime
				,VarEffectiveDate 
				,VarExpDate 
				,ProductionEndTime 
				,ProdDesc 
				,RowNumber
			FROM @VariableSpec
		
			;WITH CTE AS (
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
					,TControl = ISNULL([TControl], '')
					,UControl = ISNULL([UControl], '')
					,LControl = ISNULL([LControl], '')
					,StartDate = ProStartDate
					,ProductionEndTime = ProductionEndTime
					,ProdDesc
					,RowNumber 
				FROM @VariableSpec WHERE ProStartDate > @ConvertedST AND  ProStartDate < @ConvertedET
			)
			INSERT INTO @VariableSpec2 
			SELECT * FROM CTE 

			/* The condition is:
			1.	If the records are outside the input parameter time range, or on the time range: update the 1st and last record and return
			2.	If the records is inside the input parameter time range
			*/
			IF EXISTS(SELECT 1 FROM @VariableSpec) AND NOT EXISTS(SELECT 1 FROM @VariableSpec2)
			BEGIN 
				DECLARE @ProdId int
				SELECT @ProdId = ProductId FROM @ProductionStarts WHERE @ConvertedST BETWEEN  StartTime AND EndTime 
				 AND @ConvertedET BETWEEN  StartTime AND EndTime

				/* Insert a record at last position */
				INSERT INTO @VariableSpec2 
				SELECT TOP 1 Id, VarId, ProductId, LReject, LWarning
				,UReject, UWarning
				
				,LUser 
				,UpperUser 
				,UEntry 
				,LEntry
				,[Target]
				,TControl
				,UControl
				,LControl
				, DATEADD(SECOND, -1, @ConvertedET), DATEADD(SECOND, -1, @ConvertedET)
				,ProdDesc, RowNumber
				FROM @VariableSpec WHERE ProStartDate >= @ConvertedET AND ProductId = @ProdId ORDER BY ProStartDate, ProductionEndTime

				/* Insert a record at 1st position */
				INSERT INTO @VariableSpec2 
				SELECT TOP 1 Id, VarId, ProductId, LReject, LWarning
				,UReject, UWarning,LUser 
				,UpperUser 
				,UEntry 
				,LEntry
				,[Target]
				,TControl
				,UControl
				,LControl
				,DATEADD(SECOND, +1, @ConvertedST) , DATEADD(SECOND, +1, @ConvertedST) 
				,ProdDesc, RowNumber
				FROM @VariableSpec WHERE ProStartDate >= @ConvertedET AND ProductId = @ProdId ORDER BY ProStartDate, ProductionEndTime

				/* Update sequence number properly */
				;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY StartDate, ProductionEndTime) AS RN	FROM @VariableSpec2)
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
					,TControl = ISNULL([TControl], '')
					,UControl = ISNULL([UControl], '')
					,LControl = ISNULL([LControl], '')
					,StartDate = dbo.fnServer_CmnConvertTime(StartDate, @DbTZ,'UTC')
					,ProdDesc
					,RowNumber 
				FROM @VariableSpec2 ORDER BY StartDate, ProductionEndTime 

				RETURN
			END
		
			/* Update sequence number properly */
			;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY StartDate, ProductionEndTime) AS RN	FROM @VariableSpec2)
			UPDATE CTE SET id = RN

			/* Insert a record at last position */
			IF EXISTS(SELECT 1 FROM @VariableSpec WHERE ProStartDate > @ConvertedET)
			BEGIN
				INSERT INTO @VariableSpec2 
				SELECT Id, VarId, ProductId, LReject, LWarning
				,UReject, 
				UWarning,
				LUser 
				,UpperUser 
				,UEntry 
				,LEntry
				,[Target]
				,TControl
				,UControl
				,LControl
				,DATEADD(SECOND, -1, @ConvertedET), DATEADD(SECOND, -1, @ConvertedET)
				,ProdDesc, RowNumber
				FROM @VariableSpec2 WHERE Id = (SELECT MAX(ID) FROM @VariableSpec2)
			END
				
			/* Insert a record at 1st position */
			IF EXISTS(SELECT 1 FROM @VariableSpec WHERE ProStartDate < @ConvertedST)
			BEGIN
				INSERT INTO @VariableSpec2 
				SELECT Id, VarId, ProductId, LReject, LWarning
				,UReject, UWarning,LUser 
				,UpperUser 
				,UEntry 
				,LEntry
				,[Target]
				,TControl
				,UControl
				,LControl
				,DATEADD(SECOND, +1, @ConvertedST) , DATEADD(SECOND, +1, @ConvertedST) 
				,ProdDesc, RowNumber
				FROM @VariableSpec2 WHERE Id = 1
			END

			/* Update sequence number properly */
			;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY StartDate, ProductionEndTime) AS RN	FROM @VariableSpec2)
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
				,TControl = ISNULL([TControl], '')
				,UControl = ISNULL([UControl], '')
				,LControl = ISNULL([LControl], '')
				,StartDate = dbo.fnServer_CmnConvertTime(StartDate, @DbTZ,'UTC')
				,ProdDesc
				,RowNumber 
			FROM @VariableSpec2 ORDER BY StartDate, ProductionEndTime 
	END
END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetVariableSpecificationLimit_TimeFrame] TO [ComXClient]