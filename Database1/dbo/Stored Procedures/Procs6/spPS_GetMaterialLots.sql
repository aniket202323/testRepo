
CREATE PROCEDURE [dbo].[spPS_GetMaterialLots]
 @paramType				nVarChar(200) = null
,@ProductId				Int  = Null
,@UnitIds				nvarchar(100)  = Null
,@StatusIds				nvarchar(100)  = Null
,@lotIdentifier			nVarChar(200)  = Null
,@materialLotId			Int  = Null
,@isExcludedEmptyLots	bit
,@isAvailableForConsumption bit
,@processOrderId                  Int = Null
,@isIncludeLotsWithImplicitProduct bit
,@PageNumber       INT          = NULL -- Current page number
,@PageSize         INT          = NULL -- Total records per page to display


  AS
  

CREATE TABLE #AllUnits(PU_Id Int)
CREATE TABLE #AllStatus(Status_Id Int)
DECLARE @xml XML
DECLARE @SQLStr nvarchar(max)
DECLARE @SQLStr1 nvarchar(max)
DECLARE @SQLStr2 nvarchar(max)


DECLARE @VlotIdentifier varchar(200),@xtype int
SET @VlotIdentifier= @lotIdentifier
Select @xtype = xtype from sys.syscolumns where object_name(id) ='events' and name ='event_num'--167/231


