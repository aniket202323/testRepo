CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetAdjacentBatchProduct]
    @event_id						int = NULL,
    @starttime                      Datetime = NULL,
    @endtime                        Datetime = NULL,
    @isIncremental                  int = 0

AS
BEGIN
		
		SET NOCOUNT ON

        DECLARE
			@ConvertedET  DateTime,
			@DbTZ nvarchar(200),
			@InitialST DateTime,
			@UnitId int,
			@PreviousDate DateTime,
			@NextDate DateTime,
			@PreviousDateDiff int,
			@NextDateDiff int
       
        DECLARE @tempEvents TABLE (
            Id int
            ,Production_LineId int
            ,Production_LineDesc nVARCHAR(100)
            ,Production_UnitId int
            ,Production_UnitDesc nVARCHAR(100)
            ,Product_Id int
            ,Product_desc nVARCHAR(100)
            ,Production_Start_Time datetime
            ,Production_End_Time datetime
            ,Production_Status nVARCHAR(100)
            ,Event_Id int
            ,Event_Name nVARCHAR(100)
            ,Event_Start_Time datetime
            ,Event_End_Time datetime
            ,IsAppliedProduct int
			,ProductionRepeat int
			,Flag int
			,IsAppliedProductrepeate int
		)

        SET @UnitId = (SELECT E.PU_ID FROM dbo.Events E WHERE E.Event_Id = @event_id)
        SELECT @ConvertedET = (SELECT E.TimeStamp FROM dbo.Events E WITH(NOLOCK) WHERE E.Event_Id = @event_id)
        SELECT @PreviousDate = MAX(E.TimeStamp) from dbo.Events E WITH(NOLOCK) WHERE E.TimeStamp < @ConvertedET AND E.PU_Id = @UnitId   
        SELECT @NextDate = MIN(E.timestamp) from dbo.Events E WITH(NOLOCK) WHERE E.timestamp > @ConvertedET AND E.PU_Id = @UnitId
        SET @PreviousDateDiff = DATEDIFF(DAY, @ConvertedET, @PreviousDate)
        SET @NextDateDiff = DATEDIFF(DAY, @NextDate, @ConvertedET)
        SET @isIncremental = ISNULL(@isIncremental, 0)
        SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192

        ------Select next, previous and current batch order by event End_Time i.e. timestamp 
        ------Previous and next batch must be within a range of 5 days from the current batch i.e. input parameter @event_ido
        ;WITH CTE AS (
			SELECT 
				Id = ROW_NUMBER() OVER(ORDER BY E.Timestamp)
				,Production_LineId = L.PL_Id
				,Production_LineDesc = L.PL_Desc
				,Production_UnitId = U.PU_Id
				,Production_UnitDesc = U.PU_Desc
				,Product_Id = ISNULL(E.Applied_Product, P.Prod_Id)
				,Product_desc = CASE WHEN E.Applied_Product IS NULL THEN PB.Prod_Desc ELSE '**' + PB.Prod_Desc + '**' END
				,Production_Start_Time = CASE WHEN E.Applied_Product IS NULL 
								  THEN P.Start_Time
								  ELSE COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp) END
				,Production_End_Time = CASE WHEN E.Applied_Product IS NULL 
								THEN ISNULL(P.End_Time, GETDATE())
								ELSE E.Timestamp END
				,Production_Status = PS.ProdStatus_Desc
				,Event_Id = E.Event_Id
				,Event_Name = E.Event_Num
				,Event_Start_Time = COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp)
				,Event_End_Time = E.Timestamp
				,IsAppliedProduct = CASE WHEN E.Applied_Product IS NULL THEN 0 ELSE 1 END
				,ProductionRepeat = ROW_NUMBER() OVER(PARTITION BY ISNULL(E.Applied_Product, P.Prod_Id),
				CASE WHEN E.Applied_Product IS NULL THEN P.Start_Time ELSE ISNULL(E.Start_Time, E.TimeStamp)  END
			   ,CASE WHEN E.Applied_Product IS NULL THEN ISNULL(P.End_Time, GETDATE()) ELSE E.TimeStamp END, E.Applied_Product ORDER BY E.PU_Id, E.Timestamp)
			   ,Flag = NULL
			   ,IsAppliedProductrepeate = CASE WHEN E.Applied_Product IS NOT NULL THEN
			   ROW_NUMBER() OVER(PARTITION BY  E.Event_Id, E.TimeStamp ORDER BY E.PU_Id, E.Timestamp) ELSE 1 END
			FROM 
				dbo.Events                          E  WITH(NOLOCK)
				JOIN dbo.Prod_Units                 U  WITH(NOLOCK) ON E.Pu_Id = U.Pu_Id
				JOIN dbo.Prod_Lines_Base			L  WITH(NOLOCK) ON U.PL_Id = L.PL_Id
				JOIN dbo.Production_Status			PS WITH(NOLOCK) ON E.Event_Status = PS.ProdStatus_Id
				JOIN dbo.Production_Starts			P  WITH(NOLOCK) ON E.PU_Id = P.PU_Id
				JOIN dbo.Products_Base				PB WITH(NOLOCK) ON ISNULL(E.Applied_Product, P.Prod_Id) = PB.Prod_Id
				LEFT JOIN dbo.Event_Details			ED WITH(NOLOCK) ON E.Event_Id = ED.Event_Id
			WHERE 
				E.Pu_Id = @UnitId
				AND (E.TimeStamp = CASE WHEN @PreviousDateDiff <= 5 THEN @PreviousDate ELSE NULL END
				OR E.TimeStamp = CASE WHEN @NextDateDiff <= 5 THEN @NextDate ELSE NULL END
				OR E.Event_Id = @event_id)
				AND (P.Start_Time <= E.TimeStamp AND (P.End_time > ISNULL(E.Start_Time,E.Timestamp) OR P.End_Time IS NULL))
			)
			INSERT INTO @tempEvents
			SELECT * FROM CTE 
			WHERE IsAppliedProductrepeate = 1
			ORDER BY Production_UnitId, Event_End_Time, Production_Start_Time ASC

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

			IF EXISTS(SELECT 1 FROM @tempEvents)
			BEGIN
				SELECT
					E.Event_Id
					,Event_Start_Time = dbo.fnServer_CmnConvertTime(Event_Start_Time, @DbTZ, 'UTC')
					,Event_End_Time = dbo.fnServer_CmnConvertTime(Event_End_Time, @DbTZ, 'UTC')
					,E.Event_Name
					,E.Production_Status
					,UTCTimeStamp = E.Event_End_Time
					,E.Product_Id
					,Production_Start_Time = dbo.fnServer_CmnConvertTime(Production_Start_Time, @DbTZ, 'UTC')
					,Production_End_Time = dbo.fnServer_CmnConvertTime(Production_End_Time, @DbTZ, 'UTC')
					,E.Product_desc
					,UTCProductionTimeStamp = dbo.fnServer_CmnConvertTime(Production_End_Time, @DbTZ, 'UTC')
					,E.Production_UnitId
					,E.Production_UnitDesc
					,Prod_Line = E.Production_LineDesc
					,E.IsAppliedProduct
					,Prod_Line_Id = E.Production_LineId
					,Repeats = 1
				FROM @tempEvents E 
				ORDER BY 
					E.Event_End_Time, E.Production_Start_Time
			END
			ELSE
		   BEGIN
				SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN
			END
END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetAdjacentBatchProduct] TO [ComXClient]
