
CREATE PROCEDURE [dbo].[spWaste_GetWasteEvents]
@WasteEventId INT
,@UnitIds	nVarChar(max) = Null
,@TimeSelection Int = 3
,@StartTime DateTime = Null
,@EndTime	DateTime = Null
,@ProductionEventBased int = Null
,@AssociatedProductionEventId INT = Null
,@PageNumber		Int=0 /* 0th page is the first page */
,@PageSize			Int = 100
,@SortColumn  nVarChar(50) = 'WasteId'
,@SortDirection  nVarChar(50) = 'DESC'
,@TotalWasteEventsCount		Int OUTPUT


AS

Declare @WasteData table (
                             WasteId int,WasteAmount float, TimeStamp Datetime, EntryOn Datetime, SourceUnitId Int,  MasterUnitId Int,
                             AssociatedEventId INT, AssociatedEventNum  nvarchar(100),
                             WasteEventFaultId INT, 
                             WasteEventTypeId INT, 
                             WasteMeasurementId INT, 
                             AmountConversionDivisor INT,
                             CauseCommentId INT, ActionCommentId INT,
                             ActionLevel1Id INT, 
                             ActionLevel2Id INT, 
                             ActionLevel3Id INT, 
                             ActionLevel4Id INT, 
                             ReasonLevel1Id INT, 
                             ReasonLevel2Id INT, 
                             ReasonLevel3Id INT, 
                             ReasonLevel4Id INT, 
                             UserId INT, UserName nvarchar(100),
                             ProductId INT,  -- EventBasedCalculatedProdId and ProdStartCalculatedProdId will be coalesed to get ProductId, EventBasedCalculatedProdId has preference
                             Confirmed int,
                             TotalCount int
                         )

    If(@WasteEventId is not null AND NOT EXISTS( SELECT 1 from Waste_Event_Details where WED_Id = @WasteEventId))
        BEGIN          
           SELECT Error = 'Waste record not exists.','EWMS1000' as Code
        END


    If(@AssociatedProductionEventId is NOT NULL AND NOT EXISTS(SELECT 1 from Events where Event_Id = @AssociatedProductionEventId))
        BEGIN
            SELECT Error = 'ERROR: Valid AssociatedProductionEventId required', Code = 'NotFound', ErrorType = 'AssociatedProductionEventIdNotFound', PropertyName1 = 'AssociatedProductionEventId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @AssociatedProductionEventId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        END
    If(@WasteEventId is NULL)
        BEGIN  
              IF @StartTime Is Null or @EndTime Is Null
					BEGIN						
					    EXECUTE dbo.spBF_CalculateReportTimeFromTimeSelection @UnitIds,3,@TimeSelection,@StartTime  Output,@EndTime  Output,1
					END
				IF @StartTime Is Null OR @EndTime Is Null
				BEGIN
			               SELECT Error = 'ERROR: Could not Calculate Date', Code = 'InvalidData', ErrorType = 'ValidDatesNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					RETURN
				END

			SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')
            SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@Endtime,'UTC')	
            
            SELECT @PageNumber = ISNULL(@PageNumber,0),@Pagesize =ISNULL(@Pagesize,100)
            Create Table #UnitIds (Id Int)
          --  INSERT INTO #UnitIds (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@UnitIds,',')

            -- First consider the case where filters are provided
            Declare @sql nvarchar(max)
            Set @sql = ''

            -- filter is not working when used as Int directly, need to check
            Declare @AssociatedProductionEventIdString varchar(15);
            set @AssociatedProductionEventIdString = CONVERT(varchar(15),@AssociatedProductionEventId)

            SET @sql=
                        ';WITH TmpWaste (WasteId,WasteAmount,TimeStamp,EntryOn,SourceUnitId,MasterUnitId,AssociatedEventId,AssociatedEventNum,WasteEventFaultId,WasteEventTypeId,WasteMeasurementId,AmountConversionDivisor,CauseCommentId,ActionCommentId,ActionLevel1Id,ActionLevel2Id,ActionLevel3Id,ActionLevel4Id,ReasonLevel1Id,ReasonLevel2Id,ReasonLevel3Id,ReasonLevel4Id,UserId,UserName,ProductId,Confirmed) as (

                        Select
                                 w.WED_Id WasteId,w.Amount WasteAmount,w.TimeStamp TimeStamp,w.Entry_On EntryOn,w.Source_PU_Id SourceUnitId,w.PU_Id MasterUnitId,w.Event_Id AssociatedEventId,e.Event_Num AssociatedEventNum,w.WEFault_Id WasteEventFaultId,w.WET_Id WasteEventTypeId,w.WEMT_Id WasteMeasurementId,wem.Conversion AmountConversionDivisor,w.Cause_Comment_Id CauseCommentId,w.Action_Comment_Id ActionCommentId,w.Action_Level1 ActionLevel1Id,w.Action_Level2 ActionLevel2Id,w.Action_Level3 ActionLevel3Id,w.Action_Level4 ActionLevel4Id,w.Reason_Level1 ReasonLevel1Id,w.Reason_Level2 ReasonLevel2Id,w.Reason_Level3 ReasonLevel3Id,w.Reason_Level4 ReasonLevel4Id,w.User_Id UserId,ub.Username UserName,COALESCE(e.Applied_Product,ps.Prod_Id) AS ProductId,null Confirmed
                            from
                                Waste_Event_Details w
                                   -- JOIN #UnitIds u on u.Id = w.PU_Id
                                    LEFT JOIN Events e   on e.Event_Id = w.Event_Id
									LEFT JOIN Waste_Event_Meas wem   on wem.WEMT_Id = w.WEMT_Id
                                    LEFT JOIN Users_Base ub on ub.User_Id = w.User_Id
									LEFT JOIN Production_Starts ps on (ps.PU_Id = w.PU_Id AND ps.Start_Time <= w.TimeStamp  AND (ps.End_Time is NULL OR ps.End_Time >= w.TimeStamp) )
                        Where
                             1=1'+case when @UnitIds is not null THEN ' and W.Pu_id in ('+@UnitIds+') ' else '' end+
						Case when @EndTime is NOT NULL THEN 'AND w.TimeStamp <= '''+convert(varchar,@EndTime,109)+''''ELSE ' ' END
						+
						Case when @StartTime is NOT NULL THEN 'AND w.TimeStamp >= '''+convert(varchar,@StartTime,109)+''''ELSE ' ' END
                            +'
                              And ' + case  when @AssociatedProductionEventIdString is not null Then  'w.Event_Id = '+ @AssociatedProductionEventIdString
                                          ELSE '1=1'
                            END

                        + ')
			,TotalCnt as (Select Count(0) TotalCnt from TmpWaste)
			Select * ,(Select TotalCnt from TotalCnt) from TmpWaste
				Order By '+cast(@SortColumn as char)+' '+cast(@SortDirection as char)+'
				OFFSET '+cast((@PageSize * @pageNumber) as varchar)+'  ROWS
					FETCH NEXT  '+cast( @PageSize as varchar)+'   ROWS ONLY OPTION (RECOMPILE); '

            INSERT INTO @WasteData(
                WasteId,WasteAmount,TimeStamp,EntryOn,SourceUnitId,MasterUnitId,AssociatedEventId,AssociatedEventNum,WasteEventFaultId,WasteEventTypeId,WasteMeasurementId,AmountConversionDivisor,CauseCommentId,ActionCommentId,ActionLevel1Id,ActionLevel2Id,ActionLevel3Id,ActionLevel4Id,ReasonLevel1Id,ReasonLevel2Id,ReasonLevel3Id,ReasonLevel4Id,UserId,UserName,ProductId,Confirmed,TotalCount
            )
                EXEC(@sql)

            SET @TotalWasteEventsCount = (Select top 1 TotalCount from @WasteData)
            IF @TotalWasteEventsCount is NULL AND @pageNumber > 0
                Begin
                    SET @TotalWasteEventsCount = 0
                    SELECT Error = 'ERROR: Page number out of range', Code = 'InvalidData', ErrorType = 'ValidPagessNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                End
            IF @TotalWasteEventsCount is NULL
                Begin
                    SET @TotalWasteEventsCount = 0
                End
        END
    else
        BEGIN
            INSERT INTO @WasteData(
                WasteId,WasteAmount,TimeStamp,EntryOn,SourceUnitId,MasterUnitId,AssociatedEventId,AssociatedEventNum,WasteEventFaultId,WasteEventTypeId,WasteMeasurementId,AmountConversionDivisor,CauseCommentId,ActionCommentId,ActionLevel1Id,ActionLevel2Id,ActionLevel3Id,ActionLevel4Id,ReasonLevel1Id,ReasonLevel2Id,ReasonLevel3Id,ReasonLevel4Id,UserId,UserName,ProductId,Confirmed
            )
            Select
                w.WED_Id WasteId,w.Amount WasteAmount,w.TimeStamp TimeStamp,w.Entry_On EntryOn,w.Source_PU_Id SourceUnitId, w.PU_Id MasterUnitId,w.Event_Id AssociatedEventId,e.Event_Num AssociatedEventNum,w.WEFault_Id WasteEventFaultId,w.WET_Id WasteEventTypeId,w.WEMT_Id WasteMeasurementId,wem.Conversion AmountConversionDivisor, w.Cause_Comment_Id CauseCommentId,w.Action_Comment_Id ActionCommentId,w.Action_Level1 ActionLevel1Id,w.Action_Level2 ActionLevel2Id,w.Action_Level3 ActionLevel3Id,w.Action_Level4 ActionLevel4Id,w.Reason_Level1 ReasonLevel1Id,w.Reason_Level2 ReasonLevel2Id,w.Reason_Level3 ReasonLevel3Id,w.Reason_Level4 ReasonLevel4Id,w.User_Id UserId,ub.Username UserName,COALESCE(e.Applied_Product,ps.Prod_Id) AS ProductId ,null Confirmed
            from
                Waste_Event_Details w
                    LEFT JOIN Events e   on e.Event_Id = w.Event_Id
					LEFT JOIN Waste_Event_Meas wem   on wem.WEMT_Id = w.WEMT_Id
                    LEFT JOIN Users_Base ub   on ub.User_Id = w.User_Id
                    LEFT JOIN Production_Starts ps on (ps.PU_Id = w.PU_Id AND ps.Start_Time <= w.TimeStamp  AND (ps.End_Time is NULL OR ps.End_Time >= w.TimeStamp) )
            Where w.WED_Id = @WasteEventId

            set @TotalWasteEventsCount = 1;
        END

	    declare @DBZone nvarchar(100)
		select  @DBZone = value from site_parameters where parm_id = 192
        
select	 WasteId,WasteAmount,
         --dbo.fnserver_CmnConvertFromDbTime(TimeStamp,'UTC') TimeStamp,dbo.fnserver_CmnConvertFromDbTime(EntryOn,'UTC') EntryOn,         
         [TimeStamp] at time zone @DBZone at time zone 'UTC' [TimeStamp],  EntryOn at time zone @DBZone at time zone 'UTC' EntryOn,
           SourceUnitId,MasterUnitId,AssociatedEventId,
           AssociatedEventNum,WasteEventFaultId,WasteEventTypeId,WasteMeasurementId,AmountConversionDivisor,
           CauseCommentId,ActionCommentId,ActionLevel1Id,ActionLevel2Id,ActionLevel3Id,
           ActionLevel4Id,ReasonLevel1Id,ReasonLevel2Id,ReasonLevel3Id,
           ReasonLevel4Id,UserId,UserName,
           ProductId,Confirmed,@TotalWasteEventsCount as totalRecords 
           from @WasteData

