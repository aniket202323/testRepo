CREATE PROCEDURE [dbo].[spPS_GetMaterialTraceabilityResult]
 @ComponentId Int = Null
,@TargetMaterialLotIds nvarchar(max) = null
,@SourceMaterialLotId Int  = Null
,@PageNumber Int  = Null -- Current page number
,@PageSize Int  = Null -- Total records per page to display

  AS
   BEGIN
         DECLARE @SQL NVARCHAR(MAX)='';
		 DECLARE @StartPosition INT= @PageSize * (@PageNumber - 1);
		 DECLARE @TotalRecords INT =0;
		  DECLARE @AllTargetLotIds Table (TargetLot_Id Int)
		
		if (@TargetMaterialLotIds is not null)
		INSERT INTO @AllTargetLotIds (TargetLot_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('xxx', @TargetMaterialLotIds, ',')

SELECT @SQL ='			
	select 
	              c.event_id EventId,
				  c.source_event_id SourceEventId,
				  c.Component_Id ComponentId,
				  c.Dimension_X DimensionX,
				  CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as sourcelotIdentifier,
				  CASE WHEN (targ.lot_identifier IS NOT NULL) THEN targ.lot_identifier ELSE targ.event_num END as targetLotIdentifier,
				  dbo.fnServer_CmnConvertFromDbTime(c.entry_on, ''UTC'') as entry_on,
				  CASE WHEN (e.applied_product IS NOT NULL) THEN e.applied_product ELSE prods.prod_id END as applied_product,
				  e.pu_id,
				  COUNT(0) OVER() totalRecords
				  from event_components c
     inner join events e on e.event_id=c.source_event_id
     inner join events targ on targ.event_id=c.event_id
     left join production_starts prods on (prods.PU_Id=e.Pu_id and e.Timestamp > prods.start_time 
			 and (e.Timestamp <= prods.end_time or prods.end_time is NULL))
     	where (1=1)
			'+CASE WHEN @TargetMaterialLotIds IS NULL THEN '' ELSE 'AND c.event_id  in ('+@TargetMaterialLotIds+')' END +'
	'+CASE WHEN @SourceMaterialLotId IS NULL THEN '' ELSE 'AND c.source_event_id='+Cast(@SourceMaterialLotId as nvarchar)+' ' END +'
	'+CASE WHEN @ComponentId IS NULL THEN '' ELSE 'AND c.Component_Id='+cast(@ComponentId as nvarchar)+' ' END +'
			order by c.entry_on 
	OFFSET '+Cast(@StartPosition as nvarchar)+' ROWS
    FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;
			'
			--SELECT @SQL
			EXEC (@SQL)
    END
