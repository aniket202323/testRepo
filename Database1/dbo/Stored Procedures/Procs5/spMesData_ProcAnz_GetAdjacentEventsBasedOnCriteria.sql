CREATE  Procedure [dbo].[spMesData_ProcAnz_GetAdjacentEventsBasedOnCriteria]
    @event_id                         int = NULL,
    @starttime                        Datetime = NULL,
    @endtime                          Datetime = NULL,
    @isIncremental                    int = 0
AS
BEGIN
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
                     Id Int Identity(1,1), 
                     Event_Id int, 
                     Start_Time datetime, 
                     End_Time datetime, 
                     Event_Name nVARCHAR(100), 
					 Event_Status_Id int,
                     Event_Status nVARCHAR(100), 
                     Product_Id int, 
                     Prod_Unit int,
                     Prod_UnitDesc nVARCHAR(100), 
					 Prod_Line int,
                     Prod_LineDesc nVARCHAR(100),
                     Prod_Start_Time datetime,
                     Prod_End_Time datetime,
                     BOM int,
                     Quantity float,
                     Production_Type tinyint,
                     Production_Variable int,
                     isAppliedProduct int
              )
              SET @UnitId = (SELECT E.PU_ID FROM dbo.Events E WHERE E.Event_Id = @event_id)
              SELECT @ConvertedET = (SELECT E.TimeStamp FROM dbo.Events E WITH(NOLOCK) WHERE E.Event_Id = @event_id)
              SELECT @PreviousDate = MAX(E.TimeStamp) from dbo.Events E WITH(NOLOCK) WHERE E.TimeStamp < @ConvertedET AND E.PU_Id = @UnitId   
              SELECT @NextDate = MIN(E.timestamp) from dbo.Events E WITH(NOLOCK) WHERE E.timestamp > @ConvertedET AND E.PU_Id = @UnitId
              SET @PreviousDateDiff = DATEDIFF(DAY, @ConvertedET, @PreviousDate)
              SET @NextDateDiff = DATEDIFF(DAY, @NextDate, @ConvertedET)
              SET @isIncremental = ISNULL(@isIncremental, 0)
              SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192
              INSERT INTO @tempEvents
              SELECT DISTINCT E.Event_Id,
                     COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp),
                     E.Timestamp,
                     E.Event_Num,
					 PS.ProdStatus_Id,
                     PS.ProdStatus_Desc,
                     E.Applied_Product,
                     U.PU_Id,
                     U.PU_Desc,
					 L.PL_Id,
                     L.PL_Desc,
                     COALESCE(E.Start_Time, LAG(E.TimeStamp) OVER (PARTITION BY E.PU_Id ORDER BY E.TimeStamp), E.TimeStamp),
                     E.TimeStamp,
                     E.BOM_Formulation_Id,
                     ED.Final_Dimension_X,
                     U.Production_Type,
                     U.Production_Variable,
                     CASE WHEN E.Applied_Product IS NULL THEN 0 ELSE 1 END
              FROM dbo.Events                                 E WITH(NOLOCK)
                     JOIN dbo.Prod_Units          U WITH(NOLOCK) ON E.Pu_Id = U.Pu_Id
                     JOIN dbo.Prod_Lines_Base     L WITH(NOLOCK)  ON U.PL_Id = L.PL_Id
                     JOIN Production_Status       PS WITH(NOLOCK) ON E.Event_Status = PS.ProdStatus_Id
                     LEFT JOIN Event_Details      ED WITH(NOLOCK) ON E.Event_Id = ED.Event_Id
              WHERE E.Pu_Id = @UnitId
                     AND (E.TimeStamp = (CASE WHEN @PreviousDateDiff <= 5 THEN @PreviousDate ELSE NULL END)
                     OR E.TimeStamp = (CASE WHEN @NextDateDiff <= 5 THEN @NextDate ELSE NULL END))
                     OR E.Event_Id = @event_id
              ORDER BY E.TimeStamp
              UPDATE @tempEvents 
              SET Product_Id = S.Prod_Id 
                     ,Prod_Start_Time = S.Start_Time
                     ,Prod_End_Time = ISNULL(S.End_Time, @ConvertedET)
              FROM @tempEvents E
                     JOIN Production_Starts S WITH(NOLOCK) ON S.PU_Id = E.Prod_Unit 
                     AND S.Start_Time <= E.End_Time 
                     AND (S.End_time > E.Start_Time OR S.End_time IS NULL)
              WHERE E.Product_Id IS NULL
                                  
              IF EXISTS(SELECT 1 FROM @tempEvents)
              BEGIN
                     SELECT @InitialST = MIN(Start_time) FROM @tempEvents
                     SELECT E.Event_Id,
                           Start_Time = Case WHEN @isIncremental = 0 THEN dbo.fnServer_CmnConvertTime(E.Start_time, @DbTZ,'UTC') 
                           ELSE dbo.fnServer_CmnConvertTime(@InitialST, @DbTZ,'UTC') END,
                           End_Time = dbo.fnServer_CmnConvertTime(E.End_Time, @DbTZ,'UTC'),
                           E.Event_Name,
						   E.Event_Status_Id,
                           E.Event_Status,
                           UTCTimeStamp = dbo.fnServer_CmnConvertTime(E.End_Time, @DbTZ,'UTC'),
                           E.Product_Id,
                           Prod_Start_Time = dbo.fnServer_CmnConvertTime(E.Prod_Start_Time, @DbTZ,'UTC'),
                           Prod_End_Time = dbo.fnServer_CmnConvertTime(E.Prod_End_Time, @DbTZ,'UTC'),
                           Prod_desc = CASE WHEN isAppliedProduct = 0 THEN P.Prod_desc ELSE '**'+ P.Prod_desc + '**' END,
                           ProdUTCTimeStamp = dbo.fnServer_CmnConvertTime(E.Prod_End_Time, @DbTZ,'UTC'),
                           E.Prod_Unit,
                           E.Prod_UnitDesc,
                           E.Prod_Line, 
						   E.Prod_LineDesc,
                           BOM,
                           Quantity = CASE E.Production_Type 
                                                WHEN 1
                                                THEN (SELECT ISNULL(SUM(CONVERT(FLOAT, T.Result)),0) FROM dbo.Tests T WITH (NOLOCK)
                                                WHERE T.Var_Id = E.Production_Variable
                                                       AND T.Result_On >= E.Start_Time
                                                       AND T.Result_On <= E.End_Time) 
                                                ELSE ISNULL (E.Quantity, 0) END
                     FROM @tempEvents E 
                     LEFT JOIN dbo.products          P  WITH(NOLOCK)  ON E.Product_Id = P.Prod_Id
                     ORDER BY Start_Time
              END
              ELSE
              BEGIN
					SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '' 
              END
END
       
GRANT  EXECUTE  ON [dbo].[spMesData_ProcAnz_GetAdjacentEventsBasedOnCriteria]  TO [ComXClient]