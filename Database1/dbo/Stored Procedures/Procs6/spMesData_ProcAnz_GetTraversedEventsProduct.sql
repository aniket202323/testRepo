
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetTraversedEventsProduct]
     @event_id						int = NULL
    ,@startTime                     Datetime = NULL
    ,@endTime						Datetime = NULL
    ,@NextOrPrevious                nvarchar(10) = NULL ---- 'Current', 'Current', 'Next'
	,@isIncremental					int = 0
AS
BEGIN
		IF NOT EXISTS(Select 1 from dbo.Events WITH(NOLOCK) WHERE Event_Id = @event_id)
		BEGIN
			SELECT Error = 'ERROR: No Valid Event Found', Code = 'InvalidData', ErrorType = 'ValidEventNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		DECLARE @ConvertedST DateTime, @ConvertedET DateTime , @DbTZ nvarchar(200), @UnitId int
		SET @UnitId = (SELECT E.PU_ID FROM dbo.Events E WHERE E.Event_Id = @event_id)
		SET @isIncremental = ISNULL(@isIncremental, 0)
		SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192
		SET @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startTime, 'UTC')
		SET @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endTime, 'UTC')
       
		DECLARE @tempEventsId TABLE (
			Previous_Id int
			,Current_Id int
			,Next_Id int
		)

		DECLARE @tempEventsNameValue TABLE (
			ColValue nVARCHAR(50)
			,Event_Id int
		)
       
        DECLARE @tempEvents TABLE (
            Id int
			,Department int
			,Department_Description nVARCHAR(255)
            ,Line int
            ,Line_Description nVARCHAR(255)
            ,Unit int
            ,Unit_Description nVARCHAR(255)
            ,Product_Id int
            ,Product_Description nVARCHAR(255)
            ,Production_Start_Time datetime
            ,Production_End_Time datetime
			,ProductionUTCTimeStamp datetime
            ,Production_Status nVARCHAR(100)
            ,Event_Id int
            ,Event_Name nVARCHAR(100)
            ,Event_Start_Time datetime
            ,Event_End_Time datetime
			,EventUTCTimeStamp datetime
            ,IsAppliedProduct int
			,ProductionRepeat int
			,Flag int NULL
			,IsAppliedProductrepeate int
        )

		IF(@startTime IS NOT NULL AND @endTime IS NOT NULL)
		BEGIN
			GOTO TimeBased
		END
		ELSE IF(@NextOrPrevious IS NOT NULL)
		BEGIN
			GOTO NextOrPrevious
		END
		ELSE
		BEGIN
			SELECT Error = 'ERROR: Invalid Input Parameter', Code = 'InvalidParameter', ErrorType = 'InvalidInputParameter', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		NextOrPrevious:  

		INSERT INTO @tempEventsId
			SELECT * FROM (
				SELECT LAG(E.Event_Id) OVER(PARTITION BY E.PU_Id ORDER BY E.TimeStamp) PrevEvent
				,E.Event_Id Event_Id
				,LEAD(E.Event_Id) OVER(PARTITION BY E.PU_Id ORDER BY E.TimeStamp) NextEvent
			FROM 
				dbo.Events  E WITH(NOLOCK) 
			WHERE 
				E.PU_Id = @UnitId) AS A
		WHERE 
			A.Event_Id = @event_id

		INSERT INTO @tempEventsNameValue
		SELECT 'Previous' AS Name, Previous_Id AS Event_Id FROM @tempEventsId 
		UNION ALL
		SELECT 'Current' AS Name, Current_Id AS Event_Id FROM @tempEventsId	
		UNION ALL
		SELECT 'Next' AS Name, Next_Id AS Event_Id from @tempEventsId

        ------Select next, previous and current batch order by event End_Time i.e. timestamp 
		;WITH CTE AS (
			SELECT 
				Id = ROW_NUMBER() OVER(ORDER BY E.Timestamp)
				,Department = D.Dept_Id
				,Department_Description = D.Dept_Desc
				,Line = L.PL_Id
				,Line_Description = L.PL_Desc
				,Unit = U.PU_Id
				,Unit_Description = U.PU_Desc
				,Product = ISNULL(E.Applied_Product, P.Prod_Id)
				,Product_Description = CASE WHEN E.Applied_Product IS NULL THEN P.Prod_Desc ELSE '**' + P.Prod_Desc + '**' END
				,Production_Start_Time = CASE WHEN E.Applied_Product IS NULL 
										 THEN S.Start_Time 
										 ELSE COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp) END
				,Production_End_Time = CASE WHEN E.Applied_Product IS NULL 
									   THEN ISNULL(S.End_Time, GETDATE()) ELSE E.Timestamp END
				,ProductionUTCTimeStamp = CASE WHEN E.Applied_Product IS NULL 
									   THEN ISNULL(S.End_Time, GETDATE()) ELSE E.Timestamp END
				,Production_Status = PS.ProdStatus_Desc
				,Event_Id = E.Event_Id
				,Event_Name = E.Event_Num
				,Event_Start_Time = COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp)
				,Event_End_Time = E.Timestamp
				,EventUTCTimeStamp = E.Timestamp
		 		,IsAppliedProduct = CASE WHEN E.Applied_Product IS NULL THEN 0 ELSE 1 END
				,ProductionRepeat = ROW_NUMBER() OVER(PARTITION BY ISNULL(E.Applied_Product, P.Prod_Id)
								,CASE WHEN E.Applied_Product IS NULL THEN S.Start_Time ELSE ISNULL(E.Start_Time, E.TimeStamp) END
								,CASE WHEN E.Applied_Product IS NULL THEN ISNULL(S.End_Time, GETDATE()) ELSE E.TimeStamp END
								,E.Applied_Product ORDER BY E.PU_Id, E.Timestamp)
				,Flag = NULL
				,IsAppliedProductrepeate = CASE WHEN E.Applied_Product IS NOT NULL THEN
				ROW_NUMBER() OVER(PARTITION BY  E.Event_Id, E.TimeStamp ORDER BY E.PU_Id, E.Timestamp) ELSE 1 END
			FROM 
				dbo.Events                          E  WITH(NOLOCK)
				JOIN dbo.Prod_Units                 U  WITH(NOLOCK) ON E.Pu_Id = U.Pu_Id
				JOIN dbo.Prod_Lines_Base			L  WITH(NOLOCK) ON U.PL_Id = L.PL_Id
				 JOIN dbo.Departments_Base			D  WITH(NOLOCK) ON L.Dept_Id = D.Dept_Id
				JOIN dbo.Production_Status			PS WITH(NOLOCK) ON E.Event_Status = PS.ProdStatus_Id
				JOIN Production_Starts				S  WITH(NOLOCK) ON S.PU_Id = E.PU_Id
				JOIN dbo.products					P  WITH(NOLOCK) ON ISNULL(E.Applied_Product, S.Prod_Id) = P.Prod_Id
				LEFT JOIN dbo.Event_Details			ED WITH(NOLOCK) ON E.Event_Id = ED.Event_Id
			WHERE 
				E.Event_Id IN ((SELECT Event_Id FROM @tempEventsNameValue)) 
				AND E.PU_Id = @UnitId
				AND S.Start_Time <= E.TimeStamp 
				AND (S.End_time > ISNULL(E.Start_Time, E.TimeStamp) OR S.End_time IS NULL)
		)
		INSERT INTO @tempEvents
		SELECT * FROM CTE 
		WHERE IsAppliedProductrepeate = 1
		ORDER BY Unit, Production_Start_Time, Production_End_Time ASC

		IF NOT EXISTS(SELECT 1 FROM @tempEvents TE LEFT JOIN @tempEventsNameValue TENV ON TE.Event_Id = TENV.Event_Id WHERE TENV.ColValue = @NextOrPrevious)
		BEGIN
			SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
		ELSE
		BEGIN
			SELECT 
				TE.Id
				,TE.Department
				,TE.Department_Description
				,TE.Line
				,TE.Line_Description
				,TE.Unit
				,TE.Unit_Description
				,TE.Product_Id
				,TE.Product_Description
				,Production_Start_Time = dbo.fnServer_CmnConvertTime(TE.Production_Start_Time, @DbTZ, 'UTC')
				,Production_End_Time = dbo.fnServer_CmnConvertTime(TE.Production_End_Time, @DbTZ, 'UTC')
				,ProductionUTCTimeStamp = dbo.fnServer_CmnConvertTime(TE.ProductionUTCTimeStamp, @DbTZ, 'UTC')
				,TE.Production_Status
				,TE.Event_Id
				,TE.Event_Name
				,Event_Start_Time = dbo.fnServer_CmnConvertTime(TE.Event_Start_Time, @DbTZ, 'UTC')
				,Event_End_Time = dbo.fnServer_CmnConvertTime(TE.Event_End_Time, @DbTZ, 'UTC')
				,EventUTCTimeStamp = dbo.fnServer_CmnConvertTime(TE.EventUTCTimeStamp, @DbTZ, 'UTC')
				,TE.IsAppliedProduct
				,TENV.ColValue 
			FROM 
				@tempEvents TE
				JOIN @tempEventsNameValue TENV ON TE.Event_Id = TENV.Event_Id 
			WHERE 
				TENV.ColValue = @NextOrPrevious
			RETURN
		END

		TimeBased:

		;WITH CTE AS (
			SELECT 
				Id = ROW_NUMBER() OVER(ORDER BY E.Timestamp)
				,Department = D.Dept_Id
				,Department_Description = D.Dept_Desc
				,Line = L.PL_Id
				,Line_Description = L.PL_Desc
				,Unit = U.PU_Id
				,Unit_Description = U.PU_Desc
				,Product = ISNULL(E.Applied_Product, P.Prod_Id)
				,Product_Description = CASE WHEN E.Applied_Product IS NULL THEN P.Prod_Desc ELSE '**' + P.Prod_Desc + '**' END
				,Production_Start_Time = CASE WHEN E.Applied_Product IS NULL 
										 THEN S.Start_Time 
										 ELSE COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp) END
				,Production_End_Time = CASE WHEN E.Applied_Product IS NULL 
									   THEN ISNULL(S.End_Time, GETDATE()) ELSE E.Timestamp END
				,ProductionUTCTimeStamp = CASE WHEN E.Applied_Product IS NULL 
									   THEN ISNULL(S.End_Time, GETDATE()) ELSE E.Timestamp END
				,Production_Status = PS.ProdStatus_Desc
				,Event_Id = E.Event_Id
				,Event_Name = E.Event_Num
				,Event_Start_Time = COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp)
				,Event_End_Time = E.Timestamp
				,EventUTCTimeStamp = E.Timestamp
           		,IsAppliedProduct = CASE WHEN E.Applied_Product IS NULL THEN 0 ELSE 1 END
				,ProductionRepeat = ROW_NUMBER() OVER(PARTITION BY ISNULL(E.Applied_Product, P.Prod_Id)
								,CASE WHEN E.Applied_Product IS NULL THEN S.Start_Time ELSE ISNULL(E.Start_Time, E.TimeStamp) END
								,CASE WHEN E.Applied_Product IS NULL THEN ISNULL(S.End_Time, GETDATE()) ELSE E.TimeStamp END
								,E.Applied_Product ORDER BY E.PU_Id, E.Timestamp)
				,Flag = NULL
				,IsAppliedProductrepeate = CASE WHEN E.Applied_Product IS NOT NULL THEN
				ROW_NUMBER() OVER(PARTITION BY  E.Event_Id, E.TimeStamp ORDER BY E.PU_Id, E.Timestamp) ELSE 1 END
			FROM 
				dbo.Events                          E  WITH(NOLOCK)
				JOIN dbo.Prod_Units                 U  WITH(NOLOCK) ON E.Pu_Id = U.Pu_Id
				JOIN dbo.Prod_Lines_Base			L  WITH(NOLOCK) ON U.PL_Id = L.PL_Id
				JOIN dbo.Departments_Base			D  WITH(NOLOCK) ON L.Dept_Id = D.Dept_Id
				JOIN dbo.Production_Status			PS WITH(NOLOCK) ON E.Event_Status = PS.ProdStatus_Id
				JOIN Production_Starts				S  WITH(NOLOCK) ON S.PU_Id = E.PU_Id
				JOIN dbo.products					P  WITH(NOLOCK) ON ISNULL(E.Applied_Product, S.Prod_Id) = P.Prod_Id
				LEFT JOIN dbo.Event_Details			ED WITH(NOLOCK) ON E.Event_Id = ED.Event_Id
			WHERE 
			   E.Pu_Id = @UnitId
				AND (E.TimeStamp BETWEEN @ConvertedST AND @ConvertedET
				AND E.Start_Time BETWEEN @ConvertedST AND @ConvertedET
				AND @ConvertedST <= E.TimeStamp  AND @ConvertedET >= E.Start_Time)
				AND S.Start_Time <= E.TimeStamp 
				AND (S.End_time > ISNULL(E.Start_Time,E.Timestamp) OR S.End_Time IS NULL)
			)
			INSERT INTO @tempEvents
			SELECT * FROM CTE 
			WHERE IsAppliedProductrepeate = 1
			ORDER BY Unit, Event_End_Time, Production_Start_Time ASC

			IF NOT EXISTS(SELECT 1 FROM @tempEvents)
			BEGIN
				SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN
			END
			ELSE
			BEGIN

			;WITH CTE AS (SELECT id, ROW_NUMBER() OVER (ORDER BY Event_End_Time, Production_Start_Time, Production_End_Time ASC) AS RN FROM @tempEvents)
			UPDATE CTE SET id = RN
			
			/* Calculation for adjusting the start_time and end_time, when there is any applied product */
			IF EXISTS(SELECT 1 FROM @tempEvents WHERE IsAppliedProduct = 1)
			BEGIN
				DECLARE @AppliedProduct Table (Id int, StartTime dateTime, EndTime dateTime, IsAppliedProduct int)
			
				INSERT INTO @AppliedProduct
				SELECT Id, Production_Start_Time, Production_End_Time, IsAppliedProduct FROM @tempEvents WHERE IsAppliedProduct = 1

				UPDATE TE SET TE.Production_End_Time = T.StartTime, Flag = 1 FROM @tempEvents TE JOIN @AppliedProduct T ON T.Id - 1 = TE.Id WHERE TE.Production_End_Time > T.StartTime AND TE.IsAppliedProduct = 0;
				UPDATE TE SET TE.Production_Start_Time = T.EndTime, Flag = 1 FROM @tempEvents TE JOIN @AppliedProduct T ON T.Id + 1 = TE.Id WHERE TE.Production_Start_Time < T.EndTime AND TE.IsAppliedProduct = 0;
			END

			/* After adjusting the start time and end time of the row which where lies before and after applied product, 
			delete the duplicate rows with having same product, production start time and production end time, as there is chance that, 
			two different event having same production start time. */
			DELETE FROM @tempEvents WHERE ProductionRepeat > 1 AND Flag IS NULL

			/* Update the sequence number properly after deletion of duplicate row */
			;WITH CTE AS (SELECT id, ROW_NUMBER() OVER (ORDER BY Event_End_Time ASC) AS RN FROM @tempEvents)
			UPDATE CTE SET id = RN

			/* Delete the remaining duplicate rows which were having same production start and product */
			DELETE T1 FROM @tempEvents T1
			JOIN @tempEvents T2 ON T1.Product_Id = T2.Product_Id AND T1.Production_Start_Time = T2.Production_Start_Time
			WHERE T1.Id = T2.Id - 1	AND T1.ProductionRepeat = 1 AND T1.Flag IS NULL

			/* Update the sequence number properly after deletion of row */
			;WITH CTE AS(SELECT id,	ROW_NUMBER() OVER (ORDER BY Event_End_Time, Production_Start_Time, Production_End_Time) AS RN	FROM @tempEvents)
			UPDATE CTE SET id = RN
			
			SELECT 
				TE.Id
				,TE.Department
				,TE.Department_Description
				,TE.Line
				,TE.Line_Description
				,TE.Unit
				,TE.Unit_Description
				,TE.Product_Id
				,TE.Product_Description
				,Production_Start_Time = dbo.fnServer_CmnConvertTime(TE.Production_Start_Time, @DbTZ, 'UTC')
				,Production_End_Time = dbo.fnServer_CmnConvertTime(TE.Production_End_Time, @DbTZ, 'UTC')
				,ProductionUTCTimeStamp = dbo.fnServer_CmnConvertTime(TE.ProductionUTCTimeStamp, @DbTZ, 'UTC')
				,TE.Production_Status
				,TE.Event_Id
				,TE.Event_Name
				,Event_Start_Time = dbo.fnServer_CmnConvertTime(TE.Event_Start_Time, @DbTZ, 'UTC')
				,Event_End_Time = dbo.fnServer_CmnConvertTime(TE.Event_End_Time, @DbTZ, 'UTC')
				,EventUTCTimeStamp = dbo.fnServer_CmnConvertTime(TE.EventUTCTimeStamp, @DbTZ, 'UTC')
				,TE.IsAppliedProduct
				,NULL AS ColValue 
			FROM 
				@tempEvents TE 
			ORDER BY 
				TE.Unit, TE.Event_End_Time, TE.Production_Start_Time, TE.Production_End_Time
			RETURN
		END
END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetTraversedEventsProduct] TO [ComXClient]