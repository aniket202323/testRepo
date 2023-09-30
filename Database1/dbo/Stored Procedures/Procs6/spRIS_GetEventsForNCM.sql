/*
	Copyright (c) 2020 GE Digital. All Rights Reserved.
	=============================================================================

	=============================================================================
	Author				212517152, Rabindra Kumar
	Create On			28-march-2020
	Last Modified		28-march-2020
	Description			Returns Production Events.
	Procedure_name		[spRIS_GetEventsForNCM]

	================================================================================
	Input Parameter:
	=================================================================================
	@event_id                        --int--		    Optional input paramater
	@pageNumber                     --bigint--			Optional input paramater
	@pageSize                       --bigint--			Optional input paramater
	@TotalElement					--bigint--			Optional OUTPUT paramater

	================================================================================
	Result Set:- 1
	=================================================================================
	--sl_no
	--Event_Id
	--Pu_Id
	--Product
	--Product_Id
	--@TotalElement AS OUTPUT PARAMETER 

*/


CREATE PROCEDURE [dbo].[spRIS_GetEventsForNCM]
        @event_id                       NVARCHAR(MAX) = NULL
       ,@pageNumber                     BIGINT = NULL
       ,@pageSize                       BIGINT = NULL
	   ,@TotalElement					BIGINT = 0 OUTPUT
AS
BEGIN
        SET NOCOUNT ON

	    DECLARE @startRow INT, @endRow INT 

		DECLARE @event_id_list TABLE (
			event_id BIGINT
		)

		DECLARE @event_info TABLE (
			sl_no BIGINT IDENTITY(1,1)
			,Event_Id BIGINT
			,Event_Num NVARCHAR(50)
			,Pu_Id BIGINT
			,Product_Id BIGINT
			,Event_Status BIGINT
			,ProdStatus_Desc nVARCHAR(255)
			,Receiver_Number nVARCHAR(255)
			,Receiver_Id BIGINT
		)

		SET @PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
		SET @PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 100 ELSE @PageSize END

		SET @startRow = ((@PageNumber) - 1) * @PageSize + 1
		SET @endRow =  @PageNumber * @PageSize

		DECLARE @xml AS XML, @delimiter AS nVARCHAR(10)
		SET @delimiter =','
		SET @xml = CAST(('<X>' + REPLACE(@event_id, @delimiter ,'</X><X>')+'</X>') AS XML)
		INSERT INTO @event_id_list
		SELECT N.value('.', 'VARCHAR(10)') AS VALUE FROM @xml.nodes('X') AS T(N)

		INSERT INTO @event_info
		SELECT Distinct
			E.Event_Id
			,E.Event_Num
			,E.PU_Id
			,ProductId = ISNULL(E.Applied_Product, P.Prod_Id)
			,E.Event_Status
			,PS.ProdStatus_Desc
			,Receiver_Number = (SELECT TOP 1  E2.Event_Num FROM dbo.Events E2 WITH(NOLOCK) WHERE E2.Event_Id = EC.Source_Event_id)
			,Receiver_Id = EC.Source_Event_id	
		FROM Events E 
			JOIN dbo.[Event_Components]				EC WITH(NOLOCK) ON E.Event_Id = EC.Event_Id AND E.event_num = E.Lot_Identifier 
			JOIN dbo.[Production_Starts]			S  WITH(NOLOCK) ON (S.PU_Id = E.PU_Id AND (S.Start_Time <= E.TimeStamp AND (S.End_time > ISNULL(E.Start_Time, E.TimeStamp) OR S.End_time IS NULL)))
			JOIN dbo.[products]						P  WITH(NOLOCK) ON ISNULL(E.Applied_Product, S.Prod_Id) = P.Prod_Id
			LEFT JOIN dbo.[Production_Status]		PS WITH(NOLOCK) ON E.Event_Status = PS.ProdStatus_Id
		WHERE 
			E.Event_Id IN (SELECT event_id FROM @event_id_list)
		
		SELECT * FROM @event_info
		WHERE sl_no BETWEEN((@PageNumber) - 1) * @PageSize + 1 AND @PageNumber * @PageSize

		SELECT @TotalElement = (SELECT COUNT(1) FROM @event_info)

END
GRANT EXECUTE ON [dbo].[spRIS_GetEventsForNCM] TO [ComXClient]