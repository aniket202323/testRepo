CREATE Procedure [dbo].[spBF_GetEventsBasedonCriteria]
       @dept_id                          int = NULL,
       @line_id                          int = NULL,
       @pu_id                            int = NULL,
       @starttime                        Datetime = NULL,
       @endtime                          Datetime = NULL,
       @isIncremental                    int = 0
AS
BEGIN
              DECLARE     @ConvertedST  DateTime,
                          @ConvertedET  DateTime,
                                           @tempStartDate DateTime,
                          @DbTZ nVarChar(200),
                          @InitialST DateTime,
                          @UnitRows int,
                                           @Row int = 0,
                                           @CurrentPUID int,
                                           @ProductionType nvarchar(100),
                                           @ProductionVarId int,
                                           @ProductionTotal int
              DECLARE @tempEvents TABLE
                     (
                           Id Int Identity(1,1), 
                           Event_Id int, 
                           Start_Time datetime, 
                           End_Time datetime, 
                           Event_Name nvarchar(100), 
                           Event_Status nvarchar(100), 
                           Prod_Id int, 
                                            Prod_Unit int,
                           Prod_UnitDesc nvarchar(100), 
                           Prod_Line nvarchar(100),
                           BOM int,
                           Quantity float
                     )
              DECLARE @tempUnits TABLE
                         (       
                                    Id Int Identity(1,1),
                                         Unit_Id int
                )
              SET @isIncremental = ISNULL(@isIncremental, 0)       
              SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@starttime,'UTC')
              SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endtime,'UTC')
              SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192
              IF (@pu_id IS NOT NULL)
                       BEGIN
              INSERT INTO @tempUnits(Unit_Id)
                          SELECT Unit_Id = @pu_id
              END
              IF ((@pu_id IS NULL) AND (@line_id IS NOT NULL))
                       BEGIN
              INSERT INTO @tempUnits(Unit_Id)
                          SELECT U.PU_Id
                                  FROM dbo.Prod_Lines_Base  L WITH(NOLOCK)
                     JOIN dbo.prod_units U WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
                                   WHERE L.PL_Id = @line_id order by U.PU_Id
              END
               IF ((@line_id IS NULL) AND (@pu_id IS NULL) AND (@dept_id IS NOT NULL))
                       BEGIN
              INSERT INTO @tempUnits(Unit_Id)
                          SELECT U.PU_Id
                                  FROM Departments_Base  D WITH(NOLOCK)
                     JOIN dbo.Prod_Lines_Base          L WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
                     JOIN dbo.prod_units               U WITH(NOLOCK)  ON L.PL_Id = U.PL_Id    
                                   WHERE D.Dept_Id = @dept_id order by U.PU_Id
             END
                        SELECT @UnitRows = count(1) FROM @tempUnits
                           WHILE @Row <  @UnitRows
                BEGIN
                SELECT @Row = @Row + 1
                SELECT @CurrentPUID = TU.Unit_Id FROM @tempUnits TU WHERE TU.Id = @Row
               INSERT INTO @tempEvents(Event_Id, Start_Time, End_Time, Event_Name, Event_Status, Prod_Id, Prod_Unit, Prod_UnitDesc, Prod_Line, BOM, Quantity)
                     SELECT E.Event_Id,
                           E.Start_time,
                           E.Timestamp,
                           E.Event_Num,
                           PS.ProdStatus_Desc,
                           E.Applied_Product,
                           U.PU_Id,
                           U.PU_Desc,
                           L.PL_Desc,
                           E.BOM_Formulation_Id,
                           ED.Final_Dimension_X
                           FROM dbo.prod_units               U WITH(NOLOCK)
                           JOIN dbo.Prod_Lines_Base          L WITH(NOLOCK)  ON U.PL_Id = L.PL_Id
                           JOIN dbo.Events                                 E WITH(NOLOCK)  ON E.PU_Id = U.PU_Id
                           JOIN Production_Status                   PS WITH(NOLOCK) ON e.Event_Status = PS.ProdStatus_Id
                           LEFT JOIN Event_Details              ED WITH(NOLOCK) ON E.Event_Id = ED.Event_Id
                     WHERE U.PU_Id = @CurrentPUID
                           AND E.TimeStamp BETWEEN @ConvertedST AND @ConvertedET
                     ORDER BY E.TimeStamp DESC
                     UPDATE  d1
                           SET d1.Start_Time = d2.End_Time
                           FROM @tempEvents d2
                           JOIN @tempEvents d1 ON d1.Id = (d2.Id - 1)
                           WHERE d1.Start_Time IS NULL
                     UPDATE @tempEvents 
                           SET Prod_Id = S.Prod_Id 
                           FROM @tempEvents TE
                           JOIN Production_Starts S ON S.pu_id = TE.Prod_Unit 
                           AND (S.Start_Time <= TE.End_Time AND (S.End_time > TE.End_Time 
                           OR S.End_time IS NULL))
                           WHERE TE.Prod_Id IS NULL
                     SELECT @tempStartDate = MAX(e.TimeStamp) from dbo.Events e, @tempEvents T where e.TimeStamp < T.End_Time and e.pu_id = T.Prod_Unit and T.Start_time is NULL
                     UPDATE @tempEvents SET Start_Time = @tempStartDate where Start_Time IS NULL
                        SELECT  @ProductionType   = Production_Type,
                        @ProductionVarId  = Production_Variable
                        FROM dbo.Prod_Units WITH (NOLOCK)
                        WHERE PU_Id = @CurrentPUID
IF @ProductionType = 1
          BEGIN
          SELECT @ProductionTotal = isnull(sum(convert(Float, t.Result)),0)  
          FROM   dbo.Tests t WITH (NOLOCK), @tempEvents TE 
          WHERE t.Var_Id = @ProductionVarId
          AND t.Result_On >= TE.Start_Time
          AND t.Result_On < TE.End_Time
                update @tempEvents
                SET Quantity = @ProductionTotal WHERE Prod_Unit = @CurrentPUID
END
                 END  
                       IF EXISTS(SELECT 1 FROM @tempEvents)
                       BEGIN
                                  SELECT @InitialST = MIN(E.Start_time) FROM @tempevents E
                                  SELECT E.Event_Id,
                                                Start_Time = Case WHEN @isIncremental = 0 THEN dbo.fnServer_CmnConvertTime(E.Start_time, @DbTZ,'UTC') 
                                                ELSE dbo.fnServer_CmnConvertTime(@InitialST, @DbTZ,'UTC') END,
                                                End_Time = dbo.fnServer_CmnConvertTime(E.End_Time, @DbTZ,'UTC'),
                                                E.Event_Name,
                                                E.Event_Status,
                                                E.prod_id,
                                                P.Prod_desc,
                                                UTCTimeStamp = dbo.fnServer_CmnConvertTime(E.End_Time, @DbTZ,'UTC'),
                                                E.Prod_UnitDesc,
                                                E.Prod_Line, 
                                                BOM,
                                                Quantity
                                  FROM @tempEvents E
                                  LEFT JOIN dbo.products P WITH(NOLOCK)
                                  ON E.prod_id = P.prod_id
                       END
                       ELSE
                       BEGIN
                                  SELECT -999   -- Returning -999 when the entered Input ID is not present in DB 
                       END
END
GRANT  EXECUTE  ON [dbo].[spBF_GetEventsBasedonCriteria]  TO [ComXClient]
