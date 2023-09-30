  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Version + SET NOCOUNT ON/OFF  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CmnInputBuffer  
Author:   Matthew Wells (MSI)  
Date Created:  09/09/03  
  
Description:  
===========  
  
Change Date Who What  
=========== ==== =====  
*/  
  
CREATE procedure dbo.spLocal_CmnInputBuffer  
@SPID int  
AS  
SET NOCOUNT ON  
DBCC InputBuffer (@SPID)  
SET NOCOUNT OFF  
  