if (@UnitIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@UnitIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #AllUnits (PU_Id)  
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End
		if (@StatusIds is not null)
		Begin
			SET @xml = cast(('<X>'+replace(@StatusIds,',','</X><X>')+'</X>') as xml)
			INSERT INTO #AllStatus (Status_Id)
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		End

Begin
if(@paramType='MATERIAL_LOT_SEARCH')
       BEGIN
	   
	   	 DECLARE @StartPosition1 INT= @PageSize * (@PageNumber - 1);
		 DECLARE @StartPosition2 INT= @PageSize * (@PageNumber - 1);

SET @SQLStr1 =  '
select distinct
				   e.event_Id,
				   
				   CASE WHEN (e.applied_product IS NOT NULL) THEN e.applied_product ELSE prods.prod_id END as applied_product,
				   CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as event_num,
				   e.pu_id,
				   ed.initial_dimension_x,
				   ed.final_dimension_x,
				   e.event_status,
				   CAST(CASE WHEN (ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1 and ed.final_dimension_x > 0) THEN 1 ELSE 0 END AS BIT) availableForConsumption,
				   es.Dimension_X_Eng_Unit_Id,
				   ed.pp_id,
				   e.Timestamp
'
SET @SQLStr1 =  @SQLStr1 + '
			 from events e WITH (nolock) '
SET @SQLStr1 =  @SQLStr1 + '
			 inner join event_details ed WITH (nolock) on e.event_id = ed.event_id
			 '
IF @processOrderId IS NOT NULL
SET @SQLStr1 =  @SQLStr1 + '
			 left join Production_Plan_Starts pps on  (pps.PU_Id=e.Pu_id and pps.pp_id=' + Cast(@processOrderId as nvarchar)+' and pps.is_production=1
			 and e.Timestamp > pps.start_time and (e.Timestamp <= pps.end_time or pps.end_time is NULL))
			 '	
SET @SQLStr1 =  @SQLStr1 + '
			 left join production_starts prods on (prods.PU_Id=e.Pu_id and e.Timestamp > prods.start_time 
			 and (e.Timestamp <= prods.end_time or prods.end_time is NULL))
			 '		 
SET @SQLStr1 =  @SQLStr1 + '
			 left join Production_Status ps on e.event_status=ps.ProdStatus_Id 
			 '
SET @SQLStr1 =  @SQLStr1 + '			 
			 left join Event_Configuration ec on ec.PU_Id = e.PU_Id and ec.ET_Id = 1
			 '
SET @SQLStr1 =  @SQLStr1 + '			 
			 left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
			 '
SET @SQLStr1 =  @SQLStr1 + '
			where (1=1)   
			'  			
IF @processOrderId IS NOT  NULL
SET @SQLStr1 =   @SQLStr1 + ' 
               AND  ed.PP_Id is null and  pps.pp_id=' + Cast(@processOrderId as nvarchar)+'			
               '
IF @ProductId IS NOT NULL
  SET @SQLStr1 =  @SQLStr1 + '
                   AND ((e.applied_product is not null and e.applied_product=' + Cast(@ProductId as nvarchar)+') or  (e.applied_product is null and prods.prod_id =' + Cast(@ProductId as nvarchar)+'))'
IF @UnitIds IS NOT NULL
SET @SQLStr1 =  @SQLStr1 + '
			AND e.pu_id in (select PU_Id from #AllUnits)'
IF @StatusIds IS NOT NULL
SET @SQLStr1 =  @SQLStr1 + '
			AND e.event_status in (select Status_Id from #AllStatus)'
IF @lotIdentifier IS NOT NULL 
SET @SQLStr1 =  @SQLStr1 + '
			AND (e.Event_Num='+Case when @xtype =231 then 'N' else '' end+''''+@lotIdentifier+''')'
IF @isExcludedEmptyLots = 1 OR @isAvailableForConsumption=1
SET @SQLStr1 =  @SQLStr1 + '
			AND ed.final_dimension_x > 0'
IF @isExcludedEmptyLots = 0 OR @isAvailableForConsumption=0
SET @SQLStr1 =  @SQLStr1 + '
			AND ISNULL(ed.final_dimension_x,0) <= 0'
IF @isAvailableForConsumption = 1 
SET @SQLStr1 =  @SQLStr1 + '
			AND ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1'
IF @isAvailableForConsumption = 0
SET @SQLStr1 =  @SQLStr1 + '
			AND NOT (ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1)'
IF @isIncludeLotsWithImplicitProduct = 0 
SET @SQLStr1 =  @SQLStr1 + '
			AND e.applied_product IS NOT NULL'				
			



IF @lotIdentifier IS NOT NULL 
SET @SQLStr1 = @SQLStr1+
'
UNION

'
+
REPLACE(@SQLStr1,'AND (e.Event_Num=','AND (e.lot_identifier=')

SET @SQLStr1 = ';With S as ('+ @SQLStr1 + '
),S1 as (Select count(0)Total from S)
                    Select *,(Select Total from S1)totalRecords from S 
'
SET @SQLStr1 =  @SQLStr1 + '
			order by event_Id 
			OFFSET '+cast(@StartPosition1 as nvarchar)+' ROWS
			FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;'
			

Create table #tmpEvents1(event_Id int, Applied_product int,event_num nVarChar(max), Pu_id int,initial_dimension_x float,final_dimension_x float,event_status int,availableForConsumption bit,Dimension_X_Eng_Unit_Id int,PP_Id int,Timestamp DATETIME, totalRecords int )
insert into #tmpEvents1(event_Id,Applied_product,event_num,Pu_id,initial_dimension_x,final_dimension_x,event_status,availableForConsumption,Dimension_X_Eng_Unit_Id, PP_Id,Timestamp,totalRecords)
EXEC (@SQLStr1)

IF @processOrderId IS  NULL
UPDATE T1
       SET T1.pp_id = PPS.pp_ID
       FROM  #tmpEvents1 T1
JOIN Production_Plan_Starts PPS ON T1.pu_id = PPS.pu_id AND (T1.Timestamp > pps.start_time AND (T1.Timestamp <= pps.end_time OR pps.end_time IS NULL))
WHERE T1.pp_ID IS NULL

IF @processOrderId IS NOT NULL
UPDATE T1
       SET T1.pp_id = PPS.pp_ID
       FROM  #tmpEvents1 T1
JOIN Production_Plan_Starts PPS ON T1.pu_id = PPS.pu_id AND (T1.Timestamp > pps.start_time AND (T1.Timestamp <= pps.end_time OR pps.end_time IS NULL)
and pps.pp_id=@processOrderId and pps.is_production=1)
WHERE T1.pp_ID IS NULL

--Second Query
SET @SQLStr2 =  '

select      distinct
				   e.event_Id,
				   CASE WHEN (e.applied_product IS NOT NULL) THEN e.applied_product ELSE prods.prod_id END as applied_product,
				   CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as event_num,
				   e.pu_id,
				   ed.initial_dimension_x,
				   ed.final_dimension_x,
				   e.event_status,
				   CAST(CASE WHEN (ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1 and ed.final_dimension_x > 0) THEN 1 ELSE 0 END AS BIT) availableForConsumption,
				   es.Dimension_X_Eng_Unit_Id,
				   pps.pp_id,
				   e.Timestamp
'

SET @SQLStr2 =  @SQLStr2 + '
			 from events e WITH (nolock) '
SET @SQLStr2 =  @SQLStr2 + '
			 inner join event_details ed WITH (nolock) on e.event_id = ed.event_id
			 '
SET @SQLStr2 =  @SQLStr2 + '
			 inner join Production_Plan_Starts pps on  pps.PU_Id=e.Pu_id and pps.is_production=1 and pps.pp_id=' + Cast(@processOrderId as nvarchar)+'
			 '	

SET @SQLStr2 =  @SQLStr2 + '
			 left join production_starts prods on (prods.PU_Id=e.Pu_id and e.Timestamp > prods.start_time 
			 and (e.Timestamp <= prods.end_time or prods.end_time is NULL))
			 '			 
SET @SQLStr2 =  @SQLStr2 + '
			 left join Production_Status ps on e.event_status=ps.ProdStatus_Id 
			 '
SET @SQLStr2 =  @SQLStr2 + '			 
			 left join Event_Configuration ec on ec.PU_Id = e.PU_Id and ec.ET_Id = 1
			 '

SET @SQLStr2 =  @SQLStr2 + '			 
			 left join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
			 '

SET @SQLStr2 =  @SQLStr2 + '
			where ed.pp_id= '+ Cast(@processOrderId as nvarchar)+'
			'
IF @ProductId IS NOT NULL
  SET @SQLStr2 =  @SQLStr2 + '
                   AND ((e.applied_product is not null and e.applied_product=' + Cast(@ProductId as nvarchar)+') or  (e.applied_Product is null and prods.prod_id =' + Cast(@ProductId as nvarchar)+'))
                   '
IF @UnitIds IS NOT NULL
SET @SQLStr2 =  @SQLStr2 + '
			AND e.pu_id in (select PU_Id from #AllUnits)'
IF @StatusIds IS NOT NULL
SET @SQLStr2 =  @SQLStr2 + '
			AND e.event_status in (select Status_Id from #AllStatus)'
IF @lotIdentifier IS NOT NULL 
SET @SQLStr2 =  @SQLStr2 + '
			AND (e.Event_Num='+Case when @xtype =231 then 'N' else '' end+''''+@lotIdentifier+''')'
IF @isExcludedEmptyLots = 1 OR @isAvailableForConsumption=1
SET @SQLStr2 =  @SQLStr2 + '
			AND ed.final_dimension_x > 0'
IF @isExcludedEmptyLots = 0 OR @isAvailableForConsumption=0
SET @SQLStr2 =  @SQLStr2 + '
			AND ISNULL(ed.final_dimension_x,0) <= 0'
IF @isAvailableForConsumption = 1 
SET @SQLStr2 =  @SQLStr2 + '
			AND ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1'
IF @isAvailableForConsumption = 0
SET @SQLStr2 =  @SQLStr2 + '
			AND NOT (ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1)'
IF @isIncludeLotsWithImplicitProduct = 0 
SET @SQLStr2 =  @SQLStr2 + '
			AND e.applied_product IS NOT NULL'	



IF @lotIdentifier IS NOT NULL 
SET @SQLStr2 = @SQLStr2+
'
UNION
'
+
REPLACE(@SQLStr2,'AND (e.Event_Num=','AND (e.lot_identifier=')

SET @SQLStr2 =  ';With S as ('+@SQLStr2 + '
),S1 as (Select count(0)Total from S)
                    Select *,(Select Total from S1)totalRecords from S 
'

SET @SQLStr2 =  @SQLStr2 + '
			order by event_Id 
			OFFSET '+cast(@StartPosition1 as nvarchar)+' ROWS
			FETCH NEXT '+cast(@PageSize as nvarchar)+' ROWS ONLY;'


Create table #tmpEvents2(event_Id int, applied_product int,event_num nVarChar(max), Pu_id int,initial_dimension_x float,final_dimension_x float,event_status int,availableForConsumption bit,Dimension_X_Eng_Unit_Id int,PP_Id int,Timestamp DATETIME,totalRecords int )
insert into #tmpEvents2(event_Id,Applied_product,event_num,Pu_id,initial_dimension_x,final_dimension_x,event_status,availableForConsumption,Dimension_X_Eng_Unit_Id, PP_Id,Timestamp,totalRecords)
EXEC (@SQLStr2)

--Remove the duplicate Records
select * from #tmpEvents1 UNION  select * from #tmpEvents2

END
else if(@paramType='MATERIAL_LOT_ID')
		BEGIN
		Create table #tmpEvents(event_Id int, Applied_product int,event_num nVarChar(max), Pu_id int,initial_dimension_x float,final_dimension_x float,event_status int,availableForConsumption bit,Dimension_X_Eng_Unit_Id int,PP_Id int,Timestamp DATETIME, totalRecords int )
		insert into #tmpEvents(event_Id,Applied_product,event_num,Pu_id,initial_dimension_x,final_dimension_x,event_status,availableForConsumption,Dimension_X_Eng_Unit_Id, PP_Id,Timestamp,totalRecords)
			select distinct e.event_Id,
			       CASE WHEN (e.applied_product IS NOT NULL) THEN e.applied_product ELSE prods.prod_id END as applied_product,
			       CASE WHEN (e.lot_identifier IS NOT NULL) THEN e.lot_identifier ELSE e.event_num END as event_num,
			       e.pu_id,
			       ed.initial_dimension_x,
			       ed.final_dimension_x,
			       e.event_status,			      
			       CAST(CASE WHEN (ps.Status_Valid_For_Input=1 and ps.Count_For_Inventory=1 and ed.final_dimension_x > 0) THEN 1 ELSE 0 END AS BIT) availableForConsumption,
			       es.Dimension_X_Eng_Unit_Id,
			       pps.pp_id,
			       e.Timestamp,
			       0 as totalRecords
				from events e WITH (nolock)
					inner join event_details ed WITH (nolock) on e.event_id=ed.event_id
					left join Production_Status ps on e.event_status=ps.ProdStatus_Id
					left join Production_Plan_Starts pps on  pps.PU_Id=e.Pu_id  and e.Timestamp > pps.start_time and (e.Timestamp <= pps.end_time or pps.end_time is NULL) and (pps.pp_id=ed.pp_id or ed.pp_id is null)
					left join production_starts prods on prods.PU_Id=e.Pu_id and e.Timestamp > prods.start_time and (e.Timestamp <= prods.end_time or prods.end_time is NULL)
					left join Event_Configuration ec on ec.PU_Id=e.PU_Id and ec.ET_Id = 1
					left join Event_Subtypes es on es.Event_Subtype_Id=ec.Event_Subtype_Id
					where
					e.event_id=@materialLotId
							  
		   UPDATE t
		       SET t.pp_id = ed.pp_ID
		       FROM  #tmpEvents t
		             JOIN event_details ed ON  t.event_id=ed.event_id
		        WHERE ed.pp_ID IS not NULL and ed.event_id=@materialLotId

           select * from #tmpEvents	
	END
END
	
