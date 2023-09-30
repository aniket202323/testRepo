
/*
            Copyright (c) 2017 GE Digital. All Rights Reserved.
   =============================================================================

   =============================================================================
            Author                       212517152, Rabindra Kumar
            Create On                    12-April-2018
            Last Modified                21-December-2020
            Description                  Returns Production Events.
            Procedure_name               [spMesData_ProcAnz_GetEventsBasedonCriteria]

================================================================================
            Input Parameter:
=================================================================================
            @dept_id                        --int--             Optional input paramater
            @line_id                        --int--             Optional input paramater
            @pu_id                          --int--             Optional input paramater
            @name                           --NVARCHAR(255)--   Optional input paramater
            @product                        --NVARCHAR(255)--   Optional input paramater
            @asset                          --NVARCHAR(255)--   Optional input paramater
            @quantity                       --NVARCHAR(255)--   Optional input paramater
            @status                         --NVARCHAR(255)--   Optional input paramater
            @bom                            --NVARCHAR(255)--   Optional input paramater
            @starttime                      --datetime--        Optional input paramater
            @endtime                        --datetime--        Optional input paramater
            @isIncremental                  --int--             Optional input paramater
            @sortCol                        --nVARCHAR(100)--   Optional input paramater
            @sortOrder                      --nvarchar(100 )--  Optional input paramater
            @pageNumber                     --bigint--          Optional input paramater
            @pageSize                       --bigint--          Optional input paramater

================================================================================
            Result Set:- 1
=================================================================================
            --SL_No
            --Department
            --Department_Description
            --Line
            --Line_Description
            --Unit
            --Unit_Description
            --Production_Type
            --Production_Variable
            --Product
            --Product_Description
            --Event
            --Event_Num
            --Event_Start_Time
            --Event_End_Time
            --EventUTCTimeStamp
            --BOM
            --Production_Start_id
            --Production_Start_Time
            --Production_End_Time
            --ProdUTCTimeStamp
            --Production_Status
            --Production_Status_Description
            --Quantity
            --UOM
            --NbResults
            --CurrentPage
            --PageSize
            --TotalPages

================================================================================
            Result Set:- 2 (Distinct Plant Model [Asset] based on input parameter)
=================================================================================
            --Id
            --Name
            --AssetType

================================================================================
            Result Set:- 3 (Distinct Production Status based on input parameter)
=================================================================================
            --Id
            --Name

================================================================================
            Result Set:- 4 (Distinct Product based on input parameter)
=================================================================================
            --Id
            --Name
*/


CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetEventsBasedonCriteria]
    @dept_id                        int = NULL,
    @line_id                        int = NULL,
    @pu_id                          int = NULL,
    @name                           NVARCHAR(255) = NULL,
    @product                        NVARCHAR(255) = NULL,
    @asset                          NVARCHAR(255) = NULL,
    @quantity                       NVARCHAR(255) = NULL,
    @status                         NVARCHAR(255) = NULL,
    @bom                            NVARCHAR(255) = NULL,
    @starttime                      datetime = NULL,
    @endtime                        datetime = NULL,
    @isIncremental                  int = NULL,
    @sortCol                        NVARCHAR(100) = NULL,
    @sortOrder                      NVARCHAR(100) = NULL,
    @pageNumber                     bigint = NULL,
    @pageSize                       bigint = NULL
