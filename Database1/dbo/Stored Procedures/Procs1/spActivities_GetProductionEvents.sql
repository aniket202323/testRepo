
CREATE PROCEDURE dbo.spActivities_GetProductionEvents
    @UnitIds       nVARCHAR(max),
    @TimeSelection  INT,
    @StartTime      DATETIME = NULL,
    @EndTime        DATETIME = NULL,
    @UserId INT,
    @SortColumn       nVARCHAR(30)  = 'TimeStamp', -- Optional sort column
    @SortOrder        nVARCHAR(4)   = 'ASC', -- Optional sort order					                      
    @PageNumber					INT = 0,
    @PageSize					INT = 20,
    @TotalElement INT OUTPUT
AS
BEGIN
     CREATE TABLE   #AllUnits  (id int identity(1,1),PU_Id Int)
  
     DECLARE @xml XML

    --UnitIds
    IF @UnitIds IS NOT NULL
        Begin
            SET @xml = cast(('<X>'+replace(@UnitIds,',','</X><X>')+'</X>') as xml)
             INSERT INTO #AllUnits(Pu_Id)
            SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
        END
    --TimeSelection
    IF @TimeSelection <> 7
        BEGIN
            --Getting the Start Time and End Time from the time selection function
            EXECUTE dbo.spBF_CalculateReportTimeFromTimeSelection null, null, @TimeSelection  , @StartTime  Output,@EndTime  Output, 1
        END

    IF @StartTime Is Null OR @EndTime Is Null
        BEGIN
            SELECT Error = 'Could not Calculate Start Date and Endate, provide valid timeselection', Code = 'InvalidData', ErrorType = 'ValidDatesNotFound', PropertyName1 = 'TimeSelection', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TimeSelection, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    IF @StartTime IS NOT NULL
        BEGIN
            SET @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime, 'UTC')
        END

    IF @EndTime IS NOT NULL
        BEGIN
            SET @Endtime = dbo.fnServer_CmnConvertToDBTime(@Endtime, 'UTC')
        END
    --Pagination Provide requested page.

    DECLARE @startRow Int
    DECLARE @endRow Int

    SET @PageNumber = coalesce(@PageNumber,0)
    SET @PageSize = coalesce(@PageSize,20)

    SET @startRow = coalesce(@PageNumber * @PageSize,0) + 1
    SET @endRow = @startRow + @PageSize - 1


    -- fetching authorized units for the user
     CREATE TABLE #AuthUnits
                       ( AuthPU_Id BIGINT, AuthET_Id BIGINT)
    INSERT INTO #AuthUnits (AuthPU_Id, AuthET_Id)
    select PU_Id, ET_Id from fnBF_ApiFindAvailableUnitsAndEventTypes(@UserId);
    DECLARE @AllUnitsCount INT
    SELECT @AllUnitsCount = count(*) from  #AllUnits
    if(@AllUnitsCount = 0)
        BEGIN
            INSERT INTO #AllUnits select AuthPU_Id from #AuthUnits where AuthET_Id = 1
        END
    --Totel Element

    SELECT @TotalElement=  Count(*) FROM Events AS E
                                             INNER JOIN #AuthUnits AuthU ON AuthU.AuthPU_Id = E.PU_Id AND AuthU.AuthET_Id = 1
                                             INNER JOIN #AllUnits AU ON E.PU_Id = AU.PU_Id
    WHERE
            E.TimeStamp >= @StartTime  AND E.TimeStamp <= @EndTime

    --Result
    Declare @sql nvarchar(max)
	SET @sql = ''
	SET @sql = '
    ; WITH	TEMPEVENTS as (
        SELECT
            E.Event_Id AS EventId,
            Row_Number() Over (  Order By '+@SortColumn+' '+@SortOrder+') AS RowNumber,
            E.Event_Num												AS           EventNumber,
            E.PU_Id													AS				UnitId,
            E.Applied_Product										AS	AppliedProduct,
            E.Comment_Id											AS CommentId,
            E.Confirmed												AS Confirmed,
            dbo.fnserver_CmnConvertFromDbTime(E.Entry_On, ''UTC'')	As EntryOn,
            E.Event_Status											As EventStatus,
            E.Event_Subtype_Id										As EventSubtypeId,
            E.Source_Event											As SourceEvent,
            dbo.fnserver_CmnConvertFromDbTime(E.Start_Time, ''UTC'')	AS StartTime,
            E.Testing_Prct_Complete									As TestingPrctComplete,
            dbo.fnserver_CmnConvertFromDbTime( E.TimeStamp, ''UTC'')	AS TimeStamp,
            E.User_Id												As UserId,
            E.Lot_Identifier										As LotIdentifier,
            E.Operation_Name										As OperationName

        FROM Events AS E
                 INNER JOIN #AuthUnits AuthU ON AuthU.AuthPU_Id = E.PU_Id AND AuthU.AuthET_Id = 1
                 INNER JOIN #AllUnits AU ON E.PU_Id = AU.PU_Id
        WHERE
                E.TimeStamp >= '''+convert(nvarchar,@StartTime,9)+'''  AND E.TimeStamp <= '''+convert(nvarchar,@EndTime,9)+'''
    )
      select * from TEMPEVENTS where
          RowNumber BETWEEN '+cast(@startRow as varchar)+' AND '+cast(@endRow as varchar)+''
		  EXEC(@sql);
END
