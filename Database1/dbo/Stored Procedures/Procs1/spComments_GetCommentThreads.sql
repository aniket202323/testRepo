
CREATE PROCEDURE [dbo].[spComments_GetCommentThreads]
		@TableId	Int,
		@EntityId   nvarchar(max) =NULL,
		@TopOfChainId Int =  NULL,
		@UserId     Int=NULL
AS
/* @UserId  @TableId and @UnitId not used for security on a get at this time*/
DECLARE @MAPPED_ENTITY_ID INT;
Declare @SQL nvarchar(max)
IF @TableId IS NOT NULL AND (@TopOfChainId IS NULL AND @EntityId IS NULL) 

BEGIN
	IF @TableId = 81  --WorkOrder
		BEGIN
			SELECT @MAPPED_ENTITY_ID = PP_Id,@TableId = 35 FROM Workorder.workorders WHERE Id = @EntityId And @TableId =81
	 
			SELECT DISTINCT c.TopOfChain_Id,COUNT(c.TopOfChain_Id) AS comment_count,'WorkOrder' AS EntityType,
				p.PP_Id AS MappedEntityId,
				w.id AS  EntityId
			FROM Comments c
			JOIN Users u ON u.User_Id = c.User_Id JOIN production_plan p ON p.Comment_id=c.TopOfChain_Id 
			JOIN WorkOrder.WorkOrders w ON w.PP_Id=p.PP_Id GROUP BY C.TopOfChain_Id,p.PP_Id,W.Id
		END
	ELSE IF @TableId = 83  --Serial Number
    BEGIN
	WITH S AS (
				SELECT M.Id MAterialLotActualId,[Status] FROM WorkOrder.MaterialLotActuals M Where M.id = @EntityId 
			),S1 AS (SELECT 'DISC:'+CAST(MAterialLotActualId AS nVARCHAR) LotIdentifier_EventNum,[Status] from S )
			SELECT @MAPPED_ENTITY_ID= Event_Id ,@TableId=4 FROM Events E Join S1 ON S1.LotIdentifier_EventNum = E.Event_Num 

	  SELECT DISTINCT c.TopOfChain_Id,COUNT(c.TopOfChain_Id) AS comment_count,'SerialNumber' AS EntityType,
			E.Event_Id AS MappedEntityId,
			m.id AS  EntityId
	FROM Comments c
	JOIN Users u ON u.User_Id = c.User_Id JOIN Events e ON e.Comment_id=c.TopOfChain_Id 
	JOIN WorkOrder.MaterialLotActuals m ON 'DISC:'+CAST(m.Id AS nVARCHAR)=e.Event_Num AND m.LotIdentifier=e.Lot_Identifier GROUP BY C.TopOfChain_Id,E.Event_Id,m.Id
		

     END
	ELSE IF @TableId=4
	  BEGIN
		SELECT DISTINCT c.TopOfChain_Id,COUNT(c.TopOfChain_Id) AS comment_count,'ProductionEvent' AS EntityType,
				e.Event_Id AS MappedEntityId,
				e.Event_Id AS  EntityId
			FROM Comments c
			JOIN Users u ON u.User_Id = c.User_Id JOIN events e ON e.Comment_id=c.TopOfChain_Id  GROUP BY C.TopOfChain_Id,e.Event_Id
		END
	END
ELSE IF  @TableId IS NOT NULL AND (@EntityId IS NOT NULL OR @TopOfChainId IS NOT NULL)
	BEGIN
		IF @TableId = 81  --WorkOrder
			BEGIN
				SELECT @SQL =''
				SELECT @SQL=
'				
	 SELECT DISTINCT c.TopOfChain_Id,COUNT(c.TopOfChain_Id) AS comment_count,''WorkOrder'' AS EntityType,
			p.PP_Id AS MappedEntityId,
			w.id AS  EntityId
	 FROM Comments c
	 JOIN Users u ON u.User_Id = c.User_Id 
	 JOIN production_plan p ON p.Comment_id=c.TopOfChain_Id 
	 JOIN WorkOrder.WorkOrders w ON w.PP_Id=p.PP_Id 
	 '+case when @EntityId is not null then ' AND w.id in ('+@EntityId+')' else '' end +'
	 Where 1=1 '+case when @TopOfChainId is not null then 'c.TopOfChain_Id='+cast (@TopOfChainId as nvarchar) else '' end +'
	 GROUP BY C.TopOfChain_Id,p.PP_Id,w.Id ORDER BY c.TopOfChain_Id
'
EXEC(@SQL)


	 END
ELSE IF @TableId = 83 --Serial Number
    BEGIN
	

		SELECT @SQL =''
		SELECT @SQL ='
	  SELECT DISTINCT c.TopOfChain_Id,COUNT(c.TopOfChain_Id) AS comment_count,''SerialNumber'' AS EntityType,
			E.Event_Id AS MappedEntityId,
			m.id AS  EntityId
	FROM Comments c
	JOIN Users u ON u.User_Id = c.User_Id 
	JOIN Events e ON e.Comment_id=c.TopOfChain_Id 
	JOIN WorkOrder.MaterialLotActuals m ON ''DISC:''+CAST(m.Id AS nVARCHAR)=e.Event_Num AND m.LotIdentifier=e.Lot_Identifier 
	'+case when @EntityId is not null then ' AND m.Id in ('+@EntityId+')' else '' end +'
	Where 1=1 '+case when @TopOfChainId is not null then 'c.TopOfChain_Id='+cast (@TopOfChainId as nvarchar) else '' end +'
	GROUP BY C.TopOfChain_Id,E.Event_Id,m.Id ORDER BY c.TopOfChain_Id DESC'
	EXEC(@SQL)
     END
ELSE IF @TableId = 4  --ProductionEvent
			BEGIN

			SELECT @SQL =''
			SELECT @SQL=
			'SELECT 
					DISTINCT c.TopOfChain_Id,COUNT(c.TopOfChain_Id) AS comment_count,''ProductionEvent'' AS EntityType,
						e.Event_Id AS MappedEntityId,
						e.Event_Id AS  EntityId
					FROM Comments c
					JOIN Users u ON u.User_Id = c.User_Id 
					JOIN events e ON e.Comment_id=c.TopOfChain_Id 
					'+case when @EntityId is not null then ' AND e.Event_Id in ('+@EntityId+')' else '' end +' 
					Where 1=1 '+case when @TopOfChainId is not null then 'c.TopOfChain_Id='+cast (@TopOfChainId as nvarchar) else '' end +'
					GROUP BY C.TopOfChain_Id,e.Event_Id ORDER BY c.TopOfChain_Id
			'
EXEC(@SQL)
				
	 END
END