AS
BEGIN
    SET NOCOUNT ON

    IF EXISTS(SELECT 1
    FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@dept_id, @line_id, @pu_id))
    BEGIN
        SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@dept_id, @line_id, @pu_id)
        RETURN
    END

    SET @isIncremental = ISNULL(@isIncremental, 0)
    DECLARE @ConvertedST DateTime = CASE WHEN @starttime IS NULL
                                            THEN DATEADD(DAY, -15, GETDATE())
                                            ELSE dbo.fnServer_CmnConvertToDbTime(@starttime, 'UTC') END
    DECLARE @ConvertedET datetime = CASE WHEN @endtime IS NULL
                                            THEN GETDATE()
                                            ELSE dbo.fnServer_CmnConvertToDbTime(@endtime, 'UTC') END

    DECLARE @DbTZ nVARCHAR(255) = (SELECT value
    FROM site_parameters
    WHERE parm_id = 192)

    SET @PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
    SET @PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 10 ELSE @PageSize END
    CREATE TABLE #Prod_Events
    (
        Applied_Product int,
        Event_Id int,
        EventStartTime datetime,
        Timestamp datetime,
        Event_num nVARCHAR(50),
        BOM_Formulation_Id bigint,
        Event_Status int,
        PU_ID int,
        Start_Time datetime,
        End_Time datetime,
        Prod_Id int ,
        Start_Id int,
        Quantity Float,
        ProductId int
    )

    CREATE TABLE #Units
    (
        Dept_Id Int,
        Dept_Desc nVARCHAR(100),
        Pl_Id int,
        Pl_desc nVARCHAR(100),
        Pu_id int ,
        Pu_desc nVARCHAR(100),
        Production_variable int,
        Production_Type int
    )
    CREATE TABLE #Production_Status
    (
        ProdStatus_Id int,
        ProdStatus_Desc nVARCHAR(50)
    )

    DECLARE @ParameterDefinitionList NVARCHAR(MAX) =
                                    ' @dept_id                      int = NULL
                                    ,@line_id                       int = NULL
                                    ,@pu_id                         int = NULL
                                    ,@name                          NVARCHAR(255) = NULL
                                    ,@product                       NVARCHAR(255) = NULL
                                    ,@asset                         NVARCHAR(255) = NULL
                                    ,@quantity                      NVARCHAR(255) = NULL
                                    ,@status                        NVARCHAR(255) = NULL
                                    ,@bom                           NVARCHAR(255) = NULL
                                    ,@ConvertedST                   datetime = NULL
                                    ,@ConvertedET                   datetime = NULL
                                    ,@isIncremental                 int = NULL
                                    ,@sortCol                       NVARCHAR(100) = NULL
                                    ,@sortOrder                     NVARCHAR(100) = NULL '

    DECLARE @SQLStatement NVARCHAR(MAX) = '

--UPDATE A
--SET A.Quantity = ED.Final_Dimension_X
--From #temp A Join Event_Details ED on ED.Event_Id = E.Event_Id

;WITH
Temp as (
Select Cast(E.Applied_Product as int) Applied_Product,E.Event_Id Event_Id,Start_Time,E.TimeStamp,BOM_Formulation_Id,Event_Num,E.Event_Status,E.PU_Id,0 Quantity

from
Events E LEFT Join Event_Details ED on ED.Event_Id = E.Event_ID
WHERE E.Timestamp between @ConvertedST and @ConvertedET
UNION
Select E.Applied_Product,E.Event_Id,Start_Time,E.TimeStamp,BOM_Formulation_Id,Event_Num,E.Event_Status,E.PU_Id,0  from
Events E LEFT Join Event_Details ED on ED.Event_Id = E.Event_ID
WHERE @ConvertedST BETWEEN Start_Time AND E.TimeStamp
UNION
Select E.Applied_Product,E.Event_Id,Start_Time,E.TimeStamp,BOM_Formulation_Id,Event_Num,E.Event_Status,E.PU_Id,0  from
Events E LEFT Join Event_Details ED on ED.Event_Id = E.Event_ID
WHERE @ConvertedET BETWEEN Start_Time AND E.TimeStamp

)

,tmpEvents AS (Select Max(TimeStamp) [TimeStamp],Min(ISNULL(Start_Time, TimeStamp)) Start_Time,PU_Id from Temp Group by Pu_ID)
,tmpProdStarts as (Select S.* from tmpEvents E JOIN Production_Starts S ON (S.PU_Id = E.PU_Id AND (S.Start_Time <= E.TimeStamp AND (S.End_time > ISNULL(E.Start_Time, E.TimeStamp) OR S.End_time IS NULL))))
,Prod_Events As (Select Applied_Product,Event_Id,E.Start_Time EventStartTime,Timestamp,Event_num,BOM_Formulation_Id,Event_Status,
E.PU_ID, S.Start_Time,S.End_Time,S.Prod_Id,S.Start_Id,E.Quantity from Temp E JOIN tmpProdStarts  S  ON (S.PU_Id = E.PU_Id AND (S.Start_Time <= E.TimeStamp AND (S.End_time > ISNULL(E.Start_Time, E.TimeStamp) OR S.End_time IS NULL))))
Insert into #Prod_Events
Select *,ISNULL(Applied_Product,Prod_Id) ProductId  from Prod_Events

