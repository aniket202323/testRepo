
CREATE PROCEDURE dbo.spActivities_GetSheetDisplays @SheetType INT, -- 1 Time Based, 2 Production Event, 25 User Defined Event
                                                   @PUIds     nVARCHAR(max) = NULL,
                                                   @UserId    INT

 AS
BEGIN
    DECLARE @Units TABLE(RowID  INT IDENTITY,
                         UnitId INT NULL)
    DECLARE @Xml XML
    IF @PUIds IS NOT NULL
        BEGIN
            SET @PUIds = REPLACE(@PUIds, ' ', '')
        END
    IF @PUIds IS NOT NULL
       AND LEN(@PUIds) = 0
        BEGIN
            SET @PUIds = NULL
        END
    IF @PUIds IS NOT NULL
        BEGIN
            SET @Xml = CAST('<X>'+replace(@PUIds, ',', '</X><X>')+'</X>' AS XML)
            INSERT INTO @Units( UnitId )
            SELECT N.value('.', 'int') FROM @Xml.nodes('X') AS T(N)
        END;
    CREATE TABLE #tmpSheets(Sheet_Id   INT,
                            Sheet_Desc NVarchar(50),
                            Unit_id    INT,
                            Unit_desc  nVARCHAR(100),
                            Is_Secured BIT)
    Create table #AccessibleSheets(Sheet_Group_Id int, Sheet_Group_Desc nVarchar(255), Sheet_Id int, Sheet_Desc nvarchar(255), Sheet_Type int, App_Id int)
	INSERT INTO #AccessibleSheets
	Exec spCC_GetSheets @UserId
    IF @PUIds IS NOT NULL
        BEGIN
            INSERT INTO #tmpSheets( Sheet_Id,
                                    Sheet_Desc,
                                    Unit_id )
            SELECT S.Sheet_Id,
                   S.Sheet_Desc,
                   CASE @SheetType
                       WHEN 1
                       THEN SDO.Value
                       ELSE S.Master_Unit
                   END AS Unit_Id
                   FROM Sheets AS S
                        JOIN Sheet_Display_Options AS SDO1 ON SDO1.Sheet_Id = S.Sheet_Id
                                                              AND SDO1.Display_Option_Id = 444
                                                              AND SDO1.Value = 1
                        LEFT JOIN Sheet_Display_Options AS SDO ON SDO.Sheet_Id = S.Sheet_Id
                                                                  AND SDO.Display_Option_Id = 446
                        JOIN @Units AS U ON U.UnitId = CASE @SheetType
                                                           WHEN 1
                                                           THEN SDO.Value
                                                           ELSE S.Master_Unit
                                                       END
                   WHERE S.Sheet_Type = @SheetType
                         AND S.Is_Active = 1
            DELETE FROM #tmpSheets WHERE Sheet_Id NOT IN (SELECT Sheet_Id FROM #AccessibleSheets )
	    UPDATE #tmpSheets
              SET Unit_desc = (SELECT pu_desc FROM Prod_Units_Base WHERE Pu_id = Unit_id), Is_Secured = dbo.fnActivities_CheckSheetSecurityForActivities(Sheet_Id, 8, 3, Unit_id, @UserId)

			  		  
			;WITH SheetUnits as 
				(
					Select 
					Distinct s.sheet_desc,s.sheet_type,ISNULL(s.Master_Unit,su.PU_Id ) Pu_Id,s.Event_Subtype_Id,s.Sheet_Id
					from 
					Sheets s 
					left outer join Sheet_Unit su on su.Sheet_Id = s.sheet_id 
	
					where 
					s.sheet_id in (Select Sheet_Id from #tmpSheets)
			)
			,UDESheetsWithMismatchEventSubType As
			(
				Select 
					su.Sheet_Id
				from 
					SheetUnits su 
					join Event_Configuration Ec on ec.PU_Id = su.Pu_Id and Ec.ET_Id = 14
					Join Event_Subtypes Es on Es.Event_Subtype_Id = Ec.Event_Subtype_Id and ec.ET_Id = Es.ET_Id
				Where
					Es.Event_Subtype_Id = su.Event_Subtype_Id 
			)
			Delete T From #tmpSheets T Where T.Sheet_Id not in (Select Sheet_Id from UDESheetsWithMismatchEventSubType) and @SheetType = 25;

            SELECT Sheet_Id,
                   Sheet_Desc,
                   Unit_Id,
                   Unit_desc AS Unit_Description FROM #tmpSheets WHERE Is_Secured = 1 ORDER BY Sheet_Desc
        END
        ELSE
        BEGIN
            INSERT INTO #tmpSheets( Sheet_Id,
                                    Sheet_Desc,
                                    Unit_id )
            SELECT S.Sheet_Id,
                   S.Sheet_Desc,
                   CASE @SheetType
                       WHEN 1
                       THEN SDO.Value
                       ELSE S.Master_Unit
                   END AS Unit_Id
                   FROM Sheets AS S
                        JOIN Sheet_Display_Options AS SDO1 ON SDO1.Sheet_Id = S.Sheet_Id
                                                              AND SDO1.Display_Option_Id = 444
                                                              AND SDO1.Value = 1
                        LEFT JOIN Sheet_Display_Options AS SDO ON SDO.Sheet_Id = S.Sheet_Id
                                                                  AND SDO.Display_Option_Id = 446
                   WHERE S.Sheet_Type = @SheetType
                         AND S.Is_Active = 1

            DELETE FROM #tmpSheets WHERE Sheet_Id NOT IN (SELECT Sheet_Id FROM #AccessibleSheets )

	    UPDATE #tmpSheets
              SET Unit_desc = (SELECT pu_desc FROM Prod_Units_Base WHERE Pu_id = Unit_id), Is_Secured = dbo.fnActivities_CheckSheetSecurityForActivities(Sheet_Id, 8, 3, Unit_id, @UserId)

			  		  
			;WITH SheetUnits as 
				(
					Select 
					Distinct s.sheet_desc,s.sheet_type,ISNULL(s.Master_Unit,su.PU_Id ) Pu_Id,s.Event_Subtype_Id,s.Sheet_Id
					from 
					Sheets s 
					left outer join Sheet_Unit su on su.Sheet_Id = s.sheet_id 
	
					where 
					s.sheet_id in (Select Sheet_Id from #tmpSheets)
			)
			,UDESheetsWithMismatchEventSubType As
			(
				Select 
					su.Sheet_Id
				from 
					SheetUnits su 
					join Event_Configuration Ec on ec.PU_Id = su.Pu_Id and Ec.ET_Id = 14
					Join Event_Subtypes Es on Es.Event_Subtype_Id = Ec.Event_Subtype_Id and ec.ET_Id = Es.ET_Id
				Where
					Es.Event_Subtype_Id = su.Event_Subtype_Id 
			)
			Delete T From #tmpSheets T Where T.Sheet_Id not in (Select Sheet_Id from UDESheetsWithMismatchEventSubType) and @SheetType = 25;

            SELECT Sheet_Id,
                   Sheet_Desc,
                   Unit_Id,
                   Unit_desc AS Unit_Description FROM #tmpSheets WHERE Is_Secured = 1 ORDER BY Sheet_Desc
        END
    DROP TABLE #tmpSheets
END

