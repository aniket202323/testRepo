 /*  
Stored Procedure:   spLocal_RTCIS_Inter_Conn_Check  
Author:         John Yannone  
Date Created:       Feb 6 2004  
  
Description: Queries sysdate from dual as part of   
             a connection check to SQL Server by   
             the RTCIS Interface.  
*/  
  
  
CREATE procedure dbo.spLocal_RTCIS_Inter_Conn_Check  
--UPPER CASE denotes Parameters IN:  
@RESOURCE_ID     varchar(7)  
  
AS  
  
declare @plid  integer    --Production Line ID.   
  
  
/* Debug  
SELECT @plid = pl_id  
FROM PROD_LINES  
WHERE pl_desc = 'TT GP05'  
  
select @plid */  
  
SELECT @plid = pl_id  
FROM PROD_LINES  
WHERE pl_desc = @RESOURCE_ID  
  
select @plid as LineID  
  