INsert into #Units
select D.Dept_Id,D.Dept_Desc,Pl.Pl_Id,Pl.Pl_desc,Pu.Pu_id,Pu.Pu_desc,pu.Production_variable,pu.Production_Type  from Prod_Units_Base pu
join Prod_lines_Base pl on pl.pl_id = pu.pl_Id
join Departments_base D on D.dept_Id = pl.Dept_Id
WHere pu.Pu_Id in (Select Pu_Id from #Prod_Events)
Select * into #Event_SubTypes from Event_Subtypes

INSERT into #Production_Status
Select ProdStatus_Id,ProdStatus_Desc  from Production_Status

;WITH CTE_Events AS (
Select
            U.Dept_Id Department,U.Dept_Desc Department_Description,U.PL_Id Line,U.Pl_Desc Line_Description,A.Event_Id,
A.PU_Id Unit,U.PL_Desc Unit_Description, U.Production_Type,U.Production_Variable,A.ProductID Product,p.Prod_desc Product_Description,A.Event_Id [Event],A.Event_Num,
A.EventStartTime Event_Start_time,A.[TimeStamp] Event_End_Time,A.BOM_Formulation_Id BOM,A.Start_Id Production_Start_id,
A.Start_Time Production_Start_Time,A.End_Time Production_End_Time,PS.ProdStatus_Id Production_Status,PS.ProdStatus_Desc Production_Status_Description,
A.Quantity
,ES.dimension_X_Eng_Units UOM,Applied_Product, ROW_NUMBER() OVER (Partition by A.Event_Id Order by Event_Id,ISNULL(A.End_Time,''9999-12-31'') Desc) EventRepeat

from #Prod_Events A
            Join #Units U on A.PU_Id = U.PU_Id
            Join Event_Configuration EC ON A.PU_Id = EC.PU_Id AND EC.event_subtype_id IS NOT NULL
            Join #Event_SubTypes ES on EC.ET_Id = ES.event_subtype_id'+CASE WHEN @status IS NOT NULL THEN ' AND PS.ProdStatus_Desc = @status ' ELSE '' END+'
            Join #Production_Status PS ON A.Event_Status = PS.ProdStatus_Id
            Join Products_Base p on A.ProductId = p.Prod_Id'+CASE WHEN @product IS NOT NULL THEN ' AND P.Prod_Desc = @product ' ELSE '' END+'
Where 1=1
'
+CASE WHEN @line_id IS NOT NULL THEN ' AND U.Pl_Id = @Line_Id ' ELSE '' END
+CASE WHEN @pu_id IS NOT NULL THEN ' AND U.Pu_Id = @pu_id ' ELSE '' END
+CASE WHEN @dept_id IS NOT NULL THEN ' AND U.Dept_Id = @dept_id ' ELSE '' END
+CASE WHEN @asset IS NOT NULL THEN ' AND U.PU_Desc LIKE ''%'' + @asset + ''%'' ' ELSE '' END
+CASE WHEN @name IS NOT NULL THEN ' AND E.Event_Num LIKE ''%'' + @name + ''%'' ' ELSE '' END
+CASE WHEN @bom IS NOT NULL THEN ' AND E.BOM_Formulation_Id LIKE ''%'' + @bom + ''%'' ' ELSE '' END
+CASE WHEN @quantity IS NOT NULL THEN ' AND A.Quantity LIKE ''%'' + @quantity + ''%'' ' ELSE '' END

+')'

    SET @SQLStatement = @SQLStatement + '
                        ,CTE_Events_1 As (SELECT Department,Department_Description,Line,Line_Description,Unit,Unit_Description,Production_Type,Production_Variable,Product,Product_Description,[Event],Event_Num,Event_Start_Time,Event_End_Time,BOM,Production_Start_id,Production_Start_Time,Production_End_Time,Production_Status,Production_Status_Description,(Select Final_Dimension_X from Event_Details Where Event_Id = S.[Event]) Quantity,UOM,Applied_Product,EventRepeat
                        FROM CTE_Events S WHERE EventRepeat = 1)
                        ,CTE_Events_2 As (select Count(0) Total from CTE_Events_1)
                        SELECT Department,Department_Description,Line,Line_Description,Unit,Unit_Description,Production_Type,Production_Variable,Product,Product_Description,[Event],Event_Num,Event_Start_Time,Event_End_Time,BOM,Production_Start_id,Production_Start_Time,Production_End_Time,Production_Status,Production_Status_Description,Quantity,UOM,Applied_Product,EventRepeat, (Select Total From CTE_Events_2) Total
                        From CTE_Events_1'
    SET @SQLStatement = @SQLStatement + ' ORDER BY ' + CASE WHEN @sortCol = 'Name' THEN ' Event_Num '
                                                                                    WHEN @sortCol = 'Product' THEN ' Product_Description '
                                                                                    WHEN @sortCol = 'Asset' THEN ' Unit_Description '
                                                                                    WHEN @sortCol = 'Start' THEN ' Event_Start_Time '
                                                                                    WHEN @sortCol = 'End' THEN ' Event_END_Time '
                                                                                    WHEN @sortCol = 'Quantity' THEN ' Quantity '
                                                                                    WHEN @sortCol = 'Status' THEN ' Production_Status_Description '
                                                                                    WHEN @sortCol = 'BoM' THEN ' BoM '
                                                                                    ELSE ' Unit, Event_End_Time ' END
                                                                                    + ISNULL(' ' + @sortOrder, ' DESC ')
    SET @SQLStatement = @SQLStatement + '
                        OFFSET '+CAST(@PageSize as nvarchar)+' * ('+CAST(@pageNumber as nvarchar)+' - 1) ROWS
                        FETCH NEXT '+CAST(@PageSize as nvarchar)+' ROWS ONLY OPTION (RECOMPILE);

                        '

    DECLARE @tempEvents TABLE (
        Id Int Identity(1,1),
        Department int,
        Department_Description nVARCHAR(255),
        Line int,
        Line_Description nVARCHAR(255),
        Unit int,
        Unit_Description nVARCHAR(255),
        Production_Type tinyint,
        Production_Variable int,
        Product int,
        Product_Description nVARCHAR(255),
        [Event] int,
        Event_Num nVARCHAR(255),
        Event_Start_Time datetime,
        Event_End_Time datetime,
        BOM int,
        Production_Start_id int,
        Production_Start_Time datetime,
        Production_End_Time datetime,
        Production_Status int,
        Production_Status_Description nVARCHAR(100),
        Quantity float,
        UOM nVARCHAR(50),
        Applied_Product int,
        EventRepeat int,
        Total Int,
        ProductXML XML,
        ProductStatusxml XML)
    --======================================================================
    -- dynamic query execution (starts)
    --======================================================================

    INSERT INTO @tempEvents
        (Department,Department_Description,Line,Line_Description,Unit,Unit_Description,Production_Type,Production_Variable,Product,Product_Description,[Event],Event_Num,Event_Start_Time,Event_End_Time,BOM,Production_Start_id,Production_Start_Time,Production_End_Time,Production_Status,Production_Status_Description,Quantity,UOM,Applied_Product,EventRepeat,Total)
    EXECUTE SP_EXECUTESQL @SQLStatement, @ParameterDefinitionList,
                                        @dept_id
                                        ,@line_id
                                        ,@pu_id
                                        ,@name
                                        ,@product
                                        ,@asset
                                        ,@quantity
                                        ,@status
                                        ,@bom
                                        ,@ConvertedST
                                        ,@ConvertedET
                                        ,@isIncremental
                                        ,@sortCol
                                        ,@sortOrder
    --======================================================================
    -- Synamic query execution (end)
    --======================================================================

    IF NOT EXISTS(SELECT 1
    FROM @tempEvents)
    BEGIN
        SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END

    IF @isIncremental != 0
        DECLARE @InitialST DATETIME = (SELECT MIN(E.Event_Start_Time)
    FROM @tempevents E)

    --======================================================================
    -- To support filter on quantity (starts)
    --======================================================================

    UPDATE te SET te.Quantity = (SELECT ISNULL(SUM(CONVERT(FLOAT, T.Result)), 0)
    FROM
        dbo.Tests T WITH (NOLOCK)
    WHERE T.Var_Id = Production_Variable
        AND T.Result_On >= Event_Start_Time
        AND T.Result_On <= Event_End_Time)
    FROM
        @tempEvents te WHERE Production_Type = 1
        AND EventRepeat = 1

    --======================================================================
    -- To support filter on quantity (end)
    --======================================================================

    --======================================================================
    -- To Select records based on page number and page size (starts)
    --======================================================================
    ;WITH
        TempEvent_CTE
        AS
        (
            SELECT Id,
                Department
                , Department_Description
                , Line
                , Line_Description
                , Unit
                , Unit_Description
                , Production_Type
                , Production_Variable
                , Product
                , Product_Description
                , [Event]
                , Event_Num
                , Event_Start_Time = COALESCE(TE.Event_Start_Time, (SELECT LAG(E.Timestamp) OVER (PARTITION BY E.PU_Id ORDER BY E.Timestamp) FROM Events E WHERE TE.Unit = E.PU_Id AND TE.[Event] = E.Event_Id), @ConvertedST)
                , Event_End_Time = Event_End_Time
                , BOM
                , Production_Start_id
                , Production_Start_Time = CASE WHEN TE.Applied_Product IS NULL
                            THEN TE.Production_Start_Time
                            ELSE COALESCE(TE.Event_Start_Time, (SELECT LAG(E.Timestamp) OVER (PARTITION BY E.PU_Id ORDER BY E.Timestamp) FROM Events E WHERE TE.Unit = E.PU_Id AND TE.[Event] = E.Event_Id), @ConvertedST) END
                , Production_End_Time = CASE WHEN TE.Applied_Product IS NULL
                            THEN ISNULL(TE.Production_End_Time, @ConvertedET)
                            ELSE TE.Event_End_Time END
                , Production_Status
                , Production_Status_Description
                , Quantity
                , UOM
                , Applied_Product
                , Total
            FROM
                @tempEvents TE
        )
    SELECT
        SL_No = Id
        ,Department
        ,Department_Description
        ,Line
        ,Line_Description
        ,Unit
        ,Unit_Description
        ,Production_Type
        ,Production_Variable
        ,Product
        ,Product_Description
        ,[Event]
        ,Event_Num
        ,Event_Start_Time = CASE WHEN @isIncremental = 0
                                THEN dbo.fnServer_CmnConvertTime(Event_Start_Time, @DbTZ,'UTC')
                                ELSE dbo.fnServer_CmnConvertTime(@InitialST, @DbTZ,'UTC') END
        ,Event_End_Time = dbo.fnServer_CmnConvertTime(Event_End_Time, @DbTZ,'UTC')
        ,EventUTCTimeStamp = dbo.fnServer_CmnConvertTime(Event_End_Time, @DbTZ,'UTC')
        ,BOM
        ,Production_Start_id
        ,Production_Start_Time = dbo.fnServer_CmnConvertTime(Production_Start_Time, @DbTZ,'UTC')
        ,Production_End_Time = dbo.fnServer_CmnConvertTime(Production_End_Time, @DbTZ,'UTC')
        ,ProdUTCTimeStamp = dbo.fnServer_CmnConvertTime(Production_End_Time, @DbTZ,'UTC')
        ,Production_Status
        ,Production_Status_Description
        ,Quantity
        ,UOM
        ,NbResults = Total
        ,CurrentPage = @pageNumber
        ,PageSize = @pageSize
        ,TotalPages = FLOOR(CEILING(CAST(Total as decimal(18,2))/ @PageSize))
    FROM
        TempEvent_CTE
    --======================================================================
    -- To Select records based on page number and page size (end)
    --======================================================================

    --======================================================================
    -- Distict selection, for the dropdown in UI filter (start)
    --======================================================================
    ;with S As
        (
            SELECT DISTINCT Dept_Id Id, dept_Desc Name
                FROM #Units
                WHERE @dept_id IS NULL
            UNION ALL
                SELECT DISTINCT pl_Id, Pl_Desc
                FROM #Units
                WHERE Dept_Id = @dept_id and @dept_id IS NOT NULL
            UNION ALL
                SELECT DISTINCT pu_Id, Pu_Desc
                FROM #Units
                WHERE Pl_Id = @line_id and @line_id IS NOT NULL
        )
    SELECT *, CASE WHEN @dept_id IS NULL THEN 'Department' WHEN @line_id IS NULL THEN 'Line' ELSE 'Unit' END AssetType
    from S

    SELECT DISTINCT
        id = ProdStatus_Id,
        name = ProdStatus_Desc
    FROM
        #Production_Status Ps

    SELECT DISTINCT
        id = A.Prod_Id,
        name = A.Prod_Desc
    FROM
        Products_Base A
        join #Prod_Events B on B.ProductId = A.Prod_Id
    WHERE B.ProductId <> 1

END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetEventsBasedonCriteria] TO [ComXClient]

